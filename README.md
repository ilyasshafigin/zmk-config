# ZMK Config

English | [Русский](README.ru.md)

Configuration and firmware for my keyboards:

1. **[Lapka](#lapka)** - primary
2. [Charybdis Nano](#charybdis-nano)

## Table of contents

- [Key features](#key-features)
- [Project structure](#project-structure)
- [Operating modes](#operating-modes)
- [Modules](#modules)
- [Firmware](#firmware)
- [FAQ](#faq)
- [Keyboards](#keyboards)
- [Tester Pro Micro](#tester-pro-micro)
- [Scripts](#scripts)
- [Layout](#layout)
- [Additional OS configuration](#additional-os-configuration)
- [References](#references)

## Key features

- **Home-Row Mods**
- **Local builds** via Docker, with current firmware files in `firmware/`
- **Universal layout** based on [universal-layout](https://github.com/braindefender/universal-layout) and
  [wellum](https://github.com/braindefender/wellum)
- **Flexible setup**: with or without a dongle (one half acts as central)
- **Shared keymap** extracted into a separate file, inspired by [miryoku](https://github.com/manna-harbour/miryoku_zmk)
- **Adapted for macOS**
- **Scripts** for building, flashing, and rendering keymaps

## Project structure

This repository is not structured as a single conventional ZMK/Zephyr module at its root. The project root contains
custom tooling, while actual ZMK components are separated by role:

- `config/` - ZMK user config: `west.yml`, keymap/conf files, and shared include files (`shared/`). `config/west.yml`
  intentionally uses `self.path: config`.
- `keyboards/` - local Zephyr/ZMK module containing shield files (`keyboards/boards/shields/...`) and its own
  `keyboards/zephyr/module.yml`.
- `scripts/` and `Justfile` - custom local build, flashing, and rendering tools.
- `local-build` - [local build documentation](local-build/README.md).
- `firmware/` - generated firmware files.

## Operating modes

**Without a dongle (standalone):**

One half acts as central and connects to the computer over Bluetooth. The other half connects to it over Bluetooth.
For Charybdis, the right half is central because it contains the trackball.

**With a dongle (dongle mode):**

The dongle acts as central and connects to the computer over USB or Bluetooth. Both halves act as peripherals and
connect to the dongle over Bluetooth.

**Dongle options:**

- nice!nano v2 / Seeeduino XIAO BLE - bare USB board
- Prospector Dongle - screen showing layer, battery, status, and modifiers; based on XIAO BLE
- Dongle Display - mini OLED (128x32 / 128x64); based on nice!nano

## Modules

### Helpers

- [zmk-helpers](https://github.com/urob/zmk-helpers) - useful macros.

### Drivers

- [zmk-pmw3610-driver](https://github.com/badjeff/zmk-pmw3610-driver) - driver module for the PMW3610 sensor.
  Required for the Charybdis trackball.

### Behaviors & Input processors

- [zmk-smart-toggle](https://github.com/caksoylar/zmk-smart-toggle) - module providing smart-toggle behavior.
  Used for `swapper` and `tabber`.
- [zmk-input-processor-keybind](https://github.com/zettaface/zmk-input-processor-keybind) - module that converts
  trackball movement into arrow-key presses. Useful for moving the caret in input fields. Required for the Charybdis
  trackball.
- [zmk-scroll-snap](https://github.com/kot149/zmk-scroll-snap) - constrains trackball scrolling to the X or Y axis.
- ~~[zmk-pointing-acceleration](https://github.com/oleksandrmaslov/zmk-pointing-acceleration)~~
  ~~- adds trackball acceleration.~~
- ~~[zmk-behavior-battery-percentage-printer][bapp]~~
  ~~- fork of~~
  ~~[badjeff/zmk-behavior-battery-percentage-printer][bapp-upstream].~~
  ~~Types the battery percentage (`&bapp`) and supports configurable keycodes for digits, decimal point, space, and~~
  ~~percent sign when using custom layouts such as Universal Layout.~~

### Dongle

- [prospector-zmk-module](https://github.com/carrefinho/prospector-zmk-module) - module for the Prospector dongle.
- ~~[zmk-dongle-display](https://github.com/englmaxi/zmk-dongle-display) - module for a dongle with an OLED display.~~

## Firmware

### Building

See [local-build](local-build/README.md) for details about local builds.

### Flashing

To put a keyboard half or dongle into bootloader mode, press Reset twice. If there is no Reset button, short the RST and
GND pins twice.

Reliable procedure for initially pairing keyboard halves with a dongle. Use it when the halves have not been paired yet
or when connection problems occur:

1. Connect the dongle and flash `settings_reset.uf2`
2. Disconnect the dongle from the cable and set it aside
3. Connect the left half and flash `settings_reset.uf2`, then `peripheral_left.uf2`
4. Connect the right half and flash `settings_reset.uf2`, then `peripheral_right.uf2`
5. Connect the dongle and flash `dongle.uf2`
6. Turn on the dongle, then the left half, then the right half, in that exact order

Without a dongle, the left half acts as central. If the right half should be central, swap left and right in these
steps:

1. Connect the right half and flash `settings_reset.uf2`, then `peripheral_right.uf2`
2. Connect the left half and flash `settings_reset.uf2`, then `central_left.uf2`

If the halves are already paired with the dongle and only `dongle.uf2` changed, flashing only that file is sufficient.

## FAQ

### Battery indicators for the keyboard halves are swapped on the dongle display

Pair the keyboards with the dongle again: flash the reset firmware to both halves and the dongle as described above.
Power-on order: dongle, then left (!) half, then right half.

### `Cmd+[`/`Cmd+]` shortcuts behave incorrectly in IntelliJ IDEA and VS Code with the Russian layout

Karabiner-Elements partially fixes this issue. Add the Complex Modifications rule from the section below
(`Universal Layout fixes for GUI layer`).

### UF2 drive does not appear after a double reset

Check the cable: flashing requires a USB data cable, not a power-only cable.
If the drive still does not appear, repeat the double reset with a shorter interval and try another USB port.

### Keyboard halves do not connect over BLE after flashing

Reset connections on every device with `settings_reset.uf2`, then repeat the pairing procedure from
[Flashing](#flashing). In dongle mode, follow this power-on order: dongle, left half, right half.

## Keyboards

### [Charybdis Nano](https://github.com/bastardkb/charybdis/)

I ordered a hot-swap kit from an AliExpress seller, so its firmware differs from the original:

- Each switch has a separate small board, with all boards connected by wires. I have not identified which
  [SU120](https://github.com/e3w2q/su120-keyboard) fork the seller used
- Column and row pins differ
- Diode direction differs: I soldered the diodes as shown on the PCB, but compatibility with the original firmware
  required the opposite direction
- Matrix transform differs

**Features:**

- Uses [zmk-input-processor-keybind](https://github.com/zettaface/zmk-input-processor-keybind), which allows moving
  the caret in input fields with the trackball
- ~~Uses [zmk-pointing-acceleration](https://github.com/oleksandrmaslov/zmk-pointing-acceleration)~~
  ~~for trackball acceleration~~
- Uses [zmk-scroll-snap](https://github.com/kot149/zmk-scroll-snap) to constrain caret movement to the X or Y axis.
- In standalone mode, the right half is central (`central_right`)

![Charybdis keymap](./draw/charybdis.svg?raw=true "Charybdis keymap")
_(keymap image created with [caksoylar/keymap-drawer](https://github.com/caksoylar/keymap-drawer))_

**Firmware:**

Run `just flash` and select the required firmware:

- `charybdis_dongle_prospector` - firmware for the Prospector dongle (XIAO + prospector_adapter)
- `charybdis_central_right` - firmware for the right half acting as central
- `charybdis_peripheral_left` - firmware for the left half in dongle mode
- `charybdis_peripheral_right` - firmware for the right half, both in dongle mode and when the left half acts as central

Shield files are stored in the local `keyboards/` module. Shared pointing-device configuration lives in
`config/charybdis_pointer.dtsi` and is included from the Charybdis shield files through the `DTS_EXTRA_CPPFLAGS` include
path.

### [Lapka](https://github.com/braindefender/lapka)

![Lapka keymap](./draw/lapka.svg?raw=true "Lapka keymap")
_(keymap image created with [caksoylar/keymap-drawer](https://github.com/caksoylar/keymap-drawer))_

**Firmware:**

Run `just flash` and select the required firmware:

- `lapka_dongle (xiao_ble//zmk)` - firmware for a XIAO-based dongle
- `lapka_dongle (nice_nano//zmk)` - firmware for a nice!nano-based dongle
- `lapka_dongle_prospector` - firmware for the Prospector dongle
- `lapka_central_left` - firmware for the left half acting as central
- `lapka_peripheral_left` - firmware for the left half in dongle mode
- `lapka_peripheral_right` - firmware for the right half, both in dongle mode and when the left half acts as central

## Tester Pro Micro

Firmware for testing pins on ProMicro nRF52840 boards, including nice!nano and other clones. Copied from
[@choovick's repository](https://github.com/choovick/zmk-config-charybdis).
Bluetooth is disabled in this firmware; it works over USB only.

**Firmware:**

`just flash -s "tester_pro_micro"`

**Procedure:**

1. Flash `tester_pro_micro-nice_nano_zmk.uf2`
2. Connect the controller to the computer over USB
3. Open any text editor
4. Short the GPIO pin being tested to GND
5. The text editor should receive `pin X`, where X is the pin number
6. Test every pin

## Scripts

All scripts are in `scripts/`. [Just](https://github.com/casey/just) provides convenient commands.

### `build.sh`

Builds firmware locally. See [local-build](local-build/README.md) for details.
Help: `just build --help`
Target list: `just build --list`

### `flash.sh`

Flashes keyboard firmware.
Help: `just flash --help`
Firmware list: `just flash --list`

### `draw.sh`

Renders keymaps.
Help: `just draw --help`
Keymap list: `just draw --list`

### `validate.sh`

Runs a quick repository validation.
Command: `just validate`
Checks command help/list output and basic keymap/draw consistency.

`draw` requires helper include files from `local-build/workspace/modules/zmk/helpers/include`.
They are usually created by the first local build (`just build`).

## Layout

The `layout` directory contains a fork of [universal-layout](https://github.com/braindefender/universal-layout).

Differences:

- split into two languages: Russian and English
- flag icons added so the active layout is visible in the system
- macOS only

### Installing Universal Layout

On macOS:

1. Copy `layout/macOS/Universal.bundle` to `~/Library/Keyboard Layouts`.
2. Restart the computer or sign out and back in.
3. Select the desired layout in System Settings > Keyboard > Input Sources.
4. Remove the standard Russian and English layouts. [This guide](https://4te.me/post/flags-tray-macos/) explains how.
5. Restart the computer or sign out and back in again.

## Additional OS configuration

### Karabiner-Elements

To support language switching with Cmd+F11/F12, install
[Karabiner-Elements](https://github.com/pqrs-org/Karabiner-Elements).
In Complex Modifications, add a custom rule containing this code:

```json
{
    "description": "Set language on Cmd+F11/F12",
    "manipulators": [
        {
            "from": {
                "key_code": "f11",
                "modifiers": {
                    "mandatory": ["command"],
                    "optional": ["any"]
                }
            },
            "to": [{ "select_input_source": { "language": "ru" } }],
            "type": "basic"
        },
        {
            "from": {
                "key_code": "f12",
                "modifiers": {
                    "mandatory": ["command"],
                    "optional": ["any"]
                }
            },
            "to": [{ "select_input_source": { "language": "en" } }],
            "type": "basic"
        }
    ]
}
```

To make `Cmd+[`, `Cmd+]`, and other shortcuts behave consistently with both Russian and English layouts in IntelliJ IDEA
and VS Code, add a Complex Modifications rule with these mappings:

- `.` -> `[`
- `/` -> `]`
- `[` -> `,`
- `]` -> `.`
- `\` -> `/`

```json
{
    "description": "Universal Layout fixes for GUI layer",
    "manipulators": [
        {
            "from": {
                "key_code": "period",
                "modifiers": {
                    "mandatory": ["command"],
                    "optional": ["any"]
                }
            },
            "to": [
                {
                    "key_code": "open_bracket",
                    "modifiers": ["command"]
                }
            ],
            "type": "basic"
        },
        {
            "from": {
                "key_code": "slash",
                "modifiers": {
                    "mandatory": ["command"],
                    "optional": ["any"]
                }
            },
            "to": [
                {
                    "key_code": "close_bracket",
                    "modifiers": ["command"]
                }
            ],
            "type": "basic"
        },
        {
            "from": {
                "key_code": "open_bracket",
                "modifiers": {
                    "mandatory": ["command"],
                    "optional": ["any"]
                }
            },
            "to": [
                {
                    "key_code": "comma",
                    "modifiers": ["command"]
                }
            ],
            "type": "basic"
        },
        {
            "from": {
                "key_code": "close_bracket",
                "modifiers": {
                    "mandatory": ["command"],
                    "optional": ["any"]
                }
            },
            "to": [
                {
                    "key_code": "period",
                    "modifiers": ["command"]
                }
            ],
            "type": "basic"
        },
        {
            "from": {
                "key_code": "backslash",
                "modifiers": {
                    "mandatory": ["command"],
                    "optional": ["any"]
                }
            },
            "to": [
                {
                    "key_code": "slash",
                    "modifiers": ["command"]
                }
            ],
            "type": "basic"
        }
    ]
}
```

## References

### Charybdis

- [charybdis-3-5-dongle-prospector-studio](https://github.com/devpew/charybdis-3-5-dongle-prospector-studio)
  by @devpew - Charybdis + ZMK Studio
- [charybdis-wireless-mini-zmk-firmware](https://github.com/280Zo/charybdis-wireless-mini-zmk-firmware)
  by @280Zo - Charybdis, home-row mods, local build scripts
- [zmk-config-charybdis-mini-wireless](https://github.com/aystream/zmk-config-charybdis-mini-wireless)
  by @aystream - Charybdis
- [charybdis_zmk](https://github.com/nophramel/charybdis_zmk) by @nophramel - Charybdis
- [zmk-config-charybdis](https://github.com/choovick/zmk-config-charybdis) by @choovick - Charybdis, local builds,
  Tester Pro Micro
- [charybdis-zmk](https://github.com/vloth/charybdis-zmk) by @vloth - Charybdis

### Lapka

- [lapka-zmk-config](https://github.com/braindefender/lapka-zmk-config) - official Lapka firmware repository

### Other

- [zmk-config](https://github.com/urob/zmk-config) by @urob - home-row mods
- [zmk-config](https://github.com/minusfive/zmk-config) by @minusfive - custom keymap-drawer styles
- [zmk-config](https://github.com/mctechnology17/zmk-config) by @mctechnology17 - local builds and Makefile
- [miryoku](https://github.com/manna-harbour/miryoku_zmk) by @manna-harbour - universal layout for different keyboards
- [keymap-drawer](https://github.com/caksoylar/keymap-drawer) - keymap rendering
- [universal-layout](https://github.com/braindefender/universal-layout) - universal layout by @braindefender
- [wellum](https://github.com/braindefender/wellum) - universal layout for split keyboards by @braindefender

[bapp]: https://github.com/ilyasshafigin/zmk-behavior-battery-percentage-printer
[bapp-upstream]: https://github.com/badjeff/zmk-behavior-battery-percentage-printer
