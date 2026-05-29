def hex_to_rgb(hex_str):
    hex_str = hex_str.lstrip('#')
    return tuple(int(hex_str[i:i+2], 16) for i in (0, 2, 4))

def rgb_to_hex(rgb):
    return '#{:02x}{:02x}{:02x}'.format(int(rgb[0]), int(rgb[1]), int(rgb[2]))

def get_l(rgb):
    return 0.299 * rgb[0]/255 + 0.587 * rgb[1]/255 + 0.114 * rgb[2]/255

def interpolate(c1, c2, t):
    return tuple(c1[i] + (c2[i] - c1[i]) * t for i in range(3))

def generate_gradient(stops, steps=11):
    # stops is a list of (index, hex_color) where index is from 0 to 10
    colors = []
    for i in range(steps):
        # find bounding stops
        left_stop = None
        right_stop = None
        for j in range(len(stops)):
            if stops[j][0] <= i:
                left_stop = stops[j]
            if stops[j][0] >= i and right_stop is None:
                right_stop = stops[j]
        
        if left_stop[0] == right_stop[0]:
            colors.append(left_stop[1])
        else:
            t = (i - left_stop[0]) / (right_stop[0] - left_stop[0])
            c1 = hex_to_rgb(left_stop[1])
            c2 = hex_to_rgb(right_stop[1])
            c = interpolate(c1, c2, t)
            colors.append(rgb_to_hex(c))
    return colors

themes = {
    "neon": [
        (0, "#0f172a"),
        (3, "#4c1d95"),
        (6, "#be185d"),
        (10, "#facc15")
    ],
    "peach": [
        (0, "#ffe5b4"),
        (5, "#ff7f50"),
        (10, "#8b0000")
    ],
    "midnight": [
        (0, "#2c3e50"),
        (3, "#8e44ad"),
        (7, "#e74c3c"),
        (10, "#f1c40f")
    ],
    "dracula": [
        (0, "#282a36"),
        (3, "#6272a4"),
        (6, "#bd93f9"),
        (8, "#ff79c6"),
        (10, "#f1fa8c")
    ],
    "cyberpunk": [
        (0, "#2d1b4e"),
        (3, "#7c3aed"),
        (6, "#f472b6"),
        (8, "#facc15"),
        (10, "#22d3ee")
    ],
    "vaporwave": [
        (0, "#1e3a8a"),
        (4, "#6366f1"),
        (7, "#d946ef"),
        (10, "#2dd4bf")
    ]
}

for name, stops in themes.items():
    print(f"{name} = {{")
    colors = generate_gradient(stops)
    vals = [2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048]
    prev_l = None
    dir_str = "N/A"
    for i, h in enumerate(colors):
        l = get_l(hex_to_rgb(h))
        note = ""
        if prev_l is not None:
            if l > prev_l: note = "UP"
            else: note = "DOWN"
        print(f"  [{vals[i]}] = {{hex(\"{h}\")}}, -- L={l:.3f} {note}")
        prev_l = l
    print("}")
