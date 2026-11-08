#include <zephyr/kernel.h>
#include <string.h>
#include "util.h"

void rotate_canvas(lv_obj_t *canvas, uint8_t cbuf[], int size) {
    static uint8_t scratch[CANVAS_BUFFER_SIZE(CANVAS_SIZE)] __attribute__((aligned(LV_DRAW_BUF_ALIGN)));
    const uint32_t stride = lv_draw_buf_width_to_stride(size, CANVAS_COLOR_FORMAT);
    memcpy(scratch, cbuf, stride * size);

    /* LVGL 8 angle 900, pivot (size/2,size/2), offset (-1,0) samples
     * src(y,size-1-x) for each destination (x,y). LVGL 9 calls this 270. */
    lv_draw_sw_rotate(scratch, cbuf, size, size, stride, stride,
                      LV_DISPLAY_ROTATION_270, CANVAS_COLOR_FORMAT);
    lv_obj_invalidate(canvas);
}

void draw_background(lv_obj_t *canvas, int size) {
    lv_draw_rect_dsc_t rect_dsc;
    init_rect_dsc(&rect_dsc, LVGL_BACKGROUND);
    canvas_draw_rect(canvas, 0, 0, size, size, &rect_dsc);
}

void init_label_dsc(lv_draw_label_dsc_t *label_dsc, lv_color_t color, const lv_font_t *font,
                    lv_text_align_t align) {
    lv_draw_label_dsc_init(label_dsc);
    label_dsc->color = color;
    label_dsc->font = font;
    label_dsc->align = align;
}

void init_rect_dsc(lv_draw_rect_dsc_t *rect_dsc, lv_color_t bg_color) {
    lv_draw_rect_dsc_init(rect_dsc);
    rect_dsc->bg_color = bg_color;
}

void canvas_draw_rect(lv_obj_t *canvas, int32_t x, int32_t y, int32_t w, int32_t h,
                      lv_draw_rect_dsc_t *draw_dsc) {
    if (w <= 0 || h <= 0) {
        return;
    }
    lv_layer_t layer;
    lv_canvas_init_layer(canvas, &layer);
    lv_area_t coords = {x, y, x + w - 1, y + h - 1};
    lv_draw_rect(&layer, draw_dsc, &coords);
    lv_canvas_finish_layer(canvas, &layer);
}

void canvas_draw_text(lv_obj_t *canvas, int32_t x, int32_t y, int32_t max_w,
                      lv_draw_label_dsc_t *draw_dsc, const char *txt) {
    lv_layer_t layer;
    lv_canvas_init_layer(canvas, &layer);
    draw_dsc->text = txt;
    /* Match LVGL 8 canvas text bounds, including the canvas's bottom edge. */
    lv_area_t coords = {x, y, x + max_w - 1, lv_canvas_get_draw_buf(canvas)->header.h - 1};
    lv_draw_label(&layer, draw_dsc, &coords);
    lv_canvas_finish_layer(canvas, &layer);
}

void canvas_draw_img(lv_obj_t *canvas, int32_t x, int32_t y, const lv_image_dsc_t *src,
                     lv_draw_image_dsc_t *draw_dsc) {
    lv_layer_t layer;
    lv_canvas_init_layer(canvas, &layer);
    draw_dsc->src = src;
    lv_area_t coords = {x, y, x + src->header.w - 1, y + src->header.h - 1};
    lv_draw_image(&layer, draw_dsc, &coords);
    lv_canvas_finish_layer(canvas, &layer);
}
