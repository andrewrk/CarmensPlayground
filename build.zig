const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const use_llvm = b.option(bool, "use-llvm", "llvm backend");

    example(b, target, optimize, use_llvm, "symmetric", "bench/symmetric.zig");
    example(b, target, optimize, use_llvm, "asymmetric", "bench/asymmetric.zig");
}

fn example(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.Mode,
    use_llvm: ?bool,
    name: []const u8,
    path: []const u8,
) void {
    const exe = b.addExecutable(.{
        .name = name,
        .root_module = b.createModule(.{
            .root_source_file = b.path(path),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
    exe.use_llvm = use_llvm;
    exe.use_lld = use_llvm;
    b.installArtifact(exe);
}
