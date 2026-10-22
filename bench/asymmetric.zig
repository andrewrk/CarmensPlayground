//! One producer thread, one consumer thread.

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

    queue.state = .run;

    const producer = try std.Thread.spawn(.{}, producerRun, .{ io, gpa });
    defer producer.join();

    const consumer = try std.Thread.spawn(.{}, consumerRun, .{ io, gpa });
    defer consumer.join();
}

var queue: ThreadSafeQueue([]const u8) = .empty;
var event: Io.Event = .unset;

fn producerRun(io: Io, gpa: Allocator) void {
    producerRunFallible(io, gpa) catch |err| switch (err) {
        error.Canceled => return,
        error.OutOfMemory => @panic("OOM"),
    };
}

fn producerRunFallible(io: Io, gpa: Allocator) !void {
    for (0..10000000) |n| {
        const string = try std.fmt.allocPrint(gpa, "{d}*{d} = {d}", .{ n, n, n * n });
        if (try queue.enqueue(io, gpa, &.{string})) event.set(io);
    }
    if (try queue.enqueue(io, gpa, &.{"end"})) event.set(io);
}

fn consumerRun(io: Io, gpa: Allocator) void {
    var sum: usize = 0;
    outer: while (true) {
        event.reset();
        while (queue.check(io) catch |err| switch (err) {
            error.Canceled => return,
        }) |strings| {
            for (strings) |string| {
                if (std.mem.eql(u8, string, "end")) break :outer;
                defer gpa.free(string);
                for (string) |byte| sum += byte;
            }
        }
        event.wait(io) catch |err| switch (err) {
            error.Canceled => return,
        };
    }
    //std.io.getStdOut().writer().print("sum: {d}\n", .{sum}) catch @panic("write failure");
    if (sum != 16002606398) @panic("wrong answer");
}
