#define DT_DRV_COMPAT zmk_input_processor_trackball_arrows

#include <drivers/input_processor.h>
#include <dt-bindings/zmk/keys.h>
#include <zephyr/kernel.h>
#include <zephyr/device.h>
#include <zephyr/dt-bindings/input/input-event-codes.h>
#include <zmk/behavior.h>
#include <zmk/keymap.h>
#include <zmk/virtual_key_position.h>
#include <stdlib.h>  // abs()

#include <zephyr/logging/log.h>

LOG_MODULE_DECLARE(zmk, CONFIG_ZMK_LOG_LEVEL);

struct trackball_arrows_config {
    uint8_t index;
    int16_t threshold;
    int8_t deadzone_x;
    int8_t deadzone_y;

    // 0:left 1:right 2:up 3:down
    const struct zmk_behavior_binding *bindings;
};

struct trackball_arrows_data {
    int16_t accumulated_x;
    int16_t accumulated_y;
};

static int trackball_arrows_handle_event(
    const struct device *dev,
    struct input_event *event,
    uint32_t param1,
    uint32_t param2,
    struct zmk_input_processor_state *state
) {
    const struct trackball_arrows_config *config = dev->config;
    struct trackball_arrows_data *data = dev->data;

    LOG_DBG("handle event: type=%d code=%d val=%d", event->type, event->code, event->value);
    
    if (event->type != INPUT_EV_REL) {
        return ZMK_INPUT_PROC_STOP;
    }

    int16_t dx = 0, dy = 0;
    if (event->code == INPUT_REL_X) {
        dx = event->value;
    } else if (event->code == INPUT_REL_Y) {
        dy = event->value;
    } else {
        event->type = 0;
        event->code = 0;
        event->value = 0;

        return ZMK_INPUT_PROC_STOP;
    }
    
    if (abs(dx) < config->deadzone_x) dx = 0;
    if (abs(dy) < config->deadzone_y) dy = 0;
    
    data->accumulated_x += dx;
    data->accumulated_y += dy;

    if (abs(data->accumulated_x) >= config->threshold || abs(data->accumulated_y) >= config->threshold) {
        uint8_t binding_index = -1;
        if (data->accumulated_x <= -config->threshold) {
            binding_index = 0;
            data->accumulated_x = 0;
            LOG_DBG("key -> LEFT");
        } else if (data->accumulated_x >= config->threshold) {
            binding_index = 1;
            data->accumulated_x = 0;
            LOG_DBG("key -> RIGHT");
        } else if (data->accumulated_y <= -config->threshold) {
            binding_index = 2;
            data->accumulated_y = 0;
            LOG_DBG("key -> UP");
        } else if (data->accumulated_y >= config->threshold) {
            binding_index = 3;
            data->accumulated_y = 0;
            LOG_DBG("key -> DOWN");
        }

        if (binding_index != -1) {
            struct zmk_behavior_binding_event behavior_event = {
                .position = ZMK_VIRTUAL_KEY_POSITION_BEHAVIOR_INPUT_PROCESSOR(state->input_device_index, config->index),
                .timestamp = k_uptime_get(),
#if IS_ENABLED(CONFIG_ZMK_SPLIT)
                .source = ZMK_POSITION_STATE_CHANGE_SOURCE_LOCAL,
#endif
            };

            int ret;

            // press
            ret = zmk_behavior_invoke_binding(&config->bindings[binding_index], behavior_event, 1);
            if (ret < 0) return ret;

            // release
            ret = zmk_behavior_invoke_binding(&config->bindings[binding_index], behavior_event, 0);
            if (ret < 0) return ret;
        }
    }

    event->type = 0;
    event->code = 0;
    event->value = 0;
    
    return ZMK_INPUT_PROC_STOP;
}

static int trackball_arrows_init(const struct device *dev) {
    LOG_INF("processor initialized");
    return 0;
}

static struct zmk_input_processor_driver_api trackball_arrows_api = {
    .handle_event = trackball_arrows_handle_event,
};

#define TRACKBALL_ARROWS_INST(n)                                                                        \
    static const struct zmk_behavior_binding trackball_arrows_bindings_##n[] = {                        \
        LISTIFY(DT_INST_PROP_LEN(n, bindings), ZMK_KEYMAP_EXTRACT_BINDING, (, ), DT_DRV_INST(n))};      \
    BUILD_ASSERT(ARRAY_SIZE(trackball_arrows_bindings_##n) == 4, "bindings count must be equal to 4");  \
    static const struct trackball_arrows_config trackball_arrows_config_##n = {                         \
        .index = n,                                                                                     \
        .threshold = DT_INST_PROP(n, threshold),                                                        \
        .deadzone_x = DT_INST_PROP(n, deadzone_x),                                                      \
        .deadzone_y = DT_INST_PROP(n, deadzone_y),                                                      \
        .bindings = trackball_arrows_bindings_##n,                                                      \
    };                                                                                                  \
                                                                                                        \
    static struct trackball_arrows_data trackball_arrows_data_##n;                                      \
                                                                                                        \
    DEVICE_DT_INST_DEFINE(n,                                                                            \
                         &trackball_arrows_init,                                                        \
                         NULL,                                                                          \
                         &trackball_arrows_data_##n,                                                    \
                         &trackball_arrows_config_##n,                                                  \
                         POST_KERNEL,                                                                   \
                         CONFIG_KERNEL_INIT_PRIORITY_DEFAULT,                                           \
                         &trackball_arrows_api);

DT_INST_FOREACH_STATUS_OKAY(TRACKBALL_ARROWS_INST)
