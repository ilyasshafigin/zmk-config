#pragma once

#include "../lib/util.h"

struct peripheral_status_state {
    bool connected;
};

void draw_output_status(lv_obj_t *canvas, const struct status_state *state);
