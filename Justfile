default:
    @just --list --unsorted

dir_config := `pwd` / "config"
dir_firmware := `pwd` / "firmware"
dir_keymap_drawer := `pwd` / "draw"

# List build targets
list:
    bash scripts/build.sh --list

# List flash targets and firmware status
list-flash:
    bash scripts/flash.sh --list

# List keymaps for drawer
list-draw:
    bash scripts/draw.sh --list

# Build firmware
build *args:
    bash scripts/build.sh {{ args }}

# Flash
flash *args:
    bash scripts/flash.sh {{ args }}

# Clean firmware dir
clean-firmware:
    @echo "Remove firmwares"
    find "{{ dir_firmware }}" -type f -name "*.uf2" -delete

# Clean zmk and docker container/volumes
clean:
    bash scripts/build.sh --clean

# Clean all
clean-all: clean clean-firmware

# Draw
draw *args:
    bash scripts/draw.sh {{ args }}
