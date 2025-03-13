const std = @import("std");

const embedded_photos = embed_photos();

//const NUMBER = 72; // Builds fine.
const NUMBER = 73; // Gives weird compile error with no reference to this file.

fn embed_photos() [NUMBER] [:0] const u8 {
    var result : [NUMBER] [:0] const u8 = undefined;
    for (0..NUMBER) |i| {
        const str_i = std.fmt.comptimePrint("{}", .{i});
        result[i] = @embedFile("Photos/" ++ str_i ++ ".qoi");
    }
    return result;
}

pub fn main() anyerror!void {
    std.debug.print("{any}\n", .{embedded_photos});
}
