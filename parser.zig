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


pub fn main() !void {
//    var   temp_buffer : [100] u8 = undefined;
//    var test_fba = std.heap.FixedBufferAllocator.init(&temp_buffer);
//    const test_alloc = test_fba.allocator();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const ally = arena.allocator();


    var photo_info_array = std.ArrayList(PhotoInfo).init(ally);
    
    var line_list = std.ArrayList([] const u8).init(ally);
    defer line_list.deinit();

    // NOTE: The \r is needed for windows newlines!!!
    var line_iter = std.mem.tokenizeAny(u8, test_input, "\r\n");
    while (line_iter.next()) |line| {
        dprint("DEBUG LINE: {s}\n", .{line}); // @debug

        var field_list = std.ArrayList([] const u8).init(ally);
        defer field_list.deinit();

        var field_iter = std.mem.tokenizeAny(u8, line, ",");

        while (field_iter.next()) |field| {
            try field_list.append(field);            
        }
        
        dprint("DEBUG: FIELD LIST:{s}\n", .{field_list.items}); // @debug

        const photo_info_item = PhotoInfo{
            .filename    = field_list.items[0],
            .animal_name = field_list.items[1],
            .url         = field_list.items[2],
            .author      = field_list.items[3],
            .license     = field_list.items[4],
        };

        try photo_info_array.append(photo_info_item);
    }

    dprint("{any}\n", .{photo_info_array.items});
}

