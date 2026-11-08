#pragma once

#include <stdbool.h>
#include <stdint.h>
#include <string.h>

/* Pure L8 pixel operations; all canvas widths/heights are independent of byte stride. */
struct battery_ink_box {
    int x;
    int y;
    int width;
    int height;
};

static inline bool battery_pixel_is_ink(uint8_t pixel, bool foreground_white) {
    return (pixel > 127) == foreground_white;
}

static inline bool battery_find_ink(const uint8_t *src, int width, int height, uint32_t stride,
                                   bool foreground_white, struct battery_ink_box *box) {
    int min_x = width, min_y = height, max_x = -1, max_y = -1;
    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            if (!battery_pixel_is_ink(src[y * stride + x], foreground_white)) {
                continue;
            }
            if (x < min_x) min_x = x;
            if (y < min_y) min_y = y;
            if (x > max_x) max_x = x;
            if (y > max_y) max_y = y;
        }
    }
    if (max_x < 0) {
        return false;
    }
    *box = (struct battery_ink_box){min_x, min_y, max_x - min_x + 1, max_y - min_y + 1};
    return true;
}

static inline void battery_fit_ink(const uint8_t *src, uint32_t src_stride,
                                   const struct battery_ink_box *box, uint8_t *dst,
                                   int width, int height, uint32_t dst_stride,
                                   bool rotate_180, bool foreground_white) {
    const uint8_t background = foreground_white ? 0 : 255;
    const uint8_t foreground = foreground_white ? 255 : 0;
    /* Clear padding as well as pixels on every render, including smaller following values. */
    memset(dst, background, dst_stride * height);
    if (box == NULL || box->width <= 0 || box->height <= 0) {
        return;
    }

    /* One rational scale, not independent width/height stretches. */
    int numerator, denominator;
    if (width * box->height <= height * box->width) {
        numerator = width;
        denominator = box->width;
    } else {
        numerator = height;
        denominator = box->height;
    }
    const int scaled_w = box->width * numerator / denominator;
    const int scaled_h = box->height * numerator / denominator;
    /* Raw X runs opposite physical Y: choose the odd remainder on the raw-left side. */
    const int offset_x = width - scaled_w - (width - scaled_w) / 2;
    const int offset_y = (height - scaled_h) / 2;
    for (int y = 0; y < scaled_h; y++) {
        const int sy = box->y + (2 * y + 1) * denominator / (2 * numerator);
        for (int x = 0; x < scaled_w; x++) {
            const int sx = box->x + (2 * x + 1) * denominator / (2 * numerator);
            const int dx = offset_x + (rotate_180 ? scaled_w - 1 - x : x);
            const int dy = offset_y + (rotate_180 ? scaled_h - 1 - y : y);
            dst[dy * dst_stride + dx] = battery_pixel_is_ink(src[sy * src_stride + sx], foreground_white)
                                          ? foreground : background;
        }
    }
}
