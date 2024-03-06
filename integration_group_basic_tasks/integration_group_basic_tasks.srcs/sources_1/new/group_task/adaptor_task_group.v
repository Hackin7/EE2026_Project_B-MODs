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


module adaptor_task_group(
    // Control
    input reset, input clk,
    // LEDs, Switches, Buttons
    input btnC, btnU, btnL, btnR, btnD, input [15:0] sw, output [15:0] led,
    // 7 Segment Display
    output [6:0] seg, output dp, output [3:0] an,
    // OLED
    input [12:0] oled_pixel_index, output [15:0] oled_pixel_data,
    // Mouse
    input [11:0] mouse_xpos,  mouse_ypos, input [3:0] mouse_zpos,
    input mouse_left_click, mouse_middle_click, mouse_right_click, mouse_new_event
);
    parameter SEG_CLEAR = ~7'b0;
    parameter SEG_DIGIT_5 = 7'b0010010;
    parameter SEG_DIGIT_1 = 7'b1111001;
    parameter SEG_DIGIT_0 = 7'b1000000;
    parameter SEG_DIGIT_4 = 7'b0011001;
    

    assign dp = 0;
    assign an = 0;
    //// Clocks /////////////////////////////////////////////////////
    wire clk_25mhz, clk_12_5mhz, clk_6_25mhz, slow_clk;
    clk_counter #(2, 32) clk25m (clk, clk_25mhz);
    clk_counter #(4, 32) clk12p5m (clk, clk_12_5mhz);
    clk_counter #(8, 32) clk6p25m (clk, clk_6_25mhz);
    clk_counter #(50_000_000, 32) clkslow (clk, slow_clk); // 1hz
    
    //// 3.C Paint /////////////////////////////////////////////////////
    wire [6:0] paint_seg;

    paint paint_module(
        .clk_100M(clk),
        .clk_25M(clk_25mhz),
        .clk_12p5M(clk_12_5mhz),
        .clk_6p25M(clk_6_25mhz),
        .slow_clk(slow_clk),
        .mouse_l(reset ? 0 : mouse_left_click),
        .reset(reset | mouse_right_click),
        .enable(~reset),
        .mouse_x(mouse_xpos),
        .mouse_y(mouse_ypos),
        .pixel_index(oled_pixel_index),
        .led(led),
        .seg(paint_seg),
        .colour_chooser(oled_pixel_data)
    );

    // Group Task Logic ////////////////////////////////////////////////
    // 4.E4 - Group Number, 4.E5 - switches
    wire seg_1 = sw[15] ? paint_seg : (sw[14] ? SEG_DIGIT_0 : (sw[13] ? SEG_CLEAR : SEG_DIGIT_0));
    wire seg_0 = sw[15] ? SEG_DIGIT_4 : (sw[14] ? paint_seg : (sw[13] ? SEG_CLEAR : SEG_DIGIT_4));
    seg_multiplexer starting_digit_number(
        .clk(), 
        .seg3(SEG_DIGIT_5), .dp3(0), // 5
        .seg2(SEG_DIGIT_1), .dp2(1), // 1.
        .seg1(seg_1), .dp1(0), // 0
        .seg0(seg_0), .dp0(0), // 4.
        .seg(seg), .dp(dp), .an(an)
    );

    // 4.E6 - Button
    wire button = btnC;
    reg prev_button_state = 0;
    reg success_screen = 0;
    always @ (posedge clk) begin
        if (reset) begin
            success_screen <= 0;
        end else if (prev_button_state == 1 && button == 0 && (seg_1 == SEG_DIGIT_0 && seg_0 == SEG_DIGIT_4) ) begin // Fall
            success_screen <= 1;
        end 
        prev_button_state <= button;
    end
endmodule
