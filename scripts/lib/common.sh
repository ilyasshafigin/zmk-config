#!/usr/bin/env bash

# Shared helpers for local scripts.

die() {
  echo "Error: $*" >&2
  exit 1
}

usage_error() {
  echo "Error: $*" >&2
  exit 2
}

need() {
  command -v "$1" >/dev/null || die "Missing dependency: $1"
}

ensure_file() {
  local file="$1"
  [[ -f "$file" ]] || die "Required file not found: $file"
}

to_lc() {
  printf '%s' "$1" | tr 'A-Z' 'a-z'
}

find_by_criteria() {
  local shield="$1"
  local board="$2"
  local count="$3"
  local shields_name="$4"
  local boards_name="$5"
  local matches_name="$6"

  local shield_lc board_lc s b i

  shield_lc="$(to_lc "$shield")"
  board_lc="$(to_lc "$board")"

  eval "$matches_name=()"
  for ((i = 0; i < count; i++)); do
    eval "s=\${${shields_name}[$i]}"
    eval "b=\${${boards_name}[$i]}"
    s="$(to_lc "$s")"
    b="$(to_lc "$b")"

    [[ -n "$shield_lc" && "$s" != *"$shield_lc"* ]] && continue
    [[ -n "$board_lc" && "$b" != "$board_lc" ]] && continue

    eval "$matches_name+=(\"$i\")"
  done
}

print_matches() {
  local matches_name="$1"
  local shields_name="$2"
  local boards_name="$3"

  local i idx shield board matches_len j
  eval "matches_len=\${#${matches_name}[@]}"

  for ((j = 0; j < matches_len; j++)); do
    eval "i=\${${matches_name}[$j]}"
    eval "shield=\${${shields_name}[$i]}"
    eval "board=\${${boards_name}[$i]}"
    idx=$((i + 1))
    echo "  ${idx}. ${shield} (${board})"
  done
}

validate_number_arg() {
  local value="$1"
  local name="$2"

  [[ -n "$value" ]] || usage_error "Missing value for ${name}"
  [[ "$value" =~ ^[0-9]+$ ]] || usage_error "Expected numeric value for ${name}, got: ${value}"
}
