#!/usr/bin/env bash
set -euo pipefail

# ==========================
# Config
# ==========================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="$(realpath "$SCRIPT_DIR/..")"
LIB_COMMON="$SCRIPT_DIR/lib/common.sh"

DIR_CONFIG="$WORKSPACE/config"
DIR_DRAW="$WORKSPACE/draw"
DRAW_CONFIG="$DIR_DRAW/config.yaml"
DRAW_INCLUDE_ROOTS=(
  "$WORKSPACE/local-build/workspace/modules/zmk/helpers/include"
)

source "$LIB_COMMON"

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
    $0 lapka
    $0 --list
    $0 --all

Exit codes:
    0 success
    1 runtime error
    2 invalid arguments
EOF
}

# ==========================
# Load keymaps
# ==========================
load_keymaps() {
  [[ -d "$DIR_CONFIG" ]] || die "Config dir not found: $DIR_CONFIG"

  KEYMAPS=()
  while IFS= read -r f; do
    KEYMAPS+=("$(basename "$f" .keymap)")
  done < <(find "$DIR_CONFIG" -maxdepth 1 -name "*.keymap" | sort)

  ((${#KEYMAPS[@]} > 0)) || die "No keymaps found in $DIR_CONFIG"
}

list_keymaps() {
  echo
  echo "=== Available keymaps ==="
  echo
  for ((i = 0; i < ${#KEYMAPS[@]}; i++)); do
    echo "$((i + 1)). ${KEYMAPS[$i]}"
  done
  echo
}

interactive_select() {
  list_keymaps
  local selected_index

  prompt_select_number "Select keymap (1-${#KEYMAPS[@]}) or q: " "${#KEYMAPS[@]}" selected_index
  SELECTED="${KEYMAPS[$selected_index]}"
}

# ==========================
# Keyboard-specific args
# ==========================
get_draw_args() {
  case "$1" in
  charybdis)
    echo "-d keyboards/boards/shields/charybdis/charybdis_layouts.dtsi"
    ;;
  lapka)
    echo "-d keyboards/boards/shields/lapka/lapka_layouts.dtsi"
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

  if [[ ! -f "$input" ]]; then
    echo "Error: keymap not found: $input" >&2
    echo "Hint: run '$0 --list' to view available keymaps." >&2
    exit 1
  fi

  echo
  echo "▶ Draw '$kb'"
  echo "  Input: $input"
  echo "  Args:  $args"

  mkdir -p "$DIR_DRAW"

  keymap -c "$DRAW_CONFIG" parse -z "$input" >"$yaml"
  keymap -c "$DRAW_CONFIG" draw $args "$yaml" >"$svg"

  inkscape --export-type=png \
    --export-background=white \
    --export-filename="$png" \
    "$svg"

  echo "  ✓ $png"
}

ensure_draw_deps() {
  need keymap
  need inkscape
  ensure_file "$DRAW_CONFIG"

  local include_root=""
  for include_root in "${DRAW_INCLUDE_ROOTS[@]}"; do
    [[ -d "$include_root" ]] && return 0
  done

  cat >&2 <<EOF
Error: draw prerequisites are missing.

Expected helper include root to exist:
  - ${DRAW_INCLUDE_ROOTS[0]}

This comes from draw/config.yaml. Fix it by either:
  - running a local build first (for example: just build), or
  - restoring the local west workspace expected by keymap-drawer.
EOF
  exit 1
}

# ==========================
# Args
# ==========================
LIST=false
ALL=false
KEYBOARD=""

while [[ $# -gt 0 ]]; do
  case "$1" in
  -l | --list)
    LIST=true
    shift
    ;;
  -a | --all)
    ALL=true
    shift
    ;;
  -h | --help)
    print_header
    print_help
    exit 0
    ;;
  *)
    if [[ -n "$KEYBOARD" ]]; then
      usage_error "Unexpected extra argument: $1. Use -h for help."
    fi
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

if $LIST; then
  list_keymaps
  exit 0
fi

if $ALL; then
  ensure_draw_deps
  for kb in "${KEYMAPS[@]}"; do
    draw_one "$kb"
  done
  exit 0
fi

if [[ -n "$KEYBOARD" ]]; then
  ensure_draw_deps
  draw_one "$KEYBOARD"
else
  interactive_select
  ensure_draw_deps
  draw_one "$SELECTED"
fi
