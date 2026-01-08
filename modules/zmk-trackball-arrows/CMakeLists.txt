if ((NOT CONFIG_ZMK_SPLIT) OR CONFIG_ZMK_SPLIT_ROLE_CENTRAL)
    target_include_directories(app PRIVATE dts)
    target_sources_ifdef(CONFIG_ZMK_INPUT_PROCESSOR_TRACKBALL_ARROWS app PRIVATE src/trackball_arrows.c)
endif()
