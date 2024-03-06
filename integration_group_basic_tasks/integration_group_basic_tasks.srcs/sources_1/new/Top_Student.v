`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
//
//  FILL IN THE FOLLOWING INFORMATION:
//  STUDENT A NAME: 
//  STUDENT B NAME:
//  STUDENT C NAME: 
//  STUDENT D NAME:  
//
//////////////////////////////////////////////////////////////////////////////////


module Top_Student (
    input clk, 
    input [15:0] sw, output [15:0] led, output [5:0] seg,
    inout [7:0] JB,
    inout mouse_ps2_clk, mouse_ps2_data
);
     
    //// Clocks
    wire clk_25mhz, clk_12_5mhz, clk_6_25mhz, slow_clk;
    clk_counter #(2, 32) clk25m (clk, clk_25mhz);
    clk_counter #(4, 32) clk12p5m (clk, clk_12_5mhz);
    clk_counter #(8, 32) clk6p25m (clk, clk_6_25mhz);
    clk_counter #(50_000_000, 32) clkslow (clk, slow_clk); // 1hz
    
    //// 3.A OLED Setup ////////////////////////////////////////////////////////
    // Inputs
    wire [7:0] Jx;
    assign JB[7:0] = Jx;
    // Outputs
    wire [12:0] pixel_index;
    wire [15:0] pixel_data;
    // Module
    Oled_Display display(
        .clk(clk_6_25mhz), .reset(0), 
        .frame_begin(), .sending_pixels(), .sample_pixel(), .pixel_index(pixel_index), .pixel_data(pixel_data), 
        .cs(Jx[0]), .sdin(Jx[1]), .sclk(Jx[3]), .d_cn(Jx[4]), .resn(Jx[5]), .vccen(Jx[6]), .pmoden(Jx[7])); //to SPI
    
    //// 3.B Mouse Setup ///////////////////////////////////////////////////////
    wire [11:0] mouse_xpos;
    wire [11:0] mouse_ypos;
    wire [3:0] mouse_zpos;
    wire mouse_left_click;
    wire mouse_middle_click;
    wire mouse_right_click;
    wire mouse_new_event;
    MouseCtl mouse(
        .clk(clk), .rst(0), .value(11'b0), .setx(0), .sety(0), .setmax_x(96), .setmax_y(64),
        .xpos(mouse_xpos), .ypos(mouse_ypos), .zpos(mouse_zpos), 
        .left(mouse_left_click), .middle(mouse_middle_click), .right(mouse_right_click), .new_event(mouse_new_event),
        .ps2_clk(mouse_ps2_clk), .ps2_data(mouse_ps2_data)
    );
    
    adaptor_group_task group_task(
        .clk(clk),
        .led(led), .seg(seg),
        .oled_pixel_index(pixel_index), .oled_pixel_data(pixel_data),
        .mouse_xpos(mouse_xpos), .mouse_ypos(mouse_ypos), .mouse_zpos(mouse_zpos),
        .mouse_left_click(mouse_left_click), .mouse_middle_click(mouse_middle_click),
        .mouse_right_click(mouse_right_click), .mouse_new_event(mouse_new_event)
    );
endmodule
