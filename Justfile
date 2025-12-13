default:
    @just --list --unsorted

dir_extra_modules := `pwd`
dir_zmk := `pwd` / "zmk"
dir_config := `pwd` / "config"
dir_firmware := `pwd` / "firmware"
dir_keymap_drawer := `pwd` / "draw"

mount_nice := "/Volumes/NICENANO"
mount_xiao := "/Volumes/XIAO-SENSE"
board_nice := "nice_nano"
board_xiao := "xiao_ble"

image_zmk := "zmkfirmware/zmk-dev-arm:stable"
container_codebase := "zmk-codebase"

[private]
get-docker-opts $task:
    @echo "\
        --tty \
        --name zmk-${task//+/-} \
        --workdir /zmk \
        --volume {{ dir_config }}:/zmk-config:Z \
        --volume {{ dir_zmk }}:/zmk:Z \
        --volume {{ dir_extra_modules }}:/boards:Z \
        {{ image_zmk }}"

# Parse build.yaml and filter targets by expression
[private]
parse-targets $expr:
    #!/usr/bin/env bash
    set -euo pipefail
    attrs="[.board, .shield, .snippet]"
    filter="(($attrs | map(. // [.])), ((.include // {})[] | $attrs)) | join(\",\")"
    echo "$(yq -r "$filter" build.yaml | grep -v "^," | grep -i "${expr/#all/.*}")"

[private]
get-artifact $board $shield:
    @echo "${shield// /+}-${board}"

[private]
fix-firmware-permission artifact:
    @echo "Fix permissions for {{ artifact }}.uf2"
    chmod go+wrx "{{ dir_firmware }}/{{ artifact }}.uf2"

# Init west and docker container
init:
    #!/usr/bin/env bash
    if [ ! -d zmk ]; then
        git clone https://github.com/zmkfirmware/zmk
    fi

    opts=$(just get-docker-opts codebase)
    docker run $opts sh -c '\
        west init -l /zmk/app/ --mf /zmk-config/west.yml; \
        west update'

# Update west
update:
    #!/usr/bin/env bash
    opts=$(just get-docker-opts update)
    docker run --rm $opts sh -c '\
        west update --fetch-opt=--filter=blob:none'

# Open a shell within the ZMK environment
shell:
    docker run --rm $(just get-docker-opts shell) /bin/bash

# Build firmware for matching targets
build expr *west_args:
    #!/usr/bin/env bash
    set -euo pipefail
    targets=$(just parse-targets {{ expr }})

    [[ -z $targets ]] && echo "No matching targets found. Aborting..." >&2 && exit 1
    echo "$targets" | while IFS=, read -r board shield snippet; do
        echo "Building firmware for '$board' '$shield' '$snippet'..."
        artifact=$(just get-artifact "$board" "$shield")
        opts=$(just get-docker-opts $artifact)
        docker run --rm $opts \
            west build /zmk/app --pristine -b "$board" ${snippet:+-S "$snippet"} {{ west_args }} -- \
                ${shield:+-DSHIELD="$shield"} \
                -DZMK_CONFIG="/zmk-config" \
                -DZMK_EXTRA_MODULES="/boards" \
                -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

        echo "Copy ${artifact}.uf2 to firmware dir"
        docker cp "{{ container_codebase }}:/zmk/build/zephyr/zmk.uf2" "{{ dir_firmware }}/${artifact}.uf2"

        just fix-firmware-permission "$artifact"
    done

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

    just fix-firmware-permission "$artifact"

    echo "Copy ${artifact}.uf2 to ${mount}"
    cp -av "{{ dir_firmware }}/${artifact}.uf2" "${mount}"

# Clean firmware dir
clean-firmware:
    @echo "Remove firmwares"
    find "{{ dir_firmware }}/*.uf2" -type f -delete

# Clean zmk dir
clean-zmk:
    @echo "Remove zmk dir"
    @if [ -d zmk ]; then rm -rfv zmk; fi

# Clean docker container and volumes
clean-docker:
    @echo "Remove docker container"
    docker ps -aq --filter name='^zmk' | xargs -r docker container rm
    @echo "Remove docker volumes"
    docker volume list -q --filter name='zmk' | xargs -r docker volume rm

# Clean zmk and docker container/volumes
clean: clean-zmk clean-docker

# Clean all
clean-all: clean clean-firmware

# List build targets
list:
    @just parse-targets all | sed 's/,*$//' | sort

# Draw
draw $keyboard:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Draw '$keyboard'"
    keymap_input_file="{{ dir_config }}/$keyboard.keymap"
    keymap_svg="{{ dir_keymap_drawer }}/$keyboard.svg"
    keymap_png="{{ dir_keymap_drawer }}/$keyboard.png"
    keymap_yaml="{{ dir_keymap_drawer }}/$keyboard.yaml"
    draw_config="{{ dir_config }}/keymap-drawer.yaml"
    keymap -c "$draw_config" parse -z "$keymap_input_file" > "$keymap_yaml"
    keymap -c "$draw_config" draw "$keymap_yaml" > "$keymap_svg"
    inkscape --export-type=png --export-background=white --export-filename="$keymap_png" "$keymap_svg"
