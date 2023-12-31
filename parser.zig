const std = @import("std");

const dprint = std.debug.print;

const test_input = @embedFile("test.txt");

const PhotoInfo = struct{
    filename    : [] const u8,
    animal_name : [] const u8,
    url         : [] const u8,
    author      : [] const u8,
    license     : [] const u8,
};


const NUMBER_OF_LINES = std.mem.count(u8, test_input, "\n");

const photo_info_array = parse_input();

fn parse_input() [NUMBER_OF_LINES] PhotoInfo {

    var   result : [NUMBER_OF_LINES] PhotoInfo = undefined;
    var photo_info_index = 0;
    
    // NOTE: The \r is needed for windows newlines!!!    
    var line_iter = std.mem.tokenizeAny(u8, test_input, "\r\n");
    while (line_iter.next()) |line| : (photo_info_index += 1){ 

        var field_iter = std.mem.tokenizeAny(u8, line, ",");
        
        result[photo_info_index]  = PhotoInfo{
            .filename    = field_iter.next().?,
            .animal_name = field_iter.next().?,
            .url         = field_iter.next().?,
            .author      = field_iter.next().?,
            .license     = field_iter.next().?,
        };

    }
    return result;
}

pub fn main() !void {
    dprint("{any}\n", .{photo_info_array});
}
