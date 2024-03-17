`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.03.2024 15:53:04
// Design Name: 
// Module Name: task_c
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module adaptor_task_c(
    // Control
    input reset, input clk,
    // LEDs, Switches, Buttons
    input btnC, btnU, btnL, btnR, btnD, input [15:0] sw, output [15:0] led,
    // 7 Segment Display
    output [6:0] seg, output dp, output [3:0] an,
    // OLED
    input [12:0] oled_pixel_index, output reg [15:0] oled_pixel_data
);
    // Ease of usage
    reg [7:0] xpos; // = pixel_index % 96;
    reg [7:0] ypos; // = pixel_index / 96;
    // Animation variables
    reg [7:0] square_xpos = 45;
    reg [7:0] square_ypos = 0;
    reg btnD_prev = 0;
    reg animation_active = 0;
    reg [31:0] animation_counter = 0;
    reg square_color_changed = 0;
    reg [7:0] expand_xpos = 60; // Starting position for expansion
    reg [7:0] expand_width = 0; // Width of the expansion
    reg [31:0] expand_counter = 0; // Counter for expansion animation
    reg expand_active = 0; // Flag to indicate if expansion animation is active
    reg square_color_reset = 0; // Flag to indicate if Square color has been reset at the end
    reg [31:0] red_trail_counter = 0;
    reg red_trail_active = 0;
    reg [7:0] vertical_expand_ypos = 30; // Starting position for vertical expansion
    reg [7:0] vertical_expand_height = 0; // Height of the vertical expansion
    reg [31:0] vertical_expand_counter = 0; // Counter for vertical expansion animation
    reg vertical_expand_active = 0; // Flag to indicate if vertical expansion animation is active
    
    // Task for button press detection
    task button_press_detection;
        begin
            btnD_prev <= btnD;
            if (!btnD_prev && btnD) begin
                animation_active <= 1;
                animation_counter <= 0;
                square_color_changed <= 0;
                expand_active <= 0; // Disable expansion animation initially
                vertical_expand_active <= 0; // Disable vertical expansion animation initially
            end
        end
    endtask
    
    // Task for animation control
    task animation_control;
        begin
            if (animation_active) begin
                animation_counter <= animation_counter + 1;
                if (animation_counter < 93750000) begin // 1.5 seconds at 62.5 MHz
                    square_ypos <= (animation_counter * 35) / 93750000;
                end else if (animation_counter < 140625000) begin // Additional 0.75 seconds at 62.5 MHz
                    square_xpos <= 45 + ((animation_counter - 93750000) * 15) / 46875000;
                end else if (animation_counter < 171875000 && !square_color_changed) begin // Additional 0.5 seconds at 62.5 MHz
                    if (animation_counter == 171874999) begin
                        square_color_changed <= 1;
                    end
                end else if (animation_counter >= 171875000 && animation_counter < 203125000) begin // Additional 0.5 seconds at 62.5 MHz
                    if (animation_counter == 203124999) begin
                        expand_active <= 1; // Start expansion animation after 0.5 seconds
                    end
                end else if (animation_counter >= 203125000 && animation_counter < 234375000) begin // Additional 0.5 seconds at 62.5 MHz
                    if (animation_counter == 234374999) begin
                        vertical_expand_active <= 1; // Start vertical expansion animation after 0.5 seconds
                    end
                end else begin
                    animation_active <= 0;
                    square_xpos <= 60;
                    square_ypos <= 35;
                end
            end
        end
    endtask
    
    // Task for red trail control
    task red_trail_control;
        begin
            if (expand_active == 0 && expand_width == 15) begin // Change condition to expand_width == 15
                red_trail_counter <= red_trail_counter + 1;
                if (red_trail_counter == 31250000) begin // 0.5 seconds at 62.5 MHz
                    red_trail_active <= 1;
                end
            end
        end
    endtask
    
    // Task for expansion animation
    task expansion_animation;
        begin
            if (expand_active) begin
                expand_counter <= expand_counter + 1;
                if (expand_counter < 31250000) begin // 0.5 seconds at 62.5 MHz
                    expand_width <= (expand_counter * 15) / 31250000; // Increase width from 0 to 15 pixels
                end else begin
                    expand_active <= 0;
                    expand_width <= 15; // Change final expand_width to 15
                end
            end
        end
    endtask
    
    // Task for vertical expansion animation
    task vertical_expansion_animation;
        begin
            if (vertical_expand_active) begin
                vertical_expand_counter <= vertical_expand_counter + 1;
                if (vertical_expand_counter < 62500000) begin // 1 second at 62.5 MHz
                    vertical_expand_height <= (vertical_expand_counter * 30) / 62500000; // Increase height from 0 to 30 pixels
                end else begin
                    vertical_expand_active <= 0;
                    vertical_expand_height <= 30; // Final vertical expand height is 30
                end
            end
        end
    endtask
    
    always @ (posedge clk) begin
        button_press_detection;
        animation_control;
        red_trail_control;
        expansion_animation;
        vertical_expansion_animation;
    end
    
    always @ (*) begin
        xpos = oled_pixel_index % 96;
        ypos = oled_pixel_index / 96;
    
        if (square_color_changed && (xpos >= expand_xpos - expand_width && xpos < expand_xpos && ypos >= 35 && ypos < 40) && expand_xpos - expand_width >= 45) begin // Add condition to stop expansion at x45
            oled_pixel_data = {5'd0, 6'd63, 5'd0}; // Green expansion trail
        end else if (vertical_expand_active && (xpos >= 45 && xpos < 50 && ypos >= vertical_expand_ypos - vertical_expand_height && ypos < vertical_expand_ypos)) begin
            oled_pixel_data = {5'd0, 6'd63, 5'd0}; // Green vertical expansion trail
        end else if (xpos >= 45 && xpos < 50 && ypos >= 0 && ypos < square_ypos) begin
            oled_pixel_data = {5'd31, 6'd0, 5'd0}; // Red trail (vertical)
        end else if (xpos >= square_xpos && xpos < square_xpos + 5 && ypos >= square_ypos && ypos < square_ypos + 5) begin
            if (square_color_changed)
                oled_pixel_data = {5'd0, 6'd63, 5'd0}; // Green square
            else
                oled_pixel_data = {5'd31, 6'd0, 5'd0}; // Red square
        end else if (xpos >= 45 && xpos < square_xpos && ypos >= square_ypos && ypos < square_ypos + 5) begin
            oled_pixel_data = {5'd31, 6'd0, 5'd0}; // Red trail (horizontal)
        end else begin
            oled_pixel_data = 16'h0000; // Black
        end
    end
    
endmodule
