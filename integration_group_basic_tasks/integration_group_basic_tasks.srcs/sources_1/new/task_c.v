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


module task_c(
    // Control
    input reset, input clk,
    // LEDs, Switches, Buttons
    input btnC, btnU, btnL, btnR, btnD, input [15:0] sw, output [15:0] led,
    // 7 Segment Display
    output [6:0] seg, output dp, output [3:0] an,
    // OLED
    inout [7:0] JB
);

    //// 3.A OLED Setup ////////////////////////////////////////////////////////
    wire [7:0] Jb;
    assign JB[7:0] = Jb;

    wire clk_6_25mhz;
    clk_counter #(16, 5) clk6p25m (clk, clk_6_25mhz); 

    reg [15:0] oled_pixel_data = 16'h0000;
    wire [12:0] oled_pixel_index;
    wire [15:0] pixel_data = oled_pixel_data;
    Oled_Display display(
       .clk(clk_6_25mhz), .reset(0), 
       .frame_begin(), .sending_pixels(), .sample_pixel(), .pixel_index(oled_pixel_index), .pixel_data(pixel_data), 
       .cs(Jb[0]), .sdin(Jb[1]), .sclk(Jb[3]), .d_cn(Jb[4]), .resn(Jb[5]), .vccen(Jb[6]), .pmoden(Jb[7])); //to SPI    

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

    always @ (posedge clk) begin
        btnD_prev <= btnD;
    
        if (!btnD_prev && btnD) begin
            animation_active <= 1;
            animation_counter <= 0;
            square_color_changed <= 0;
            expand_active <= 0; // Disable expansion animation initially
        end
    
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
            end else begin
                animation_active <= 0;
                square_xpos <= 60;
                square_ypos <= 35;
            end
        end
        
        if (expand_active == 0 && expand_width == 10) begin
            red_trail_counter <= red_trail_counter + 1;
            if (red_trail_counter == 31250000) begin // 0.5 seconds at 62.5 MHz
                red_trail_active <= 1;
            end
        end
        
        // Expansion animation
        if (expand_active) begin
            expand_counter <= expand_counter + 1;
            if (expand_counter < 31250000) begin // 0.5 seconds at 62.5 MHz
                expand_width <= (expand_counter * 10) / 31250000; // Increase width from 0 to 10 pixels
            end else begin
                expand_active <= 0;
                expand_width <= 10;
            end
        end
    end
    
    always @ (*) begin
        xpos = oled_pixel_index % 96;
        ypos = oled_pixel_index / 96;
    
        if (red_trail_active && xpos >= 50 && xpos < 56 && ypos >= 35 && ypos < 40) begin
            oled_pixel_data = {5'd31, 6'd0, 5'd0}; // Red trail (x50 to x55, y30 to y35)
        end else if (square_color_changed && (xpos >= expand_xpos - expand_width && xpos < expand_xpos && ypos >= 35 && ypos < 40)) begin
            oled_pixel_data = {5'd0, 6'd63, 5'd0}; // Green expansion trail
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