`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.03.2024 14:14:54
// Design Name: 
// Module Name: seg_multiplexer
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


module adaptor_group_task(
    input clk,
    output [15:0] led, output [5:0] seg,
    // OLED
    input [12:0] oled_pixel_index, input [15:0] oled_pixel_data,
    // Mouse
    input [11:0] mouse_xpos,  mouse_ypos, input [3:0] mouse_zpos,
    input mouse_left_click, mouse_middle_click, mouse_right_click, mouse_new_event
);

    //// Clocks /////////////////////////////////////////////////////
    wire clk_25mhz, clk_12_5mhz, clk_6_25mhz, slow_clk;
    clk_counter #(2, 32) clk25m (clk, clk_25mhz);
    clk_counter #(4, 32) clk12p5m (clk, clk_12_5mhz);
    clk_counter #(8, 32) clk6p25m (clk, clk_6_25mhz);
    clk_counter #(50_000_000, 32) clkslow (clk, slow_clk); // 1hz
    
    //// 3.C Paint /////////////////////////////////////////////////////
    paint paint_module(
        .clk_100M(clk),
        .clk_25M(clk_25mhz),
        .clk_12p5M(clk_12_5mhz),
        .clk_6p25M(clk_6_25mhz),
        .slow_clk(slow_clk),
        .mouse_l(mouse_left_click),
        .reset(mouse_right_click),
        .enable(1),
        .mouse_x(mouse_xpos),
        .mouse_y(mouse_ypos),
        .pixel_index(oled_pixel_index),
        .led(led),
        .seg(seg),
        .colour_chooser(oled_pixel_data)
    );
endmodule
