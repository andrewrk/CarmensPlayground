//! Many producer threads, one consumer thread, fixed-sized ring buffer to connect them.

const builtin = @import("builtin");
const std = @import("std");
const Allocator = std.mem.Allocator;
const ThreadSafeQueue = @import("ThreadSafeQueue.zig").ThreadSafeQueue;

var debug_allocator: std.heap.DebugAllocator(.{
    .safety = false,
    .stack_trace_frames = 0,
}) = .init;

const producer_count = 4;
const item_count = 1_000_000_000;
const ring_buffer_capacity = 16;

pub fn main() !void {
    var arena_instance = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const arena = arena_instance.allocator();
    const args = try std.process.argsAlloc(arena);

    const Which = enum { debug, smp, c };
    const which = std.meta.stringToEnum(Which, args[1]) orelse @panic("bad allocator choice");
    const gpa = switch (which) {
        .debug => debug_allocator.allocator(),
        .smp => std.heap.smp_allocator,
        .c => if (builtin.link_libc) std.heap.raw_c_allocator else @panic("need link libc"),
    };

    var ring_buffer: RingBuffer([]const u8) = try .init(gpa, ring_buffer_capacity);
    defer ring_buffer.deinit(gpa);

    var producers: [producer_count]std.Thread = undefined;
    defer for (producers[0..producer_count]) |producer| producer.join();

    for (producers[0..]) |*producer| {
        producer.* = try std.Thread.spawn(.{}, producerRun, .{ gpa, &ring_buffer });
    }

    const consumer = try std.Thread.spawn(.{}, consumerRun, .{ gpa, &ring_buffer });
    defer consumer.join();
}

fn producerRun(gpa: Allocator, ring_buffer: *RingBuffer([]const u8)) void {
    producerRunFallible(gpa, ring_buffer) catch @panic("OOM");
}

fn producerRunFallible(gpa: Allocator, ring_buffer: *RingBuffer([]const u8)) !void {
    for (0..item_count) |n| {
        const string = try std.fmt.allocPrint(gpa, "{d}*{d} = {d}", .{ n, n, n * n });
        ring_buffer.push(string);
    }
    ring_buffer.push("end");
}

fn consumerRun(gpa: Allocator, ring_buffer: *RingBuffer([]const u8)) void {
    var done: u32 = 0;
    var sum: usize = 0;
    while (done < producer_count) {
        const string = ring_buffer.pop();
        if (std.mem.eql(u8, string, "end")) {
            done += 1;
            continue;
        }
        for (string) |byte| sum += byte;
        defer gpa.free(string);
    }
    std.io.getStdOut().writer().print("sum: {d}\n", .{sum}) catch @panic("write failure");
    // if (sum != 16002606398) @panic("wrong answer");
}

fn RingBuffer(T: type) type {
    return struct {
        producer_index: u64,
        consumer_index: u64,
        items: []T,
        mutex: std.Thread.Mutex,
        cv: std.Thread.Condition,

        const Self = @This();

        fn init(gpa: Allocator, capacity: usize) !Self {
            return .{
                .producer_index = 0,
                .consumer_index = 0,
                .items = try gpa.alloc(T, capacity),
                .mutex = .{},
                .cv = .{},
            };
        }

        fn push(self: *Self, item: T) void {
            self.mutex.lock();
            defer self.mutex.unlock();

            while (self.producer_index - self.consumer_index == self.items.len) {
                self.cv.wait(&self.mutex);
            }
            self.items[self.producer_index % self.items.len] = item;
            self.producer_index += 1;
            self.cv.signal();
        }

        fn pop(self: *Self) T {
            self.mutex.lock();
            defer self.mutex.unlock();

            while (self.producer_index == self.consumer_index) {
                self.cv.wait(&self.mutex);
            }
            const item = self.items[self.consumer_index % self.items.len];
            self.consumer_index += 1;
            self.cv.signal();
            return item;
        }

        fn deinit(self: *Self, gpa: Allocator) void {
            gpa.free(self.items);
        }
    };
}
