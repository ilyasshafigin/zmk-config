# AGENTS.md

Guidance for coding agents working in this repository.

## Scope and priorities

- This repo is a ZMK user configuration with local helper scripts.
- Primary source folders: `config/`, `boards/`, `dts/`, `app/`, `scripts/`, `draw/`.
- Build matrix is defined in `build.yaml`.
- West manifest and module pins are in `config/west.yml`.
- Prefer minimal, targeted edits that preserve existing naming and layout patterns.

## Rule files check (Cursor/Copilot)

- Checked `.cursor/rules/`: not present.
- Checked `.cursorrules`: not present.
- Checked `.github/copilot-instructions.md`: not present.
- No repository-specific Cursor/Copilot instruction files currently apply.

## Quick command reference

- List all Just recipes: `just`
- List build targets: `just list` or `just build --list`
- Build interactively: `just build`
- Build one target by index: `just build -n 1`
- Build targets by shield filter: `just build -s "lapka_dongle"`
- Build by shield+board: `just build -s "lapka_dongle" -b "xiao_ble//zmk"`
- Build all configured targets: `just build --all`
- Build all and force `west update`: `just build --all --update`
- Clean local west workspace/artifacts: `just clean` (delegates to `scripts/build.sh --clean`)
- Flash interactively: `just flash`
- Flash one target by index: `just flash -n 1`
- Flash by shield+board: `just flash -s "lapka_dongle" -b "nice_nano//zmk"`
- List flashable targets and UF2 status: `just list-flash`
- Draw keymap interactively: `just draw`
- Draw one keymap: `just draw lapka`
- Draw all keymaps: `just draw --all`

## Build, lint, and test policy

### Build

- Canonical local build entrypoint: `just build ...`.
- Under the hood this runs `scripts/build.sh` using Docker image `zmkfirmware/zmk-build-arm:stable`.
- `scripts/build.sh` reads `build.yaml` and emits UF2 files to `firmware/`.

### Lint/format

- There is no dedicated lint task (no `shellcheck`, `yamllint`, etc. configured in repo).
- There is no autoformatter task configured in Just recipes.
- Formatting expectations are enforced mainly by `.editorconfig` and existing style.

### Tests

- There is no repository-local unit/integration test suite configured.
- Practical verification is successful firmware build(s) and optional keymap rendering.
- Equivalent of running a single test: build a single firmware target.

Single-target verification examples:

- `just build -n 1`
- `just build -s "charybdis_central_right" -b "nice_nano//zmk"`

Broader verification examples:

- `just build --all`
- `just draw --all`

## CI awareness

- Build workflow: `.github/workflows/build.yml` (reuses upstream ZMK user-config workflow).
- Draw workflow: `.github/workflows/draw-keymaps.yml` (reuses keymap-drawer workflow).
- Keep local command usage aligned with these workflows when possible.

## Code style guidelines

### Global formatting

- Follow `.editorconfig` strictly:
  - `end_of_line = lf`
  - `charset = utf-8`
  - `insert_final_newline = true`
  - `trim_trailing_whitespace = true` (except Markdown)
  - `max_line_length = 120`
- Indentation by file type:
  - `*.{c,h,xml,dtsi,overlay,keymap}` -> 4 spaces
  - `*.{json,yml,sh}` -> 2 spaces

### Shell scripts (`scripts/*.sh`)

- Keep shebang: `#!/usr/bin/env bash`.
- Keep strict mode near top: `set -euo pipefail`.
- Use `snake_case` for functions and local variables.
- Use `UPPER_SNAKE_CASE` for script-level constants/config paths.
- Quote variable expansions unless intentional word splitting is required.
- Prefer helper functions from `scripts/lib/common.sh`:
  - `need` for dependency checks
  - `ensure_file` for required files
  - `die` / `usage_error` for consistent failures
- Use `local` inside functions for non-global variables.
- Preserve existing CLI UX patterns: `--help`, `--list`, interactive fallback.

### YAML (`build.yaml`, workflow files, draw config)

- Use 2-space indentation.
- Keep existing key ordering and grouping where already meaningful.
- In `build.yaml`, keep entries grouped by keyboard family and dongle/role.
- Avoid reformatting large YAML blocks unless functionally needed.

### DTSI/overlay/keymap files

- Keep include directives at the top of the file.
- Preserve current include style (`#include <...>` for external, `#include "..."` for local).
- Use 4-space indentation and keep matrix/layout alignment readable.
- Preserve existing macro style (`ZMK_LAYER`, `ZMK_COMBO`, `MAKE_HRM`, etc.).
- Layer/behavior identifiers follow existing uppercase short names (e.g. `DEF`, `SYM`, `NAV`).
- Do not rename established layer IDs or behavior names without full cross-file updates.

### Naming conventions

- Shell functions: `verb_object` in snake_case (example: `build_by_number`).
- Shell constants: uppercase (example: `BUILD_YAML`, `OUTPUT_DIR`).
- Build target naming mirrors board/shield naming in `build.yaml`.
- Keep filenames and shield names consistent with existing underscore-separated patterns.

## Error handling and reliability expectations

- Fail fast on invalid args and missing dependencies/files.
- For argument validation, prefer existing helpers (e.g. `validate_number_arg`).
- Keep explicit non-zero exit codes semantics where present:
  - `1` runtime failure
  - `2` argument/usage failure
- Preserve retry/wait logic in flashing flows unless fixing a concrete bug.
- Do not silently swallow errors except where the code already intentionally does so.

## Change discipline for agents

- Do not edit generated artifacts unless explicitly requested:
  - `firmware/*.uf2`
  - `local-build/artifact/**`
  - `local-build/workspace/**`
  - `draw/*.png` and `draw/*.svg` (unless task is keymap rendering output)
- Prefer editing source inputs (`config/`, `boards/`, `build.yaml`, `scripts/`).
- Keep patches focused; avoid drive-by formatting-only changes.
- If introducing a new command, wire it through `Justfile` for consistency.

## Minimal validation checklist after edits

- For script/CLI changes:
  - `just build --help`
  - `just flash --help`
  - `just draw --help`
- For build-matrix or keymap changes:
  - run at least one targeted build (`just build -n <N>` or shield+board filter)
- For draw config/keymap legend changes:
  - run `just draw <keymap>` for the affected keymap

If a requested task cannot be fully validated locally (missing dependencies/hardware),
state what was not run and provide the exact command for a human to run.
