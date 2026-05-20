#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="$(realpath "$SCRIPT_DIR/..")"

run_check() {
  local description="$1"
  shift

  printf '==> %s\n' "$description"
  "$@" >/dev/null
}

check_keymap_draw_support() {
  local keymap_file keymap_name draw_file
  local missing=0

  shopt -s nullglob
  for keymap_file in "$WORKSPACE"/config/*.keymap; do
    keymap_name="$(basename "$keymap_file" .keymap)"
    draw_file="$WORKSPACE/draw/$keymap_name.yaml"

    if [[ ! -f "$draw_file" ]]; then
      printf 'Missing draw config for keymap: %s\n' "$keymap_name" >&2
      missing=1
    fi
  done
  shopt -u nullglob

  ((missing == 0))
}

main() {
  run_check "just build --help" just build --help
  run_check "just flash --help" just flash --help
  run_check "just draw --help" just draw --help
  run_check "just build --list" just build --list
  run_check "just flash --list" just flash --list
  run_check "just draw --list" just draw --list

  check_keymap_draw_support
  printf '==> keymap draw support check\n'
}

main "$@"
