// This is a simple quiz game / app to help learn common butterflies
// native to North America.
//
// Created by 10aded with help from tw0st3p from Dec 2023 - Jan 2024.
//
// This project was compiled using the Zig compiler (version 0.11.0)
// and built with the command:
//
//     zig build -Doptimize=ReleaseFast
//
// run in the top directory of the project.
//
// The entire source code of this project is available on GitHub at:
//
//   https://github.com/10aded/Butterfly-Quiz
//
// and was developed (almost) entirely on the Twitch channel 10aded. Copies of the
// stream are available on YouTube at the @10aded channel.
//
// All photos in the project are from Wikimedia Commons, and as such
// have all be released under various Creative Commons / Public Domain licenses.
// See the README for more information and links to the image sources / licenses.
//
// This project includes a copy of raylib, specifically commit number 710e81.
//
// Raylib is created by github user Ray (@github handle raysan5) and available at:
//
//    https://github.com/raysan5
//
// See the pages above for full license details.

const std = @import("std");
const rl  = @cImport(@cInclude("raylib.h"));

// The database path with all of the photo source / author / license information.
const PHOTO_INFO_FILENAME = "photo-source-license-links.csv";

// The path of the font file, embedded at comptime.
const merriweather_ttf  : [:0] const u8 = @embedFile("./Font/Merriweather-Regular.ttf");

const Vec2   = @Vector(2, f32);

// Color theme.
// The colors below have been selected from the color themes
// - st-8-moonlight
// - gloom-8
// by Skiller Thomson and thatoneaiguy respectively.
// These are available on lospec.com, and are archived at:
//     https://web.archive.org/web/20221128055838/https://lospec.com/palette-list/st-8-moonlight
//     https://web.archive.org/web/20240112214204/https://lospec.com/palette-list/gloom-8
// respectively.

// UI Colors
const BLACK     = rlc(  0,   0,   0);
const WHITE     = rlc(255, 255, 255);
const LBLUE1    = rlc(195, 220, 229);
const LBLUE2    = rlc(163, 190, 204);
const PURPLE1   = rlc( 81,  78,  93);
const PURPLE2   = rlc( 58,  55,  65);
const DARKGRAY1 = rlc( 54,  57,  64);
const DARKGRAY2 = rlc( 34,  36,  38);

const background_color               = DARKGRAY1;
const button_border_color_unselected = BLACK;
const button_fill_color_unselected   = LBLUE2;
const button_hover_color_unselected  = LBLUE1;


const button_border_color_incorrect  = PURPLE2;
const button_fill_color_incorrect    = PURPLE1;


var button_option_font : rl.Font = undefined;
var attribution_font   : rl.Font = undefined;

const option_text_color_default      = BLACK;
const option_text_color_incorrect    = DARKGRAY2;
const attribution_text_color         = WHITE;

// UI Sizes
const border_thickness    = 5;

// Window defaults
const WINDOW_TITLE : [:0] const u8 = "Butterfly Quiz"; // Null-terminated since eventually passed to raylib.
const initial_screen_width  = 1920;
const initial_screen_hidth  = 1080;
const initial_screen_center = Vec2{ 0.5 * initial_screen_width, 0.5 * initial_screen_hidth};

// Screen size
var screen_width : f32  = undefined;
var screen_hidth : f32  = undefined;

// Photo size
var photo_height : f32  = undefined;
var photo_center : Vec2 = undefined;

// Button and button spaces
var button_width            : f32 = undefined;
var button_height           : f32 = undefined;
var button_horizontal_space : f32 = undefined;
var button_vertical_space   : f32 = undefined;

// Game globals
// Mouse
var mouse_pos      : Vec2 = undefined;
var mouse_down_last_frame = false;
var mouse_down            = false;

// Button positions and interaction
var button_positions        : [4] @Vector(2,f32) = undefined;
var button_hover            = [4] bool { false, false, false, false };
var incorrect_option_chosen = [4] bool { false, false, false, false };
var button_clicked = false;
var button_clicked_index : usize = 0;

// Text heights
var attribution_height : f32 = undefined;
var button_text_height : f32 = undefined;

