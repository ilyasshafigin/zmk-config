#include <zephyr/kernel.h>
#include <stdio.h>
#include "battery.h"
#include "battery_fit.h"

#define SOURCE_WIDTH 160
#define SOURCE_HEIGHT 64

LV_IMAGE_DECLARE(bolt);

/* Shared only by display-work-queue callbacks, never by event producers. */
static uint8_t source_cbuf[L8_BUFFER_SIZE(SOURCE_WIDTH, SOURCE_HEIGHT)]
    __attribute__((aligned(LV_DRAW_BUF_ALIGN)));
static lv_obj_t *source_canvas;

void battery_renderer_init(lv_obj_t *parent) {
    if (source_canvas != NULL) {
        return;
    }
    source_canvas = lv_canvas_create(parent);
    lv_canvas_set_buffer(source_canvas, source_cbuf, SOURCE_WIDTH, SOURCE_HEIGHT, CANVAS_COLOR_FORMAT);
    /* Hidden objects still support explicit canvas draw layers; no on-screen source label. */
    lv_obj_add_flag(source_canvas, LV_OBJ_FLAG_HIDDEN);
}

void draw_battery_status(lv_obj_t *canvas, const struct status_state *state) {
    char text[5];
    snprintf(text, sizeof(text), "%u%%", (unsigned int)MIN(state->battery, 100));
    lv_canvas_fill_bg(source_canvas, LVGL_BACKGROUND, LV_OPA_COVER);
    lv_draw_label_dsc_t label_dsc;
    init_label_dsc(&label_dsc, LVGL_FOREGROUND, &lv_font_montserrat_48, LV_TEXT_ALIGN_LEFT);
    /* canvas_draw_text completes the draw layer before scanning the actual native glyph ink. */
    canvas_draw_text(source_canvas, 0, 0, SOURCE_WIDTH, &label_dsc, text);

    const lv_draw_buf_t *source = lv_canvas_get_draw_buf(source_canvas);
    lv_draw_buf_t *target = lv_canvas_get_draw_buf(canvas);
    const bool foreground_white = IS_ENABLED(CONFIG_NICE_VIEW_BATTERY_WIDGET_INVERTED);
    struct battery_ink_box box;
    const bool has_ink = battery_find_ink(source->data, SOURCE_WIDTH, SOURCE_HEIGHT,
                                         source->header.stride, foreground_white, &box);
    battery_fit_ink(source->data, source->header.stride, has_ink ? &box : NULL,
                    target->data, target->header.w, target->header.h, target->header.stride,
                    IS_ENABLED(CONFIG_NICE_VIEW_BATTERY_PERCENT_ROTATE_180), foreground_white);
    lv_obj_invalidate(canvas);
}

void draw_charging_status(lv_obj_t *canvas, const struct status_state *state) {
    lv_canvas_fill_bg(canvas, LVGL_BACKGROUND, LV_OPA_COVER);
    if (state->charging) {
        lv_draw_image_dsc_t img_dsc;
        lv_draw_image_dsc_init(&img_dsc);
        canvas_draw_img(canvas, 4, 5, &bolt, &img_dsc);
    }
}
