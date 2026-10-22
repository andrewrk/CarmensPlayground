//! Thread pool with all threads doing roughly the same thing.

const builtin = @import("builtin");
const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

var debug_allocator: std.heap.DebugAllocator(.{
    .safety = false,
    .stack_trace_frames = 0,
}) = .init;

pub fn main(init: std.process.Init) !void {
    var arena_instance = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const arena = arena_instance.allocator();
    const args = try init.minimal.args.toSlice(arena);

    const Which = enum { debug, smp, c };
    const which = std.meta.stringToEnum(Which, args[1]) orelse @panic("bad allocator choice");
    const gpa = switch (which) {
        .debug => debug_allocator.allocator(),
        .smp => std.heap.smp_allocator,
        .c => if (builtin.link_libc) std.heap.c_allocator else @panic("need link libc"),
    };

    var io_threaded: Io.Threaded = .init(gpa, .{});
    const io: Io = io_threaded.io();

    for (0..20) |_| {
        var g: Io.Group = .init;
        defer g.await(io) catch |err| switch (err) {
            error.Canceled => {},
        };
        for (0..2000) |i| {
            g.async(io, run, .{ gpa, i });
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