// Question indexes
var current_photo_index:            u32 = undefined;
var photo_indices: [NUMBER_OF_LINES]u32 = undefined;
var current_text_options:        [4]u32 = undefined;

// Random number generator
var prng : std.rand.Xoshiro256 = undefined;

// Photo textures.
var photo_texture_array : [NUMBER_OF_LINES] rl.Texture2D = undefined;


// Count the number of lines (at compile time).
const NUMBER_OF_LINES = count_lines();

fn count_lines() usize {
    // The standard zig documentation has examples about setEvalBranchQuota.
    // Without this a compile error is generated saying the limit is too low.
    @setEvalBranchQuota(30_000);
    var count : usize = 0;
    for (photo_information_csv) |char| {
        if (char == '\n') count += 1;
    }
    // We return one less than count because the first row in the photo information
    // .csv file consists of column titles.
    return count - 1;
}

// Embed the photos (in .qoi format) in ./Photos/ into the .exe
// We use .qoi files over .png files since we ran an experiment (see timing-test.txt)
// and found that while the size of the .exe was about 10% larger when using .png
// versions of the images, the app startup time in both Debug and ReleaseFast modes
// using .qoi files was significantly faster (about 2.5x, 40% faster respectively.)

const embedded_photo_array = embed_photos();

fn embed_photos() [NUMBER_OF_LINES] [:0] const u8 {
    var result  : [NUMBER_OF_LINES] [:0] const u8 = undefined;
    for (0..NUMBER_OF_LINES) |i| {
        const str_i = std.fmt.comptimePrint("{}", .{i});
        result[i] = @embedFile("Photos/" ++ str_i ++ ".qoi");
    }
    return result;
}

// We process the photo metadata in `photo-source-license-links.csv` at
// compile time for use in the quiz.
// While photo-source-license-links.csv is a ; - delimited .csv file,
// instead of processing it with some .csv library, we do it manually by just
// tokenizing over ";" and put the entries into photo_info_array (below).

const photo_information_csv = @embedFile(PHOTO_INFO_FILENAME);

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

// The comptime function we use to process "photo-source-license-links.csv".
// Huge thanks to tw0st3p for carrying me through this part on stream!

