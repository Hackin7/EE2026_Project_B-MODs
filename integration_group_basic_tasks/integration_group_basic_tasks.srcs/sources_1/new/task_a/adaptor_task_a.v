`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.03.2024 10:38:24
// Design Name: 
// Module Name: top
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


module adaptor_task_a(
    // Control
    input reset, input clk,
    // LEDs, Switches, Buttons
    input btnC, btnU, btnL, btnR, btnD, input [15:0] sw, output [15:0] led,
    // 7 Segment Display
    output [6:0] seg, output dp, output [3:0] an,
    // OLED
    input [12:0] oled_pixel_index, output [15:0] oled_pixel_data,
    // Mouse - NOT NEEDED
    input [11:0] mouse_xpos,  mouse_ypos, input [3:0] mouse_zpos,
    input mouse_left_click, mouse_middle_click, mouse_right_click, mouse_new_event
);
    parameter WIDTH = 96;
    parameter HEIGHT = 64;
    parameter RED = {5'd31, 6'd0, 5'd0};
    parameter ORANGE = {5'd31, 6'd41, 5'd0};
    parameter GREEN = {5'd0, 6'd31, 5'd0};
    
    //// Drawing Functions /////////////////////////////////////////////////////////
    function is_in_box(input [7:0] x, input [7:0] y, input [7:0] x1, input [7:0] y1, input [7:0] x2, input [7:0] y2);
        begin
            is_in_box = (x1 <= x) && (x <= x2) && (y1 <= y) && (y <= y2);
        end
    endfunction
    
    function is_in_circle(
            input [31:0] x, input [31:0] y, 
            input [31:0] x_centre, input [31:0] y_centre, input [31:0] radius);
        begin
            // check if distance_squared from centre is less than equal to radius_squared
            is_in_circle = (x - x_centre)**2 + (y - y_centre)**2 <= radius**2;
            //is_in_circle = x*x - 2*x*x_centre + 4*(x_centre*x_centre) + y*y - 2*y*y_centre + 4*(y_centre*y_centre) <= radius**2;
            //is_in_circle = (x*x + 4*(x_centre*x_centre) + y*y + 4*(y_centre*y_centre) <= radius*radius + 2*x*x_centre + 2*y*y_centre);
        end
    endfunction
    
    function bruteforce_is_in_triangle(
        input [31:0] x_in, input [31:0] y_in, input [31:0] x_top_left, input [31:0] y_top_left);
        begin
            bruteforce_is_in_triangle = (
                ((y_in - y_top_left) == 0 && ((x_in - x_top_left) >= 5 && (x_in - x_top_left) <= 6)) ||
                ((y_in - y_top_left) == 1 && ((x_in - x_top_left) >= 5 && (x_in - x_top_left) <= 6)) ||
                ((y_in - y_top_left) == 2 && ((x_in - x_top_left) >= 4 && (x_in - x_top_left) <= 7)) ||
                ((y_in - y_top_left) == 3 && ((x_in - x_top_left) >= 4 && (x_in - x_top_left) <= 7)) ||
                ((y_in - y_top_left) == 4 && ((x_in - x_top_left) >= 3 && (x_in - x_top_left) <= 8)) ||
                ((y_in - y_top_left) == 5 && ((x_in - x_top_left) >= 3 && (x_in - x_top_left) <= 8)) ||
                ((y_in - y_top_left) == 6 && ((x_in - x_top_left) >= 2 && (x_in - x_top_left) <= 9)) ||
                ((y_in - y_top_left) == 7 && ((x_in - x_top_left) >= 2 && (x_in - x_top_left) <= 9)) ||
                ((y_in - y_top_left) == 8 && ((x_in - x_top_left) >= 2 && (x_in - x_top_left) <= 9)) ||
                ((y_in - y_top_left) == 9 && ((x_in - x_top_left) >= 1 && (x_in - x_top_left) <= 10))
            );
        end
    endfunction
    
    function is_rect_ring(
        input [7:0] x, input [7:0] y, 
        input [7:0] x_centre, input [7:0] y_centre, 
        input [7:0] inner_x_radius, input [7:0] inner_y_radius, 
        input [7:0] x_thickness, input [7:0] y_thickness
    );
        begin
            is_rect_ring = (
                ~is_in_box(x, y, x_centre-inner_x_radius, y_centre-inner_y_radius, x_centre+inner_x_radius, y_centre+inner_y_radius) &&
                is_in_box(
                    x, y, 
                    x_centre-inner_x_radius-x_thickness, y_centre-inner_y_radius-y_thickness, 
                    x_centre+inner_x_radius+x_thickness, y_centre+inner_y_radius+y_thickness
                )
            );
        end
    endfunction

    // OLED //////////////////////////////////////////////////////////////////////
    reg [15:0] oled_data = 16'h07E0;
    wire [12:0] pixel_index = oled_pixel_index;
    assign oled_pixel_data = oled_data;
    // Ease of usage
    reg [7:0] xpos; // = pixel_index % 96;
    reg [7:0] ypos; // = pixel_index / 96;
    always @ (*) begin
        xpos = pixel_index % 96; 
        ypos = pixel_index / 96;
        if (element_state[0] && is_rect_ring(xpos, ypos, WIDTH/2, HEIGHT/2, WIDTH/2-3, HEIGHT/2-3, 1, 1)) begin // -2-1 = -3
            oled_data = RED; // Red
        end else if (element_state[1] && is_rect_ring(xpos, ypos, WIDTH/2, HEIGHT/2, WIDTH/2 - 8, HEIGHT/2 - 8, 3, 3)) begin // -3 - 2 - 3 = -8
            oled_data = ORANGE; 
        end else if (element_state[2] && is_rect_ring(xpos, ypos, WIDTH/2, HEIGHT/2, WIDTH/2 - 11, HEIGHT/2 - 11, 1, 1)) begin // -8 -2 -1 = -11
            oled_data = GREEN;
        end else if (element_state[3] && is_rect_ring(xpos, ypos, WIDTH/2, HEIGHT/2, WIDTH/2 - 15, HEIGHT/2 - 15, 2, 2)) begin //-11 -2 -2 = -15
            oled_data = GREEN;
        end else if (element_state[4] && is_rect_ring(xpos, ypos, WIDTH/2, HEIGHT/2, WIDTH/2 - 20, HEIGHT/2 - 20, 3, 3)) begin // -15 -2 -3 = -20
            oled_data = GREEN; 
        // Red Box
        end else if (element_state[5] && is_in_box(xpos, ypos, WIDTH/2-1, HEIGHT/2-1, WIDTH/2+1, HEIGHT/2+1)) begin
            oled_data = RED;
        // Orange Circle
        end else if (element_state[6] && is_in_circle(xpos, ypos, WIDTH/2, HEIGHT/2, 3)) begin
            oled_data = ORANGE;
        // Green Triangle
        end else if (element_state[7] && bruteforce_is_in_triangle(xpos, ypos, WIDTH/2 - 5, HEIGHT/2 - 5)) begin
            oled_data = GREEN;
        end else begin
            oled_data = 16'h0;
        end
    end
        
    //// Elements State //////////////////////////////////////////////////////////////////////////
    wire [7:0] element_state;
    assign element_state[0] = 1;
    assign element_state[1] = btnC;
    
    animation_timer anim_timer(clk, btnC, element_state[4:2]);
    wire [2:0] middle_trigger_state;
    middle_square_timer #(5_000_000, 20_000_000) mid_timer(clk, reset, btnC & btnD, middle_trigger_state);
    assign element_state[5] = middle_trigger_state == 1;
    assign element_state[6] = middle_trigger_state == 2;
    assign element_state[7] = middle_trigger_state == 3;
endmodule
