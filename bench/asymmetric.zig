//! One producer thread, one consumer thread.

const builtin = @import("builtin");
const std = @import("std");
const Allocator = std.mem.Allocator;
const ThreadSafeQueue = @import("ThreadSafeQueue.zig").ThreadSafeQueue;

var debug_allocator: std.heap.DebugAllocator(.{
    .safety = false,
    .stack_trace_frames = 0,
}) = .init;

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

    queue.state = .run;

    const producer = try std.Thread.spawn(.{}, producerRun, .{gpa});
    defer producer.join();

    const consumer = try std.Thread.spawn(.{}, consumerRun, .{gpa});
    defer consumer.join();
}

var queue: ThreadSafeQueue([]const u8) = .empty;
var event: std.Thread.ResetEvent = .{};

fn producerRun(gpa: Allocator) void {
    producerRunFallible(gpa) catch @panic("OOM");
}

fn producerRunFallible(gpa: Allocator) !void {
    for (0..10000000) |n| {
        const string = try std.fmt.allocPrint(gpa, "{d}*{d} = {d}", .{ n, n, n * n });
        if (try queue.enqueue(gpa, &.{string})) event.set();
    }
    if (try queue.enqueue(gpa, &.{"end"})) event.set();
}

fn consumerRun(gpa: Allocator) void {
    var sum: usize = 0;
    outer: while (true) {
        event.reset();
        while (queue.check()) |strings| {
            for (strings) |string| {
                if (std.mem.eql(u8, string, "end")) break :outer;
                defer gpa.free(string);
                for (string) |byte| sum += byte;
            }
        }
        event.wait();
    }
    //std.io.getStdOut().writer().print("sum: {d}\n", .{sum}) catch @panic("write failure");
    if (sum != 16002606398) @panic("wrong answer");
}
