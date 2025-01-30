const std     = @import("std");
const builtin = @import("builtin");

// Fail the build if the compiler is too old.
const cv = builtin.zig_version;
const compiler_min   = @Vector(3, u32) {0, 13, 0};
const compiler_curr  = @Vector(3, u32) {cv.major, cv.minor, cv.patch};
const compiler_order = order_compiler(compiler_min, compiler_curr);

comptime {
    if (compiler_order == .gt) { @compileError(old_compiler_error_msg); }
}

pub fn build(b: *std.Build) void {

	const target = b.standardTargetOptions(.{});
	const optimize = b.standardOptimizeOption(.{});

	const exe = b.addExecutable(.{
		.name = "butterfly-quiz",
		.root_source_file = b.path("main.zig"),
		.target = target, .optimize = optimize,
	});

    const raylib_dep = b.dependency("raylib_5_5", .{
        .target = target,
        .optimize = optimize,
    });

    exe.linkLibrary(raylib_dep.artifact("raylib"));
    
    // Usually this is b.installArtifact(exe), but that is just the line below
    // with default options.
    const install_artifact = b.addInstallArtifact(exe, .{
        .dest_dir = .{ .override = .prefix },
    });
    b.getInstallStep().dependOn(&install_artifact.step);

    const run_exe = b.addRunArtifact(exe);
    run_exe.step.dependOn(b.getInstallStep());
    
	const run_step = b.step("run", "run the quiz");
	run_step.dependOn(&run_exe.step);

}

// Procedures for checking that the Zig compiler is new enough.
pub fn order_compiler(left : @Vector(3, usize), right : @Vector(3, usize)) std.math.Order {
    if (left[0] < right[0]) return .lt;
    if (left[0] > right[0]) return .gt;
    if (left[1] < right[1]) return .lt;
    if (left[1] > right[1]) return .gt;
    if (left[2] < right[2]) return .lt;
    if (left[2] > right[2]) return .gt;
    return .eq;
}

const compiler_min_str  = std.fmt.comptimePrint("{d}.{d}.{d}", .{compiler_min[0], compiler_min[1], compiler_min[2]});
const compiler_curr_str = std.fmt.comptimePrint("{d}.{d}.{d}", .{compiler_curr[0], compiler_curr[1], compiler_curr[2]});

const old_compiler_error_msg = "ERROR: Building the project requires the compiler version to be "
    ++ compiler_min_str ++ " at minimum. " ++
    "The current compiler is: " ++ compiler_curr_str ++ ".";
