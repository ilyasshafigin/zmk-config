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

load_build_manifest() {
  local build_yaml="$1"
  local boards_name="$2"
  local shields_name="$3"
  local snippets_name="${4-}"
  local cmake_args_name="${5-}"

  local line

  ensure_file "$build_yaml"

  ensure_identifier "$boards_name"
  ensure_identifier "$shields_name"
  [[ -z "$snippets_name" ]] || ensure_identifier "$snippets_name"
  [[ -z "$cmake_args_name" ]] || ensure_identifier "$cmake_args_name"

  eval "$boards_name=()"
  eval "$shields_name=()"
  [[ -z "$snippets_name" ]] || eval "$snippets_name=()"
  [[ -z "$cmake_args_name" ]] || eval "$cmake_args_name=()"

  while IFS= read -r line; do eval "$boards_name+=(\"$line\")"; done < <(yq '.include[].board' "$build_yaml")
  while IFS= read -r line; do eval "$shields_name+=(\"$line\")"; done < <(yq '.include[].shield' "$build_yaml")

  if [[ -n "$snippets_name" ]]; then
    while IFS= read -r line; do eval "$snippets_name+=(\"$line\")"; done < <(yq '.include[].snippet // ""' "$build_yaml")
  fi

  if [[ -n "$cmake_args_name" ]]; then
    while IFS= read -r line; do eval "$cmake_args_name+=(\"$line\")"; done < <(yq '.include[]."cmake-args" // ""' "$build_yaml")
  fi
}

get_artifact_name() {
  local shield="$1"
  local board="$2"

  echo "${shield// /+}-${board//\/\//_}"
}

to_lc() {
  printf '%s' "$1" | tr 'A-Z' 'a-z'
}

ensure_identifier() {
  local value="$1"

  [[ "$value" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] || die "Invalid variable name: $value"
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

  ensure_identifier "$shields_name"
  ensure_identifier "$boards_name"
  ensure_identifier "$matches_name"

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

  ensure_identifier "$matches_name"
  ensure_identifier "$shields_name"
  ensure_identifier "$boards_name"

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

prompt_select_number() {
  local prompt="$1"
  local max="$2"
  local result_name="$3"
  local ans

  ensure_identifier "$result_name"

  while true; do
    read -rp "$prompt" ans
    [[ "$ans" == "q" ]] && exit 0
    [[ "$ans" =~ ^[0-9]+$ ]] || continue
    if ((ans >= 1 && ans <= max)); then
      eval "$result_name=$((ans - 1))"
      return 0
    fi
  done
}
