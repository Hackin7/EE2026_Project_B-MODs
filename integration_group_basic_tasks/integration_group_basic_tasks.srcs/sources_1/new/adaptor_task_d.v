
module adaptor_task_d(
    input reset, input clk,
    input btnC, btnU, btnL, btnR, btnD, input [15:0] sw, output [15:0] led,
    output [6:0] seg, output dp, output [3:0] an,
    inout [7:0] JB
);

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
    .cs(Jb[0]), .sdin(Jb[1]), .sclk(Jb[3]), .d_cn(Jb[4]), .resn(Jb[5]), .vccen(Jb[6]), .pmoden(Jb[7])
);

reg [7:0] square_xpos = 0, square_ypos = 0;
reg [15:0] square_color = 16'h001F;
reg [31:0] move_counter = 0;
parameter FAST_SPEED = 2222222; 
parameter SLOW_SPEED = 3333333; 
reg [31:0] speed_threshold = FAST_SPEED;
reg btnC_prev, btnU_prev, btnL_prev, btnR_prev, btnD_prev;

always @(posedge clk) begin
    btnC_prev <= 0;
    btnU_prev <= 0;
    btnL_prev <= 0;
    btnR_prev <= 0;
    btnD_prev <= 0;
end


always @(posedge clk) begin
    speed_threshold <= sw[0] ? SLOW_SPEED : FAST_SPEED;
    
    move_counter <= move_counter + 1;
    if(move_counter >= speed_threshold) begin
        if(!btnU_prev && btnU && square_ypos > 0) square_ypos <= square_ypos - 1;
        if(!btnD_prev && btnD && square_ypos < 59) square_ypos <= square_ypos + 1;
        if(!btnL_prev && btnL && square_xpos > 0) square_xpos <= square_xpos - 1;
        if(!btnR_prev && btnR && square_xpos < 91) square_xpos <= square_xpos + 1;
        if(btnC) begin
            square_xpos <= 48; 
            square_ypos <= 59;
            square_color <= 16'hFFFF; 
        end
        move_counter <= 0;
    end
end

always @(*) begin
    if ((oled_pixel_index % 96 >= square_xpos) && (oled_pixel_index % 96 < square_xpos + 5) &&
        (oled_pixel_index / 96 >= square_ypos) && (oled_pixel_index / 96 < square_ypos + 5)) begin
        oled_pixel_data = square_color;
    end else begin
        oled_pixel_data = 16'h0000; 
    end
end

endmodule
