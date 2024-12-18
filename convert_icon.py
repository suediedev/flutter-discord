import cairosvg

# Convert SVG to PNG with 1024x1024 resolution
cairosvg.svg2png(
    url="assets/icon/app_icon.svg",
    write_to="assets/icon/app_icon.png",
    output_width=1024,
    output_height=1024
)
