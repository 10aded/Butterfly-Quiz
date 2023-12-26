// raylib-zig (c) Nikolas Wipper 2023

const std = @import("std");
const rl  = @import("raylib");

// We directly copied some pre-existing raylib bindings by github user Not-Nik (et. al) at:
//
//     https://github.com/Not-Nik/raylib-zig/
//
// We copied commit number 239d3a.
//
// Raylib is created by github user Ray (@raysan5) and available at:
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

    
    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key

        var screen_width : f32 = initial_screen_width;
        var screen_hidth : f32= initial_screen_hidth;
        
        rl.beginDrawing();

        // Draw image.
        const image_center = @Vector(2, f32) { 0.5 * screen_width, 0.3 * screen_hidth};
        const image_height = 0.4 * screen_hidth;
        
        draw_centered_rect(image_center, 500, image_height, rl.Color.gray);

        // Draw text button backgrounds.
        const button_grid_center = @Vector(2, f32) { 0.5 * screen_width, 0.75 * screen_hidth };

        const button_11x = button_grid_center[0] - 0.5 * button_horizontal_space - 0.5 * button_width;
        const button_11y = button_grid_center[1] - 0.5 * button_vertical_space - 0.5 * button_height;
        const button_12x = button_grid_center[0] + 0.5 * button_horizontal_space + 0.5 * button_width;
        const button_12y = button_grid_center[1] - 0.5 * button_vertical_space - 0.5 * button_height;
        const button_21x = button_grid_center[0] - 0.5 * button_horizontal_space - 0.5 * button_width;
        const button_21y = button_grid_center[1] + 0.5 * button_vertical_space + 0.5 * button_height;
        const button_22x = button_grid_center[0] + 0.5 * button_horizontal_space + 0.5 * button_width;
        const button_22y = button_grid_center[1] + 0.5 * button_vertical_space + 0.5 * button_height;        

        const button_11 = @Vector(2, f32){button_11x, button_11y};
        const button_12 = @Vector(2, f32){button_12x, button_12y};
        const button_21 = @Vector(2, f32){button_21x, button_21y};
        const button_22 = @Vector(2, f32){button_22x, button_22y};
        
        draw_centered_rect(button_11, button_width, button_height, rl.Color.gray);
        draw_centered_rect(button_12, button_width, button_height, rl.Color.gray);
        draw_centered_rect(button_21, button_width, button_height, rl.Color.gray);
        draw_centered_rect(button_22, button_width, button_height, rl.Color.gray);        

        
//        const button_centers = [4] @Vector(2, f32) = { button_grid_center[0] - 
        
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.black);

        rl.drawText("Congrats! You created your first window!", 190, 200, 20, rl.Color.white);

    }
}
