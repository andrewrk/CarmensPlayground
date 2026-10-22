const std = @import("std");
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;
const Io = std.Io;

pub fn ThreadSafeQueue(comptime T: type) type {
    return struct {
        worker_owned: std.ArrayListUnmanaged(T),
        /// Protected by `mutex`.
        shared: std.ArrayListUnmanaged(T),
        mutex: Io.Mutex,
        state: State,

        const Self = @This();

        pub const State = enum { wait, run };

        pub const empty: Self = .{
            .worker_owned = .empty,
            .shared = .empty,
            .mutex = .init,
            .state = .wait,
        };

        pub fn deinit(self: *Self, gpa: Allocator) void {
            self.worker_owned.deinit(gpa);
            self.shared.deinit(gpa);
            self.* = undefined;
        }

        /// Must be called from the worker thread.
        pub fn check(self: *Self, io: Io) error{Canceled}!?[]T {
            self.worker_owned.clearRetainingCapacity();
            {
                try self.mutex.lock(io);
                defer self.mutex.unlock(io);
                assert(self.state == .run);
                if (self.shared.items.len == 0) {
                    self.state = .wait;
                    return null;
                }
                std.mem.swap(std.ArrayList(T), &self.worker_owned, &self.shared);
            }
            const result = self.worker_owned.items;
            return result;
        }

        /// Adds items to the queue, returning true if and only if the worker
        /// thread is waiting. Thread-safe.
        /// Not safe to call from the worker thread.
        pub fn enqueue(
            self: *Self,
            io: Io,
            gpa: Allocator,
            items: []const T,
        ) error{ OutOfMemory, Canceled }!bool {
            try self.mutex.lock(io);
            defer self.mutex.unlock(io);
            try self.shared.appendSlice(gpa, items);
            return switch (self.state) {
                .run => false,
                .wait => {
                    self.state = .run;
                    return true;
                },
            };
        }

        /// Safe only to call exactly once when initially starting the worker.
        pub fn start(self: *Self) bool {
            assert(self.state == .wait);
            if (self.shared.items.len == 0) return false;
            self.state = .run;
            return true;
        }
    };
}
