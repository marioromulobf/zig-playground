const std = @import("std");

pub fn build(b: *std.Build) void {
    const exName = "bitonic-api";

    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const zapDep = b.dependency("zap", .{});

    const exeMod = b.addModule(exName, .{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = exName,
        .root_module = exeMod,
    });

    exe.root_module.addImport("zap", zapDep.module("zap"));
    exe.linkSystemLibrary("c");

    b.installArtifact(exe);
}