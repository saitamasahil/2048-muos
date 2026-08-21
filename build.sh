#!/bin/bash
# ==============================================================================
# 2048 Plus - Unified Build Script
# ==============================================================================
# Usage:
#   ./build.sh              (Interactive: asks 1) muOS, 2) PortMaster, 3) Both)
#   ./build.sh muos         (Builds muOS package only)
#   ./build.sh portmaster   (Builds PortMaster package only)
#   ./build.sh both         (Builds both packages)
# ==============================================================================
set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$PROJECT_ROOT/build"
PM_SOURCE_DIR="$PROJECT_ROOT/portmaster"

# Read version from globals.lua
MAJOR=$(grep -oP 'major = \K\d+' "$PROJECT_ROOT/globals.lua")
MINOR=$(grep -oP 'minor = \K\d+' "$PROJECT_ROOT/globals.lua")
PATCH=$(grep -oP 'patch = \K\d+' "$PROJECT_ROOT/globals.lua")

if [ -z "$MAJOR" ] || [ -z "$MINOR" ] || [ -z "$PATCH" ]; then
    echo "Error: Could not determine version from globals.lua"
    exit 1
fi

TAG="v${MAJOR}.${MINOR}.${PATCH}"
mkdir -p "$BUILD_DIR"

# ------------------------------------------------------------------------------
# Function: Build muOS Package
# ------------------------------------------------------------------------------
build_muos() {
    echo ""
    echo "Building muOS Package..."
    
    APP_NAME="2048 Plus"
    OUTPUT="$BUILD_DIR/${APP_NAME}_${TAG}.muxapp"
    WORKDIR="$BUILD_DIR/pkg_${MAJOR}${MINOR}${PATCH}"

    rm -rf "$WORKDIR" "$OUTPUT"
    mkdir -p "$WORKDIR/$APP_NAME/.game"

    # Copy launcher script
    cp "$PROJECT_ROOT/mux_launch.sh" "$WORKDIR/$APP_NAME/"

    # Copy all Lua source files
    cp "$PROJECT_ROOT/"*.lua "$WORKDIR/$APP_NAME/.game/"

    # Copy licenses
    cp -r "$PROJECT_ROOT/licenses" "$WORKDIR/$APP_NAME/.game/"

    # Copy all assets
    cp -r "$PROJECT_ROOT/assets" "$WORKDIR/$APP_NAME/.game/"

    # Copy LÖVE binary and libs
    cp -r "$PROJECT_ROOT/bin" "$WORKDIR/$APP_NAME/.game/"
    mkdir -p "$WORKDIR/$APP_NAME/.game/static"

    # Copy glyph for muOS menu icon
    mkdir -p "$WORKDIR/$APP_NAME/glyph"
    if [ -f "$PROJECT_ROOT/assets/logo/logo_2048.svg" ]; then
        cp "$PROJECT_ROOT/assets/logo/logo_2048.svg" "$WORKDIR/$APP_NAME/glyph/"
    elif [ -f "$PROJECT_ROOT/assets/glyph/logo_2048.svg" ]; then
        cp "$PROJECT_ROOT/assets/glyph/logo_2048.svg" "$WORKDIR/$APP_NAME/glyph/"
    fi

    # Create the .muxapp package
    mkdir -p "$BUILD_DIR"
    (cd "$WORKDIR" && zip -qr "package.muxapp" ./"$APP_NAME" && mv "package.muxapp" "$OUTPUT")
    rm -rf "$WORKDIR"

    MUX_SIZE=$(du -h "$OUTPUT" | cut -f1)
    echo "[OK] muOS package created: build/${APP_NAME}_${TAG}.muxapp ($MUX_SIZE)"
}

# ------------------------------------------------------------------------------
# Function: Build PortMaster Package
# ------------------------------------------------------------------------------
build_portmaster() {
    echo ""
    echo "Building PortMaster Package..."

    TMP_STAGE="/tmp/pm_stage_$$"
    mkdir -p "$TMP_STAGE/gamedata"

    # Stage code, sprites, icons, UI, font, SFX (exclude loose music & repo meta)
    rsync -av \
      --exclude="music" \
      --exclude=".git*" \
      --exclude="*.sh" \
      --exclude="build*" \
      --exclude="bin" \
      --exclude="demo.webp" \
      --exclude="splash.webp" \
      --exclude="screenshots" \
      --exclude="licenses" \
      --exclude="portmaster" \
      "$PROJECT_ROOT/" "$TMP_STAGE/gamedata/" > /dev/null

    tar -czf "$TMP_STAGE/gamedata.tar.gz" -C "$TMP_STAGE" gamedata
    rm -rf "$TMP_STAGE/gamedata"

    TAR_SIZE=$(du -h "$TMP_STAGE/gamedata.tar.gz" | cut -f1)
    echo "[OK] gamedata.tar.gz created ($TAR_SIZE)"

    # Build standalone PortMaster release zip
    ZIP_STAGE="/tmp/pm_zip_$$"
    mkdir -p "$ZIP_STAGE/2048plus/gamedata/assets/music"
    mkdir -p "$ZIP_STAGE/2048plus/licenses"

    if [ -f "$PM_SOURCE_DIR/2048 Plus.sh" ]; then
        cp "$PM_SOURCE_DIR/2048 Plus.sh" "$ZIP_STAGE/"
    fi

    [ -f "$PM_SOURCE_DIR/README.md" ] && cp "$PM_SOURCE_DIR/README.md" "$ZIP_STAGE/2048plus/2048plus.md"
    [ -f "$PM_SOURCE_DIR/gameinfo.xml" ] && cp "$PM_SOURCE_DIR/gameinfo.xml" "$ZIP_STAGE/2048plus/"
    [ -f "$PM_SOURCE_DIR/port.json" ] && cp "$PM_SOURCE_DIR/port.json" "$ZIP_STAGE/2048plus/"
    [ -f "$PM_SOURCE_DIR/screenshot.png" ] && cp "$PM_SOURCE_DIR/screenshot.png" "$ZIP_STAGE/2048plus/"

    cp "$TMP_STAGE/gamedata.tar.gz" "$ZIP_STAGE/2048plus/"
    cp "$PROJECT_ROOT/assets/music/"*.mp3 "$ZIP_STAGE/2048plus/gamedata/assets/music/"
    cp -r "$PROJECT_ROOT/licenses/"* "$ZIP_STAGE/2048plus/licenses/"

    RELEASE_ZIP="$BUILD_DIR/2048plus.zip"
    rm -f "$RELEASE_ZIP" "$BUILD_DIR/gamedata.tar.gz"
    (cd "$ZIP_STAGE" && zip -r -q "2048plus.zip" "2048 Plus.sh" "2048plus" && mv "2048plus.zip" "$RELEASE_ZIP")
    rm -rf "$ZIP_STAGE" "$TMP_STAGE"

    ZIP_SIZE=$(du -h "$RELEASE_ZIP" | cut -f1)
    echo "[OK] PortMaster package created: build/2048plus.zip ($ZIP_SIZE)"
}

# ------------------------------------------------------------------------------
# Interactive Menu / Argument Parsing
# ------------------------------------------------------------------------------
echo "2048 Plus $TAG"

TARGET="$1"

if [ -z "$TARGET" ]; then
    echo "Select build target:"
    echo "  1) muOS Package"
    echo "  2) PortMaster Package"
    echo "  3) Both"
    echo ""
    read -r -p "Enter choice [1/2/3] (Press Enter for Both): " CHOICE
    case "$CHOICE" in
        1|muos|MUOS)
            TARGET="muos"
            ;;
        2|portmaster|pm|PM|PortMaster)
            TARGET="portmaster"
            ;;
        3|both|all|ALL|BOTH|"")
            TARGET="both"
            ;;
        *)
            echo "Invalid choice '$CHOICE'. Defaulting to Both."
            TARGET="both"
            ;;
    esac
fi

case "$TARGET" in
    1|muos|MUOS)
        build_muos
        ;;
    2|portmaster|pm|PM|PortMaster)
        build_portmaster
        ;;
    3|both|all|ALL|BOTH)
        build_muos
        build_portmaster
        ;;
    *)
        echo "Unknown target '$TARGET'. Valid options: muos, portmaster, both"
        exit 1
        ;;
esac

echo ""
echo "Build Completed Successfully!"
ls -lh "$BUILD_DIR"
