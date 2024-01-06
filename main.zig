// File / Project description here...
// TODO...

// All of the animal names / photo author / photo location is in image-information.txt
//
// This project includes a copy of raylib, specifically commit number 710e81.
//
// Raylib is created by github user Ray (@github handle raysan5) and available at:
//
//    https://github.com/raysan5
//
// See the pages above for full license details.

// NOTE: Currently the order of the animals shown is decided by permuting
// an array of type [NUMBER_OF_LINES] u8, if the quiz has more than 255
// animals errors will likely ensue.

// TODO:
// - Add in detailed README about project, especially about photo licenses.

const std = @import("std");
const rl  = @cImport(@cInclude("raylib.h"));

const PHOTO_INFO_FILENAME = "photo-source-license-links.csv";

const merriweather_ttf  : [:0] const u8 = @embedFile("Merriweather-Regular.ttf");

const dprint = std.debug.print;

const Vec2   = @Vector(2, f32);

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

var button_option_font : rl.Font = undefined;
var attribution_font : rl.Font = undefined;

// UI Sizes
const border_thickness    = 5;

// Window defaults.
const WINDOW_TITLE : [:0] const u8 = "Butterfly Quiz";
const initial_screen_width  = 1920;
const initial_screen_hidth  = 1080;
const initial_screen_center = Vec2{ 0.5 * initial_screen_width, 0.5 * initial_screen_hidth};

// Screen size.
var screen_width : f32  = undefined;
var screen_hidth : f32  = undefined;
var photo_center : Vec2 = undefined;
var photo_height : f32  = undefined;

// Button spaces.
var button_width            : f32 = undefined;
var button_height           : f32 = undefined;
var button_horizontal_space : f32 = undefined;
var button_vertical_space   : f32 = undefined;

// Game globals
// Mouse
var mouse_down_last_frame = false;
var mouse_down            = false;
var mouse_pos : Vec2 = undefined;      

// Button
var button_positions : [4] @Vector(2,f32) = undefined;
var button_hover   = [4] bool { false, false, false, false };
var button_clicked = false;
var button_clicked_index : usize = 0;

// Question indexes
var current_photo_index: u32 = undefined;
var photo_indices: [NUMBER_OF_LINES]u32 = undefined;
var current_text_options: [4]u32 = undefined;

// Rngs
var prng : std.rand.Xoshiro256 = undefined;

// Photo textures.
var   photo_texture_array : [NUMBER_OF_LINES] rl.Texture2D = undefined;

// Count the number of lines at compile time.
const NUMBER_OF_LINES = count_lines();
// NOTE: The order in which the questions are chosen is done by creating
// a array of type [NUMBER_OF_LINES] u8, if a quiz with more than
// 255 animals is desired, types from u8 will need to be updated.

comptime {
    std.debug.assert(NUMBER_OF_LINES < 255);
}


fn count_lines() usize {
    @setEvalBranchQuota(10_000);
    var count : usize = 0;
    for (photo_information_txt) |char| {
        if (char == '\n') count += 1;
    }
    return count - 1; // We return -1 b.c. of headers in the first row of the information table.
}

// Embed the photos in ./Photos/ into the .exe
const embedded_photo_array = embed_photos();

fn embed_photos() [NUMBER_OF_LINES] [:0] const u8 {
    var result : [NUMBER_OF_LINES] [:0] const u8 = undefined;
    for (0..NUMBER_OF_LINES) |i| {
        const str_i = std.fmt.comptimePrint("{}", .{i});
        result[i] = @embedFile("Photos/" ++ str_i ++ ".png");
    }
    return result;
}

// We process the photo metadata in `image-information.txt` at compile time for
// use in the quiz.
// While image-information.txt is a ; - delimited .csv file, instead of processing
// it with some .csv library, we just tokenize over ";" and put the entries into
// photo_info_array.

const photo_information_txt = @embedFile(PHOTO_INFO_FILENAME);
const PhotoInfo = struct{
    filename        : [:0] const u8,
    common_name     : [:0] const u8,
    scientific_name : [:0] const u8,
    url             : [:0] const u8,
    author          : [:0] const u8,
    licence         : [:0] const u8,
    licence_link    : [:0] const u8,
    image_title     : [:0] const u8,
};

const photo_info_array = parse_input();

// The comptime function we use to process "image-information.txt".
// Huge thanks to tw0st3p for carrying me through this part on stream!

fn parse_input() [NUMBER_OF_LINES] PhotoInfo {
    // The standard zig documentation has examples about setEvalBranchQuota.
    // Without this a compile error is generated saying the limit is too low.
    @setEvalBranchQuota(100_000);

    var result : [NUMBER_OF_LINES] PhotoInfo = undefined;
    var photo_info_index = 0;
    
    // NOTE: The \r is needed for windows newlines!!!    
    var line_iter = std.mem.tokenizeAny(u8, photo_information_txt, "\r\n");
    while (line_iter.next()) |line| : (photo_info_index += 1){
        if (photo_info_index == 0) continue;
        var field_iter = std.mem.tokenizeAny(u8, line, ";");
        defer std.debug.assert(field_iter.next() == null);

//        @compileLog(photo_info_index); // @debug
        // The -1 appears below because we skip the first line in the info table.
        result[photo_info_index - 1]  = PhotoInfo{
            .filename        = field_iter.next().? ++ "\x00",
            .common_name     = field_iter.next().? ++ "\x00",
            .scientific_name = field_iter.next().? ++ "\x00",
            .url             = field_iter.next().? ++ "\x00",
            .author          = field_iter.next().? ++ "\x00",
            .licence         = field_iter.next().? ++ "\x00",
            .licence_link    = field_iter.next().? ++ "\x00",
            .image_title     = field_iter.next().? ++ "\x00",
        };
    }
    return result;
}

