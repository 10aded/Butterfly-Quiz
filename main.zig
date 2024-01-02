const std = @import("std");
const rl  = @cImport(@cInclude("raylib.h"));

// We directly included a copy of raylib into our project.
//
// We copied commit number 710e81.
//
// Raylib is created by github user Ray (@github handle raysan5) and available at:
//
//    https://github.com/raysan5
//
// See the pages above for full license details.


// TODO:
// - Add in detailed README about project, especially about photo licenses.
// - Get logic / next screen working.
// - Randomize incorrect name options.
// suggestion: use std.rand.Random.shuffle()
// See https://zigbin.io/56ecb3
// - Randomize photo selection order.

const dprint = std.debug.print;

const Vec2   = @Vector(2, f32);

// All of the animal names / photo author / photo location is in image-information.txt
// We process this at compile for use in the project.
// While image-information.txt is a ; - delimited .csv file, instead of processing
// it with some .csv library, we just tokenize over ";" and put the entries into
// photo_info_array.

const photo_information_txt = @embedFile("image-information.txt");

const embedded_photo_array = embed_photos();

fn embed_photos() [NUMBER_OF_LINES] [:0] const u8 {
    var result : [NUMBER_OF_LINES] [:0] const u8 = undefined;
    for (0..NUMBER_OF_LINES) |i| {
        const str_i = std.fmt.comptimePrint("{}", .{i});
        result[i] = @embedFile("Photos/" ++ str_i ++ ".png");
    }
    return result;
}

const PhotoInfo = struct{
    filename        : [:0] const u8,
    common_name     : [:0] const u8,
    scientific_name : [:0] const u8,
    url             : [:0] const u8,
    author          : [:0] const u8,
    licence         : [:0] const u8,
    licence_link    : [:0] const u8,
};

const photo_info_array = parse_input();

// Colors
const RED    = rl.RED;
const YELLOW = rl.YELLOW;
const GOLD   = rl.GOLD;

const BLACK     = rl.BLACK;
const DARKGRAY  = rl.DARKGRAY;
const GRAY      = rl.GRAY;
const LIGHTGRAY = rl.LIGHTGRAY;
const WHITE     = rl.WHITE;

// UI Colors
const background_color    = DARKGRAY;
const button_border_color = BLACK;
const button_fill_color   = LIGHTGRAY;
const button_hover_color  = YELLOW;

const text_color          = GOLD;

// UI Sizes
const border_thickness    = 5;

// Screen defaults.
const initial_screen_width  = 1920;
const initial_screen_hidth  = 1080;
const initial_screen_center = Vec2{ 0.5 * initial_screen_width, 0.5 * initial_screen_hidth};

// Button spaces.
const button_width  = 0.4 * initial_screen_width;
const button_height = 0.1 * initial_screen_hidth;
const button_horizontal_space = 0.1 * initial_screen_width;
const button_vertical_space   = 0.1 * initial_screen_hidth; 

// Helpful notes (thanks tw0st3p) (again!)
// * dupeZ in mem/Allocator.zig duplicates memory but adds a 0 byte on the end of it.
// * @setEvalBranchQuota(<num>) may need to be set for large comptime loops.
//   The standard zig documentation has examples about this.

const NUMBER_OF_LINES = count_lines();

fn count_lines() usize {
    var count : usize = 0;
    for (photo_information_txt) |char| {
        if (char == '\n') count += 1;
    }
    return count;
}

// The comptime function we use to process "image-information.txt".
// Huge thanks to tw0st3p for carrying me through this part on stream!

fn parse_input() [NUMBER_OF_LINES] PhotoInfo {
    @setEvalBranchQuota(10_000);

    //    @compileLog(NUMBER_OF_LINES);
    var   result : [NUMBER_OF_LINES] PhotoInfo = undefined;
    var photo_info_index = 0;
    
    // NOTE: The \r is needed for windows newlines!!!    
    var line_iter = std.mem.tokenizeAny(u8, photo_information_txt, "\r\n");
    while (line_iter.next()) |line| : (photo_info_index += 1){ 
        var field_iter = std.mem.tokenizeAny(u8, line, ";");
        defer std.debug.assert(field_iter.next() == null);

        // May need @compileLog()
        //        @compileLog(line);
        result[photo_info_index]  = PhotoInfo{
            .filename        = field_iter.next().? ++ "\x00",
            .common_name     = field_iter.next().? ++ "\x00",
            .scientific_name = field_iter.next().? ++ "\x00",
            .url             = field_iter.next().? ++ "\x00",
            .author          = field_iter.next().? ++ "\x00",
            .licence         = field_iter.next().? ++ "\x00",
            .licence_link    = field_iter.next().? ++ "\x00",
        };
        //        @compileLog(result[photo_info_index]);
    }
    return result;
}

