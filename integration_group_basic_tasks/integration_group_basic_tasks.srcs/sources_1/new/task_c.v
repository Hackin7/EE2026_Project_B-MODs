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
    
    // Color variables
    parameter COLOR_RED = 16'b11111_000000_00000;
    parameter COLOR_GREEN = 16'b00000_101010_00000;
    parameter COLOR_BLACK = 16'd0;
    
    // Subtask C variables
    reg fill_status = 0;
    reg [31:0] fill_count = 0;
    reg fill_complete = 0;
    reg move_right_status = 0;
    reg [31:0] delay_after_fill = 0;
    reg [31:0] move_right_count = 0;
    reg move_right_complete = 0;
    reg [31:0] delay_before_color_change = 0;
    reg change_color_status = 0;
    reg move_left_status = 0;
    reg move_up_status = 0; 
    reg animation_complete_status = 0;
    reg reset_status = 0;
    reg [31:0] move_left_count = 0;
    reg [31:0] move_up_count = 0;
    reg [31:0] delay_after_animation = 0;
    reg final_state = 0;
    
    always @ (posedge clk) begin
        xpos <= oled_pixel_index % 96;
        ypos <= oled_pixel_index / 96;
        
        if (sw[0] == 1) begin
            oled_pixel_data <= COLOR_BLACK;
            
            if (ypos >= 2 && (ypos < 7 + fill_count/1_250_000) && xpos >= 45 && xpos < 50) begin
                oled_pixel_data <= COLOR_RED;
            end 
                    
            else if (final_state == 1 && ((ypos >= 7 && ypos < 32 && xpos >= 45 && xpos < 50) || (ypos >= 32 && ypos < 37 && xpos >= 45 && xpos < 65))) begin
                oled_pixel_data <= COLOR_GREEN;
            end
                    
            if (btnD == 1) begin
                fill_status <= 1;      
            end    
                
            if (fill_status == 1) begin 
                fill_count <= (fill_count == 37_500_000) ? 37_500_000 : fill_count + 1;      
            end          
                   
            if (fill_count == 0 && fill_status == 1) begin
                fill_complete <= 1;
            end
           
            if (fill_complete == 1) begin
                delay_after_fill <= (delay_after_fill == 37_500_000) ? 37_500_000 : delay_after_fill + 1;            
                if (delay_after_fill == 37_500_000) begin
                    move_right_status <= 1;              
                end
            end
           
            if (move_right_status == 1) begin
                move_right_count <= (move_right_count == 18_750_000) ? 18_750_000 : move_right_count + 1;
                if (ypos >= 2 + fill_count/1_250_000 && (ypos < 7 + fill_count/1_250_000) && 
                    xpos >= 45 && xpos < 50 + move_right_count/1_250_000) begin
                    oled_pixel_data <= COLOR_RED;
                end
            end
           
            if (move_right_count == 18_750_000) begin
                move_right_complete <= 1;
            end
           
            if (move_right_complete == 1) begin
                delay_before_color_change <= delay_before_color_change + 1;
                if (delay_before_color_change == 12_500_000) begin
                    change_color_status <= 1;
                    delay_before_color_change <= 0;              
                end
            end
           
            if (change_color_status == 1) begin
                if (ypos >= 2 + fill_count/1_250_000 && (ypos < 7 + fill_count/1_250_000) && 
                    xpos >= 45 + move_right_count/1_250_000 && xpos < 50 + move_right_count/1_250_000) 
                begin
                    oled_pixel_data <= COLOR_GREEN;
                end
                if (delay_before_color_change == 12_500_000) begin
                    move_left_status <= 1;               
                end
            end
           
            if (move_left_status == 1) begin
                move_left_count <= (move_left_count == 37_500_000) ? 37_500_000 : move_left_count + 1;
                if (ypos >= 2 + fill_count/1_250_000 && (ypos < 7 + fill_count/1_250_000) && 
                    xpos >= 45 + 15 - move_left_count/2_500_000 && xpos < 50 + 15)
                begin
                    oled_pixel_data <= COLOR_GREEN;
                end            
            end
           
            if (move_left_count == 37_500_000) begin
                move_up_status <= 1;            
            end
           
            if (move_up_status == 1) begin
                move_up_count <= (move_up_count == 75_000_000) ? 75_000_000 : move_up_count + 1;
                if (ypos >= 2 + 30 - move_up_count/2_500_000 && (ypos < 7 + 30) && xpos >= 45 && xpos < 50) begin
                    oled_pixel_data <= COLOR_GREEN;
                end
            end
           
            if (move_up_count == 75_000_000) begin
                animation_complete_status <= 1;
                delay_after_animation <= 0;   
            end
           
            if (animation_complete_status == 1) begin
                delay_after_animation <= (delay_after_animation == 12_500_000)? 12_500_000 : delay_after_animation + 1;
                if (delay_after_animation == 12_500_000) begin
                    reset_status <= 1;                           
                end
            end
           
            if (reset_status == 1) begin                    
                fill_status <= 0;
                fill_complete <= 0;
                move_right_status <= 0;
                move_right_complete <= 0; 
                change_color_status <= 0;
                move_left_status <= 0;
                move_up_status <= 0;
                animation_complete_status <= 0;
                reset_status <= 0;            
                final_state <= 1;    
                fill_count <= 0;  
                delay_after_fill <= 0;
                move_right_count <= 0;
                move_left_count <= 0;
                move_up_count <= 0;
                delay_before_color_change <= 0;
                delay_after_animation <= 0;                   
            end
        end
        else begin
            fill_status <= 0;
            fill_complete <= 0;
            move_right_status <= 0;
            move_right_complete <= 0; 
            change_color_status <= 0;
            move_left_status <= 0;
            move_up_status <= 0;
            animation_complete_status <= 0;
            reset_status <= 0;            
            final_state <= 0;    
            fill_count <= 0;  
            delay_after_fill <= 0;
            move_right_count <= 0;
            move_left_count <= 0;
            move_up_count <= 0;
            delay_before_color_change <= 0;
            delay_after_animation <= 0;   
        end        
             
    end
    
endmodule
