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
BUILD_YAML="$WORKSPACE/build.yaml"

WEST_WS="$WORKSPACE/local-build/workspace"
ARTIFACTS="$WORKSPACE/local-build/artifact"
OUTPUT_DIR="$WORKSPACE/firmware"

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
need docker
need yq

# ==========================
# Load builds
# ==========================
load_builds() {
    [[ -f "$BUILD_YAML" ]] || die "build.yaml not found"

    BOARDS=()
    SHIELDS=()
    SNIPPETS=()
    CMAKE_ARGS=()

    while IFS= read -r line; do BOARDS+=("$line"); done \
        < <(yq '.include[].board' "$BUILD_YAML")

    while IFS= read -r line; do SHIELDS+=("$line"); done \
        < <(yq '.include[].shield' "$BUILD_YAML")

    while IFS= read -r line; do SNIPPETS+=("$line"); done \
        < <(yq '.include[].snippet // ""' "$BUILD_YAML")

    while IFS= read -r line; do CMAKE_ARGS+=("$line"); done \
        < <(yq '.include[]."cmake-args" // ""' "$BUILD_YAML")

    BUILD_COUNT="${#BOARDS[@]}"
    (( BUILD_COUNT > 0 )) || die "No builds found in build.yaml"
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
    -n, --number N          Flash N-th build (1-based)
    -s, --shield S          Filter by shield name (substring)
    -b, --board B           Filter by board name (exact)
    -l, --list              List available firmwares
    -a, --all               Build all firmwares
    --clean|--clean-deps    Clean workspace and dependencies
    --update                Force west update
    -h, --help              Show this help
EOF
}

list_builds() {
    echo
    echo "=== Available Build Configurations ==="
    echo
    for ((i=0;i<BUILD_COUNT;i++)); do
        n=$((i+1))
        echo "$n. ${SHIELDS[$i]} (${BOARDS[$i]})"
        [[ -n "${SNIPPETS[$i]}" ]] && echo "   └─ Snippet: ${SNIPPETS[$i]}"
        [[ -n "${CMAKE_ARGS[$i]}" ]] && echo "   └─ CMake args: ${CMAKE_ARGS[$i]}"
        echo
    done
}

interactive_select() {
    list_builds
    while true; do
        read -rp "Select build (1-$BUILD_COUNT) or q: " ans
        [[ "$ans" == "q" ]] && exit 0
        [[ "$ans" =~ ^[0-9]+$ ]] || continue
        (( ans>=1 && ans<=BUILD_COUNT )) && {
            SELECTED=$((ans-1))
            return
        }
    done
}

# ==========================
# Build selection
# ==========================
find_by_criteria() {
    local shield="$1"
    local board="$2"

    local shield_lc=$(printf '%s' "$shield" | tr 'A-Z' 'a-z')
    local board_lc=$(printf '%s' "$board" | tr 'A-Z' 'a-z')

    MATCHES=()
    for ((i=0;i<BUILD_COUNT;i++)); do
        s=$(printf '%s' "${SHIELDS[$i]}" | tr 'A-Z' 'a-z')
        b=$(printf '%s' "${BOARDS[$i]}" | tr 'A-Z' 'a-z')

        [[ -n "$shield_lc" && "$s" != *"$shield_lc"* ]] && continue
        [[ -n "$board_lc" && "$b" != "$board_lc" ]] && continue

        MATCHES+=("$i")
    done
}

get_artifact_name() {
    local shield="$1"
    local board="$2"
    echo "${shield// /+}-${board}"
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

    mkdir -p "$WEST_WS" "$ARTIFACTS" "$OUTPUT_DIR"

    echo
    echo "============================================================"
    echo "Building: $shield ($board)"
    echo "============================================================"
    echo

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

      if [ -d /repo/modules ]; then
        cp -aR /repo/modules/. modules/local
        for mod_path in modules/local/*/ ; do
          if [ -d \"\$mod_path\" ]; then
            mod_name=\$(basename \"\$mod_path\")
            if [ ! -d \"\$mod_path.git\" ]; then
              echo \"Initializing git for \$mod_name...\"
              cd \"\$mod_path\" && git init && cd -
            fi
          fi
        done
      fi

      mkdir zmk-config/boards/shields/charybdis/includes
      cp /repo/config/includes/layers.h zmk-config/boards/shields/charybdis/includes/
      cp /repo/config/charybdis_pointer.dtsi zmk-config/boards/shields/charybdis/

      [ -d .west ] || west init -l config
      [ \"$force_update\" != \"true\" -a -d zmk ] || west update 2>/dev/null || true
      west zephyr-export

      west build -s zmk/app -d \"$build_dir\" -b \"$board\" ${snippet:+-S \"$snippet\"} --pristine \
        -- \
        -DZMK_CONFIG=/workspace/config \
        -DZMK_EXTRA_MODULES=/workspace/zmk-config \
        -DSHIELD=\"$shield\" \
        -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
        $cmake_args
    "

    local uf2="$ARTIFACTS/$shield_dir/zephyr/zmk.uf2"
    if [[ -f "$uf2" ]]; then
        local out_name="$(get_artifact_name "$shield" "$board")".uf2
        cp "$uf2" "$OUTPUT_DIR/$out_name"
        chmod go+wrx "$OUTPUT_DIR/$out_name"
        echo
        echo "✓ Firmware: $OUTPUT_DIR/$out_name"
    else
        echo "⚠️  UF2 not found"
    fi
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
        -n|--number) NUMBER="$2"; shift 2 ;;
        -s|--shield) SHIELD="$2"; shift 2 ;;
        -b|--board)  BOARD="$2"; shift 2 ;;
        -l|--list)   LIST=true; shift ;;
        -a|--all)    ALL=true; shift;;
        -h|--help)   HELP=true; shift ;;
        --clean|--clean-deps) CLEAN=true; shift ;;
        --update)    UPDATE=true; shift ;;
        *) die "Unknown argument: $1" ;;
    esac
done

# ==========================
# Main
# ==========================
print_header
load_builds

if $HELP; then
    print_help
    exit 0
fi

if $LIST; then
    list_builds
    exit 0
fi

if $ALL; then
    echo "Will build the following configurations:"
    for ((i=0;i<BUILD_COUNT;i++)); do
        echo "  $((i+1)). ${SHIELDS[$i]} (${BOARDS[$i]})"
    done
    echo

    for ((i=0;i<BUILD_COUNT;i++)); do
        run_build "$i" "$UPDATE"
        if $UPDATE; then
          UPDATE=false
        fi
    done
    exit 0
fi

if $CLEAN; then
    clean_deps
fi

if [[ -n "$NUMBER" ]]; then
    (( NUMBER>=1 && NUMBER<=BUILD_COUNT )) || die "Invalid build number"
    SELECTED=$((NUMBER-1))
    run_build "$SELECTED" "$UPDATE"
elif [[ -n "$SHIELD" || -n "$BOARD" ]]; then
    find_by_criteria "$SHIELD" "$BOARD"

    if (( ${#MATCHES[@]} == 0 )); then
        echo "No matches for shield=\"$SHIELD\" board=\"$BOARD\""
        exit 1
    fi

    echo "Will build the following configurations:"
    for i in "${MATCHES[@]}"; do
        echo "  $((i+1)). ${SHIELDS[$i]} (${BOARDS[$i]})"
    done
    echo

    for i in "${MATCHES[@]}"; do
        run_build "$i" "$UPDATE"
        if $UPDATE; then
          UPDATE=false
        fi
    done

    exit 0
else
    interactive_select
    run_build "$SELECTED" "$UPDATE"
fi