fn parse_input() [NUMBER_OF_LINES] PhotoInfo {
    @setEvalBranchQuota(200_000);
    var result : [NUMBER_OF_LINES] PhotoInfo = undefined;
    var photo_info_index = 0;
    
    // Note: Since we complied this on Windows, the \r is needed
    // to deal with the newlines!
    var line_iter = std.mem.tokenizeAny(u8, photo_information_csv, "\r\n");
    while (line_iter.next()) |line| : (photo_info_index += 1){
        if (photo_info_index == 0) continue;
        var field_iter = std.mem.tokenizeAny(u8, line, ";");
        defer std.debug.assert(field_iter.next() == null);

        // We use photo_info_index - 1 instead of photo_info_index since
        // we want to skip the first line (of titles) in the photo info table.
        // Since we render several of these entries as text on screen with raylib,
        // (which, as it is written in C, uses null-terminated strings) we need
        // to convert the strings to be null-terminated, hence the "\x00" bytes.
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

    // @experiment
    // Setup a Timer to see the difference between loading creating textures from
    // .png vs .qoi
    // files.

    // var stopwatch = try std.time.Timer.start();
    
    // Set up RNG.
    const seed  = std.time.milliTimestamp();
    prng        = std.rand.DefaultPrng.init(@intCast(seed));

    // Spawn / setup raylib window.    
    rl.InitWindow(initial_screen_width, initial_screen_hidth, WINDOW_TITLE);
    defer rl.CloseWindow();

    rl.SetWindowState(rl.FLAG_WINDOW_RESIZABLE);
    rl.SetTargetFPS(144);

    // Import font from embedded file.
    const merriweather_font = rl.LoadFontFromMemory(".ttf", merriweather_ttf, merriweather_ttf.len, 108, null, 95);

    button_option_font = merriweather_font;
    attribution_font   = merriweather_font;
    
    // Load butterfly photos.
    // We chose .qoi files over .png since these load faster as textures, see
    // the comments near the procedure embed_photo() for more details.
    //
    // NOTE: All of the photos in this project have been released under
    // creative commons licenses or into the public domain.
    // Their authors, and a link to the source of the photos (and their licenses)
    // can be found in the file
    //
    //     photo-source-license-links.csv.
    //
    // in the GitHub source of this project, linked at the top of this file.

    inline for (0..NUMBER_OF_LINES) |i| {
        photo_texture_array[i] = rl.LoadTextureFromImage(rl.LoadImageFromMemory(".qoi", embedded_photo_array[i], embedded_photo_array[i].len));
    }

    // @experiment
    // Measure texture loading time.
    // const texture_loading_time_nano = stopwatch.read();
    // std.debug.print(".qoi loading time: {}\n", .{std.fmt.fmtDuration(texture_loading_time_nano)});
    
    // Generate a random permutation of all photos.
    const random = prng.random();
    // Create the list {0,1,2,..., NUMBER_OF_LINES - 1}.
    photo_indices = std.simd.iota(u32, NUMBER_OF_LINES);
    // Shuffle the list.
    random.shuffle(u32, &photo_indices);
    // Set up first photo / selection choices.
    current_photo_index = 0;
    update_button_options(photo_indices[current_photo_index]);

    // +----------------+
    // | Main game loop |
    // +----------------+
    while ( ! rl.WindowShouldClose() ) { // Listen for close button or ESC key.

        screen_width = @floatFromInt(rl.GetScreenWidth());
        screen_hidth = @floatFromInt(rl.GetScreenHeight());
        
        photo_center = Vec2 { 0.5 * screen_width, 0.275 * screen_hidth};
        photo_height = 0.45 * screen_hidth;
        
        compute_button_geometry();

        process_input_update_state();

        render();
    }
}

// When text is drawn in raylib, the position parameter passed in determines
// the top-left coordinate of the first character. Since we want to center the
// button text, we need to do some position calculations before calling DrawTextEx.

fn draw_text_center( str : [:0] const u8, pos : Vec2, height : f32, color : rl.Color, font : rl.Font) void {
    const spacing  = height / 10;
    const text_vec = rl.MeasureTextEx(font, str, height, spacing);

    const tl_pos = rl.Vector2{
        .x = pos[0] - 0.5 * text_vec.x,
        .y = pos[1] - 0.5 * text_vec.y,
    };

    rl.DrawTextEx(font, str.ptr, tl_pos, height, spacing, color);    
}

// Draw text where the position determines the top-left coordinate of the first
// character, but now also return the length of the text.

fn draw_text_tl( str : [:0] const u8, pos : Vec2, height : f32, color : rl.Color, font : rl.Font) f32 {
    const spacing  = height / 10;
    const text_vec = rl.MeasureTextEx(font, str, height, spacing);
    const tl_pos   = rl.Vector2{
        .x = pos[0],
        .y = pos[1],
    };
    rl.DrawTextEx(font, str.ptr, tl_pos, height, spacing, color);
    return text_vec.x;
}

// Draw text where the position determines the top-right coordinate
// of the last character.

fn draw_text_tr( str : [:0] const u8, pos : Vec2, height : f32, color : rl.Color, font : rl.Font) void {
    const spacing  = height / 10;
    const text_vec = rl.MeasureTextEx(font, str, height, spacing);

    const tl_pos = rl.Vector2{
        .x = pos[0] - text_vec.x,
        .y = pos[1],
    };

    rl.DrawTextEx(font, str.ptr, tl_pos, height, spacing, color);
}

// Draw a rectangle with a texture, as well as a border for the texture,
// where the position determines the center of the rectangle
// (instead of its top-left coordinate).
// Note: The size of the border is determined by the global border_thickness.

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

// Draw a plain (colored) rectangle, where the position determines the center.

fn draw_centered_rect( pos : Vec2, width : f32, height : f32, color : rl.Color) void {
    const top_left_x : i32 = @intFromFloat(pos[0] - 0.5 * width);
    const top_left_y : i32 = @intFromFloat(pos[1] - 0.5 * height);
    rl.DrawRectangle(top_left_x, top_left_y, @intFromFloat(width), @intFromFloat(height), color);
}


// Our main render procedure, called once per frame.

fn render() void {
    rl.BeginDrawing();
    defer rl.EndDrawing();

    rl.ClearBackground(background_color);

    // Draw the question photo, a border for it, and remember its width.
    const photo_texture_index = photo_indices[current_photo_index];
    const photo_width = draw_bordered_texture(&photo_texture_array[photo_texture_index], photo_center, photo_height, BLACK);

    // Render attribution for the photo.
    attribution_height = 0.04 * screen_hidth;
    const attribution_spacing = 0.01 * screen_hidth;
    const author_pos = Vec2{photo_center[0] - 0.5 * photo_width, photo_center[1] + 0.5 * photo_height + attribution_spacing};
    const author_len = draw_text_tl(photo_info_array[photo_indices[current_photo_index]].author, author_pos, attribution_height, WHITE, attribution_font);

    // Nudge the attribution abbreviation down if it overlaps with the photographer.
    // This can occur (e.g.) in photos with a small width.
    // This is a bit hacky, but gets the job done.
    const license_abbr = photo_info_array[photo_indices[current_photo_index]].licence;
    const text_vec = rl.MeasureTextEx(attribution_font, license_abbr, attribution_height, attribution_height / 10);
    const is_overlapping = photo_width - text_vec.x < author_len;

    var license_pos : Vec2 = author_pos + Vec2{photo_width,0};
    if (is_overlapping) {
        license_pos += Vec2{0, 0.04 * screen_hidth};
    }
    
    draw_text_tr(license_abbr, license_pos, attribution_height, attribution_text_color, attribution_font);
    
    // Set button colors.
    for (button_positions, 0..) |pos, i| {
        var border_color = button_border_color_unselected;
        if (incorrect_option_chosen[i]) {
            border_color = button_border_color_incorrect;
        }
        
        var button_interior_color = button_fill_color_unselected;
        if (button_hover[i]) {
            button_interior_color = button_hover_color_unselected;
            if (incorrect_option_chosen[i]) {
                button_interior_color = button_fill_color_incorrect;
            }
        } else {
            button_interior_color = button_fill_color_unselected;
            if (incorrect_option_chosen[i]) {
                button_interior_color = button_fill_color_incorrect;
            }
        }

        // Draw button rectangles.
        draw_centered_rect(pos, button_width, button_height, border_color);
        const button_fill_width  = @max(0, button_width  - 2 * border_thickness);
        const button_fill_height = @max(0, button_height - 2 * border_thickness);

        draw_centered_rect(pos, button_fill_width, button_fill_height, button_interior_color);
    }

    // Draw button text.
    button_text_height = 0.5 * button_height;
    for (current_text_options, 0..) |opt_i, i| {
        const pos = button_positions[i];
        var text_color = option_text_color_default;
        if (incorrect_option_chosen[i]) {
            text_color = option_text_color_incorrect;
        }
        draw_text_center(photo_info_array[opt_i].common_name, pos, button_text_height, text_color, button_option_font);
    }

    // Draw extra attribution information.
    const attr_message1 : [:0] const u8 = "All the photos in this project are from Wikimedia Commons; url links to their sources and licenses are located at";
    const attr_message2 : [:0] const u8 = "https://github.com/10aded/Butterfly-Quiz in the" ++ " " ++ PHOTO_INFO_FILENAME ++ " " ++ "file";
    const attr_pos = Vec2{0.5 * screen_width, 0.95 * screen_hidth};
    draw_text_center(attr_message1, attr_pos - Vec2{0, 0.02 * screen_hidth}, attribution_height * 0.75, attribution_text_color, attribution_font);
    draw_text_center(attr_message2, attr_pos + Vec2{0, 0.02 * screen_hidth}, attribution_height * 0.75, attribution_text_color, attribution_font);
}

// The sizes of the buttons are dynamic in that they adjust with the dimensions
// of the screen, so their sizes need to be computed. That happens here.

fn compute_button_geometry() void {
    button_width            = 0.4  * screen_width;
    button_height           = 0.1  * screen_hidth;
    button_horizontal_space = 0.05 * screen_width;
    button_vertical_space   = 0.05 * screen_hidth;
    
    const button_grid_center = Vec2 { 0.5 * screen_width, 0.75 * screen_hidth };

    const tl_x = button_grid_center[0] - 0.5 * button_horizontal_space - 0.5 * button_width;
    const tr_x = button_grid_center[0] + 0.5 * button_horizontal_space + 0.5 * button_width;        
    const bl_x = tl_x;
    const br_x = tr_x;
    
    const tl_y = button_grid_center[1] - 0.5 * button_vertical_space - 0.5 * button_height;
    const bl_y = button_grid_center[1] + 0.5 * button_vertical_space + 0.5 * button_height;
    const tr_y = tl_y;
    const br_y = bl_y;
    
    const tl_pos = Vec2{tl_x, tl_y};
    const tr_pos = Vec2{tr_x, tr_y};
    const bl_pos = Vec2{bl_x, bl_y};
    const br_pos = Vec2{br_x, br_y};

    button_positions = [4] @Vector(2,f32) { tl_pos, tr_pos, bl_pos, br_pos};
}

// Get the new mouse positions / mouse clicks, and update the state of the quiz.

fn process_input_update_state() void {
    // Mouse input processing.
    const rl_mouse_pos = rl.GetMousePosition();
    mouse_pos = Vec2 { rl_mouse_pos.x, rl_mouse_pos.y};

    // Detect button clicks.
    mouse_down = rl.IsMouseButtonDown(rl.MOUSE_BUTTON_LEFT);
    defer mouse_down_last_frame = mouse_down;

    // Compute when the mouse is hovering over a button.
    for (button_positions, 0..) |pos, i| {
        const center_diff = pos - mouse_pos;
        button_hover[i] = abs(center_diff[0]) <= 0.5 * button_width and abs(center_diff[1]) <= 0.5 * button_height;
    }

    // Determine a button has been clicked, and if so, what its index is.
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
    // Otherwise fade button color / text when an incorrect choice is clicked.

    const random = prng.random();

    if (button_clicked) {
        // Determined if the correct option was selected.
        if (current_text_options[button_clicked_index] == photo_indices[current_photo_index]) {
            // Correct option selected, so do updates.
            current_photo_index += 1;
            if (current_photo_index == NUMBER_OF_LINES) {
                current_photo_index = 0;
                random.shuffle(u32, &photo_indices);
            }
            update_button_options(photo_indices[current_photo_index]);
            // Reset tracking which incorrect options were clicked.
            incorrect_option_chosen = [4]bool{false, false, false, false};
        } else {
            // An incorrect option was clicked, so track it.
            incorrect_option_chosen[button_clicked_index] = true;
        }
    }
}

// Randomly choose three incorrect options for a given photo,
// and permute these with the correct option.

fn update_button_options(solution_index : u32) void {
    current_text_options[0] = solution_index;
    const random = prng.random();

    // Generate a shuffled list of {0,1,...,NUMBER_OF_LINES - 1}.
    var option_indices: [NUMBER_OF_LINES]u32 = std.simd.iota(u32, NUMBER_OF_LINES);
    random.shuffle(u32, &option_indices);

    // Fill in the other button options from the shuffled list.
    var option_index: u32 = 0;
    for (1..4) |i| {
        if (solution_index == option_indices[option_index]) option_index += 1;
        current_text_options[i] = option_indices[option_index];
        option_index += 1;
    }
    random.shuffle(u32, &current_text_options);
}

// Create a custom Raylib color since apparently it can't be initialized using
// {r,g,b,a} syntax.

fn rlc(r : u8, g : u8, b : u8) rl.Color {
    const rlcolor = rl.Color{
        .r = r,
        .g = g,
        .b = b,
        .a = 255,
    };
    return rlcolor;
}

// In Zig version 0.11.0, the builtin function @abs is not available, (although
// it seems like it will be available in Zig version 0.12.0).
// So this is just a crude absolute value function.
// We know there are more efficient ways to do this (like e.g. those in
// Hacker's Delight by Warren), but this is a simple app so don't @ me!

fn abs(x : f32) f32 {
    return if (x >= 0) x else -x;
}
