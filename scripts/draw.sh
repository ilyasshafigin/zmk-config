#!/usr/bin/env bash
set -euo pipefail

# ==========================
# Config
# ==========================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="$(realpath "$SCRIPT_DIR/..")"

DIR_CONFIG="$WORKSPACE/config"
DIR_KEYMAP_DRAWER="$WORKSPACE/draw"
DRAW_CONFIG="$DIR_CONFIG/keymap-drawer.yaml"

# ==========================
# Helpers
# ==========================
die() {
    echo "Error: $*" >&2
    exit 1
}

need() {
    command -v "$1" >/dev/null || die "Missing dependency: $1"
}

# ==========================
# Dependencies check
# ==========================
need keymap
need inkscape

# ==========================
# UI
# ==========================
print_header() {
cat <<EOF
╔════════════════════════════════════════════╗
║   ZMK Keymap Drawer Script                 ║
╚════════════════════════════════════════════╝
EOF
}

print_help() {
cat <<EOF

Usage: $0 <keyboard>

Arguments:
    <keyboard>     Name of keyboard (e.g. 'corne', 'charybdis')

Examples:
    $0 corne

Outputs:
    draw/<keyboard>.svg
    draw/<keyboard>.png
    draw/<keyboard>.yaml

EOF
}

# ==========================
# Args
# ==========================
case "${1:-}" in
    -h|--help)
        print_header
        print_help
        exit 0
        ;;
    "")
        die "Keyboard name required. Use -h for help."
        ;;
esac

KEYBOARD="$1"
[[ $# -eq 1 ]] || die "Only one keyboard allowed. Use -h for help."

DRAW_ARGS=""
case "$KEYBOARD" in
    charybdis)
        DRAW_ARGS="-d boards/shields/charybdis/charybdis_layout.dtsi"
        ;;
    corne|totem)
        DRAW_ARGS=""
        ;;
    *)
        echo "Warning: Unknown keyboard '$KEYBOARD', using default args"
        ;;
esac

# ==========================
# Main
# ==========================
print_header

[[ -f "$DRAW_CONFIG" ]] || die "keymap-drawer.yaml not found: $DRAW_CONFIG"

KEYMAP_INPUT_FILE="$DIR_CONFIG/$KEYBOARD.keymap"
KEYMAP_YAML="$DIR_KEYMAP_DRAWER/$KEYBOARD.yaml"
KEYMAP_SVG="$DIR_KEYMAP_DRAWER/$KEYBOARD.svg"
KEYMAP_PNG="$DIR_KEYMAP_DRAWER/$KEYBOARD.png"

[[ -f "$KEYMAP_INPUT_FILE" ]] || die "Keymap not found: $KEYMAP_INPUT_FILE"

echo "Draw '$KEYBOARD'"
echo "Input:  $KEYMAP_INPUT_FILE"
echo "Config: $DRAW_CONFIG"
echo "Draw args: $DRAW_ARGS"

mkdir -p "$DIR_KEYMAP_DRAWER"

echo "Parse keymap -> $KEYMAP_YAML"
keymap -c "$DRAW_CONFIG" parse -z "$KEYMAP_INPUT_FILE" > "$KEYMAP_YAML"

echo "Draw SVG -> $KEYMAP_SVG"
keymap -c "$DRAW_CONFIG" draw $DRAW_ARGS "$KEYMAP_YAML" > "$KEYMAP_SVG"

echo "Export PNG -> $KEYMAP_PNG"
inkscape --export-type=png \
         --export-background=white \
         --export-filename="$KEYMAP_PNG" \
         "$KEYMAP_SVG"

echo
echo "✓ Generated:"
echo "  $KEYMAP_YAML"
echo "  $KEYMAP_SVG"
echo "  $KEYMAP_PNG"
