from PIL import Image
import os
from datetime import datetime

# Load the image
img = Image.open("image.png")

# Resize the image if it's larger than 96x64 pixels
if img.size[0] > 96 or img.size[1] > 64:
    img = img.resize((96, 64), resample=Image.LANCZOS)

# Generate the Verilog function
verilog_function = "function [15:0] show_image(\n"
verilog_function += "    input [31:0] x, input [31:0] y,\n"
verilog_function += "    input [31:0] x_offset, input [31:0] y_offset);\n"
verilog_function += "begin\n"

# Loop over each pixel and generate the corresponding Verilog code
for y in range(64):
    for x in range(96):
        pixel = img.getpixel((x, y))
        red = pixel[0] // 8
        green = pixel[1] // 4
        blue = pixel[2] // 8

        verilog_function += f"    if (x - x_offset == {x} && y - y_offset == {y}) begin\n"
        verilog_function += f"        show_image = 16'b{red:05b}{green:06b}{blue:05b};\n"
        verilog_function += "    end else\n"

verilog_function += "        show_image = 16'b0000000000000000; // NULL value\n"
verilog_function += "end\n"
verilog_function += "endfunction\n"

# Get the current date and time
now = datetime.now()
date_time_str = now.strftime("%Y%m%d_%H%M%S")

# Create the output file name
output_filename = f"Image_{date_time_str}.v"
output_path = os.path.join(os.path.dirname(__file__), output_filename)

# Save the Verilog function to the new file
with open(output_path, "w") as file:
    file.write(verilog_function)

print(f"Verilog function saved to: {output_path}")