pub fn main() anyerror!void {
    // Set up RNG.
    const seed   = std.time.milliTimestamp();
    prng   = std.rand.DefaultPrng.init(@intCast(seed));
    
    rl.InitWindow(initial_screen_width, initial_screen_hidth, WINDOW_TITLE);
    defer rl.CloseWindow();

    rl.SetTargetFPS(144);

    // Import fonts.
    //    const default_font = rl.GetFontDefault();
    
    const merriweather_font = rl.LoadFontFromMemory(".ttf", merriweather_ttf, merriweather_ttf.len, 50, null, 95);
    
//    const georgia_font = rl.LoadFontEx("C:/Windows/Fonts/georgia.ttf", 108, null, 95);
    button_option_font = merriweather_font;
    attribution_font   = merriweather_font;
    
    // Load butterfly images.

    // Ludicrously, raylib does not using .jpgs as textures in the intuitive way.
    // (not that they actually tell you this !!!!)
    // Loading .jps caused fails, so the all images are .png files.    
    // As such, every image in this project will be a .png file.
    // All of the photos in this project have either been released to either
    // the public domain or have a creative commons license.
    // Their authors, and a link to the original work and license can be found in
    // image-information.txt.

//    var   photo_image_array   : [NUMBER_OF_LINES] rl.Image     = undefined;

    inline for (0..NUMBER_OF_LINES) |i| {
//        photo_image_array[i]   = rl.LoadImageFromMemory(".png", embedded_photo_array[i], embedded_photo_array[i].len);
        photo_texture_array[i] = rl.LoadTextureFromImage(rl.LoadImageFromMemory(".png", embedded_photo_array[i], embedded_photo_array[i].len));
    }

    // Select a random current_photo_index and shuffle to begin with.
    const random = prng.random();
    photo_indices = std.simd.iota(u32, NUMBER_OF_LINES);
//    dprint("photo indexes before shuffle: {d}\n", .{photo_indices}); // @debug
    random.shuffle(u32, &photo_indices);
//    dprint("photo indexes after shuffle: {d}\n", .{photo_indices}); // @debug
    current_photo_index = 0;
    update_button_options(photo_indices[current_photo_index]);
    
    // Main game loop
    while (!rl.WindowShouldClose()) { // Detect window close button or ESC key

        // TODO: Adjust these when the window size can be adjusted.
        // Update screen dimensions.
        screen_width = initial_screen_width;
        screen_hidth = initial_screen_hidth;
        
        photo_center = Vec2 { 0.5 * screen_width, 0.275 * screen_hidth};
        photo_height = 0.45 * screen_hidth;
        
        compute_button_geometry();

        process_input_update_state();

        render();
    }
}

// In Zig version 0.12, @abs will be available, as of version 0.11 it is not. 
fn abs(x : f32) f32 {
    return if (x >= 0) x else -x;
}

fn draw_text_center( str : [:0] const u8, pos : Vec2, height : f32, color : rl.Color, font : rl.Font) void {
    // TODO: Figure out why <zig string>.ptr works!
//    const rl_string = str.ptr;
    // Figure out the center of the text by measuring the text itself.
    const spacing = height / 10;
    const text_vec = rl.MeasureTextEx(font, str, height, spacing);

    const tl_pos = rl.Vector2{
        .x = pos[0] - 0.5 * text_vec.x,
        .y = pos[1] - 0.5 * text_vec.y,
    };

    rl.DrawTextEx(font, str.ptr, tl_pos, height, spacing, color);    
}

fn draw_text_tl( str : [:0] const u8, pos : Vec2, height : f32, color : rl.Color, font : rl.Font) void {
    const spacing = height / 10;
    const tl_pos = rl.Vector2{
        .x = pos[0],
        .y = pos[1],
    };
    rl.DrawTextEx(font, str.ptr, tl_pos, height, spacing, color);    
}

fn draw_text_tr( str : [:0] const u8, pos : Vec2, height : f32, color : rl.Color, font : rl.Font) void {
    const spacing = height / 10;
    const text_vec = rl.MeasureTextEx(font, str, height, spacing);

    const tl_pos = rl.Vector2{
        .x = pos[0] - text_vec.x,
        .y = pos[1],
    };

    rl.DrawTextEx(font, str.ptr, tl_pos, height, spacing, color);
}

// Draw a centered texture of a specified height.
fn draw_bordered_texture(texturep : *rl.Texture2D, center_pos : Vec2 , height : f32, border_color : rl.Color ) f32 {
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
    return scaled_w;
}

