### config
extra_modules_dir=${PWD}
extra_modules= -DZMK_EXTRA_MODULES="/boards"
config=${PWD}/config
keymap_drawer=${PWD}/keymap-drawer
nice_mount=/Volumes/NICENANO
xiao_mount=/Volumes/XIAO-SENSE
zmk_image=zmkfirmware/zmk-dev-arm:stable
nice=nice_nano_v2
xiao=seeeduino_xiao_ble
container=zmk-codebase
docker_opts= \
	--interactive \
	--tty \
	--name zmk-$@ \
	--workdir /zmk \
	--volume "${config}:/zmk-config:Z" \
	--volume "${PWD}/zmk:/zmk:Z" \
	--volume "${extra_modules_dir}:/boards:Z" \
	${zmk_image}

clone_zmk:
	if [ ! -d zmk ]; then git clone https://github.com/zmkfirmware/zmk; fi

codebase: clone_zmk
	docker run ${docker_opts} sh -c '\
		west init -l /zmk/app/; \
		west update'

### name
keyboard_name_nice= '-DCONFIG_ZMK_KEYBOARD_NAME="Nice_Corne_View"'
keyboard_name_nice_dongle= '-DCONFIG_ZMK_KEYBOARD_NAME="Nice_Dongle"'
keyboard_name_xiao_dongle= '-DCONFIG_ZMK_KEYBOARD_NAME="Xiao_Dongle"'

### west
west_built_nice= \
		west build /zmk/app --pristine --board "${nice}"

west_built_xiao= \
		west build /zmk/app --pristine --board "${xiao}"

### shields
shield_settings_reset= \
		-- -DSHIELD="settings_reset" -DZMK_CONFIG="/zmk-config"
shield_corne_central_dongle= \
		-- -DSHIELD="corne_central_dongle" -DZMK_CONFIG="/zmk-config"
shield_corne_central_left= \
		-- -DSHIELD="corne_central_left" -DZMK_CONFIG="/zmk-config"
shield_corne_peripheral_left= \
		-- -DSHIELD="corne_peripheral_left" -DZMK_CONFIG="/zmk-config"
shield_corne_peripheral_right= \
		-- -DSHIELD="corne_peripheral_right" -DZMK_CONFIG="/zmk-config"

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
		${west_built_nice} ${shield_settings_reset}
	docker cp ${container}:${uf2_copy_nice_settings_reset}
	${uf2_chmod_nice_settings_reset}
build_nice_corne_central_dongle:
	docker run --rm ${docker_opts} \
		${west_built_nice} ${shield_corne_central_dongle} \
		${keyboard_name_nice_dongle} ${extra_modules}
	docker cp ${container}:${uf2_copy_nice_corne_central_dongle}
	${uf2_chmod_nice_corne_central_dongle}
build_nice_corne_central_left:
	docker run --rm ${docker_opts} \
		${west_built_nice} ${shield_corne_central_left} \
		${keyboard_name_nice} ${extra_modules}
	docker cp ${container}:${uf2_copy_nice_corne_central_left}
	${uf2_chmod_nice_corne_central_left}
build_nice_corne_peripheral_left:
	docker run --rm ${docker_opts} \
		${west_built_nice} ${shield_corne_peripheral_left} \
		${keyboard_name_nice} ${extra_modules}
	docker cp ${container}:${uf2_copy_nice_corne_peripheral_left}
	${uf2_chmod_nice_corne_peripheral_left}
build_nice_corne_peripheral_right:
	docker run --rm ${docker_opts} \
		${west_built_nice} ${shield_corne_peripheral_right} \
		${keyboard_name_nice} ${extra_modules}
	docker cp ${container}:${uf2_copy_nice_corne_peripheral_right}
	${uf2_chmod_nice_corne_peripheral_right}
build_xiao_settings_reset:
	docker run --rm ${docker_opts} \
		${west_built_xiao} ${shield_settings_reset}
	docker cp ${container}:${uf2_copy_xiao_settings_reset}
	${uf2_chmod_xiao_settings_reset}
build_xiao_corne_central_dongle:
	docker run --rm ${docker_opts} \
		${west_built_xiao} ${shield_corne_central_dongle} \
		${keyboard_name_xiao_dongle} ${extra_modules}
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
	@ printf "Waiting for ${nice} bootloader to appear at ${nice_mount}.."
	@ while [ ! -d ${nice_mount} ]; do sleep 1; printf "."; done; printf "\n"
	cp -av firmware/nice_corne_central_dongle.uf2 ${nice_mount}

flash_nice_corne_central_left:
	@ printf "Waiting for ${nice} bootloader to appear at ${nice_mount}.."
	@ while [ ! -d ${nice_mount} ]; do sleep 1; printf "."; done; printf "\n"
	cp -av firmware/nice_corne_central_left.uf2 ${nice_mount}

flash_nice_corne_left:
	@ printf "Waiting for ${nice} bootloader to appear at ${nice_mount}.."
	@ while [ ! -d ${nice_mount} ]; do sleep 1; printf "."; done; printf "\n"
	cp -av firmware/nice_corne_peripheral_left.uf2 ${nice_mount}

flash_nice_corne_right:
	@ printf "Waiting for ${nice} bootloader to appear at ${nice_mount}.."
	@ while [ ! -d ${nice_mount} ]; do sleep 1; printf "."; done; printf "\n"
	cp -av firmware/nice_corne_peripheral_right.uf2 ${nice_mount}

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
	keymap_input_file="${config}/$$keymap.keymap"; \
	keymap_svg="${keymap_drawer}/$$keymap.svg"; \
	keymap_yaml="${keymap_drawer}/$$keymap.yaml"; \
	draw_config="${keymap_drawer}/config.yaml"; \
	keymap -c "$$draw_config" parse -z "$$keymap_input_file" > "$$keymap_yaml"; \
	keymap -c "$$draw_config" draw "$$keymap_yaml" > "$$keymap_svg"

# vim: set ft=make fdm=marker:
