### config
dir_extra_modules=${PWD}
dir_zmk=${PWD}/zmk
dir_config=${PWD}/config
dir_keymap_drawer=${PWD}/draw

arg_zmk_extra_modules=-DZMK_EXTRA_MODULES="/boards"
arg_zmk_config=-DZMK_CONFIG="/zmk-config"
arg_cmake_export_commands=-DCMAKE_EXPORT_COMPILE_COMMANDS=ON

mount_nice=/Volumes/NICENANO
mount_xiao=/Volumes/XIAO-SENSE
board_nice=nice_nano_v2
board_xiao=seeeduino_xiao_ble

zmk_image=zmkfirmware/zmk-dev-arm:stable
container=zmk-codebase
docker_opts= \
	--interactive \
	--tty \
	--name zmk-$@ \
	--workdir /zmk \
	--volume "${dir_config}:/zmk-config:Z" \
	--volume "${dir_zmk}:/zmk:Z" \
	--volume "${dir_extra_modules}:/boards:Z" \
	${zmk_image}

clone_zmk:
	if [ ! -d zmk ]; then git clone https://github.com/zmkfirmware/zmk; fi

codebase: clone_zmk
	docker run ${docker_opts} sh -c '\
		west init -l /zmk/app/ --mf /zmk-config/west.yml; \
		west update'

### west
west_built_nice= \
		west build /zmk/app --pristine --board "${board_nice}"

west_built_xiao= \
		west build /zmk/app --pristine --board "${board_xiao}"

### args
args_nice_corne_central=#'-DCONFIG_ZMK_KEYBOARD_NAME="NiceCorne"'
args_nice_corne_dongle=#'-DCONFIG_ZMK_KEYBOARD_NAME="NiceCorneDongle"' -DCONFIG_ZMK_SLEEP=n
args_xiao_corne_dongle=#'-DCONFIG_ZMK_KEYBOARD_NAME="XiaoCorneDongle"' -DCONFIG_ZMK_SLEEP=n

### shields
arg_shield_settings_reset=-DSHIELD="settings_reset"
arg_shield_corne_central_dongle=-DSHIELD="corne_central_dongle"
arg_shield_corne_central_left=-DSHIELD="corne_central_left"
arg_shield_corne_peripheral_left=-DSHIELD="corne_peripheral_left"
arg_shield_corne_peripheral_right=-DSHIELD="corne_peripheral_right"

### uf2
uf2_copy_nice_settings_reset=/zmk/build/zephyr/zmk.uf2 firmware/nice_settings_reset.uf2
uf2_copy_nice_corne_central_dongle=/zmk/build/zephyr/zmk.uf2 firmware/nice_corne_central_dongle.uf2
uf2_copy_nice_corne_central_left=/zmk/build/zephyr/zmk.uf2 firmware/nice_corne_central_left.uf2
uf2_copy_nice_corne_peripheral_left=/zmk/build/zephyr/zmk.uf2 firmware/nice_corne_peripheral_left.uf2
uf2_copy_nice_corne_peripheral_right=/zmk/build/zephyr/zmk.uf2 firmware/nice_corne_peripheral_right.uf2
uf2_copy_xiao_settings_reset=/zmk/build/zephyr/zmk.uf2 firmware/xiao_settings_reset.uf2
uf2_copy_xiao_corne_central_dongle=/zmk/build/zephyr/zmk.uf2 firmware/xiao_corne_central_dongle.uf2

### chmod
uf2_chmod_nice_settings_reset=chmod go+wrx firmware/nice_settings_reset.uf2
uf2_chmod_nice_corne_central_dongle=chmod go+wrx firmware/nice_corne_central_dongle.uf2
uf2_chmod_nice_corne_central_left=chmod go+wrx firmware/nice_corne_central_left.uf2
uf2_chmod_nice_corne_peripheral_left=chmod go+wrx firmware/nice_corne_peripheral_left.uf2
uf2_chmod_nice_corne_peripheral_right=chmod go+wrx firmware/nice_corne_peripheral_right.uf2
uf2_chmod_xiao_settings_reset=chmod go+wrx firmware/xiao_settings_reset.uf2
uf2_chmod_xiao_corne_central_dongle=chmod go+wrx firmware/xiao_corne_central_dongle.uf2

### build
build_nice_settings_reset:
	docker run --rm ${docker_opts} \
		${west_built_nice} -- ${arg_shield_settings_reset} ${arg_zmk_config} ${arg_cmake_export_commands}
	docker cp ${container}:${uf2_copy_nice_settings_reset}
	${uf2_chmod_nice_settings_reset}
build_nice_corne_central_dongle:
	docker run --rm ${docker_opts} \
		${west_built_nice} -- ${arg_shield_corne_central_dongle} ${arg_zmk_config} ${arg_cmake_export_commands} \
		${args_nice_corne_dongle} ${arg_zmk_extra_modules}
	docker cp ${container}:${uf2_copy_nice_corne_central_dongle}
	${uf2_chmod_nice_corne_central_dongle}
build_nice_corne_central_left:
	docker run --rm ${docker_opts} \
		${west_built_nice} -- ${arg_shield_corne_central_left} ${arg_zmk_config} ${arg_cmake_export_commands} \
		${args_nice_corne_central} ${arg_zmk_extra_modules}
	docker cp ${container}:${uf2_copy_nice_corne_central_left}
	${uf2_chmod_nice_corne_central_left}
build_nice_corne_peripheral_left:
	docker run --rm ${docker_opts} \
		${west_built_nice} -- ${arg_shield_corne_peripheral_left} ${arg_zmk_config} ${arg_cmake_export_commands} \
		${arg_zmk_extra_modules}
	docker cp ${container}:${uf2_copy_nice_corne_peripheral_left}
	${uf2_chmod_nice_corne_peripheral_left}
build_nice_corne_peripheral_right:
	docker run --rm ${docker_opts} \
		${west_built_nice} -- ${arg_shield_corne_peripheral_right} ${arg_zmk_config} ${arg_cmake_export_commands} \
		${arg_zmk_extra_modules}
	docker cp ${container}:${uf2_copy_nice_corne_peripheral_right}
	${uf2_chmod_nice_corne_peripheral_right}
build_xiao_settings_reset:
	docker run --rm ${docker_opts} \
		${west_built_xiao} -- ${arg_shield_settings_reset} ${arg_zmk_config} ${arg_cmake_export_commands}
	docker cp ${container}:${uf2_copy_xiao_settings_reset}
	${uf2_chmod_xiao_settings_reset}
build_xiao_corne_central_dongle:
	docker run --rm ${docker_opts} \
		${west_built_xiao} -- ${arg_shield_corne_central_dongle} ${arg_zmk_config} ${arg_cmake_export_commands} \
		${args_xiao_corne_dongle} ${arg_zmk_extra_modules}
	docker cp ${container}:${uf2_copy_xiao_corne_central_dongle}
	${uf2_chmod_xiao_corne_central_dongle}

build_settings_reset: build_nice_settings_reset build_xiao_settings_reset
build_corne_central_dongle: build_nice_corne_central_dongle build_xiao_corne_central_dongle
build_corne_left: build_nice_corne_central_left build_nice_corne_peripheral_left
build_corne_right: build_nice_corne_peripheral_right
build_corne: build_settings_reset \
	build_corne_central_dongle \
	build_corne_left \
	build_corne_right

# Open a shell within the ZMK environment
shell:
	docker run --rm ${docker_opts} /bin/bash

# flash
flash_nice_corne_central_dongle:
	@ printf "Waiting for ${board_nice} bootloader to appear at ${mount_nice}.."
	@ while [ ! -d ${mount_nice} ]; do sleep 1; printf "."; done; printf "\n"
	cp -av firmware/nice_corne_central_dongle.uf2 ${mount_nice}

flash_nice_corne_central_left:
	@ printf "Waiting for ${board_nice} bootloader to appear at ${mount_nice}.."
	@ while [ ! -d ${mount_nice} ]; do sleep 1; printf "."; done; printf "\n"
	cp -av firmware/nice_corne_central_left.uf2 ${mount_nice}

flash_nice_corne_left:
	@ printf "Waiting for ${board_nice} bootloader to appear at ${mount_nice}.."
	@ while [ ! -d ${mount_nice} ]; do sleep 1; printf "."; done; printf "\n"
	cp -av firmware/nice_corne_peripheral_left.uf2 ${mount_nice}

flash_nice_corne_right:
	@ printf "Waiting for ${board_nice} bootloader to appear at ${mount_nice}.."
	@ while [ ! -d ${mount_nice} ]; do sleep 1; printf "."; done; printf "\n"
	cp -av firmware/nice_corne_peripheral_right.uf2 ${mount_nice}

# Clean
clean_firmware:
	find firmware/*.uf2 -type f -delete

clean_zmk:
	if [ -d zmk ]; then rm -rfv zmk; fi

clean: clean_zmk
	docker ps -aq --filter name='^zmk' | xargs -r docker container rm
	docker volume list -q --filter name='zmk' | xargs -r docker volume rm

clean_all: clean clean_firmware
	@echo "cleaning all"

# Draw
draw_corne:
	keymap="corne"; \
	keymap_input_file="${dir_config}/$$keymap.keymap"; \
	keymap_svg="${dir_keymap_drawer}/$$keymap.svg"; \
	keymap_png="${dir_keymap_drawer}/$$keymap.png"; \
	keymap_yaml="${dir_keymap_drawer}/$$keymap.yaml"; \
	draw_config="${dir_config}/keymap-drawer.yaml"; \
	keymap -c "$$draw_config" parse -z "$$keymap_input_file" > "$$keymap_yaml"; \
	keymap -c "$$draw_config" draw "$$keymap_yaml" > "$$keymap_svg"
#	inkscape --export-type png --export-filename $$keymap_png --export-dpi 300 --export-background=white $$keymap_svg

# vim: set ft=make fdm=marker:
