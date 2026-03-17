#!/usr/bin/env bash
set -euo pipefail

# ==========================
# Config
# ==========================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="$(realpath "$SCRIPT_DIR/..")"
LIB_COMMON="$SCRIPT_DIR/lib/common.sh"

MOUNT_NICE="/Volumes/NICENANO"
MOUNT_XIAO="/Volumes/XIAO-SENSE"
BOARD_NICE="nice_nano//zmk"
BOARD_XIAO="xiao_ble//zmk"
FIRMWARE_DIR="$WORKSPACE/firmware"
BUILD_YAML="$WORKSPACE/build.yaml"
BOOT_WAIT_SEC="${BOOT_WAIT_SEC:-120}"

source "$LIB_COMMON"

# ==========================
# Dependencies check
# ==========================
need yq

# ==========================
# Load builds
# ==========================
load_builds() {
  ensure_file "$BUILD_YAML"

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

  FIRMWARE_COUNT="${#BOARDS[@]}"
  ((FIRMWARE_COUNT > 0)) || die "No builds found in build.yaml"
  ((${#SHIELDS[@]} == FIRMWARE_COUNT)) || die "Malformed build.yaml: boards/shields count mismatch"
  ((${#SNIPPETS[@]} == FIRMWARE_COUNT)) || die "Malformed build.yaml: boards/snippets count mismatch"
  ((${#CMAKE_ARGS[@]} == FIRMWARE_COUNT)) || die "Malformed build.yaml: boards/cmake-args count mismatch"
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
    $0 -s "totem_dongle" -b "xiao_ble//zmk"

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
  while true; do
    read -rp "Select firmware to flash (1-$FIRMWARE_COUNT) or q: " ans
    [[ "$ans" == "q" ]] && exit 0
    [[ "$ans" =~ ^[0-9]+$ ]] || continue
    ((ans >= 1 && ans <= FIRMWARE_COUNT)) && {
      SELECTED=$((ans - 1))
      return
    }
  done
}

get_artifact_name() {
  local shield="$1"
  local board="$2"
  echo "${shield// /+}-${board//\/\//_}"
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

  local waited=0
  printf "Waiting for %s bootloader to appear at %s..." "$board" "$mount"
  while [ ! -d "$mount" ]; do
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
