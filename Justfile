default:
    @just --list --unsorted

dir_extra_modules := `pwd`
dir_zmk := `pwd` / "zmk"
dir_config := `pwd` / "config"
dir_firmware := `pwd` / "firmware"
dir_keymap_drawer := `pwd` / "draw"

mount_nice := "/Volumes/NICENANO"
mount_xiao := "/Volumes/XIAO-SENSE"
board_nice := "nice_nano_v2"
board_xiao := "seeeduino_xiao_ble"

image_zmk := "zmkfirmware/zmk-dev-arm:stable"
container := "zmk-codebase"

_docker_opts $task:
    echo "\
        --interactive \
        --tty \
        --name zmk-{{ task }} \
        --workdir /zmk \
        --volume {{ dir_config }}:/zmk-config:Z \
        --volume {{ dir_zmk }}:/zmk:Z \
        --volume {{ dir_extra_modules }}:/boards:Z \
        {{ image_zmk }}"

# Parse build.yaml and filter targets by expression
_parse_targets $expr:
    #!/usr/bin/env bash
    attrs="[.board, .shield, .snippet]"
    filter="(($attrs | map(. // [.])), ((.include // {})[] | $attrs)) | join(\",\")"
    echo "$(yq -r "$filter" build.yaml | grep -v "^," | grep -i "${expr/#all/.*}")"

# Fix firmware file permission
_fix_firmware_permission $artifact:
    #!/usr/bin/env bash
    echo "Fix permissions for $artifact"
    chmod go+wrx {{ dir_firmware }}/$artifact.uf2

# Build firmware for single board & shield combination
_build_single $board $shield $snippet *west_args:
    #!/usr/bin/env bash
    set -euo pipefail
    artifact="${shield:+${shield// /+}-}${board}"

    echo "Building firmware for $artifact..."
    docker run --rm $(just _docker_opts $artifact) \
        west build /zmk/app --pristine -b "${board}" ${snippet:+-S "$snippet"} {{ west_args }} -- \
            ${shield:+-DSHIELD="$shield"} \
            -DZMK_CONFIG="/zmk-config" \
            -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

    echo "Copy $artifact to firmware dir"
    docker cp {{ container }}:/zmk/build/zephyr/zmk.uf2 {{ dir_firmware }}/$artifact.uf2

    just _fix_firmware_permission $artifact

# Init west and docker container
init:
    #!/usr/bin/env bash
    if [ ! -d zmk ]; then
        git clone https://github.com/zmkfirmware/zmk
    fi

    opts=$(just _docker_opts codebase)
    docker run $opts sh -c '\
        west init -l /zmk/app/ --mf /zmk-config/west.yml; \
        west update'

# Update west
update:
    #!/usr/bin/env bash
    opts=$(just _docker_opts update)
    docker run --rm $opts \
        west update --fetch-opt=--filter=blob:none

# Open a shell within the ZMK environment
shell:
    #!/usr/bin/env bash
    opts=$(just _docker_opts codebase)
    docker run --rm $opts /bin/bash

# Build firmware for matching targets
build expr *west_args:
    #!/usr/bin/env bash
    set -euo pipefail
    targets=$(just _parse_targets {{ expr }})

    [[ -z $targets ]] && echo "No matching targets found. Aborting..." >&2 && exit 1
    echo "$targets" | while IFS=, read -r board shield snippet; do
        just _build_single "$board" "$shield" "$snippet" {{ west_args }}
    done

# Flash
flash $board $shield:
    #!/usr/bin/env bash
    set -euo pipefail
    artifact="${shield:+${shield// /+}-}${board}"
    local mount=""
    case "$board" in
        "$board_nice")
            mount=$mount_nice
        ;;
        "$board_xiao")
            mount=$mount_xiao
        ;;
        *)
            echo "Unknown board ${board}"
            exit
        ;;
    esac

    printf "Waiting for ${board} bootloader to appear at ${mount}.."
    while [ ! -d ${mount} ]; do sleep 1; printf "."; done; printf "\n"

    just _fix_firmware_permission $artifact

    echo "Copy ${artifact} to ${mount}"
    cp -av {{ dir_firmware }}/$artifact.uf2 ${mount}

# Clean firmware dir
clean_firmware:
    find firmware/*.uf2 -type f -delete

# Clean zmk dir
clean_zmk:
    if [ -d zmk ]; then rm -rfv zmk; fi

# Clean docker container and volumes
clean_docker:
    docker ps -aq --filter name='^zmk' | xargs -r docker container rm
    docker volume list -q --filter name='zmk' | xargs -r docker volume rm

# Clean zmk and docker container/volumes
clean: clean_zmk clean_docker

# Clean all
clean_all: && clean clean_firmware
    @echo "Cleaning all"

# List build targets
list:
    @just _parse_targets all | sed 's/,*$//' | sort

# Draw
draw $keyboard:
    #!/usr/bin/env bash
    echo "Draw '$keyboard'"
    keymap_input_file="{{ dir_config }}/$keyboard.keymap"
    keymap_svg="{{ dir_keymap_drawer }}/$keyboard.svg"
    keymap_png="{{ dir_keymap_drawer }}/$keyboard.png"
    keymap_yaml="{{ dir_keymap_drawer }}/$keyboard.yaml"
    draw_config="{{ dir_config }}/keymap-drawer.yaml"
    keymap -c "$draw_config" parse -z "$keymap_input_file" > "$keymap_yaml"
    keymap -c "$draw_config" draw "$keymap_yaml" > "$keymap_svg"
    inkscape --export-type=png --export-background=white --export-filename="$keymap_png" "$keymap_svg"
