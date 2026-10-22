//! Many producer threads, one consumer thread, fixed-sized ring buffer to connect them.

const builtin = @import("builtin");
const std = @import("std");
const Allocator = std.mem.Allocator;
const ThreadSafeQueue = @import("ThreadSafeQueue.zig").ThreadSafeQueue;
const Io = std.Io;
const Smp2Allocator = @import("Smp2Allocator.zig");

pub const smp2_allocator: std.mem.Allocator = .{
    .ptr = undefined,
    .vtable = &Smp2Allocator.vtable,
};

var debug_allocator: std.heap.DebugAllocator(.{
    .safety = false,
    .stack_trace_frames = 0,
}) = .init;

const producer_count = 4;
const item_count = 1_000_000_000;
const ring_buffer_capacity = 16;

pub fn main(init: std.process.Init) !void {
    var arena_instance = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const arena = arena_instance.allocator();
    const args = try init.minimal.args.toSlice(arena);
    const io = init.io;

    const Which = enum { debug, smp, smp2, c };
    const which = std.meta.stringToEnum(Which, args[1]) orelse @panic("bad allocator choice");
    const gpa = switch (which) {
        .debug => debug_allocator.allocator(),
        .smp => std.heap.smp_allocator,
        .smp2 => smp2_allocator,
        .c => if (builtin.link_libc) std.heap.c_allocator else @panic("need link libc"),
    };

    var ring_buffer: RingBuffer([]const u8) = try .init(gpa, ring_buffer_capacity);
    defer ring_buffer.deinit(gpa);

    var producers: [producer_count]std.Thread = undefined;
    defer for (producers[0..producer_count]) |producer| producer.join();

    for (producers[0..]) |*producer| {
        producer.* = try std.Thread.spawn(.{}, producerRun, .{ io, gpa, &ring_buffer });
    }

    const consumer = try std.Thread.spawn(.{}, consumerRun, .{ io, gpa, &ring_buffer });
    defer consumer.join();
}

fn producerRun(io: Io, gpa: Allocator, ring_buffer: *RingBuffer([]const u8)) void {
    producerRunFallible(io, gpa, ring_buffer) catch @panic("OOM");
}

fn producerRunFallible(io: Io, gpa: Allocator, ring_buffer: *RingBuffer([]const u8)) !void {
    for (0..item_count) |n| {
        const string = try std.fmt.allocPrint(gpa, "{d}*{d} = {d}", .{ n, n, n * n });
        ring_buffer.push(io, string);
    }
    ring_buffer.push(io, "end");
}

fn consumerRun(io: Io, gpa: Allocator, ring_buffer: *RingBuffer([]const u8)) void {
    var done: u32 = 0;
    var sum: usize = 0;
    while (done < producer_count) {
        const string = ring_buffer.pop(io);
        if (std.mem.eql(u8, string, "end")) {
            done += 1;
            continue;
        }
        for (string) |byte| sum += byte;
        defer gpa.free(string);
    }
    var stdout_file_writer: std.Io.File.Writer = .init(.stdout(), io, &.{});
    const stdout_writer = &stdout_file_writer.interface;
    stdout_writer.print("sum: {d}\n", .{sum}) catch @panic("write failure");
    stdout_writer.flush() catch @panic("flush failure");
}

fn RingBuffer(T: type) type {
    return struct {
        producer_index: u64,
        consumer_index: u64,
        items: []T,
        mutex: Io.Mutex,
        cv: Io.Condition,

        const Self = @This();

        fn init(gpa: Allocator, capacity: usize) !Self {
            return .{
                .producer_index = 0,
                .consumer_index = 0,
                .items = try gpa.alloc(T, capacity),
                .mutex = .init,
                .cv = .init,
            };
        }

        fn push(self: *Self, io: Io, item: T) void {
            self.mutex.lock(io) catch unreachable;
            defer self.mutex.unlock(io);

            while (self.producer_index - self.consumer_index == self.items.len) {
                self.cv.wait(io, &self.mutex) catch unreachable;
            }
            self.items[self.producer_index % self.items.len] = item;
            self.producer_index += 1;
            self.cv.signal(io);
        }

        fn pop(self: *Self, io: Io) T {
            self.mutex.lock(io) catch unreachable;
            defer self.mutex.unlock(io);

            while (self.producer_index == self.consumer_index) {
                self.cv.wait(io, &self.mutex) catch unreachable;
            }
            const item = self.items[self.consumer_index % self.items.len];
            self.consumer_index += 1;
            self.cv.signal(io);
            return item;
        }

        fn deinit(self: *Self, gpa: Allocator) void {
            gpa.free(self.items);
        }
    };
}
