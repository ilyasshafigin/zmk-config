#!/usr/bin/env bash
set -euo pipefail

# ==========================
# Config
# ==========================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="$(realpath "$SCRIPT_DIR/..")"

DIR_CONFIG="$WORKSPACE/config"
DIR_DRAW="$WORKSPACE/draw"
DRAW_CONFIG="$DIR_DRAW/config.yaml"

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
Usage: $0 [OPTIONS] [KEYMAP]

Options:
    -l, --list        List available keymaps
    -a, --all         Draw all keymaps
    -h, --help        Show this help

Without arguments:
    Interactive keymap selection

Examples:
    $0 totem
    $0 --list
    $0 --all
EOF
}

# ==========================
# Load keymaps
# ==========================
load_keymaps() {
    [[ -d "$DIR_CONFIG" ]] || die "Config dir not found: $DIR_CONFIG"

    KEYMAPS=()
    while IFS= read -r f; do
        KEYMAPS+=( "$(basename "$f" .keymap)" )
    done < <(find "$DIR_CONFIG" -maxdepth 1 -name "*.keymap" | sort)

    (( ${#KEYMAPS[@]} > 0 )) || die "No keymaps found in $DIR_CONFIG"
}

list_keymaps() {
    echo
    echo "=== Available keymaps ==="
    echo
    for ((i=0;i<${#KEYMAPS[@]};i++)); do
        echo "$((i+1)). ${KEYMAPS[$i]}"
    done
    echo
}

interactive_select() {
    list_keymaps
    while true; do
        read -rp "Select keymap (1-${#KEYMAPS[@]}) or q: " ans
        [[ "$ans" == "q" ]] && exit 0
        [[ "$ans" =~ ^[0-9]+$ ]] || continue
        (( ans>=1 && ans<=${#KEYMAPS[@]} )) && {
            SELECTED="${KEYMAPS[$((ans-1))]}"
            return
        }
    done
}

# ==========================
# Keyboard-specific args
# ==========================
get_draw_args() {
    case "$1" in
        charybdis)
            echo "-d boards/shields/charybdis/charybdis_layout.dtsi"
            ;;
        *)
            echo ""
            ;;
    esac
}

# ==========================
# Draw one keymap
# ==========================
draw_one() {
    local kb="$1"

    local input="$DIR_CONFIG/$kb.keymap"
    local yaml="$DIR_DRAW/$kb.yaml"
    local svg="$DIR_DRAW/$kb.svg"
    local png="$DIR_DRAW/$kb.png"
    local args="$(get_draw_args "$kb")"

    [[ -f "$input" ]] || die "Keymap not found: $input"

    echo
    echo "▶ Draw '$kb'"
    echo "  Input: $input"
    echo "  Args:  $args"

    mkdir -p "$DIR_DRAW"

    keymap -c "$DRAW_CONFIG" parse -z "$input" > "$yaml"
    keymap -c "$DRAW_CONFIG" draw $args "$yaml" > "$svg"

    inkscape --export-type=png \
             --export-background=white \
             --export-filename="$png" \
             "$svg"

    echo "  ✓ $png"
}

# ==========================
# Args
# ==========================
LIST=false
ALL=false
KEYBOARD=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -l|--list) LIST=true; shift ;;
        -a|--all)  ALL=true; shift ;;
        -h|--help)
            print_header
            print_help
            exit 0
            ;;
        *)
            KEYBOARD="$1"
            shift
            ;;
    esac
done

# ==========================
# Main
# ==========================
print_header
load_keymaps

$LIST && { list_keymaps; exit 0; }

if $ALL; then
    for kb in "${KEYMAPS[@]}"; do
        draw_one "$kb"
    done
    exit 0
fi

if [[ -n "$KEYBOARD" ]]; then
    draw_one "$KEYBOARD"
else
    interactive_select
    draw_one "$SELECTED"
fi
