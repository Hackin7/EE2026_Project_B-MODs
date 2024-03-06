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
    // Control
    input clk,
    // LEDs, Switches, Buttons
    input btnC, btnU, btnL, btnR, btnD, input [15:0] sw, output [15:0] led,
    // 7 Segment Display
    output [5:0] seg, output dp, output [3:0] an,
    // OLED PMOD
    inout [7:0] JB,
    inout mouse_ps2_clk, mouse_ps2_data
);
    
    //// Setup ///////////////////////////////////////////////////////////////////////////////////////////////////////
    //// Clocks /////////////////////////////////////////////
    wire clk_25mhz, clk_12_5mhz, clk_6_25mhz, slow_clk;
    clk_counter #(2, 32) clk25m (clk, clk_25mhz);
    clk_counter #(4, 32) clk12p5m (clk, clk_12_5mhz);
    clk_counter #(8, 32) clk6p25m (clk, clk_6_25mhz);
    clk_counter #(50_000_000, 32) clkslow (clk, slow_clk); // 1hz

    //// 3.A OLED Setup //////////////////////////////////////
    // Inputs
    wire [7:0] Jx;
    assign JB[7:0] = Jx;
    // Outputs
    wire [12:0] oled_pixel_index;
    wire [15:0] oled_pixel_data;
    // Module
    Oled_Display display(
        .clk(clk_6_25mhz), .reset(0), 
        .frame_begin(), .sending_pixels(), .sample_pixel(), .pixel_index(oled_pixel_index), .pixel_data(oled_pixel_data), 
        .cs(Jx[0]), .sdin(Jx[1]), .sclk(Jx[3]), .d_cn(Jx[4]), .resn(Jx[5]), .vccen(Jx[6]), .pmoden(Jx[7])); //to SPI
    
    //// 3.B Mouse Setup /////////////////////////////////////
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
    

    //// Group Task //////////////////////////////////////////////////////////////////////////////////////////////////
    wire group_reset = 0;
    wire [15:0] group_led; 
    wire [6:0] group_seg;
    wire [15:0] group_oled_pixel_data;

    adaptor_task_group task_group(
        .reset(group_reset), .clk(clk),
        .led(group_led), .seg(group_seg),
        .oled_pixel_index(oled_pixel_index), .oled_pixel_data(group_oled_pixel_data),
        .mouse_xpos(mouse_xpos), .mouse_ypos(mouse_ypos), .mouse_zpos(mouse_zpos),
        .mouse_left_click(mouse_left_click), .mouse_middle_click(mouse_middle_click),
        .mouse_right_click(mouse_right_click), .mouse_new_event(mouse_new_event)
    );

    //// Task A //////////////////////////////////////////////////////////////////////////////////////////////////
    wire a_reset;
    wire [15:0] a_led; 
    wire [6:0] a_seg;
    wire [15:0] a_oled_pixel_data;

    adaptor_task_a task_a(
        .reset(a_reset), .clk(clk),
        .btnC(btnC), .btnU(btnU), .btnL(L), .btnR(btnR), .btnD(btnD), 
        .led(a_led), .seg(a_seg),
        .oled_pixel_index(oled_pixel_index), .oled_pixel_data(a_oled_pixel_data),
        .mouse_xpos(mouse_xpos), .mouse_ypos(mouse_ypos), .mouse_zpos(mouse_zpos),
        .mouse_left_click(mouse_left_click), .mouse_middle_click(mouse_middle_click),
        .mouse_right_click(mouse_right_click), .mouse_new_event(mouse_new_event)
    );

    //// Overall Control Logic ////////////////////////////////////////////////////////////////////////////////////
    wire enable_task_group = sw[0];
    wire enable_task_a = sw[1];
    assign led = enable_task_group ? group_led : (enable_task_a ? a_led : 0);
    assign seg = enable_task_group ? group_seg : (enable_task_a ? a_seg : 0);
    assign oled_pixel_data = enable_task_group ? group_oled_pixel_data : (enable_task_a ? a_oled_pixel_data : 16'hFFFF);

    assign group_reset = ~enable_task_group;
    assign a_reset = ~enable_task_a;

endmodule
