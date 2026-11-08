#pragma once

#include <lvgl.h>
#include <zephyr/kernel.h>
#include "../lib/util.h"

struct zmk_widget_screen {
    sys_snode_t node;
    lv_obj_t *obj;
    uint8_t cbuf[CANVAS_BUFFER_SIZE(TOP_SIZE)] __attribute__((aligned(LV_DRAW_BUF_ALIGN)));
    uint8_t cbuf2[L8_BUFFER_SIZE(PERCENT_WIDTH, PERCENT_HEIGHT)] __attribute__((aligned(LV_DRAW_BUF_ALIGN)));
    uint8_t charging_cbuf[CANVAS_BUFFER_SIZE(TOP_SIZE)] __attribute__((aligned(LV_DRAW_BUF_ALIGN)));
    struct status_state state;
};

int zmk_widget_screen_init(struct zmk_widget_screen *widget, lv_obj_t *parent);
lv_obj_t *zmk_widget_screen_obj(struct zmk_widget_screen *widget);
