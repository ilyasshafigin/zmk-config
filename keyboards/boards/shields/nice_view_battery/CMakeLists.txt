if(NOT CONFIG_ZMK_SPLIT OR CONFIG_ZMK_SPLIT_ROLE_CENTRAL)
  message(FATAL_ERROR "nice_view_battery supports split peripherals only")
endif()

if(CONFIG_ZMK_DISPLAY AND CONFIG_NICE_VIEW_BATTERY_WIDGET_STATUS)
  zephyr_library_include_directories(${CMAKE_SOURCE_DIR}/include)
  zephyr_library_sources(
    custom_status_screen.c
    assets/bolt.c
    assets/link.c
    assets/link_disconnected.c
    lib/util.c
    widgets/battery.c
    widgets/output.c
    screens/peripheral.c
  )
endif()
