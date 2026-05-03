# AGENTS.md

Compact repo guidance for OpenCode agents. Keep edits targeted and prefer executable config/scripts over README prose.

## Repo shape

- This is a ZMK user config, not an app repo; there is no local unit test suite.
- Build targets live in `build.yaml`; west module pins live in `config/west.yml` (`self.path: config`).
- Source inputs are `config/`, `boards/`, `dts/`, `app/`, `zephyr/module.yml`, `scripts/`, and `draw/`.
- Generated/local outputs to avoid editing unless explicitly requested: `firmware/*.uf2`, `local-build/workspace/**`,
  `local-build/artifact/**`, and rendered `draw/*.svg` / `draw/*.png`.
- No repo-local `.github/workflows/`, `.pre-commit-config.yaml`, `.cursor/rules/`, `.cursorrules`,
  `.github/copilot-instructions.md`, or OpenCode config were found.

## Commands that matter

- List Just recipes: `just`
- Quick repo smoke check: `just validate`
- Build target list: `just list` or `just build --list`
- Build one target: `just build -n 1`
- Build by shield substring: `just build -s "lapka_dongle"`
- Build by exact board plus shield filter: `just build -s "lapka_dongle" -b "xiao_ble//zmk"`
- Build all targets: `just build --all` (`--update` forces `west update` first)
- Flash list/status: `just list-flash` or `just flash --list`
- Flash one target: `just flash -n 1`
- Draw keymaps: `just draw --list`, `just draw lapka`, or `just draw --all`
- Clean cached west workspace/artifacts: `just clean`; remove UF2s too: `just clean-all`

## Build and draw quirks

- `scripts/build.sh` requires `docker` and `yq`, uses Docker image `zmkfirmware/zmk-build-arm:stable`, and writes UF2s to
  `firmware/` with names derived from `shield` + `board`.
- Local builds run from a cached west workspace at `local-build/workspace/`; use `just build --update ...` when module pins or
  upstream west deps need refreshing.
- The build script copies repo sources into the west workspace and passes `-DZMK_CONFIG=/workspace/config` plus
  `-DZMK_EXTRA_MODULES=/workspace/zmk-config`; do not assume in-place west builds from the repo root.
- Charybdis builds deliberately copy `config/includes/layers.h` and `config/charybdis_pointer.dtsi` into the workspace shield
  dir before building.
- `just draw ...` needs `keymap`, `inkscape`, `draw/config.yaml`, and helper includes under
  `local-build/workspace/modules/zmk/helpers/include` (usually created by the first `just build`).

## Flashing quirks

- `scripts/flash.sh` maps `nice_nano//zmk` to `/Volumes/NICENANO` and `xiao_ble//zmk` to `/Volumes/XIAO-SENSE`.
- It waits up to `BOOT_WAIT_SEC` seconds (default `120`) for the bootloader volume and rejects obvious board/volume mismatches.
- Flashing depends on existing matching UF2s in `firmware/`; run a focused build first if `just flash --list` shows `MISSING`.

## Validation expectations

- For script/CLI changes, run `just validate` plus the affected `--help` / `--list` command if useful.
- For build-matrix, board, shield, or keymap changes, run at least one focused build such as `just build -n <N>` or a
  shield/board-filtered build.
- For draw config or keymap legend changes, run `just draw <keymap>` after a build has populated helper includes.
- If Docker, hardware, or GUI tools are unavailable, state exactly which command was not run.

## Style and conventions

- Follow `.editorconfig`: LF, UTF-8, final newline, max line length 120; 4 spaces for `*.{c,h,xml,dtsi,overlay,keymap}` and
  2 spaces for `*.{json,yml,sh}`.
- Keep shell scripts in `scripts/` on Bash strict mode (`set -euo pipefail`), with `snake_case` functions/locals and shared
  helpers from `scripts/lib/common.sh` (`need`, `ensure_file`, `die`, `usage_error`, `validate_number_arg`).
- Preserve CLI UX already used by scripts: `--help`, `--list`, non-interactive flags, and interactive fallback.
- Keep `build.yaml` entries grouped by keyboard family and preserve exact board strings like `nice_nano//zmk`.
- In DTS/keymap files, keep includes at the top, use existing macro style (`ZMK_LAYER`, `ZMK_COMBO`, `MAKE_HRM`, etc.), and
  do not rename layer/behavior IDs without updating all references.
