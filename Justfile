default:
    @just --list --unsorted

dir_config := `pwd` / "config"
dir_firmware := `pwd` / "firmware"
dir_keymap_drawer := `pwd` / "draw"

# List build targets
list:
    bash local-build/build.sh --list

# Build firmware
build *args:
    bash local-build/build.sh {{ args }}

# Flash
flash *args:
    bash firmware/flash.sh {{ args }}

# Clean firmware dir
clean-firmware:
    @echo "Remove firmwares"
    find "{{ dir_firmware }}/*.uf2" -type f -delete

# Clean zmk and docker container/volumes
clean:
    bash local-build/build.sh --clean

# Clean all
clean-all: clean clean-firmware

# Draw
#draw *args='':
#    bash draw/draw.sh {{ args }}

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
