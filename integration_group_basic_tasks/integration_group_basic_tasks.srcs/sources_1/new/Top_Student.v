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


module Top_Student (input clk, 
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
    wire [7:0] Jx;
    assign JB[7:0] = Jx;
    wire [12:0] pixel_index;
    reg [15:0] oled_data = 16'h07E0;
    //reg [15:0] oled_data = sw[4] ? {5'd31, 6'd0, 5'd0} : {5'd0, 6'd63, 5'd0};
    
    wire [15:0] pixel_data;// = oled_data;
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
        .clk(clk), .rst(0), .value(11'b0), .setx(0), .sety(0), .setmax_x(1), .setmax_y(1),
        .xpos(mouse_xpos), .ypos(mouse_ypos), .zpos(mouse_zpos), 
        .left(mouse_left_click), .middle(mouse_middle_click), .right(mouse_right_click), .new_event(mouse_new_event),
        .ps2_clk(mouse_ps2_clk), .ps2_data(mouse_ps2_data)
    );
    
    /*assign led[15] = mouse_state[28];
    assign led[14] = mouse_state[29];
    assign led[13] = mouse_state[30];*/
    
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
        .mouse_x(256),
        .mouse_y(256),
        .pixel_index(pixel_index),
        .led(led),
        .seg(seg),
        .colour_chooser(pixel_data)
    );
    
endmodule