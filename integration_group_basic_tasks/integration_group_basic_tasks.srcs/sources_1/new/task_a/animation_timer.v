`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.03.2024 16:59:02
// Design Name: 
// Module Name: animation_timer
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


module animation_timer (input clk, input enable, output reg [2:0] triggers);
    // 1 second is 100_000_000;
    parameter COUNT1 = 200_000_000; // 2 seconds
    parameter COUNT2 = 150_000_000; // 1.5 seconds
    parameter COUNT3 = 100_000_000; // 1 seconds
    parameter COUNT4 = 100_000_000; // 1 seconds
    parameter BITWIDTH = 32;
    
    
    reg [BITWIDTH-1:0] counter;
    initial begin
        counter <= 0;
        triggers <= 0;
    end;
    always @ (posedge clk) begin
        if (enable != 0) begin
            counter <= counter + 1;
            if (counter == COUNT1) begin
                triggers[0] <= 1;
            end else if (counter == COUNT1 + COUNT2) begin
                triggers[1] <= 1;
            end else if (counter == COUNT1 + COUNT2 + COUNT3) begin
                triggers[2] <= 1;
            end else if (counter == COUNT1 + COUNT2 + COUNT3 + COUNT4) begin
                triggers <= 0; // Reset all
                counter <= 0; 
            end
        end else begin
            counter <= 0; // reset counter
            triggers <= 0;
        end
    end
endmodule
