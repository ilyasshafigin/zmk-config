#include <zephyr/kernel.h>
#include "output.h"

LV_IMAGE_DECLARE(link);
LV_IMAGE_DECLARE(link_disconnected);

void draw_output_status(lv_obj_t *canvas, const struct status_state *state) {
    lv_draw_image_dsc_t img_dsc;
    lv_draw_image_dsc_init(&img_dsc);
    canvas_draw_img(canvas, 0, 0, state->connected ? &link : &link_disconnected, &img_dsc);
}
