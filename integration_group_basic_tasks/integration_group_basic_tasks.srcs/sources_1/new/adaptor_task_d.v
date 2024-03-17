module adaptor_task_d(
    input reset, input clk,
    input btnC, btnU, btnL, btnR, btnD, input [15:0] sw, output [15:0] led,
    output [6:0] seg, output dp, output [3:0] an,
    // OLED
    input [12:0] oled_pixel_index, output reg [15:0] oled_pixel_data
);

    reg [7:0] square_xpos = 0, square_ypos = 0;
    reg [15:0] square_color = 16'h001F;
    reg [31:0] move_counter = 0;
    parameter SPEED_45 = 2222222; //45 pixels per sec
    parameter SPEED_30 = 3333333; //30 pixels per sec 
    parameter SPEED_15 = 6666666; //15 pixels per sec
    reg [31:0] speed_threshold = SPEED_45;

    reg btnC_prev, btnU_prev, btnL_prev, btnR_prev, btnD_prev;
    reg [2:0] active_btn = 3'b000; 

    always @(posedge clk) begin
        if(btnU && !btnU_prev) active_btn <= 3'b001;
        else if(btnL && !btnL_prev) active_btn <= 3'b011;
        else if(btnR && !btnR_prev) active_btn <= 3'b100;
        else if(btnC && !btnC_prev) begin
            square_xpos <= 48; 
            square_ypos <= 59;
            square_color <= 16'hFFFF;
            active_btn <= 3'b000; 
        end

        if (sw[0] && active_btn <= 3'b001) speed_threshold <= SPEED_15;
        else if (sw[0] && active_btn <= 3'b011) speed_threshold <= SPEED_30;
        else if (sw[0] && active_btn <= 3'b100) speed_threshold <= SPEED_30;
        else if (!sw[0]) speed_threshold <= SPEED_45;
             

        move_counter <= move_counter + 1;
        if(move_counter >= speed_threshold) begin
            case (active_btn)
                3'b001: if(square_ypos > 0) square_ypos <= square_ypos - 1; // Up
                3'b011: if(square_xpos > 0) square_xpos <= square_xpos - 1; // Left
                3'b100: if(square_xpos < 91) square_xpos <= square_xpos + 1; // Right
                default: ; // No movement
            endcase
            move_counter <= 0;
        end

        /* Button ----------------------------*/
        btnC_prev <= btnC;
        btnU_prev <= btnU;
        btnL_prev <= btnL;
        btnR_prev <= btnR;
        btnD_prev <= btnD;
        
        /* Reset -----------------------------*/
        if (reset) begin
            square_xpos <= 0; 
            square_ypos <= 0;
            square_color <= 16'h001F;
            move_counter <= 0;
            active_btn <= 3'b000;
        end
    end
 

    always @(posedge clk) begin
        if ((oled_pixel_index % 96 >= square_xpos) && (oled_pixel_index % 96 < square_xpos + 5) &&
            (oled_pixel_index / 96 >= square_ypos) && (oled_pixel_index / 96 < square_ypos + 5)) begin
            oled_pixel_data <= square_color;
        end else begin
            oled_pixel_data <= 16'h0000;
        end
    end

endmodule
