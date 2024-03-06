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
    input [15:0] sw, output [15:0] led,
    inout [7:0] JB,
    inout mouse_ps2_clk, mouse_ps2_data
);
     
    
    //// 3.A OLED Setup ////////////////////////////////////////////////////////
    wire [7:0] Jx;
    assign JB[7:0] = Jx;
    
    wire clk_6_25mhz;
    clk_counter #(7, 5) clk6p25m (clk, clk_6_25mhz); 
        
    //reg [15:0] oled_data = 16'h07E0;
    reg [15:0] oled_data = sw[4] ? {5'd31, 6'd0, 5'd0} : {5'd0, 6'd63, 5'd0};
    
    wire [15:0] pixel_data = oled_data;
    Oled_Display display(
        .clk(clk_6_25mhz), .reset(0), 
        .frame_begin(), .sending_pixels(), .sample_pixel(), .pixel_index(), .pixel_data(oled_data), 
        .cs(Jx[0]), .sdin(Jx[1]), .sclk(Jx[3]), .d_cn(Jx[4]), .resn(Jx[5]), .vccen(Jx[6]), .pmoden(Jx[7])); //to SPI
    
    //// 3.B Mouse Setup ////////////////////////////////////////////////////////
    wire [31:0] mouse_state;
    MouseCtl mouse(
        .clk(clk), .rst(0), .value(11'b0), .setx(0), .sety(0), .setmax_x(1), .setmax_y(1),
        .xpos(mouse_state[11:0]), .ypos(mouse_state[23:12]), .zpos(mouse_state[27:24]), 
        .left(mouse_state[28]), .middle(mouse_state[29]), .right(mouse_state[30]), .new_event(mouse_state[31]),
        .ps2_clk(mouse_ps2_clk), .ps2_data(mouse_ps2_data)
    );
    
    assign led[15] = mouse_state[28];
    assign led[14] = mouse_state[29];
    assign led[13] = mouse_state[30];
    
    //// 3.C Paint /////////////////////////////////////////////////////
    
    
endmodule