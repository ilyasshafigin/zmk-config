#include <zephyr/kernel.h>

#include <zephyr/logging/log.h>
LOG_MODULE_DECLARE(zmk, CONFIG_ZMK_LOG_LEVEL);

#include <zmk/event_manager.h>
#include <zmk/events/usb_conn_state_changed.h>
#include <zmk/events/battery_state_changed.h>
#include <zmk/events/split_peripheral_status_changed.h>
#include <zmk/split/bluetooth/peripheral.h>
#include <zmk/display.h>
#include <zmk/usb.h>
#include <zmk/ble.h>
#include <zmk/battery.h>

#include "peripheral.h"
#include "../widgets/output.h"
#include "../widgets/battery.h"

static sys_slist_t widgets = SYS_SLIST_STATIC_INIT(&widgets);

// Draw

static void draw_top(lv_obj_t *widget, uint8_t cbuf[], const struct status_state *state) {
    lv_obj_t *canvas = lv_obj_get_child(widget, 0);
    draw_background(canvas, TOP_SIZE);

    draw_output_status(canvas, state);

    rotate_canvas(canvas, cbuf, TOP_SIZE);
}

static void draw_middle(lv_obj_t *widget, uint8_t charging_cbuf[], const struct status_state *state) {
    lv_obj_t *canvas = lv_obj_get_child(widget, 1);
    draw_battery_status(canvas, state);

    lv_obj_t *charging = lv_obj_get_child(widget, 2);
    draw_charging_status(charging, state);
    rotate_canvas(charging, charging_cbuf, TOP_SIZE);
}

// Battery status

static void set_battery_status(struct zmk_widget_screen *widget,
                               struct battery_status_state state) {
#if IS_ENABLED(CONFIG_USB_DEVICE_STACK)
    widget->state.charging = state.usb_present;
#endif /* IS_ENABLED(CONFIG_USB_DEVICE_STACK) */

    widget->state.battery = state.level;

    draw_middle(widget->obj, widget->charging_cbuf, &widget->state);
}

static void battery_status_update_cb(struct battery_status_state state) {
    struct zmk_widget_screen *widget;
    SYS_SLIST_FOR_EACH_CONTAINER(&widgets, widget, node) { set_battery_status(widget, state); }
}

static struct battery_status_state battery_status_get_state(const zmk_event_t *eh) {
    const struct zmk_battery_state_changed *ev = as_zmk_battery_state_changed(eh);

    return (struct battery_status_state){
        .level = (ev != NULL) ? ev->state_of_charge : zmk_battery_state_of_charge(),
#if IS_ENABLED(CONFIG_USB_DEVICE_STACK)
        .usb_present = zmk_usb_is_powered(),
#endif /* IS_ENABLED(CONFIG_USB_DEVICE_STACK) */
    };
}

ZMK_DISPLAY_WIDGET_LISTENER(widget_battery_status, struct battery_status_state,
                            battery_status_update_cb, battery_status_get_state);

ZMK_SUBSCRIPTION(widget_battery_status, zmk_battery_state_changed);
#if IS_ENABLED(CONFIG_USB_DEVICE_STACK)
ZMK_SUBSCRIPTION(widget_battery_status, zmk_usb_conn_state_changed);
#endif /* IS_ENABLED(CONFIG_USB_DEVICE_STACK) */

// Peripheral status

static struct peripheral_status_state get_state(const zmk_event_t *_eh) {
    return (struct peripheral_status_state){.connected = zmk_split_bt_peripheral_is_connected()};
}

static void set_connection_status(struct zmk_widget_screen *widget,
                                  struct peripheral_status_state state) {
    widget->state.connected = state.connected;

    draw_top(widget->obj, widget->cbuf, &widget->state);
}

static void output_status_update_cb(struct peripheral_status_state state) {
    struct zmk_widget_screen *widget;
    SYS_SLIST_FOR_EACH_CONTAINER(&widgets, widget, node) { set_connection_status(widget, state); }
}

ZMK_DISPLAY_WIDGET_LISTENER(widget_peripheral_status, struct peripheral_status_state,
                            output_status_update_cb, get_state)
ZMK_SUBSCRIPTION(widget_peripheral_status, zmk_split_peripheral_status_changed);

// Initialization

int zmk_widget_screen_init(struct zmk_widget_screen *widget, lv_obj_t *parent) {
    widget->obj = lv_obj_create(parent);
    lv_obj_set_size(widget->obj, 160, 68);
    lv_obj_set_style_bg_color(widget->obj, LVGL_BACKGROUND, LV_PART_MAIN);
    lv_obj_set_style_bg_opa(widget->obj, LV_OPA_COVER, LV_PART_MAIN);

    lv_obj_t *top = lv_canvas_create(widget->obj);
    lv_obj_align(top, LV_ALIGN_TOP_RIGHT, 0, 0);
    lv_canvas_set_buffer(top, widget->cbuf, TOP_SIZE, TOP_SIZE, CANVAS_COLOR_FORMAT);
    lv_canvas_fill_bg(top, LVGL_BACKGROUND, LV_OPA_COVER);

    lv_obj_t *middle = lv_canvas_create(widget->obj);
    lv_obj_align(middle, LV_ALIGN_TOP_LEFT, 8, 0);
    lv_canvas_set_buffer(middle, widget->cbuf2, PERCENT_WIDTH, PERCENT_HEIGHT, CANVAS_COLOR_FORMAT);
    lv_canvas_fill_bg(middle, LVGL_BACKGROUND, LV_OPA_COVER);

    /* Same native rotation as the connection icon: physical bolt starts at (50,5). */
    lv_obj_t *charging = lv_canvas_create(widget->obj);
    lv_obj_align(charging, LV_ALIGN_TOP_RIGHT, 0, 46);
    lv_canvas_set_buffer(charging, widget->charging_cbuf, TOP_SIZE, TOP_SIZE, CANVAS_COLOR_FORMAT);
    lv_canvas_fill_bg(charging, LVGL_BACKGROUND, LV_OPA_COVER);
    battery_renderer_init(widget->obj);

    sys_slist_append(&widgets, &widget->node);
    widget_battery_status_init();
    widget_peripheral_status_init();

    return 0;
}

lv_obj_t *zmk_widget_screen_obj(struct zmk_widget_screen *widget) { return widget->obj; }
