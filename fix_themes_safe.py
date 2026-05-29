import math

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
            
    final_hexes = []
    for i in range(steps):
        r, g, b = raw_colors[i]
        curr_l = get_l([r, g, b])
        t_l = target_l[i]
        if curr_l > 0:
            scale = t_l / curr_l
            r = min(255, r * scale)
            g = min(255, g * scale)
            b = min(255, b * scale)
        else:
            r = g = b = t_l * 255
        final_hexes.append(rgb_to_hex([r, g, b]))
    return final_hexes

# ONLY the broken themes, we completely leave the classic themes alone!
themes_config = {
    "peach": [(0, "#ffe5b4"), (10, "#8b0000")],
    "midnight": [(0, "#2c3e50"), (5, "#8e44ad"), (10, "#f1c40f")],
    "neon": [(0, "#0f172a"), (3, "#4c1d95"), (6, "#be185d"), (10, "#facc15")],
    "cyberpunk": [(0, "#2d1b4e"), (3, "#7c3aed"), (6, "#f472b6"), (8, "#22d3ee"), (10, "#facc15")],
    "vaporwave": [(0, "#1e3a8a"), (5, "#d946ef"), (10, "#6ee7b7")],
    "dracula": [(0, "#282a36"), (3, "#6272a4"), (6, "#ff79c6"), (10, "#f1fa8c")],
}

with open("renderer.lua", "r") as f:
    lines = f.readlines()

out_lines = []
in_tile_colors = False
current_theme = None
vals = [2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048]
val_idx = 0
colors = []

for line in lines:
    if "=" in line and "{" in line and "tile_colors" not in line and "super_tile" not in line and "dark_text" not in line:
        theme_name = line.split("=")[0].strip()
        if theme_name in themes_config:
            current_theme = theme_name
            colors = generate_monotonic_gradient(themes_config[theme_name])
        else:
            current_theme = None
            
    if "tile_colors = {" in line and current_theme is not None:
        in_tile_colors = True
        val_idx = 0
        out_lines.append(line)
        continue
        
    if in_tile_colors:
        if "}," in line and "[" not in line:
            in_tile_colors = False
            out_lines.append(line)
            continue
            
        if "[" in line and "]" in line and "=" in line:
            val_str = line.split("[")[1].split("]")[0]
            val = int(val_str)
            if val == 0:
                out_lines.append(line)
            else:
                hex_col = colors[val_idx]
                val_idx += 1
                out_lines.append(f'            [{val}]    = {{hex("{hex_col}")}},\n')
            continue
            
    out_lines.append(line)

with open("renderer.lua", "w") as f:
    f.writelines(out_lines)
print("done")
