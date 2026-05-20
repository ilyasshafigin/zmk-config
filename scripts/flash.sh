#!/usr/bin/env bash
set -euo pipefail

# ==========================
# Config
# ==========================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="$(realpath "$SCRIPT_DIR/..")"
LIB_COMMON="$SCRIPT_DIR/lib/common.sh"

BOARD_MOUNT_MAP=(
  "nice_nano//zmk|/Volumes/NICENANO"
  "xiao_ble//zmk|/Volumes/XIAO-SENSE"
)
FIRMWARE_DIR="$WORKSPACE/firmware"
BUILD_YAML="$WORKSPACE/build.yaml"
BOOT_WAIT_SEC="${BOOT_WAIT_SEC:-120}"

source "$LIB_COMMON"

# ==========================
# Load builds
# ==========================
load_builds() {
  load_build_manifest "$BUILD_YAML" BOARDS SHIELDS

  FIRMWARE_COUNT="${#BOARDS[@]}"
  ((FIRMWARE_COUNT > 0)) || die "No builds found in build.yaml"
  ((${#SHIELDS[@]} == FIRMWARE_COUNT)) || die "Malformed build.yaml: boards/shields count mismatch"
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

Without arguments:
    Interactive firmware selection

Examples:
    $0 -l                    # List
    $0 -n 1                  # Flash first
    $0 -s "lapka_dongle" -b "xiao_ble//zmk"

Exit codes:
    0 success
    1 runtime error
    2 invalid arguments
EOF
}

list_builds() {
  echo
  echo "=== Available Firmware Files ==="
  echo
  for ((i = 0; i < FIRMWARE_COUNT; i++)); do
    n=$((i + 1))
    artifact="$(get_artifact_name "${SHIELDS[$i]}" "${BOARDS[$i]}").uf2"
    file="$FIRMWARE_DIR/$artifact"
    status="❌ MISSING"
    [[ -f "$file" ]] && status="✅ READY"
    echo "$n. ${SHIELDS[$i]} (${BOARDS[$i]}) [$status]"
  done
  echo
}

interactive_select() {
  list_builds
  prompt_select_number "Select firmware to flash (1-$FIRMWARE_COUNT) or q: " "$FIRMWARE_COUNT" SELECTED
}

resolve_mount_for_board() {
  local board="$1"
  local entry map_board map_mount

  for entry in "${BOARD_MOUNT_MAP[@]}"; do
    IFS='|' read -r map_board map_mount <<<"$entry"
    if [[ "$map_board" == "$board" ]]; then
      echo "$map_mount"
      return 0
    fi
  done

  return 1
}

check_for_mismatched_bootloader() {
  local expected_board="$1"
  local expected_mount="$2"
  local entry map_board map_mount

  for entry in "${BOARD_MOUNT_MAP[@]}"; do
    IFS='|' read -r map_board map_mount <<<"$entry"
    [[ "$map_mount" == "$expected_mount" ]] && continue

    if [[ -d "$map_mount" ]]; then
      echo
      die "Detected bootloader for '$map_board' at '$map_mount', but selected firmware is for '$expected_board'. Choose matching firmware/controller and retry."
    fi
  done
}

# ==========================
# Flash
# ==========================
flash_one() {
  local idx="$1"

  local board="${BOARDS[$idx]}"
  local shield="${SHIELDS[$idx]}"
  local artifact="$(get_artifact_name "$shield" "$board").uf2"
  local uf2="$FIRMWARE_DIR/$artifact"

  [[ -d "$FIRMWARE_DIR" ]] || die "Firmware dir not found: $FIRMWARE_DIR"
  [[ -f "$uf2" ]] || die "Firmware not found: $uf2"

  echo "Flash firmware for '$board' '$shield'"

  local mount=""
  mount="$(resolve_mount_for_board "$board")" || {
    die "Unknown board '$board'. Add board/mount mapping in BOARD_MOUNT_MAP."
  }

  local waited=0
  printf "Waiting for %s bootloader to appear at %s..." "$board" "$mount"

  if [[ ! -d "$mount" ]]; then
    check_for_mismatched_bootloader "$board" "$mount"
  fi

  while [ ! -d "$mount" ]; do
    check_for_mismatched_bootloader "$board" "$mount"

    sleep 1
    waited=$((waited + 1))
    if ((waited >= BOOT_WAIT_SEC)); then
      echo
      die "Timed out waiting for bootloader at $mount. Replug device in bootloader mode and retry."
    fi
    printf "."
  done
  printf "\n"

  echo "Copy $artifact to ${mount}"
  retry_cp "$uf2" "$mount" || die "Failed to copy firmware after retries"
  echo "✓ Done!"
}

retry_cp() {
  local src="$1"
  local dst_dir="$2"
  local max_retries=5
  local attempt=1

  while [ $attempt -le $max_retries ]; do
    if [ ! -d "$dst_dir" ]; then
      echo "✓ Volume $dst_dir auto-unmounted (flash success!)"
      return 0
    fi

    echo "Attempt $attempt/$max_retries: Copy $(basename "$src") → $dst_dir"

    if cp -nX "$src" "$dst_dir/" 2>/dev/null; then
      echo "✓ Copy successful"
      return 0
    fi

    echo "Attempt $attempt failed, retrying in 1s..." >&2
    sleep 1
    ((attempt++))
  done

  if [ ! -d "$dst_dir" ]; then
    echo "✓ Volume unmounted after retries (flash success!)"
    return 0
  fi

  echo "✗ Failed after $max_retries attempts" >&2
  return 1
}

flash_by_number() {
  local number="$1"

  ((number >= 1 && number <= FIRMWARE_COUNT)) || die "Invalid build number: $number"
  SELECTED=$((number - 1))
  flash_one "$SELECTED"
}

flash_by_criteria() {
  local shield="$1"
  local board="$2"
  local first

  find_by_criteria "$shield" "$board" "$FIRMWARE_COUNT" SHIELDS BOARDS MATCHES

  if ((${#MATCHES[@]} == 0)); then
    echo "No matches for shield=\"$shield\" board=\"$board\"." >&2
    echo "Hint: run '$0 -l' to inspect targets." >&2
    list_builds
    exit 1
  fi

  if ((${#MATCHES[@]} > 1)); then
    echo "Multiple matches (${#MATCHES[@]}), narrow filters or use -n:" >&2
    print_matches MATCHES SHIELDS BOARDS
    first="${MATCHES[0]}"
    echo "Hint: use '$0 -n $((first + 1))' for exact target." >&2
    echo "Hint: or narrow filters, e.g. '$0 -s \"${SHIELDS[$first]}\" -b \"${BOARDS[$first]}\"'." >&2
    exit 1
  fi

  SELECTED="${MATCHES[0]}"
  echo "Selected: $((SELECTED + 1)). ${SHIELDS[$SELECTED]} (${BOARDS[$SELECTED]})"
  echo
  flash_one "$SELECTED"
}

flash_by_select() {
  interactive_select
  flash_one "$SELECTED"
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
  -h | --help)
    HELP=true
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

need yq

print_header
load_builds

if $LIST; then
  list_builds
  exit 0
fi

if [[ -n "$NUMBER" && (-n "$SHIELD" || -n "$BOARD") ]]; then
  usage_error "Use either -n or (-s/-b), not both."
fi

if [[ -n "$NUMBER" ]]; then
  flash_by_number "$NUMBER"
elif [[ -n "$SHIELD" || -n "$BOARD" ]]; then
  flash_by_criteria "$SHIELD" "$BOARD"
else
  flash_by_select
fi
