default:
    @just --list --unsorted

dir_config := `pwd` / "config"
dir_firmware := `pwd` / "firmware"
dir_keymap_drawer := `pwd` / "draw"

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

# List build targets
list:
    bash local-build/build.sh --list

# Draw
draw $keyboard *args='':
    bash draw/draw.sh $keyboard {{ args }}
