const std    = @import("std");
const raySdk = @import("raylib/src/build.zig");

pub fn build(b: *std.Build) void {
	const target = b.standardTargetOptions(.{});

	const optimize = b.standardOptimizeOption(.{});

	const exe = b.addExecutable(.{
		.name = "butterfly-quiz",
		.root_source_file = .{ .path = "main.zig" },
		.target = target,
		.optimize = optimize,
	});

	b.installArtifact(exe);

	var raylib = raySdk.addRaylib(b, target, optimize, .{});
	exe.addIncludePath(.{ .path = "raylib/src" });
	exe.linkLibrary(raylib);

	const run_cmd = b.addRunArtifact(exe);

	run_cmd.step.dependOn(b.getInstallStep());

	if (b.args) |args| {
		run_cmd.addArgs(args);
	}

	const run_step = b.step("run", "run the quiz");
	run_step.dependOn(&run_cmd.step);
}
