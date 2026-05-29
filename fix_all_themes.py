import re
import math
import colorsys

def hex_to_rgb(hex_str):
    hex_str = hex_str.lstrip('#')
    return [int(hex_str[i:i+2], 16) for i in (0, 2, 4)]

def rgb_to_hex(rgb):
    return '#{:02x}{:02x}{:02x}'.format(int(rgb[0]), int(rgb[1]), int(rgb[2]))

def get_l(rgb):
    return 0.299 * rgb[0]/255 + 0.587 * rgb[1]/255 + 0.114 * rgb[2]/255

def interpolate_rgb(c1, c2, t):
    return [c1[i] + (c2[i] - c1[i]) * t for i in range(3)]

def generate_monotonic_gradient(stops, steps=11):
    # stops: list of (index, hex)
    # We will interpolate, but then force Luminance to be strictly monotonic.
    colors = []
    
    # First, get target L values for each step
    l_stops = [(i, get_l(hex_to_rgb(h))) for i, h in stops]
    target_l = []
    for i in range(steps):
        left = right = None
        for j in range(len(l_stops)):
            if l_stops[j][0] <= i: left = l_stops[j]
            if l_stops[j][0] >= i and right is None: right = l_stops[j]
        if left[0] == right[0]:
            target_l.append(left[1])
        else:
            t = (i - left[0]) / (right[0] - left[0])
            target_l.append(left[1] + (right[1] - left[1]) * t)
            
    # Then get raw interpolated RGB
    raw_colors = []
    for i in range(steps):
        left = right = None
        for j in range(len(stops)):
            if stops[j][0] <= i: left = stops[j]
            if stops[j][0] >= i and right is None: right = stops[j]
        if left[0] == right[0]:
            raw_colors.append(hex_to_rgb(left[1]))
        else:
            t = (i - left[0]) / (right[0] - left[0])
            c1 = hex_to_rgb(left[1])
            c2 = hex_to_rgb(right[1])
            raw_colors.append(interpolate_rgb(c1, c2, t))
            
    # Now adjust raw_colors to match target_l exactly
    final_hexes = []
    for i in range(steps):
        r, g, b = raw_colors[i]
        curr_l = get_l([r, g, b])
        t_l = target_l[i]
        
        # Scale to target luminance
        if curr_l > 0:
            scale = t_l / curr_l
            r = min(255, r * scale)
            g = min(255, g * scale)
            b = min(255, b * scale)
        else:
            r = g = b = t_l * 255
            
        final_hexes.append(rgb_to_hex([r, g, b]))
    
    return final_hexes

themes_config = {
    "retro": [(0, "#8bac0f"), (10, "#0f380f")], # decreasing
    "peach": [(0, "#ffe5b4"), (10, "#8b0000")], # decreasing
    "midnight": [(0, "#2c3e50"), (5, "#8e44ad"), (10, "#f1c40f")], # increasing
    "neon": [(0, "#0f172a"), (3, "#4c1d95"), (6, "#be185d"), (10, "#facc15")], # increasing
    "cyberpunk": [(0, "#2d1b4e"), (3, "#7c3aed"), (6, "#f472b6"), (8, "#22d3ee"), (10, "#facc15")], # increasing (cyan then yellow)
    "vaporwave": [(0, "#1e3a8a"), (5, "#d946ef"), (10, "#6ee7b7")], # increasing
    "dracula": [(0, "#282a36"), (3, "#6272a4"), (6, "#ff79c6"), (10, "#f1fa8c")], # increasing
    "gold": [(0, "#1c1917"), (5, "#b69d74"), (10, "#ffe87c")], # increasing
    "matcha": [(0, "#2e4a1a"), (5, "#8bc34a"), (10, "#fff8e1")], # increasing
    "matrix": [(0, "#022c22"), (5, "#10b981"), (10, "#d1fae5")], # increasing
    
    # Fix the classic themes too!
    "ocean": [(0, "#1a5276"), (5, "#3498db"), (10, "#d6eaf8")], # going up
    "forest": [(0, "#1b5e20"), (5, "#4caf50"), (10, "#e8f5e9")], # going up
    "sunset": [(0, "#fdebd0"), (5, "#e74c3c"), (10, "#641e16")], # down
    "candy": [(0, "#f8c8dc"), (5, "#af7ac5"), (10, "#4a235a")], # down
    "volcano": [(0, "#e5e5e5"), (5, "#e67e22"), (10, "#641e16")], # down
    "abyss": [(0, "#ccfbf1"), (5, "#14b8a6"), (10, "#042f2e")], # down
    "eclipse": [(0, "#18181b"), (5, "#7f8c8d"), (10, "#f1c40f")], # up
    "light": [(0, "#eee4da"), (5, "#f67c5f"), (10, "#edc22e")], # Wait, classic is tricky, let's just make it strictly increase or decrease? No, classic is 2-64 (down), 128-2048 (up). Let's fix them to be strictly monotonic!
}

# Actually for "ocean", "forest", "sunset", "candy", "volcano", "abyss", "eclipse":
# Let's just make them fully strictly monotonic!

themes_config["ocean"] = [(0, "#d6eaf8"), (5, "#5dade2"), (10, "#154360")] # down
themes_config["forest"] = [(0, "#e8f5e9"), (5, "#66bb6a"), (10, "#145a32")] # down
themes_config["sunset"] = [(0, "#fdebd0"), (5, "#e67e22"), (10, "#641e16")] # down
themes_config["candy"] = [(0, "#f5eef8"), (5, "#af7ac5"), (10, "#4a235a")] # down
themes_config["volcano"] = [(0, "#e5e5e5"), (5, "#e67e22"), (10, "#641e16")] # down
themes_config["abyss"] = [(0, "#e0f2fe"), (5, "#0d9488"), (10, "#022c22")] # down
themes_config["eclipse"] = [(0, "#f4f4f5"), (5, "#7f8c8d"), (10, "#18181b")] # down
themes_config["light"] = [(0, "#eee4da"), (5, "#f67c5f"), (10, "#7b241c")] # down
themes_config["dark"] = [(0, "#2c3e50"), (5, "#e74c3c"), (10, "#f1c40f")] # up
themes_config["oled"] = [(0, "#000000"), (10, "#ffffff")] # up

import sys

with open("renderer.lua", "r") as f:
    content = f.read()

for t_name, stops in themes_config.items():
    colors = generate_monotonic_gradient(stops)
    vals = [2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048]
    
    # build the replacement block
    block_lines = ["        tile_colors = {", f'            [0]    = {{hex("{colors[0]}")}},']
    for i, v in enumerate(vals):
        block_lines.append(f'            [{v}]    = {{hex("{colors[i]}")}},')
    block_lines.append("        },")
    replacement = "\n".join(block_lines)
    
    # replace in content using regex
    pattern = re.compile(rf'({t_name}\s*=\s*{{[\s\S]*?)tile_colors\s*=\s*{{.*?}},', re.DOTALL)
    content = pattern.sub(rf'\1{replacement}', content, count=1)
    
with open("renderer.lua", "w") as f:
    f.write(content)
print("Updated renderer.lua")
