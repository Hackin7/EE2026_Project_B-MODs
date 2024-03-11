`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.03.2024 23:12:58
// Design Name: 
// Module Name: adaptor_task_b
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


module adaptor_task_b(
        input clk,
        input btnC, btnR, btnL, 
        input [15:0] sw,
        input [12:0] oled_pixel_index, output [15:0] oled_pixel_data
);
    parameter [15:0] WHITE = 16'b11111_111111_11111;
    parameter [15:0] RED = 16'b11111_000000_00000;
    parameter [15:0] GREEN = 16'b00000_111111_00000;
    parameter [15:0] BLUE = 16'b00000_000000_11111;
    parameter [15:0] BLACK = 16'b00000_000000_00000;
    parameter WIDTH = 96, HEIGHT = 64;
    parameter SQUARE_LENGTH = 6;
    parameter BORDER_THICKNESS = 3;
    reg [7:0] xpos; reg [7:0] ypos;
    reg [15:0] oled_data = BLACK;
    wire [12:0] pixel_index = oled_pixel_index;
    assign oled_pixel_data = oled_data;

    reg [2:0] green_box_pos = 3'd3;
    reg [31:0] counter, enable_task_counter;
    reg [31:0] move_counter;
   
   function is_green_border(input [7:0] size, 
           input [7:0] x, input [7:0] y,
           input [7:0] x_start, input [7:0] y_start,
           input [4:0] width, input [4:0] gap);
           reg long_range, short_range; 
       begin
           long_range = (x >= x_start && x < x_start + size + 2 * width + 2 * gap) && ((y >= y_start && y < y_start + width) || (y >= y_start + width + 2 * gap + size && y < y_start + 2 * width + 2 * gap + size));
           short_range = (((x >= x_start && x < x_start + width)|| (x >= x_start + 2* gap + width + size && x < x_start + 2* gap + 2 * width + size )) && (y >= y_start + width && y < y_start + size + 2 * width + 2 * gap));
           is_green_border = long_range || short_range;
       end
   endfunction
   
   function is_box( input [7:0] x, input [7:0] y,
           input [7:0] x_start, input [7:0] y_start,
           input [7:0] size
       ); begin
       is_box = (x >= x_start && x <= x_start + size) && (y >= y_start && y <= y_start + size);
   end
   endfunction
    always @ (posedge clk) begin
        if (sw[0]) begin
            counter <= counter + 1;
            enable_task_counter <= counter >= 400_000_000 ? 1 : 0;
        end else if (~sw[0]) begin
            counter <= 0;
            enable_task_counter <= 0;
        end
        if (enable_task_counter) begin
            if (btnL && green_box_pos > 1) begin 
                move_counter <= move_counter + 1;
                if (move_counter >= 1_000_000) begin
                    green_box_pos <= green_box_pos - 1;
                    counter <= 0;
                end
            end else if (btnR && green_box_pos < 5) begin 
                move_counter <= move_counter + 1;
                if (move_counter >= 1_000_000) begin
                    green_box_pos <= green_box_pos + 1;
                    move_counter <= 0;
                end
            end else move_counter <= 0;
        end
    end
    
    always @ (*) begin
        xpos = pixel_index % 96;
        ypos = pixel_index / 96;
        if (enable_task_counter) begin
            if (is_box(xpos, ypos, 8'd46, 8'd29, SQUARE_LENGTH)) begin 
                oled_data <= WHITE; 
            end else if (is_box(xpos, ypos, 8'd30, 8'd29, SQUARE_LENGTH)) begin 
                oled_data <= WHITE;
            end else if (is_box(xpos, ypos, 8'd15, 8'd29, SQUARE_LENGTH)) begin 
                oled_data <= WHITE;
            end else if (is_box(xpos, ypos, 8'd60, 8'd29, SQUARE_LENGTH)) begin 
                oled_data <= WHITE;
            end else if (is_box(xpos, ypos, 8'd75, 8'd29, SQUARE_LENGTH)) begin 
                oled_data <= WHITE;
            end else if (is_green_border(SQUARE_LENGTH, xpos, ypos, 8'd70, 8'd25, BORDER_THICKNESS, 2)) begin
                oled_data <= GREEN;
            end else oled_data <= BLACK;
        end
        
        case (green_box_pos)
            1: begin 
                if (is_green_border(SQUARE_LENGTH, xpos, ypos, 8'd10, 8'd25, BORDER_THICKNESS, 2)) begin
                    oled_data <= GREEN;
                end else oled_data <= BLACK;
            end
            2: begin 
                if (is_green_border(SQUARE_LENGTH, xpos, ypos, 8'd25, 8'd25, BORDER_THICKNESS, 2)) begin
                    oled_data <= GREEN;
                end else oled_data <= BLACK;
            end
            3: begin 
                if (is_green_border(SQUARE_LENGTH, xpos, ypos, 8'd40, 8'd25, BORDER_THICKNESS, 2)) begin
                    oled_data <= GREEN;
                end else oled_data <= BLACK;
            end
            4: begin 
                if (is_green_border(SQUARE_LENGTH, xpos, ypos, 8'd55, 8'd25, BORDER_THICKNESS, 2)) begin
                    oled_data <= GREEN;
                end else oled_data <= BLACK;
            end
            5: begin 
                if (is_green_border(SQUARE_LENGTH, xpos, ypos, 8'd70, 8'd25, BORDER_THICKNESS, 2)) begin
                    oled_data <= GREEN;
                end else oled_data <= BLACK;
            end
        endcase
   end

endmodule
