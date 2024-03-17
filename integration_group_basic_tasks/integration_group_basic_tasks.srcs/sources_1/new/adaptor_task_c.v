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
    parameter BLACK = {5'd0, 6'd0, 5'd0};
    parameter RED = {5'd31, 6'd0, 5'd0};
    parameter GREEN = {5'd0, 6'd63, 5'd0};

    // Ease of usage
    reg [7:0] xpos; // = pixel_index % 96;
    reg [7:0] ypos; // = pixel_index / 96;
    
    // Animation variables
    reg [7:0] square_xpos = 45;
    reg [7:0] square_ypos = 0;
    
    
    reg btnD_prev = 0;
    
    reg [3:0] animation_state = 0; 
    reg green_enabled = 0;
    // 4 states - 
    /* 
    0(idle), 
    1(down red), 
    2(down right), 
    3(red stop)
    4(green stop)
    5(green left)
    6(green up)
    7(green stop)
    8(red stop)
    */
    
    reg [30-1:0] down_pixel_state = ~(30'b0);
    reg [15-1:0] right_pixel_state = ~(15'b0);

    // Task for button press detection --- Initialisation -------------------------------------------------
    task button_press_detection;
        begin
            btnD_prev <= btnD;
            if (!btnD_prev && btnD) begin
                animation_state <= 1;
            end
        end
    endtask
    
    // Task for animation control
    task animation_control;
        begin
        end
    endtask
    
    // Task for red trail control
    task red_trail_control;
        begin
        end
    endtask
    
    // Task for expansion animation
    task expansion_animation;
        begin
        end
    endtask
    
    // Task for vertical expansion animation
    task vertical_expansion_animation;
        begin
        end
    endtask
    
    task reset_control;
        begin
            if (reset) begin
            end
        end
    endtask
    
    always @ (posedge clk) begin
        button_press_detection;
        animation_control;
        red_trail_control;
        expansion_animation;
        vertical_expansion_animation;
        reset_control;
    end
    
    always @ (*) begin
        xpos = oled_pixel_index % 96;
        ypos = oled_pixel_index / 96;
    
        // Add condition to stop expansion at x45
        if (45 <= xpos && xpos < 45+5 && ypos < 35) begin 
            if (down_pixel_state[ypos] == 1) begin
                oled_pixel_data <= RED;
            end else if (green_enabled) begin
                oled_pixel_data <= GREEN;
            end
        end else if (30 <= xpos && xpos < 35 && 45 <= xpos && xpos < 60) begin 
            if (right_pixel_state[xpos - 45] == 1) begin
                oled_pixel_data <= RED;
            end else if (green_enabled) begin
                oled_pixel_data <= GREEN;
            end
        end else begin
            oled_pixel_data <= BLACK;
        end
    end
    
endmodule
