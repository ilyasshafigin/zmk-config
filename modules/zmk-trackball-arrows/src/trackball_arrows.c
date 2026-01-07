#define DT_DRV_COMPAT zmk_input_processor_trackball_arrows

#include <zephyr/kernel.h>
#include <zephyr/device.h>
#include <drivers/input_processor.h>
#include <zephyr/dt-bindings/input/input-event-codes.h>
#include <dt-bindings/zmk/keys.h>

#include <zephyr/logging/log.h>

LOG_MODULE_DECLARE(zmk, CONFIG_ZMK_LOG_LEVEL);

// Режимы работы
#define MODE_DISCRETE 0
#define MODE_CONTINUOUS 1

struct trackball_arrows_config {
    int16_t threshold;
    int8_t mode;
    int8_t deadzone_x;
    int8_t deadzone_y;
    bool track_remainders;
};

struct trackball_arrows_data {
    int16_t accumulated_x;
    int16_t accumulated_y;
    bool arrow_up_active;
    bool arrow_down_active;
    bool arrow_left_active;
    bool arrow_right_active;
};

// Основная функция обработки события
static int trackball_arrows_handle_event(
    const struct device *dev,
    struct input_event *event,
    uint32_t param1,
    uint32_t param2,
    struct zmk_input_processor_state *state
) {
    const struct trackball_arrows_config *config = dev->config;
    struct trackball_arrows_data *data = dev->data;
    
    if (event->type != INPUT_EV_REL) {
        return 0;
    }
    
    int16_t x = 0, y = 0;
    
    if (event->code == INPUT_REL_X) {
        x = event->value;
    } else if (event->code == INPUT_REL_Y) {
        y = event->value;
    } else {
        return 0;
    }
    
    // Мертвая зона
    if (x > -config->deadzone_x && x < config->deadzone_x) {
        x = 0;
    }
    if (y > -config->deadzone_y && y < config->deadzone_y) {
        y = 0;
    }
    
    if (config->mode == MODE_CONTINUOUS) {
        // Continuous mode - генерируем клавиши пока есть движение
        if (x > config->threshold) {
            if (!data->arrow_right_active) {
                data->arrow_right_active = true;
                event->type = INPUT_EV_KEY;
                event->code = INPUT_KEY_RIGHT;
                event->value = 1;  // press
                return 0;
            }
        } else if (x < -config->threshold) {
            if (!data->arrow_left_active) {
                data->arrow_left_active = true;
                event->type = INPUT_EV_KEY;
                event->code = INPUT_KEY_LEFT;
                event->value = 1;
                return 0;
            }
        }
        
        if (y > config->threshold) {
            if (!data->arrow_down_active) {
                data->arrow_down_active = true;
                event->type = INPUT_EV_KEY;
                event->code = INPUT_KEY_DOWN;
                event->value = 1;
                return 0;
            }
        } else if (y < -config->threshold) {
            if (!data->arrow_up_active) {
                data->arrow_up_active = true;
                event->type = INPUT_EV_KEY;
                event->code = INPUT_KEY_UP;
                event->value = 1;
                return 0;
            }
        }
        
        // Если движение остановилось - отпускаем клавиши
        if (x == 0 && y == 0) {
            if (data->arrow_right_active) {
                data->arrow_right_active = false;
                event->type = INPUT_EV_KEY;
                event->code = INPUT_KEY_RIGHT;
                event->value = 0;  // release
                return 0;
            }
            if (data->arrow_left_active) {
                data->arrow_left_active = false;
                event->type = INPUT_EV_KEY;
                event->code = INPUT_KEY_LEFT;
                event->value = 0;
                return 0;
            }
            if (data->arrow_down_active) {
                data->arrow_down_active = false;
                event->type = INPUT_EV_KEY;
                event->code = INPUT_KEY_DOWN;
                event->value = 0;
                return 0;
            }
            if (data->arrow_up_active) {
                data->arrow_up_active = false;
                event->type = INPUT_EV_KEY;
                event->code = INPUT_KEY_UP;
                event->value = 0;
                return 0;
            }
        }
        
    } else {
        // Discrete mode - аккумулируем и срабатываем по порогу
        data->accumulated_x += x;
        data->accumulated_y += y;
        
        if (data->accumulated_x > config->threshold) {
            event->type = INPUT_EV_KEY;
            event->code = INPUT_KEY_RIGHT;
            event->value = 1;  // press
            data->accumulated_x = 0;
            return 0;
        } else if (data->accumulated_x < -config->threshold) {
            event->type = INPUT_EV_KEY;
            event->code = INPUT_KEY_LEFT;
            event->value = 1;
            data->accumulated_x = 0;
            return 0;
        }
        
        if (data->accumulated_y > config->threshold) {
            event->type = INPUT_EV_KEY;
            event->code = INPUT_KEY_DOWN;
            event->value = 1;
            data->accumulated_y = 0;
            return 0;
        } else if (data->accumulated_y < -config->threshold) {
            event->type = INPUT_EV_KEY;
            event->code = INPUT_KEY_UP;
            event->value = 1;
            data->accumulated_y = 0;
            return 0;
        }
    }
    
    // Подавляем оригинальное движение
    event->type = 0;
    event->code = 0;
    event->value = 0;
    
    return 0;
}

// Инициализация
static int trackball_arrows_init(const struct device *dev) {
    LOG_INF("Trackball to Arrow Keys processor initialized");
    return 0;
}

// API структура
static struct zmk_input_processor_driver_api trackball_arrows_api = {
    .handle_event = trackball_arrows_handle_event,
};

// Макрос для определения конфигурации из devicetree
#define TRACKBALL_ARROWS_INST(n)                                                \
    static const struct trackball_arrows_config trackball_arrows_config_##n = { \
        .threshold = DT_INST_PROP(n, threshold),                                \
        .mode = DT_INST_ENUM_IDX(n, mode),                                      \
        .deadzone_x = DT_INST_PROP(n, deadzone_x),                              \
        .deadzone_y = DT_INST_PROP(n, deadzone_y),                              \
        .track_remainders = DT_INST_PROP(n, track_remainders),                  \
    };                                                                          \
                                                                                \
    static struct trackball_arrows_data trackball_arrows_data_##n;              \
                                                                                \
    DEVICE_DT_INST_DEFINE(n,                                                    \
                         &trackball_arrows_init,                                \
                         NULL,                                                  \
                         &trackball_arrows_data_##n,                            \
                         &trackball_arrows_config_##n,                          \
                         POST_KERNEL,                                           \
                         CONFIG_KERNEL_INIT_PRIORITY_DEFAULT,                   \
                         &trackball_arrows_api);

DT_INST_FOREACH_STATUS_OKAY(TRACKBALL_ARROWS_INST)
