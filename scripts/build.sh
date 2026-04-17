#!/usr/bin/env bash

# ZMK Local Build Script using Docker
#
# Original script https://github.com/choovick/zmk-config-charybdis/blob/main/local-build/build.py commit 2d27ec9

set -euo pipefail

# ==========================
# Config
# ==========================
IMAGE="zmkfirmware/zmk-build-arm:stable"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="$(realpath "$SCRIPT_DIR/..")"
LIB_COMMON="$SCRIPT_DIR/lib/common.sh"
BUILD_YAML="$WORKSPACE/build.yaml"

WEST_WS="$WORKSPACE/local-build/workspace"
ARTIFACTS="$WORKSPACE/local-build/artifact"
OUTPUT_DIR="$WORKSPACE/firmware"

source "$LIB_COMMON"

# ==========================
# Progress UI
# ==========================

CURRENT_BUILD=0
TOTAL_BUILDS=0
NINJA_CURRENT=0
NINJA_TOTAL=0
NINJA_PERCENT=0

setup_progress() {
  TOTAL_BUILDS="$FIRMWARE_COUNT"
  CURRENT_BUILD=0
}

parse_ninja_progress() {
  local line="$1"

  if [[ "$line" =~ ^\[([0-9]+)/([0-9]+)\] ]]; then
    NINJA_CURRENT="${BASH_REMATCH[1]}"
    NINJA_TOTAL="${BASH_REMATCH[2]}"

    if ((NINJA_TOTAL > 0)); then
      NINJA_PERCENT=$((NINJA_CURRENT * 100 / NINJA_TOTAL))
    fi

    return 0
  fi

  return 1
}

draw_progress() {
  local shield="$1"
  local board="$2"

  local percent="$NINJA_PERCENT"

  local width=30
  local filled=$((percent * width / 100))

  local bar=""

  for ((i = 0; i < filled; i++)); do bar+="█"; done
  for ((i = filled; i < width; i++)); do bar+="░"; done

  printf "\r\033[K"
  printf "\r[%d/%d] %s (%s)  %s %3d%% (%d/%d)" \
    "$CURRENT_BUILD" \
    "$TOTAL_BUILDS" \
    "$shield" \
    "$board" \
    "$bar" \
    "$percent" \
    "$NINJA_CURRENT" \
    "$NINJA_TOTAL"
}

start_progress() {
  CURRENT_BUILD=$((CURRENT_BUILD + 1))
}

# ==========================
# Load builds
# ==========================
BUILD_COUNT=0
FIRMWARE_COUNT=0
BOARDS=()
SHIELDS=()
SNIPPETS=()
CMAKE_ARGS=()

