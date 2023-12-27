const std = @import("std");

pub fn main() void {
    const x : f32 = 2.1;
    const y = @abs(x);
    try std.debug.print("Hello, {d}!\n", .{y});
}
