# Local builds

## Requirements

Install and start Docker Desktop. On macOS:

```shell
brew install --cask docker
```

Install `yq` and `just`:

```shell
brew install just yq
```

## Usage

Run all commands from the project root.

### Interactive mode

```shell
just build
```

The script:

- reads configuration from `build.yaml`
- displays available build targets
- prompts you to select a build target
- starts Docker to build the firmware
- prints the path to the resulting file in `firmware/`, for example `lapka_dongle-xiao_ble_zmk.uf2`

### Command-line mode

```shell
# Build by target number from the configuration list
just build -n 1

# Build by shield name (partial matches are supported)
just build -s "lapka_dongle"

# Build by exact board and shield
just build -b "nice_nano//zmk" -s "charybdis_peripheral_left"

# Display all build targets
just build -l
just list

# Display help
just build -h

# Remove cached dependencies
just build --clean
just clean
```

### Dependency caching

The script keeps a persistent west workspace at:

- `local-build/workspace/`

This directory is ignored by Git and contains west dependencies (`zephyr/`, `zmk/`, `modules/`, and others), so later
builds do not download them again.

Useful flags:

- `--clean` (alias: `--clean-deps`): removes both:
  - `local-build/workspace/` (dependencies; the next build runs a fresh `west update`)
  - `local-build/artifact/` (temporary build artifacts)
- `--update`: forces `west update` before building

### How it works

The script keeps the Git repository clean by using a separate west workspace:

- `local-build/workspace/`

Resulting firmware is saved in `firmware/` as `*.uf2` files.

Inside the Docker container, the script mounts:

- `/repo`: repository sources
- `/workspace`: west workspace
- `/artifacts`: exported build output (`local-build/artifact/` on the host)

The active build directory, `/out`, is inside the container rather than a host bind mount. This avoids writing
intermediate CMake/Ninja files through Docker Desktop's host file-sharing layer, where corrupted generated files
were observed on macOS. After the build, its output is copied to `/artifacts/`; only a successful build
publishes a UF2 to `firmware/`. The container and its internal build directory are removed on exit.
If `west build` fails, its partial output is exported when available for diagnostics; the previous firmware is left
unchanged and the command returns an error.

Each build copies only the required source directories from the repository into `/workspace`:

- `/repo/config` → `/workspace/config`
- `/repo/keyboards` → `/workspace/keyboards`

Important: the repository root is not a conventional Zephyr/ZMK module. `config/` serves as the ZMK user config, while
`keyboards/` is a separate local module containing shield files.

The script then runs:

- `west init -l config` (only when required)
- `west update` (only when `zmk/` is missing or `--update` was specified)
- `west build`:

  ```shell
  west build ... \
    -DZMK_CONFIG=/workspace/config \
    -DZMK_EXTRA_MODULES=/workspace/keyboards \
    -DDTS_EXTRA_CPPFLAGS=-I/workspace/config
  ```

`west build` flags:

- `-DZMK_CONFIG=/workspace/config` - points to the ZMK user config.
- `-DZMK_EXTRA_MODULES=/workspace/keyboards` - adds the local module containing keyboard and shield definitions.
- `-DDTS_EXTRA_CPPFLAGS=-I/workspace/config` - adds `config/` to the devicetree preprocessor include path. This lets
  shield files from `keyboards/` include custom devicetree files from `config/`, such as
  `config/charybdis_pointer.dtsi`, without copying them into the shield directory.
