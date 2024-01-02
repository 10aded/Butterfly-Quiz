const std = @import("std");
const RndGen = std.rand.DefaultPrng;

pub fn main() void {
    const seed = std.time.milliTimestamp();
    var prng = std.rand.DefaultPrng.init(@intCast(seed));
    const random = prng.random();
    const i = random.intRangeAtMost(u8, 0, 10);
    std.debug.print("{}\n", .{i});
}
