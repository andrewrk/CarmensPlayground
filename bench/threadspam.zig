//! One producer thread, one consumer thread.

const builtin = @import("builtin");
const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

var debug_allocator: std.heap.DebugAllocator(.{
    .safety = false,
    .stack_trace_frames = 0,
}) = .init;

// Will allocate 8KiB per iteration, so this will stay under 1GiB.
const iteration_count = 100_000;

pub fn main(init: std.process.Init) !void {
    var arena_instance = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const arena = arena_instance.allocator();
    const args = try init.minimal.args.toSlice(arena);
    const io = init.io;

    const Which = enum { debug, smp, c };
    const which = std.meta.stringToEnum(Which, args[1]) orelse @panic("bad allocator choice");
    const gpa = switch (which) {
        .debug => debug_allocator.allocator(),
        .smp => std.heap.smp_allocator,
        .c => if (builtin.link_libc) std.heap.c_allocator else @panic("need link libc"),
    };

    try work(io, gpa, iteration_count);
}

fn alloc_and_free(alloc: std.mem.Allocator) !void {
    const b1 = try alloc.alloc(u8, 1 << 13);
    defer alloc.free(b1);
    const b2 = try alloc.alloc(u8, 1 << 12);
    defer alloc.free(b2);
}

pub fn work(io: std.Io, alloc: std.mem.Allocator, spam_count: usize) !void {
    for (0..spam_count) |_| {
        const t = try std.Thread.spawn(.{}, alloc_and_free, .{alloc});
        t.join();
        // Without a call to sleep this will pass too quickly to observe.
        try Io.sleep(io, .fromMilliseconds(2), .awake);
    }
}
