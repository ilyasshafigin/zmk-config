default:
    @just --list --unsorted

dir_extra_modules := `pwd`
dir_zmk := `pwd` / "zmk"
dir_config := `pwd` / "config"
dir_firmware := `pwd` / "firmware"
dir_keymap_drawer := `pwd` / "draw"
dir_boards := `pwd` / "boards"

mount_nice := "/Volumes/NICENANO"
mount_xiao := "/Volumes/XIAO-SENSE"
board_nice := "nice_nano"
board_xiao := "xiao_ble"

[private]
get-artifact $board $shield:
    @echo "${shield// /+}-${board}"

# Build firmware
build *args:
    bash local-build/build.sh {{ args }}

# Flash
flash $board $shield:
    #!/usr/bin/env bash
    set -euo pipefail
    artifact=$(just get-artifact "$board" "$shield")
    echo "Flash firmware for '$board' '$shield'"
    mount=""
    case "$board" in
        "{{ board_nice }}")
            mount="{{ mount_nice }}"
        ;;
        "{{ board_xiao }}")
            mount="{{ mount_xiao }}"
        ;;
        *)
            echo "Unknown board ${board}"
            exit
        ;;
    esac

    printf "Waiting for ${board} bootloader to appear at ${mount}.."
    while [ ! -d ${mount} ]; do sleep 1; printf "."; done; printf "\n"

    echo "Copy ${artifact}.uf2 to ${mount}"
    cp -av "{{ dir_firmware }}/${artifact}.uf2" "${mount}"

# Clean firmware dir
clean-firmware:
    @echo "Remove firmwares"
    find "{{ dir_firmware }}/*.uf2" -type f -delete

# Clean zmk and docker container/volumes
clean:
    bash local-build/build.sh --clean

# Clean all
clean-all: clean clean-firmware

# List build targets
list:
    bash local-build/build.sh --list

# Draw
draw $keyboard *args='':
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Draw '$keyboard'"
    keymap_input_file="{{ dir_config }}/$keyboard.keymap"
    keymap_svg="{{ dir_keymap_drawer }}/$keyboard.svg"
    keymap_png="{{ dir_keymap_drawer }}/$keyboard.png"
    keymap_yaml="{{ dir_keymap_drawer }}/$keyboard.yaml"
    draw_config="{{ dir_config }}/keymap-drawer.yaml"
    keymap -c "$draw_config" parse -z "$keymap_input_file" > "$keymap_yaml"
    keymap -c "$draw_config" draw {{ args }} "$keymap_yaml" > "$keymap_svg"
    inkscape --export-type=png --export-background=white --export-filename="$keymap_png" "$keymap_svg"