pub fn main() anyerror!void {

    //    dprint("Number of lines: {}\n", .{NUMBER_OF_LINES}); // @debug
    dprint("{any}\n", .{photo_info_array}); // @debug
    
    rl.InitWindow(initial_screen_width, initial_screen_hidth, "Butterfly Quiz");
    defer rl.CloseWindow();

    rl.SetTargetFPS(144);

    // Import fonts.
    //    const default_font = rl.GetFontDefault();
    const georgia_font = rl.LoadFontEx("C:/Windows/Fonts/georgia.ttf", 200, null, 95);
    
    var mouse_down_last_frame = false;

    // Load butterfly image.

    // Ludicrously, raylib does not using .jpgs as textures in the intuitive way.
    // (not that they actually tell you this !!!!
    // As such, every image in this project will be a .png file.
    // All of the photos in this project have either been released to the public domain or have a creative commons license; their authors, and a link to the original work and license can be found in image-information.txt.

    // NOTE: Loading .jps caused fails, so the convention is that all images are .png files.

    var   photo_image_array   : [NUMBER_OF_LINES] rl.Image     = undefined;
    var   photo_texture_array : [NUMBER_OF_LINES] rl.Texture2D = undefined;

    inline for (0..NUMBER_OF_LINES) |i| {
        photo_image_array[i]   = rl.LoadImageFromMemory(".png", embedded_photo_array[i], embedded_photo_array[i].len);
        photo_texture_array[i] = rl.LoadTextureFromImage(photo_image_array[i]);

    }


    var current_photo_index  : u32 = 0;

    var current_text_options = [4] u32{0, 1, 2, 3};
    
    // Main game loop
    while (!rl.WindowShouldClose()) { // Detect window close button or ESC key

        var screen_width : f32 = initial_screen_width;
        var screen_hidth : f32 = initial_screen_hidth;

        // Draw image.
        const image_center = Vec2 { 0.5 * screen_width, 0.3 * screen_hidth};
        const image_height = 0.5 * screen_hidth;
        
        // Determine button positions.
        const button_grid_center = Vec2 { 0.5 * screen_width, 0.8 * screen_hidth };

        const tl_button_x = button_grid_center[0] - 0.5 * button_horizontal_space - 0.5 * button_width;
        const tr_button_x = button_grid_center[0] + 0.5 * button_horizontal_space + 0.5 * button_width;        
        const bl_button_x = tl_button_x;
        const br_button_x = tr_button_x;
        
        const tl_button_y = button_grid_center[1] - 0.5 * button_vertical_space - 0.5 * button_height;
        const tr_button_y = tl_button_y;
        const bl_button_y = button_grid_center[1] + 0.5 * button_vertical_space + 0.5 * button_height;
        const br_button_y = bl_button_y;
        
        const tl_button_pos = Vec2{tl_button_x, tl_button_y};
        const tr_button_pos = Vec2{tr_button_x, tr_button_y};
        const bl_button_pos = Vec2{bl_button_x, bl_button_y};
        const br_button_pos = Vec2{br_button_x, br_button_y};

        const button_positions = [4] @Vector(2,f32) { tl_button_pos, 
                                                     tr_button_pos,
                                                     bl_button_pos,
                                                     br_button_pos};

        // Mouse input processing.
        const rl_mouse_pos : rl.Vector2 = rl.GetMousePosition();
        const mouse_pos = Vec2 { rl_mouse_pos.x, rl_mouse_pos.y};

        var button_hover   = [4] bool { false, false, false, false };

        // Compute hovers.
        for (button_positions, 0..) |pos, i| {
            button_hover[i] = abs(pos[0] - mouse_pos[0]) <= 0.5 * button_width and abs(pos[1] - mouse_pos[1]) <= 0.5 * button_height;
        }

        // Detect button clicks.
        const mouse_down = rl.IsMouseButtonDown(rl.MOUSE_BUTTON_LEFT);
        defer mouse_down_last_frame = mouse_down;

        var button_clicked = false;
        var button_clicked_index : usize = 0;
        for (0..4) |i| {
            if (button_hover[i] and ! mouse_down_last_frame and mouse_down) {
                button_clicked       = true;
                button_clicked_index = i;
                break;
            }
        }

        if ( button_clicked ) {
            dprint("{s}{d}\n", .{"button clicked:", button_clicked_index}); // @debug
        }
        
        // Detect if the correct button was pressed.
        // If so, update current_photo_index and current_text_options.
        // Otherwise (TODO): fade text / color on incorrect button choice
        // (if a button was pressed).

        if ( button_clicked and current_text_options[button_clicked_index] == current_photo_index ) {
            // Correct option selected, so do updates.
            dprint("DEBUG: Correct option selected ({})\n", .{button_clicked_index});
            // TODO: Randomize this!
            current_photo_index += 1;
            current_photo_index %= 4;
            const temp = current_text_options[0];
            for (0..3) |i| {
                current_text_options[i] = current_text_options[i + 1];
            }
            current_text_options[3] = temp;
        }
        
        rl.BeginDrawing();

        rl.ClearBackground(DARKGRAY);

        // Draw button colors.
        for (button_positions, 0..) |pos, i| {
            var button_interior_color = button_fill_color;
            if (button_hover[i]) {
                button_interior_color = button_hover_color;
            }
            draw_centered_rect(pos, button_width, button_height, button_border_color);
            const button_fill_width  = @max(0, button_width  - 2 * border_thickness);
            const button_fill_height = @max(0, button_height - 2 * border_thickness);
            draw_centered_rect(pos, button_fill_width, button_fill_height, button_interior_color);
        }

        // Draw button text.

        // var   button_text : [4] [] const u8 = undefined;
        // for (0..4) |i| {
            
        //     button_text[i] = photo_info_array[i].common_name;
        // }
        //        const button_text = [4] [] const u8{"Hackberry", "Little Copper", "Queen", "Little Yellow"};
        
        for (current_text_options, 0..) |opt_i, i| {
            const pos = button_positions[i];
            draw_text(photo_info_array[opt_i].common_name, pos, 50, BLACK, georgia_font);
        }

        // Draw image (and a border for it).
        
        draw_bordered_texture(&photo_texture_array[current_photo_index], image_center, image_height, BLACK);
        
        defer rl.EndDrawing();

    }
}

