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
    
    // Subtask C variables
    reg red_trail_start = 0;
    reg [31:0] red_trail_count = 0;
    reg red_trail_done = 0;
    reg red_expansion_start = 0;
    reg [31:0] red_expansion_delay = 0;
    reg [31:0] red_expansion_count = 0;
    reg red_square_start = 0;
    reg [31:0] red_square_delay = 0;
    reg green_trail_start = 0;
    reg green_trail_done = 0;
    reg green_expansion_start = 0;
    reg [31:0] green_trail_count = 0;
    reg [31:0] green_expansion_count = 0;
    reg [31:0] green_expansion_delay = 0;
    reg final_state = 0;
    
    task reset_control;
        begin
            if (reset) begin
                red_trail_start = 0;
                red_trail_count = 0;
                red_trail_done = 0;
                red_expansion_start = 0;
                red_expansion_delay = 0;
                red_expansion_count = 0;
                red_square_start = 0;
                red_square_delay = 0;
                green_trail_start = 0;
                green_trail_done = 0;
                green_expansion_start = 0;
                green_trail_count = 0;
                green_expansion_count = 0;
                green_expansion_delay = 0;
                final_state = 0;
            end
        end
    endtask
    
    always @ (posedge clk) begin
        reset_control;
        xpos <= oled_pixel_index % 96;
        ypos <= oled_pixel_index / 96;
        
        if (~reset) begin
            if (ypos >= 2 && (ypos < 7 + red_trail_count/1_250_000) && xpos >= 45 && xpos < 50) begin
                oled_pixel_data <= 16'b11111_000000_00000;
            end 
                    
            else if ( final_state == 1 && ((ypos >= 7 && ypos < 32 && xpos >= 45 && xpos < 50) || (ypos >= 32 && ypos < 37 && xpos >= 45 && xpos < 65)) ) begin
                oled_pixel_data <= 16'b00000_101010_00000;
            end
                
            else begin
                oled_pixel_data <= 16'd0;
            end
                    
            if (btnD == 1) begin
                red_trail_start <= 1;      
            end    
                
            if (red_trail_start == 1) begin 
                red_trail_count <= (red_trail_count == 37_500_000) ? 37_500_000 : red_trail_count + 1;      
            end          
                   
            if (red_trail_count == 0 && red_trail_start == 1) begin
                red_trail_done <= 1;
            end
           
            if (red_trail_done == 1) begin
                red_expansion_delay <= (red_expansion_delay == 37_500_000) ? 37_500_000 : red_expansion_delay + 1;            
                if (red_expansion_delay == 37_500_000) begin
                    red_expansion_start <= 1;              
                end
            end
           
            if (red_expansion_start == 1) begin
                red_expansion_count <= (red_expansion_count == 18_750_000) ? 18_750_000 : red_expansion_count + 1;
                if (ypos >= 2 + red_trail_count/1_250_000 && (ypos < 7 + red_trail_count/1_250_000) && 
                    xpos >= 45 && xpos < 50 + red_expansion_count/1_250_000) begin  //btw 45 and 65
                    oled_pixel_data <= 16'b11111_000000_00000;
                end
            end
           
            if (red_expansion_count == 18_750_000) begin
                red_square_start <= 1;
            end
           
            if (red_square_start == 1) begin
                red_square_delay <= red_square_delay + 1;
                if (red_square_delay == 12_500_000) begin
                    green_trail_start <= 1;
                    red_square_delay <= 0;              
                end
            end
           
            if (green_trail_start == 1) begin
                if (ypos >= 2 + red_trail_count/1_250_000 && (ypos < 7 + red_trail_count/1_250_000) && 
                    xpos >= 45 + red_expansion_count/1_250_000 && xpos < 50 + red_expansion_count/1_250_000) 
                begin
                    oled_pixel_data <= 16'b00000_101010_00000;
                end
                if (red_square_delay == 12_500_000) begin
                    green_trail_done <= 1;               
                end
            end
           
            if (green_trail_done == 1) begin
                green_trail_count <= (green_trail_count == 37_500_000) ? 37_500_000 : green_trail_count + 1;
                if (ypos >= 2 + red_trail_count/1_250_000 && (ypos < 7 + red_trail_count/1_250_000) && 
                    xpos >= 45 + 15 - green_trail_count/2_500_000 && xpos < 50 + 15)
                begin
                    oled_pixel_data <= 16'b00000_101010_00000;
                end            
            end
           
            if (green_trail_count == 37_500_000) begin
                green_expansion_start <= 1;            
            end
           
            if (green_expansion_start == 1) begin
                green_expansion_count <= (green_expansion_count == 75_000_000) ? 75_000_000 : green_expansion_count + 1;
                if (ypos >= 2 + 30 - green_expansion_count/2_500_000 && (ypos < 7 + 30) && xpos >= 45 && xpos < 50) begin
                    oled_pixel_data <= 16'b00000_101010_00000;
                end
            end
           
            if (green_expansion_count == 75_000_000) begin
                green_expansion_delay <= 0;   
            end
           
            if (green_expansion_delay == 0) begin
                green_expansion_delay <= (green_expansion_delay == 12_500_000)? 12_500_000 : green_expansion_delay + 1;
                if (green_expansion_delay == 12_500_000) begin
                    final_state <= 1;                           
                end
            end
           
            if (final_state == 1) begin                    
                red_trail_start <= 0;
                red_trail_done <= 0;
                red_expansion_start <= 0;
                red_square_start <= 0; 
                green_trail_start <= 0;
                green_trail_done <= 0;
                green_expansion_start <= 0;
                red_trail_count <= 0;  
                red_expansion_delay <= 0;
                red_expansion_count <= 0;
                green_trail_count <= 0;
                green_expansion_count <= 0;
                red_square_delay <= 0;
                green_expansion_delay <= 0;                   
            end
        end
        else begin
            red_trail_start <= 0;
            red_trail_done <= 0;
            red_expansion_start <= 0;
            red_square_start <= 0; 
            green_trail_start <= 0;
            green_trail_done <= 0;
            green_expansion_start <= 0;
            final_state <= 0;    
            red_trail_count <= 0;  
            red_expansion_delay <= 0;
            red_expansion_count <= 0;
            green_trail_count <= 0;
            green_expansion_count <= 0;
            red_square_delay <= 0;
            green_expansion_delay <= 0;   
        end        
             
    end
    
endmodule
