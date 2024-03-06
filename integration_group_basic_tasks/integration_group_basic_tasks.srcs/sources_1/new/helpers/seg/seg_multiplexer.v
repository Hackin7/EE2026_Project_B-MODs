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


module seg_multiplexer(
    input clk, 
    input [6:0] seg0, seg1, seg2, seg3,
    input dp0, dp1, dp2, dp3,
    output reg [6:0] seg, 
    output reg dp,
    output reg [3:0] an
);
    reg [1:0] state = 0;
    always @ (posedge clk) begin
        if (state == 0) begin 
            seg <= seg0;
            dp <= dp0;
            an <= 4'b0001;
        end else if (state == 1) begin 
            seg <= seg1;
            dp <= dp1;
            an <= 4'b0010;
        end else if (state == 2) begin 
            seg <= seg2;
            dp <= dp2;
            an <= 4'b0100;
        end else if (state == 3) begin 
            seg <= seg3;
            dp <= dp3;
            an <= 4'b1000;
        end 
        state <= state + 1;
    end
endmodule