// In Zig version 0.12, @abs will be available, as of version 0.11 it is not. 
fn abs(x : f32) f32 {
    return if (x >= 0) x else -x;
}

// TODO: Make Vec2 type.
fn draw_text( str : [] const u8, pos : Vec2, height : f32, color : rl.Color, font : rl.Font) void {
    // TODO: Figure out why <zig string>.ptr works!
    const rl_string = str.ptr;
    // Figure out the center of the text by measuring the text itself.
    const spacing = height / 10;
    const text_vec = rl.MeasureTextEx(font, rl_string, height, spacing);

    const tl_pos = rl.Vector2{
        .x = pos[0] - 0.5 * text_vec.x,
        .y = pos[1] - 0.5 * text_vec.y,
    };

    rl.DrawTextEx(font, rl_string, tl_pos, height, spacing, color);    
}


// Draw a centered texture of a specified height.
fn draw_bordered_texture(texturep : *rl.Texture2D, center_pos : Vec2 , height : f32, border_color : rl.Color ) void {
    const twidth  : f32  = @floatFromInt(texturep.*.width);
    const theight : f32  = @floatFromInt(texturep.*.height);
    
    const scaling_ratio  = height / theight;
    
    const scaled_h  = height;
    const scaled_w  = scaled_h * twidth / theight;
    
    const dumb_rl_tl_vec2 = rl.Vector2{
        .x = center_pos[0] - 0.5 * scaled_w,
        .y = center_pos[1] - 0.5 * scaled_h,
    };
    // The 3rd arg (0) is for rotation.
    draw_centered_rect(center_pos, scaled_w + 2 * border_thickness, height + 2 * border_thickness, border_color);
    rl.DrawTextureEx(texturep.*, dumb_rl_tl_vec2, 0, scaling_ratio, WHITE);
}

fn draw_centered_rect( pos : Vec2, width : f32, height : f32, color : rl.Color) void {
    const top_left_x : i32 = @intFromFloat(pos[0] - 0.5 * width);
    const top_left_y : i32 = @intFromFloat(pos[1] - 0.5 * height);
    rl.DrawRectangle(top_left_x, top_left_y, @intFromFloat(width), @intFromFloat(height), color);
}
