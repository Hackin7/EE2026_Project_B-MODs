from PIL import Image
import os
from datetime import datetime
from collections import Counter

# Color reduction function
def reduce_colors(img, num_colors):
    # Get the colors in the image
    colors = img.getdata()

    # Count the occurrences of each color
    color_counts = Counter(colors)

    # Sort the colors by their counts in descending order
    sorted_colors = sorted(color_counts.items(), key=lambda x: x[1], reverse=True)

    # Create a new palette with the top num_colors colors
    new_palette = [color for color, count in sorted_colors[:num_colors]]

    # Quantize the image to the new palette
    quantized_img = img.convert('P', palette=Image.WebPalette(new_palette))

    return quantized_img

# Load the image
img = Image.open("image.png")

# Reduce the number of colors (e.g., 128)
num_colors = 128
img = reduce_colors(img, num_colors)

# Resize the image if it's larger than 96x64 pixels
if img.size[0] > 96 or img.size[1] > 64:
    img = img.resize((96, 64), resample=Image.LANCZOS)

# Create a color dictionary
color_dict = {}

# Iterate over pixels and populate the color dictionary
for y in range(64):
    for x in range(96):
        pixel = img.getpixel((x, y))
        red = pixel[0] // 8
        green = pixel[1] // 4
        blue = pixel[2] // 8
        color = f"{red:05b}{green:06b}{blue:05b}"

        if color not in color_dict:
            color_dict[color] = f"16'b{color}"

# Generate the Verilog function
verilog_function = "function [15:0] show_image(\n"
verilog_function += "    input [31:0] x, input [31:0] y,\n"
verilog_function += "    input [31:0] x_offset, input [31:0] y_offset);\n"
verilog_function += "begin\n"

for color, binary_color in color_dict.items():
    verilog_function += f"    if ({binary_color} == 16'b{color}) begin\n"

    for y in range(64):
        for x in range(96):
            pixel = img.getpixel((x, y))
            red = pixel[0] // 8
            green = pixel[1] // 4
            blue = pixel[2] // 8
            pixel_color = f"{red:05b}{green:06b}{blue:05b}"

            if pixel_color == color:
                verilog_function += f"        if (x - x_offset == {x} && y - y_offset == {y}) show_image = {binary_color};\n"
                verilog_function += "        else\n"

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