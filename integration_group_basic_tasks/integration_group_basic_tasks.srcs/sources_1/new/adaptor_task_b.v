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
        input clk, reset,
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

    reg [2:0] green_box_pos = 3'd5;
    reg [31:0] counter, enable_task_counter;
    reg [31:0] move_counter;
    reg shift_once;
    reg [15:0] COLOR = WHITE;
    wire [2:0] middle_trigger_state;
    middle_square_timer #(.LOOP_STATE(0)) mid_timer(clk, reset, enable_task_counter & btnC, middle_trigger_state);
    /* Trigger_state
    0: white, 1: red, 2: green, 3: blue , goes back to 0
    */
    reg [3:0] box_color;
    function is_green_border(input [7:0] size, 
            input [7:0] x, input [7:0] y,
            input [7:0] x_start, input [7:0] y_start,
            input [4:0] width, //  
            input [4:0] gap    // gap of item
       );
        reg long_range, short_range;
        
        /* 
           _c
        a |_| b
           d
        */
         
        begin
            long_range = (
                ((x_start+1 <= x) && (x <= x_start + size + 2 * width + 2 * gap - 1)) // x: Within outer box 
                && 
                (
                    ((y_start <= y) && (y < y_start + width))        // top side (c)
                    ||     
                    (                                                // bottom side (d)
                        ((y_start + width + 2 * gap + size) <= y) && 
                        (y < y_start + 2 * width + 2 * gap + size)
                    )
                )
            );
            short_range = (
                (
                    ((x_start + 1 <= x) && (x <= x_start + width))    // left side (a)
                    || 
                    (
                        (x_start + 2* gap + width + size <= x) 
                        && 
                        (x <= x_start + 2* gap + 2 * width + size - 1) 
                    )
                ) && 
                (y_start + width <= y && y < y_start + size + 2 * width + 2 * gap) // y: within box
            );
            is_green_border = long_range || short_range;
        end
    endfunction
   
    function is_box( input [7:0] x, input [7:0] y,
            input [7:0] x_start, input [7:0] y_start,
            input [7:0] size
    ); begin
        is_box = (x >= x_start && x < x_start + size) && (y >= y_start && y < y_start + size);
        end
    endfunction
    
    always @ (posedge clk) begin
        if (sw[0]) begin
            counter <= counter <= 400_000_000 ? counter + 1 : counter;
            if (counter >= 399_999_999) begin
                enable_task_counter <= 1;
            end
        end 
        if (reset || ~sw[0]) begin
            shift_once <= 0;
            counter <= 0;
            enable_task_counter <= 0;
            green_box_pos <= 3;
        end else if (enable_task_counter) begin
            if (~shift_once) begin
                shift_once <= 1;
                green_box_pos <= 5;
            end
            if (btnL && green_box_pos > 1) begin 
                move_counter <= move_counter + 1;
                if (move_counter >= 5_000_000) begin
                    green_box_pos <= green_box_pos - 1;
                    move_counter <= 0;
                end
            end else if (btnR && green_box_pos < 5) begin 
                move_counter <= move_counter + 1;
                if (move_counter >= 5_000_000) begin
                    green_box_pos <= green_box_pos + 1;
                    move_counter <= 0;
                end
            end else move_counter <= 0;
        end else green_box_pos <= 3;
    end
    
    always @ (*) begin
        xpos = pixel_index % 96;
        ypos = pixel_index / 96;
        box_color <= middle_trigger_state;
        if (enable_task_counter) begin
            if (is_box(xpos, ypos, 8'd45, 8'd29, SQUARE_LENGTH)) begin 
                oled_data <= COLOR; 
            end else if (is_box(xpos, ypos, 8'd30, 8'd29, SQUARE_LENGTH)) begin 
                oled_data <= COLOR;
            end else if (is_box(xpos, ypos, 8'd15, 8'd29, SQUARE_LENGTH)) begin 
                oled_data <= COLOR;
            end else if (is_box(xpos, ypos, 8'd60, 8'd29, SQUARE_LENGTH)) begin 
                oled_data <= COLOR;
            end else if (is_box(xpos, ypos, 8'd75, 8'd29, SQUARE_LENGTH)) begin 
                oled_data <= COLOR;
            end else oled_data <= BLACK;
        end else begin
            if (is_green_border(SQUARE_LENGTH, xpos, ypos, 8'd40, 8'd25, BORDER_THICKNESS, 2)) begin
                oled_data <= GREEN;
            end else oled_data <= BLACK;
        end
        
        case (green_box_pos)
            1: begin 
                if (is_green_border(SQUARE_LENGTH, xpos, ypos, 8'd10, 8'd25, BORDER_THICKNESS, 2)) begin
                    oled_data <= GREEN;
                    if (is_green_border(SQUARE_LENGTH, xpos, ypos, 8'd25, 8'd25, BORDER_THICKNESS, 2)) begin
                        oled_data <= BLACK;
                    end
                    if (is_green_border(SQUARE_LENGTH, xpos, ypos, 8'd40, 8'd25, BORDER_THICKNESS, 2)) begin
                        oled_data <= BLACK;
                    end
                    if (is_green_border(SQUARE_LENGTH, xpos, ypos, 8'd55, 8'd25, BORDER_THICKNESS, 2)) begin
                        oled_data <= BLACK;
                    end
                    if (is_green_border(SQUARE_LENGTH, xpos, ypos, 8'd70, 8'd25, BORDER_THICKNESS, 2)) begin
                        oled_data <= BLACK;
                    end
                end 
            end
            2: begin 
                if (is_green_border(SQUARE_LENGTH, xpos, ypos, 8'd25, 8'd25, BORDER_THICKNESS, 2)) begin
                    oled_data <= GREEN;
                    if (is_green_border(SQUARE_LENGTH, xpos, ypos, 8'd10, 8'd25, BORDER_THICKNESS, 2)) begin
                        oled_data <= BLACK;
                    end
                    if (is_green_border(SQUARE_LENGTH, xpos, ypos, 8'd40, 8'd25, BORDER_THICKNESS, 2)) begin
                        oled_data <= BLACK;
                    end
                    if (is_green_border(SQUARE_LENGTH, xpos, ypos, 8'd55, 8'd25, BORDER_THICKNESS, 2)) begin
                        oled_data <= BLACK;
                    end
                    if (is_green_border(SQUARE_LENGTH, xpos, ypos, 8'd70, 8'd25, BORDER_THICKNESS, 2)) begin
                        oled_data <= BLACK;
                    end
                end
            end
            3: begin 
                if (is_green_border(SQUARE_LENGTH, xpos, ypos, 8'd40, 8'd25, BORDER_THICKNESS, 2)) begin
                    oled_data <= GREEN;
                    if (is_green_border(SQUARE_LENGTH, xpos, ypos, 8'd10, 8'd25, BORDER_THICKNESS, 2)) begin
                        oled_data <= BLACK;
                    end
                    if (is_green_border(SQUARE_LENGTH, xpos, ypos, 8'd25, 8'd25, BORDER_THICKNESS, 2)) begin
                        oled_data <= BLACK;
                    end
                    if (is_green_border(SQUARE_LENGTH, xpos, ypos, 8'd55, 8'd25, BORDER_THICKNESS, 2)) begin
                        oled_data <= BLACK;
                    end
                    if (is_green_border(SQUARE_LENGTH, xpos, ypos, 8'd70, 8'd25, BORDER_THICKNESS, 2)) begin
                        oled_data <= BLACK;
                    end
                end
            end
            4: begin 
                if (is_green_border(SQUARE_LENGTH, xpos, ypos, 8'd55, 8'd25, BORDER_THICKNESS, 2)) begin
                    oled_data <= GREEN;
                    if (is_green_border(SQUARE_LENGTH, xpos, ypos, 8'd10, 8'd25, BORDER_THICKNESS, 2)) begin
                        oled_data <= BLACK;
                    end
                    if (is_green_border(SQUARE_LENGTH, xpos, ypos, 8'd25, 8'd25, BORDER_THICKNESS, 2)) begin
                        oled_data <= BLACK;
                    end
                    if (is_green_border(SQUARE_LENGTH, xpos, ypos, 8'd40, 8'd25, BORDER_THICKNESS, 2)) begin
                        oled_data <= BLACK;
                    end
                    if (is_green_border(SQUARE_LENGTH, xpos, ypos, 8'd70, 8'd25, BORDER_THICKNESS, 2)) begin
                        oled_data <= BLACK;
                    end
                end
            end
            5: begin 
                if (is_green_border(SQUARE_LENGTH, xpos, ypos, 8'd70, 8'd25, BORDER_THICKNESS, 2)) begin
                    oled_data <= GREEN;
                    if (is_green_border(SQUARE_LENGTH, xpos, ypos, 8'd10, 8'd25, BORDER_THICKNESS, 2)) begin
                        oled_data <= BLACK;
                    end
                    if (is_green_border(SQUARE_LENGTH, xpos, ypos, 8'd25, 8'd25, BORDER_THICKNESS, 2)) begin
                        oled_data <= BLACK;
                    end
                    if (is_green_border(SQUARE_LENGTH, xpos, ypos, 8'd40, 8'd25, BORDER_THICKNESS, 2)) begin
                                            oled_data <= BLACK;
                    end
                    if (is_green_border(SQUARE_LENGTH, xpos, ypos, 8'd55, 8'd25, BORDER_THICKNESS, 2)) begin
                        oled_data <= BLACK;
                    end
                end
            end
        endcase
        
        case (box_color)
            0: COLOR <= WHITE;
            1: COLOR <= RED;
            2: COLOR <= GREEN;
            3: COLOR <= BLUE;
        endcase
    end
    
endmodule