load_builds() {
  load_build_manifest "$BUILD_YAML" BOARDS SHIELDS SNIPPETS CMAKE_ARGS

  BUILD_COUNT="${#BOARDS[@]}"
  ((BUILD_COUNT > 0)) || die "No builds found in build.yaml"
  ((${#SHIELDS[@]} == BUILD_COUNT)) || die "Malformed build.yaml: boards/shields count mismatch"
  ((${#SNIPPETS[@]} == BUILD_COUNT)) || die "Malformed build.yaml: boards/snippets count mismatch"
  ((${#CMAKE_ARGS[@]} == BUILD_COUNT)) || die "Malformed build.yaml: boards/cmake-args count mismatch"
}

# ==========================
# UI
# ==========================
print_header() {
  cat <<EOF
╔════════════════════════════════════════════╗
║   ZMK Local Build Script (Docker)          ║
╚════════════════════════════════════════════╝
EOF
}

print_help() {
  cat <<EOF
Usage: $0 [OPTIONS]

Options:
    -n, --number N          Build N-th target (1-based)
    -s, --shield S          Filter by shield name (substring)
    -b, --board B           Filter by board name (exact)
    -l, --list              List available build targets
    -a, --all               Build all targets
    --clean|--clean-deps    Clean workspace and dependencies
    --update                Force west update
    -h, --help              Show this help

Without arguments:
    Interactive build selection

Examples:
    $0 -l                    # List
    $0 -n 1                  # Build first
    $0 -s "lapka_dongle" -b "xiao_ble//zmk"
    $0 --all --update        # Update west and build all firmwares

Exit codes:
    0 success
    1 runtime error
    2 invalid arguments
EOF
}

list_builds() {
  echo
  echo "=== Available Build Configurations ==="
  echo
  for ((i = 0; i < BUILD_COUNT; i++)); do
    n=$((i + 1))
    echo "$n. ${SHIELDS[$i]} (${BOARDS[$i]})"
    [[ -n "${SNIPPETS[$i]}" ]] && echo "   └─ Snippet: ${SNIPPETS[$i]}"
    [[ -n "${CMAKE_ARGS[$i]}" ]] && echo "   └─ CMake args: ${CMAKE_ARGS[$i]}"
  done
  echo
}

interactive_select() {
  list_builds
  prompt_select_number "Select build (1-$BUILD_COUNT) or q: " "$BUILD_COUNT" SELECTED
  FIRMWARE_COUNT=1
}

# ==========================
# Cleanup
# ==========================
clean_deps() {
  echo "Cleaning west workspace..."
  rm -rf "$WEST_WS"
  mkdir -p "$WEST_WS"

  echo "Cleaning artifacts..."
  rm -rf "$ARTIFACTS"
  mkdir -p "$ARTIFACTS"
}

# ==========================
# Docker build
# ==========================
run_build() {
  local idx="$1"
  local force_update="$2"

  local board="${BOARDS[$idx]}"
  local shield="${SHIELDS[$idx]}"
  local snippet="${SNIPPETS[$idx]}"
  local cmake_args="${CMAKE_ARGS[$idx]}"

  local shield_dir="$(echo "$shield" | tr ' _' '--')"
  local build_dir="/out/$shield_dir"

  NINJA_CURRENT=0
  NINJA_TOTAL=0
  NINJA_PERCENT=0

  start_progress
  draw_progress "$shield" "$board"

  mkdir -p "$WEST_WS" "$ARTIFACTS" "$OUTPUT_DIR"

  docker run --rm \
    -v "$WORKSPACE:/repo" \
    -v "$WEST_WS:/workspace" \
    -v "$ARTIFACTS:/out" \
    -w /workspace \
    "$IMAGE" \
    sh -c "
      set -e

      mkdir -p /workspace /out
      cd /workspace

      rm -rf config
      cp -R /repo/config ./config

      rm -rf zmk-config
      mkdir -p zmk-config/zephyr
      [ -d /repo/boards ] && cp -R /repo/boards zmk-config/
      [ -d /repo/dts ] && cp -R /repo/dts zmk-config/
      [ -d /repo/app ] && cp -R /repo/app zmk-config/
      [ -f /repo/zephyr/module.yml ] && cp /repo/zephyr/module.yml zmk-config/zephyr/module.yml

      mkdir zmk-config/boards/shields/charybdis/includes
      cp /repo/config/includes/layers.h zmk-config/boards/shields/charybdis/includes/
      cp /repo/config/charybdis_pointer.dtsi zmk-config/boards/shields/charybdis/

      [ -d .west ] || west init -l config
      if [ \"$force_update\" = \"true\" ] || [ ! -d zmk ]; then
        west update
      fi
      west zephyr-export

      west build -s zmk/app -d \"$build_dir\" -b \"$board\" ${snippet:+-S \"$snippet\"} --pristine \
        -- \
        -DZMK_CONFIG=/workspace/config \
        -DZMK_EXTRA_MODULES=/workspace/zmk-config \
        -DSHIELD=\"$shield\" \
        -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
        $cmake_args
    " 2>&1 | while IFS= read -r line; do
    if parse_ninja_progress "$line"; then
      draw_progress "$shield" "$board"
    else
      printf "\r\033[K%s\n" "$line"
      draw_progress "$shield" "$board"
    fi
  done

  local uf2="$ARTIFACTS/$shield_dir/zephyr/zmk.uf2"
  if [[ -f "$uf2" ]]; then
    local out_name="$(get_artifact_name "$shield" "$board")".uf2
    cp "$uf2" "$OUTPUT_DIR/$out_name"
    chmod go+wrx "$OUTPUT_DIR/$out_name"
    printf "\r\033[K"
    printf "\r\033[K%s\n" "✓ Firmware: $OUTPUT_DIR/$out_name"
  else
    printf "\r\033[K%s\n" "⚠️  UF2 not found"
  fi

  printf "\r\033[K"
}

build_all() {
  FIRMWARE_COUNT="$BUILD_COUNT"
  MATCHES=()

  echo "Will build the following configurations:"
  for ((i = 0; i < BUILD_COUNT; i++)); do
    echo "  $((i + 1)). ${SHIELDS[$i]} (${BOARDS[$i]})"
    MATCHES+=("$i")
  done
  echo

  setup_progress
  for i in "${MATCHES[@]}"; do
    run_build "$i" "$UPDATE"
    if $UPDATE; then UPDATE=false; fi
  done
}

build_by_number() {
  local number="$1"
  ((number >= 1 && number <= BUILD_COUNT)) || die "Invalid build number"
  SELECTED=$((number - 1))
  FIRMWARE_COUNT=1
  setup_progress
  run_build "$SELECTED" "$UPDATE"
}

build_by_criteria() {
  local shield="$1"
  local board="$2"
  local first

  find_by_criteria "$shield" "$board" "$BUILD_COUNT" SHIELDS BOARDS MATCHES

  if ((${#MATCHES[@]} == 0)); then
    echo "No build targets for shield=\"$shield\" board=\"$board\"." >&2
    echo "Hint: run '$0 -l' to inspect available targets." >&2
    exit 1
  fi

  echo "Will build the following configurations:"
  print_matches MATCHES SHIELDS BOARDS
  echo

  FIRMWARE_COUNT="${#MATCHES[@]}"
  setup_progress
  for i in "${MATCHES[@]}"; do
    run_build "$i" "$UPDATE"
    if $UPDATE; then UPDATE=false; fi
  done
}

build_by_select() {
  interactive_select
  setup_progress
  run_build "$SELECTED" "$UPDATE"
}

# ==========================
# Args
# ==========================
NUMBER=""
SHIELD=""
BOARD=""
LIST=false
ALL=false
CLEAN=false
UPDATE=false
HELP=false

while [[ $# -gt 0 ]]; do
  case "$1" in
  -n | --number)
    [[ $# -ge 2 ]] || usage_error "Option '$1' requires a value."
    validate_number_arg "$2" "$1"
    NUMBER="$2"
    shift 2
    ;;
  -s | --shield)
    [[ $# -ge 2 ]] || usage_error "Option '$1' requires a value."
    SHIELD="$2"
    shift 2
    ;;
  -b | --board)
    [[ $# -ge 2 ]] || usage_error "Option '$1' requires a value."
    BOARD="$2"
    shift 2
    ;;
  -l | --list)
    LIST=true
    shift
    ;;
  -a | --all)
    ALL=true
    shift
    ;;
  -h | --help)
    HELP=true
    shift
    ;;
  --clean | --clean-deps)
    CLEAN=true
    shift
    ;;
  --update)
    UPDATE=true
    shift
    ;;
  *) usage_error "Unknown argument: $1. Use -h for help." ;;
  esac
done

# ==========================
# Main
# ==========================

if $HELP; then
  print_header
  print_help
  exit 0
fi

print_header

if $CLEAN; then
  clean_deps
  if ! $ALL && [[ -z "$NUMBER" && -z "$SHIELD" && -z "$BOARD" ]]; then
    exit 0
  fi
fi

if $LIST; then
  need yq
  load_builds
  list_builds
  exit 0
fi

if $ALL; then
  need docker
  need yq
  load_builds
  build_all
  exit 0
fi

if [[ -n "$NUMBER" && (-n "$SHIELD" || -n "$BOARD") ]]; then
  usage_error "Use either -n or (-s/-b), not both."
fi

if [[ -n "$NUMBER" ]]; then
  validate_number_arg "$NUMBER" "--number"
  need docker
  need yq
  load_builds
  build_by_number "$NUMBER"
elif [[ -n "$SHIELD" || -n "$BOARD" ]]; then
  need docker
  need yq
  load_builds
  build_by_criteria "$SHIELD" "$BOARD"
else
  need docker
  need yq
  load_builds
  build_by_select
fi
