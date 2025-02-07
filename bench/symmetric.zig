const builtin = @import("builtin");
const std = @import("std");
const Allocator = std.mem.Allocator;

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

    var thread_pool: std.Thread.Pool = undefined;
    try thread_pool.init(.{
        .allocator = gpa,
        .n_jobs = std.Thread.getCpuCount() catch @panic("cpu count"),
    });
    defer thread_pool.deinit();

    for (0..10) |_| {
        var wg: std.Thread.WaitGroup = .{};
        defer wg.wait();

        for (0..1000) |i| {
            thread_pool.spawnWg(&wg, run, .{ gpa, i });
        }
    }
}

fn run(gpa: Allocator, n: usize) void {
    runFallible(gpa, n) catch @panic("OOM");
}

fn runFallible(gpa: Allocator, n: usize) !void {
    var numbers: std.ArrayListUnmanaged(usize) = .empty;
    defer numbers.deinit(gpa);

    for (0..n) |i| {
        try numbers.append(gpa, i);
    }

    var strings: std.AutoArrayHashMapUnmanaged(usize, []const u8) = .empty;
    defer {
        for (strings.values()) |v| gpa.free(v);
        strings.deinit(gpa);
    }

    for (numbers.items) |i| {
        try strings.put(gpa, n, try std.fmt.allocPrint(gpa, "{d}", .{i}));
    }
}
