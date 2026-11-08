#pragma once

#include <lvgl.h>
#include <zephyr/kernel.h>

#define CANVAS_SIZE 68
#define TOP_SIZE 22
#define PERCENT_WIDTH 122
#define PERCENT_HEIGHT 68
#define CANVAS_COLOR_FORMAT LV_COLOR_FORMAT_L8
#define L8_BUFFER_SIZE(width, height) \
    LV_CANVAS_BUF_SIZE(width, height, LV_COLOR_FORMAT_GET_BPP(CANVAS_COLOR_FORMAT), LV_DRAW_BUF_STRIDE_ALIGN)
#define CANVAS_BUFFER_SIZE(size) L8_BUFFER_SIZE(size, size)
#define LVGL_BACKGROUND \
    (IS_ENABLED(CONFIG_NICE_VIEW_BATTERY_WIDGET_INVERTED) ? lv_color_black() : lv_color_white())
#define LVGL_FOREGROUND \
    (IS_ENABLED(CONFIG_NICE_VIEW_BATTERY_WIDGET_INVERTED) ? lv_color_white() : lv_color_black())

struct status_state {
    uint8_t battery;
    bool charging;
    bool connected;
};

void rotate_canvas(lv_obj_t *canvas, uint8_t cbuf[], int size);
void draw_background(lv_obj_t *canvas, int size);
void init_rect_dsc(lv_draw_rect_dsc_t *rect_dsc, lv_color_t bg_color);
void init_label_dsc(lv_draw_label_dsc_t *label_dsc, lv_color_t color, const lv_font_t *font,
                    lv_text_align_t align);
void canvas_draw_rect(lv_obj_t *canvas, int32_t x, int32_t y, int32_t w, int32_t h,
                      lv_draw_rect_dsc_t *draw_dsc);
void canvas_draw_text(lv_obj_t *canvas, int32_t x, int32_t y, int32_t max_w,
                      lv_draw_label_dsc_t *draw_dsc, const char *txt);
void canvas_draw_img(lv_obj_t *canvas, int32_t x, int32_t y, const lv_image_dsc_t *src,
                     lv_draw_image_dsc_t *draw_dsc);