fn draw_centered_rect( pos : Vec2, width : f32, height : f32, color : rl.Color) void {
    const top_left_x : i32 = @intFromFloat(pos[0] - 0.5 * width);
    const top_left_y : i32 = @intFromFloat(pos[1] - 0.5 * height);
    rl.DrawRectangle(top_left_x, top_left_y, @intFromFloat(width), @intFromFloat(height), color);
}


fn render() void {
    rl.BeginDrawing();
    defer rl.EndDrawing();

    rl.ClearBackground(DARKGRAY);

    // Draw image, a border for it, and return the photo width.
    const photo_texture_index = photo_indices[current_photo_index];
    const photo_width = draw_bordered_texture(&photo_texture_array[photo_texture_index], photo_center, photo_height, BLACK);

    // Image attribution.
    const attribution_height = 0.04 * screen_hidth;
    const attribution_spacing = 0.01 * screen_hidth;
    const author_pos = Vec2{photo_center[0] - 0.5 * photo_width, photo_center[1] + 0.5 * photo_height + attribution_spacing};
    draw_text_tl(photo_info_array[photo_indices[current_photo_index]].author, author_pos, attribution_height, WHITE, attribution_font);

    const license_pos = author_pos + Vec2{photo_width, 0};
    draw_text_tr(photo_info_array[photo_indices[current_photo_index]].licence, license_pos, attribution_height, WHITE, attribution_font);
    
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
    for (current_text_options, 0..) |opt_i, i| {
        const pos = button_positions[i];
        draw_text_center(photo_info_array[opt_i].common_name, pos, 50, BLACK, button_option_font);
    }

    // Draw extra attribution information.
    const info_message1 : [:0] const u8 = "All the photos in this project are from Wikimedia Commons; url links to their sources and licenses are located at";
    const info_message2 : [:0] const u8 = "https://github.com/10aded/Butterfly-Quiz in the" ++ PHOTO_INFO_FILENAME ++ "file";
    const info_pos = Vec2{0.5 * screen_width, 0.95 * screen_hidth};
    draw_text_center(info_message1, info_pos - Vec2{0, 0.02 * screen_hidth}, attribution_height * 0.75, WHITE, attribution_font);
    draw_text_center(info_message2, info_pos + Vec2{0, 0.02 * screen_hidth}, attribution_height * 0.75, WHITE, attribution_font);
}

fn compute_button_geometry() void {
    button_width            = 0.4 * screen_width;
    button_height           = 0.1 * screen_hidth;
    button_horizontal_space = 0.05 * screen_width;
    button_vertical_space   = 0.05 * screen_hidth;
    
    const button_grid_center = Vec2 { 0.5 * screen_width, 0.75 * screen_hidth };

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

    button_positions = [4] @Vector(2,f32) { tl_button_pos, 
                                           tr_button_pos,
                                           bl_button_pos,
                                           br_button_pos};
}

fn process_input_update_state() void {
    // Mouse input processing.
    const rl_mouse_pos : rl.Vector2 = rl.GetMousePosition();
    mouse_pos = Vec2 { rl_mouse_pos.x, rl_mouse_pos.y};

    // Detect button clicks.
    mouse_down = rl.IsMouseButtonDown(rl.MOUSE_BUTTON_LEFT);
    defer mouse_down_last_frame = mouse_down;

    // Compute hovers.
    for (button_positions, 0..) |pos, i| {
        button_hover[i] = abs(pos[0] - mouse_pos[0]) <= 0.5 * button_width and abs(pos[1] - mouse_pos[1]) <= 0.5 * button_height;
    }
    
    button_clicked = false;
    button_clicked_index = 0;
    for (0..4) |i| {
        if (button_hover[i] and ! mouse_down_last_frame and mouse_down) {
            button_clicked       = true;
            button_clicked_index = i;
            break;
        }
    }

    // Detect if the correct button was pressed.
    // If so, update current_photo_index and current_text_options.
    // Otherwise (TODO): fade text / color on incorrect button choice
    // (if a button was pressed).

    const random = prng.random();

    if ( button_clicked and current_text_options[button_clicked_index] == photo_indices[current_photo_index] ) {
        // Correct option selected, so do updates.
//        dprint("DEBUG: Correct option selected ({})\n", .{button_clicked_index}); // @debug


        current_photo_index += 1;
        if (current_photo_index == NUMBER_OF_LINES) {
            current_photo_index = 0;
            random.shuffle(u32, &photo_indices);
        }
        update_button_options(photo_indices[current_photo_index]);
    }
}

fn update_button_options(solution_index : u32) void {
    current_text_options[0] = solution_index;
    const random = prng.random();

    // Randomly fill the other options with distinct indexes.
    var indices: [NUMBER_OF_LINES]u32 = std.simd.iota(u32, NUMBER_OF_LINES);
    random.shuffle(u32, &indices);

    var i: u32 = 1;
    for (indices) |index| {
        if (index == solution_index) continue;
        current_text_options[i] = index;
        i += 1;
        if (i == 4) break;
    }

    random.shuffle(u32, &current_text_options);
}

