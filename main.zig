// TODO: Determine when the mouse is hovering over a button, and register when it is clicked over a button too.


const std = @import("std");
const rl  = @import("raylib");

const dprint = std.debug.print;

const GRAY = rl.Color.gray;
const RED  = rl.Color.red;
const YELLOW = rl.Color.yellow;

// We directly copied some pre-existing raylib bindings by Nikolas Wipper (@github handle Not-Nik) et. al at:
//
//     https://github.com/Not-Nik/raylib-zig/
//
// We copied commit number 239d3a.
//
// The linceraylib-zig (c)  2023//
//
// Raylib is created by github user Ray (@github handle raysan5) and available at:
//
//    https://github.com/raysan5
//
// See the pages above for full license details.

const initial_screen_width  = 1920;
const initial_screen_hidth  = 1080;
const initial_screen_center = @Vector(2, f32){ 0.5 * initial_screen_width, 0.5 * initial_screen_hidth};

// Button spaces.
const button_width  = 0.3 * initial_screen_width;
const button_height = 0.1 * initial_screen_hidth;
const button_horizontal_space = 0.1 * initial_screen_width;
const button_vertical_space   = 0.1 * initial_screen_hidth; 

fn draw_centered_rect( pos : @Vector(2, f32), width : f32, height : f32, color : rl.Color) void {
    const top_left_x : i32 = @intFromFloat(pos[0] - 0.5 * width);
    const top_left_y : i32 = @intFromFloat(pos[1] - 0.5 * height);
    rl.drawRectangle(top_left_x, top_left_y, @intFromFloat(width), @intFromFloat(height), color);
}

pub fn main() anyerror!void {


    rl.initWindow(initial_screen_width, initial_screen_hidth, "raylib-zig [core] example - basic window");
    defer rl.closeWindow();

    rl.setTargetFPS(144);

    var mouse_down_last_frame = false;

    // Load butterfly image.

    // TODO:
    // Ludicrously, raylib does not using .jpgs as textures in the intuitive way.
    // (not that they actually tell you this !!!!
    // As such, every image in this project will be a .png file.
    // All of the photos in this project have either been released to the public domain or have a creative commons license; their authors, and a link to the original work and license can be found in image-information.txt.

    // TODO: Convert to loading from memory proc.
    
    //    const butterfly1 : rl.Image = rl.loadImage("0.jpg");
    var butterfly1 : rl.Image = rl.loadImage("0.png");
    
    // Determine width and height of image...
    const iwidth  : f32 = @floatFromInt(butterfly1.width);
    const iheight : f32 = @floatFromInt(butterfly1.height);

    const scaled_width = 500 * iwidth / iheight;
    
    // Scale image so that height is 500.
    
    rl.imageResize(&butterfly1, @intFromFloat(scaled_width), 500);
    
    const texture1 : rl.Texture2D = rl.loadTextureFromImage(butterfly1);
    
    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key

        var screen_width : f32 = initial_screen_width;
        var screen_hidth : f32= initial_screen_hidth;

        // Draw image.
        const image_center = @Vector(2, f32) { 0.5 * screen_width, 0.3 * screen_hidth};
        const image_height = 0.4 * screen_hidth;
        
        draw_centered_rect(image_center, 500, image_height, GRAY);

        // Determine button positions.
        const button_grid_center = @Vector(2, f32) { 0.5 * screen_width, 0.75 * screen_hidth };

        const tl_button_x = button_grid_center[0] - 0.5 * button_horizontal_space - 0.5 * button_width;
        const tr_button_x = button_grid_center[0] + 0.5 * button_horizontal_space + 0.5 * button_width;        
        const bl_button_x = tl_button_x;
        const br_button_x = tr_button_x;
        
        const tl_button_y = button_grid_center[1] - 0.5 * button_vertical_space - 0.5 * button_height;
        const tr_button_y = tl_button_y;
        const bl_button_y = button_grid_center[1] + 0.5 * button_vertical_space + 0.5 * button_height;
        const br_button_y = bl_button_y;
        
        const tl_button_pos = @Vector(2, f32){tl_button_x, tl_button_y};
        const tr_button_pos = @Vector(2, f32){tr_button_x, tr_button_y};
        const bl_button_pos = @Vector(2, f32){bl_button_x, bl_button_y};
        const br_button_pos = @Vector(2, f32){br_button_x, br_button_y};

        const button_positions = [4] @Vector(2,f32) { tl_button_pos, 
                                                      tr_button_pos,
                                                      bl_button_pos,
                                                      br_button_pos};

        // Mouse input processing.
        const rl_mouse_pos : rl.Vector2 = rl.getMousePosition();
        const mouse_pos = @Vector(2, f32) { rl_mouse_pos.x, rl_mouse_pos.y};

        var button_hover   = [4] bool { false, false, false, false };

        // Compute hovers.
        for (button_positions, 0..) |pos, i| {
            button_hover[i] = abs(pos[0] - mouse_pos[0]) <= 0.5 * button_width and abs(pos[1] - mouse_pos[1]) <= 0.5 * button_height;
        }

        // Detect button clicks.
        var button_clicked = [4] bool { false, false, false, false };
        const mouse_down = rl.isMouseButtonDown(rl.MouseButton.mouse_button_left);
        defer mouse_down_last_frame = mouse_down;

        for (0..4) |i| {
            button_clicked[i] = button_hover[i] and ! mouse_down_last_frame and mouse_down;
            if ( button_clicked[i] ) {
                dprint("{s}{d}\n", .{"button clicked:", i}); // @debug
            }
        }


        
        rl.beginDrawing();

        for (button_positions, 0..) |pos, i| {
            const button_color = if (button_clicked[i]) YELLOW else (if (button_hover[i]) RED else GRAY);
            draw_centered_rect(pos, button_width, button_height, button_color);
        }

        // TODO: Use actual image center instead.
//        butterfly1.drawImage(
        rl.drawTexture(texture1, 0, 0, rl.Color.white);
        
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.black);

        rl.drawText("Congrats! You created your first window!", 190, 200, 20, rl.Color.white);

    }
}

// In Zig version 0.12, @abs will be available, as of version 0.11 it is not. 
fn abs(x : f32) f32 {
    return if (x >= 0) x else -x;
}
