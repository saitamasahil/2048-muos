import re

# Read original renderer.lua from git HEAD
import subprocess
result = subprocess.run(["git", "show", "HEAD:renderer.lua"], capture_output=True, text=True)
original_content = result.stdout

with open("renderer.lua", "r") as f:
    current_content = f.read()

classic_themes = ["ocean", "forest", "sunset", "candy", "volcano", "abyss", "eclipse", "light", "dark", "oled"]

for theme in classic_themes:
    # Match the tile_colors block for the theme in original content
    pattern = re.compile(rf'({theme}\s*=\s*{{[\s\S]*?)tile_colors\s*=\s*{{.*?}},', re.DOTALL)
    
    match_orig = pattern.search(original_content)
    if match_orig:
        # Extract the exact tile_colors block from original
        orig_tile_colors_block = re.search(r'tile_colors\s*=\s*{.*?},', match_orig.group(0), re.DOTALL).group(0)
        
        # Replace it in current_content
        match_curr = pattern.search(current_content)
        if match_curr:
            curr_tile_colors_block = re.search(r'tile_colors\s*=\s*{.*?},', match_curr.group(0), re.DOTALL).group(0)
            
            # Sub out the block
            # Be careful with replace in the whole text, just replace the first instance found for this theme
            
            # Using sub on the specific match
            def replacer(m):
                return m.group(1) + orig_tile_colors_block
                
            current_content = pattern.sub(replacer, current_content, count=1)

with open("renderer.lua", "w") as f:
    f.write(current_content)
print("Classic themes restored.")
