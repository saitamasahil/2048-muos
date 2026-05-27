#!/bin/bash
# shellcheck shell=bash
set -e

# Build script for 2048 muOS (.muxapp package)
# Usage: bash build.sh

# Get project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Create build directory if it doesn't exist
BUILD_DIR="$PROJECT_ROOT/build"
if [ ! -d "$BUILD_DIR" ]; then
    echo "Creating build directory: $BUILD_DIR"
    mkdir -p "$BUILD_DIR"
fi

# Read version from globals.lua
MAJOR=$(grep -oP 'major = \K\d+' "$PROJECT_ROOT/globals.lua")
MINOR=$(grep -oP 'minor = \K\d+' "$PROJECT_ROOT/globals.lua")
PATCH=$(grep -oP 'patch = \K\d+' "$PROJECT_ROOT/globals.lua")

if [ -z "$MAJOR" ] || [ -z "$MINOR" ] || [ -z "$PATCH" ]; then
    echo "Error: Could not determine version from globals.lua"
    exit 1
fi

TAG="v${MAJOR}.${MINOR}.${PATCH}"
echo "Building 2048 version: $TAG"

# Set up paths
OUTPUT="$BUILD_DIR/2048_${TAG}.muxapp"
WORKDIR="$BUILD_DIR/pkg_${MAJOR}${MINOR}${PATCH}"

# Clean up old build
rm -rf "$WORKDIR" "$OUTPUT"
mkdir -p "$WORKDIR/2048/.game"

# Copy launcher script
echo "Copying launcher..."
cp "$PROJECT_ROOT/mux_launch.sh" "$WORKDIR/2048/"

# Copy Lua source files
echo "Copying game source..."
cp "$PROJECT_ROOT/conf.lua" "$WORKDIR/2048/.game/"
cp "$PROJECT_ROOT/globals.lua" "$WORKDIR/2048/.game/"
cp "$PROJECT_ROOT/main.lua" "$WORKDIR/2048/.game/"
cp "$PROJECT_ROOT/game.lua" "$WORKDIR/2048/.game/"
cp "$PROJECT_ROOT/grid.lua" "$WORKDIR/2048/.game/"
cp "$PROJECT_ROOT/tile.lua" "$WORKDIR/2048/.game/"
cp "$PROJECT_ROOT/input.lua" "$WORKDIR/2048/.game/"
cp "$PROJECT_ROOT/renderer.lua" "$WORKDIR/2048/.game/"
cp "$PROJECT_ROOT/save.lua" "$WORKDIR/2048/.game/"
cp "$PROJECT_ROOT/splash.lua" "$WORKDIR/2048/.game/"
cp "$PROJECT_ROOT/timer.lua" "$WORKDIR/2048/.game/"

# Copy assets (excluding glyph subfolder — handled separately)
echo "Copying assets..."
mkdir -p "$WORKDIR/2048/.game/assets"
if [ -d "$PROJECT_ROOT/assets" ]; then
    (
        shopt -s dotglob
        for item in "$PROJECT_ROOT/assets/"*; do
            bname="$(basename "$item")"
            [ "$bname" = "glyph" ] && continue
            cp -r "$item" "$WORKDIR/2048/.game/assets/" 2>/dev/null || true
        done
    )
fi

# Copy LÖVE binary and libs
echo "Copying LÖVE runtime..."
cp -r "$PROJECT_ROOT/bin" "$WORKDIR/2048/.game/"

# Create static directory for saves
mkdir -p "$WORKDIR/2048/.game/static"

# --- Glyph handling (resolution-specific icons, same as Scrappy) ---
mkdir -p "$WORKDIR/2048/glyph"
GLYPH_SRC=""
if [ -f "$PROJECT_ROOT/assets/logo_monochrome.png" ]; then
    GLYPH_SRC="$PROJECT_ROOT/assets/logo_monochrome.png"
fi
if [ -n "$GLYPH_SRC" ]; then
    echo "Copying logo_monochrome.png to glyph directory..."
    cp "$GLYPH_SRC" "$WORKDIR/2048/glyph/"
    # Copy resolution-specific pre-sized icons for proper muOS glyph display
    GLYPH_ASSET_DIR="$PROJECT_ROOT/assets/glyph"
    for res in 640x480 720x480 720x576 720x720 1024x768 1280x720 1920x1080; do
        mkdir -p "$WORKDIR/2048/glyph/$res"
        if [ -f "$GLYPH_ASSET_DIR/$res.png" ]; then
            cp "$GLYPH_ASSET_DIR/$res.png" "$WORKDIR/2048/glyph/$res/logo_2048.png"
        else
            # Fallback to default icon if resolution-specific one not found
            cp "$GLYPH_SRC" "$WORKDIR/2048/glyph/$res/logo_2048.png"
        fi
    done
    # Cleanup loose PNGs from glyph root (keep only the main one)
    if [ -d "$WORKDIR/2048/glyph/" ]; then
        find "$WORKDIR/2048/glyph/" -maxdepth 1 -name "*.png" ! -name "logo_2048.png" -delete
    fi
else
    echo "Warning: logo_2048.png not found in assets/"
fi

# Create the .muxapp package
echo "Creating package..."
(cd "$WORKDIR" && zip -qr "$OUTPUT" ./2048)

# Clean up
rm -rf "$WORKDIR"

echo -e "\nBuild complete!"
ls -lh "$OUTPUT"
