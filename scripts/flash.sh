#!/usr/bin/env bash
set -euo pipefail

# ==========================
# Config
# ==========================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="$(realpath "$SCRIPT_DIR/..")"

MOUNT_NICE="/Volumes/NICENANO"
MOUNT_XIAO="/Volumes/XIAO-SENSE"
BOARD_NICE="nice_nano"
BOARD_XIAO="xiao_ble"
FIRMWARE_DIR="$WORKSPACE/firmware"
BUILD_YAML="$WORKSPACE/build.yaml"

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
║   ZMK Firmware Flash Script                ║
╚════════════════════════════════════════════╝
EOF
}

print_help() {
cat <<EOF
Usage: $0 [OPTIONS]

Options:
    -n, --number N    Flash N-th build (1-based)
    -s, --shield S    Filter by shield name (substring)
    -b, --board B     Filter by board name (exact)
    -l, --list        List available firmwares
    -h, --help        Show this help

Examples:
    $0 -l                    # List
    $0 -n 1                  # Flash first
    $0 -s charybdis -b nice  # Flash charybdis nice_nano
EOF
}

list_builds() {
    echo
    echo "=== Available Firmware Files ==="
    echo
    for ((i=0;i<BUILD_COUNT;i++)); do
        n=$((i+1))
        artifact="${SHIELDS[$i]// /+}-${BOARDS[$i]}.uf2"
        file="$FIRMWARE_DIR/$artifact"
        status="❌ MISSING"
        [[ -f "$file" ]] && status="✅ READY"
        echo "$n. ${SHIELDS[$i]} (${BOARDS[$i]}) [$status]"
        echo
    done
}

interactive_select() {
    list_builds
    while true; do
        read -rp "Select firmware to flash (1-$BUILD_COUNT) or q: " ans
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
    echo "${shield// /+}-${board}.uf2"
}

# ==========================
# Flash
# ==========================
flash_one() {
    local idx="$1"

    local board="${BOARDS[$idx]}"
    local shield="${SHIELDS[$idx]}"
    local artifact=$(get_artifact_name "$shield" "$board")
    local uf2="$FIRMWARE_DIR/$artifact"

    [[ -f "$uf2" ]] || die "Firmware not found: $uf2"

    echo "Flash firmware for '$board' '$shield'"

    local mount=""
    case "$board" in
        "$BOARD_NICE")
            mount="$MOUNT_NICE"
        ;;
        "$BOARD_XIAO")
            mount="$MOUNT_XIAO"
        ;;
        *)
            die "Unknown board ${board}"
        ;;
    esac

    printf "Waiting for %s bootloader to appear at %s..." "$board" "$mount"
    while [ ! -d "$mount" ]; do
        sleep 1
        printf "."
    done
    printf "\n"

    echo "Copy $artifact to ${mount}"
    retry_cp "$uf2" "$mount" || die "Failed to copy firmware after retries"
    echo "✓ Done!"
}

retry_cp() {
    local src="$1"
    local dst="$2"
    local max_retries=5
    local attempt=1

    while [ $attempt -le $max_retries ]; do
        if cp -X "$src" "$dst/"; then
            if [ -f "$dst/$(basename "$src")" ] 2>/dev/null; then
                echo "✓ Copy successful on attempt $attempt"
                return 0
            fi
        fi

        echo "Attempt $attempt/$max_retries failed (permission denied?), retrying in 2s..." >&2
        sleep 2
        ((attempt++))
    done

    return 1
}

# ==========================
# Args
# ==========================
NUMBER=""
SHIELD=""
BOARD=""
LIST=false
HELP=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--number) NUMBER="$2"; shift 2 ;;
        -s|--shield) SHIELD="$2"; shift 2 ;;
        -b|--board)  BOARD="$2"; shift 2 ;;
        -l|--list)   LIST=true; shift ;;
        -h|--help)   HELP=true; shift ;;
        *) die "Unknown argument: $1. Use -h for help." ;;
    esac
done

# ==========================
# Main
# ==========================
print_header
load_builds

$HELP && { print_help; exit 0; }

$LIST && { list_builds; exit 0; }

if [[ -n "$NUMBER" ]]; then
    (( NUMBER>=1 && NUMBER<=BUILD_COUNT )) || die "Invalid build number: $NUMBER"
    SELECTED=$((NUMBER-1))
    flash_one "$SELECTED"
elif [[ -n "$SHIELD" || -n "$BOARD" ]]; then
    find_by_criteria "$SHIELD" "$BOARD"

    if (( ${#MATCHES[@]} == 0 )); then
        echo "No matches for shield=\"$SHIELD\" board=\"$BOARD\""
        list_builds
        exit 1
    fi

    if (( ${#MATCHES[@]} > 1 )); then
        echo "Multiple matches (${#MATCHES[@]}), please narrow search or use -n:"
        for i in "${MATCHES[@]}"; do
            echo "  $((i+1)). ${SHIELDS[$i]} (${BOARDS[$i]})"
        done
        exit 1
    fi

    SELECTED="${MATCHES[0]}"
    echo "Selected: $((SELECTED+1)). ${SHIELDS[$SELECTED]} (${BOARDS[$SELECTED]})"
    echo
    flash_one "$SELECTED"
else
    interactive_select
    flash_one "$SELECTED"
fi
