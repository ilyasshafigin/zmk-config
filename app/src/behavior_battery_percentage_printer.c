/*
 * Minimal ZMK behavior: types battery percentage with a label when activated.
 * Uses zmk_battery_state_of_charge().
 *
 */

#define DT_DRV_COMPAT zmk_behavior_battery_percentage_printer

#include <zephyr/kernel.h>
#include <zephyr/device.h>
#include <zephyr/logging/log.h>
#include <drivers/behavior.h>
#include <zmk/behavior.h>
#include <zmk/events/battery_state_changed.h>
#include <zmk/events/keycode_state_changed.h>
#include <zmk/battery.h>
#include <dt-bindings/zmk/keys.h>

#if IS_ENABLED(CONFIG_ZMK_SPLIT_BLE_CENTRAL_BATTERY_LEVEL_FETCHING)
#include <zmk/split/central.h>
#endif // IS_ENABLED(CONFIG_ZMK_SPLIT_BLE_CENTRAL_BATTERY_LEVEL_FETCHING)

LOG_MODULE_DECLARE(zmk, CONFIG_ZMK_LOG_LEVEL);

/* increased buffer to contain prefix + digits + space + percent */
#define MAX_CHARS 32
#define TYPE_DELAY_MS 10

#if DT_HAS_COMPAT_STATUS_OKAY(DT_DRV_COMPAT)

struct behavior_battery_printer_data {
    struct k_work_delayable typing_work;
    uint8_t chars[MAX_CHARS];
    uint8_t chars_len;
    uint8_t current_idx;
    bool key_pressed;
    uint32_t digit_keycodes[10];
    uint32_t space_keycode;
    uint32_t dot_keycode;
    uint32_t percent_keycode;
};

struct behavior_battery_printer_config {
    uint32_t digit_keycodes[10];
    uint32_t space_keycode;
    uint32_t dot_keycode;
    uint32_t percent_keycode;
};

static inline void reset_typing_state(struct behavior_battery_printer_data *data) {
    data->current_idx = 0;
    data->key_pressed = false;
    data->chars_len = 0;
    memset(data->chars, 0, sizeof(data->chars));
}

/* map an ASCII char used in our phrase to an encoded keycode understood by
 * raise_zmk_keycode_state_changed_from_encoded().
 *
 * Supports:
 *  - digits '0'..'9' -> configurable per-device DT property
 *  - letters a..z / A..Z -> letter keycodes (uppercase uses LS(...) to require shift)
 *  - space ' ' -> SPACE
 *  - dot '.' -> DOT
 *  - percent '%' -> PERCENT (macro includes shift)
 */
static uint32_t char_to_encoded_keycode(uint8_t ch, const struct behavior_battery_printer_data *data) {
    /* digits */
    if (ch >= '0' && ch <= '9') {
        return data->digit_keycodes[ch - '0'];
    }

    /* space */
    if (ch == ' ') {
        return data->space_keycode;
    }

    /* dot/period */
    if (ch == '.') {
        return data->dot_keycode;
    }

    /* percent sign (uses define that includes shift) */
    if (ch == '%') {
        return data->percent_keycode;
    }

    return 0;
    // /* letters */
    // /* map lowercase and uppercase by explicit cases to use the key macros defined
    //  * in dt-bindings/zmk/keys.h. For uppercase, wrap with LS(...) so Shift is sent.
    //  *
    //  * Note: LS(...) and letter macros (A, B, C, ...) are available via keys headers.
    //  * If for some reason LS isn't defined in your build, we can instead press/release
    //  * an explicit SHIFT key around the letter; tell me if LS isn't available.
    //  */
    // bool upper = false;
    // if (ch >= 'A' && ch <= 'Z') {
    //     upper = true;
    //     ch = (uint8_t)(ch - 'A' + 'a'); /* normalize to lowercase for switch */
    // }

    // switch (ch) {
    // case 'a':
    //     return upper ? LS(A) : A;
    // case 'b':
    //     return upper ? LS(B) : B;
    // case 'c':
    //     return upper ? LS(C) : C;
    // case 'd':
    //     return upper ? LS(D) : D;
    // case 'e':
    //     return upper ? LS(E) : E;
    // case 'f':
    //     return upper ? LS(F) : F;
    // case 'g':
    //     return upper ? LS(G) : G;
    // case 'h':
    //     return upper ? LS(H) : H;
    // case 'i':
    //     return upper ? LS(I) : I;
    // case 'j':
    //     return upper ? LS(J) : J;
    // case 'k':
    //     return upper ? LS(K) : K;
    // case 'l':
    //     return upper ? LS(L) : L;
    // case 'm':
    //     return upper ? LS(M) : M;
    // case 'n':
    //     return upper ? LS(N) : N;
    // case 'o':
    //     return upper ? LS(O) : O;
    // case 'p':
    //     return upper ? LS(P) : P;
    // case 'q':
    //     return upper ? LS(Q) : Q;
    // case 'r':
    //     return upper ? LS(R) : R;
    // case 's':
    //     return upper ? LS(S) : S;
    // case 't':
    //     return upper ? LS(T) : T;
    // case 'u':
    //     return upper ? LS(U) : U;
    // case 'v':
    //     return upper ? LS(V) : V;
    // case 'w':
    //     return upper ? LS(W) : W;
    // case 'x':
    //     return upper ? LS(X) : X;
    // case 'y':
    //     return upper ? LS(Y) : Y;
    // case 'z':
    //     return upper ? LS(Z) : Z;
    // default:
    //     return 0;
    // }
}

static void send_key(struct behavior_battery_printer_data *data) {
    if (data->current_idx >= data->chars_len || data->current_idx >= ARRAY_SIZE(data->chars)) {
        reset_typing_state(data);
        return;
    }

    uint8_t ch = data->chars[data->current_idx];
    uint32_t keycode = char_to_encoded_keycode(ch, data);
    if (!keycode) {
        LOG_WRN("behavior_battery_printer: unsupported char '%c' (idx %u)", ch, data->current_idx);
        reset_typing_state(data);
        return;
    }

    bool pressed = !data->key_pressed;
    raise_zmk_keycode_state_changed_from_encoded(keycode, pressed, k_uptime_get());
    data->key_pressed = pressed;

    if (pressed) {
        /* schedule release */
        k_work_schedule(&data->typing_work, K_MSEC(TYPE_DELAY_MS));
        return;
    } else {
        /* released -> next char */
        data->current_idx++;
        if (data->current_idx < data->chars_len) {
            k_work_schedule(&data->typing_work, K_MSEC(TYPE_DELAY_MS));
        } else {
            reset_typing_state(data);
        }
    }
}

static void type_keys_work(struct k_work *work) {
    struct k_work_delayable *dwork = CONTAINER_OF(work, struct k_work_delayable, work);
    struct behavior_battery_printer_data *data = CONTAINER_OF(dwork, struct behavior_battery_printer_data, typing_work);
    send_key(data);
}

static int behavior_battery_printer_init(const struct device *dev) {
    struct behavior_battery_printer_data *data = dev->data;
    const struct behavior_battery_printer_config *config = dev->config;
    k_work_init_delayable(&data->typing_work, type_keys_work);
    memcpy(data->digit_keycodes, config->digit_keycodes, sizeof(data->digit_keycodes));
    data->space_keycode = config->space_keycode;
    data->dot_keycode = config->dot_keycode;
    data->percent_keycode = config->percent_keycode;
    reset_typing_state(data);
    return 0;
}

/* convert small uint -> ascii digits (0..999) */
static void uint_to_chars(uint32_t v, uint8_t *buffer, uint8_t *len) {
    char tmp[4];
    int t = 0;
    if (v == 0) {
        buffer[0] = '0';
        *len = 1;
        return;
    }
    while (v > 0 && t < (int)sizeof(tmp)) {
        tmp[t++] = '0' + (v % 10);
        v /= 10;
    }
    for (int i = 0; i < t; i++) {
        buffer[i] = tmp[t - 1 - i];
    }
    *len = t;
}

/* on_pressed: build literal "Level Bat. " + digits + " %" and type it */
static int on_pressed(struct zmk_behavior_binding *binding, struct zmk_behavior_binding_event event) {
    const struct device *dev = zmk_behavior_get_binding(binding->behavior_dev);
    struct behavior_battery_printer_data *data = dev->data;

    if (data->key_pressed || data->current_idx) {
        /* typing in progress, ignore */
        return ZMK_BEHAVIOR_OPAQUE;
    }

    /* read battery percentage (0..100) from ZMK API */
    uint8_t percent = zmk_battery_state_of_charge();

#if IS_ENABLED(CONFIG_ZMK_SPLIT)
#if IS_ENABLED(CONFIG_ZMK_SPLIT_BLE_CENTRAL_BATTERY_LEVEL_FETCHING)
    uint8_t source = event.source;
    if (source != 0xFF) {
        zmk_split_central_get_peripheral_battery_level(source, &percent);
    }
#endif
#endif

    if (percent > 100) percent = 100;

    LOG_INF("behavior_battery_printer: battery SOC read = %u%%", percent);

    reset_typing_state(data);

    /* prefix exactly as requested (capital L and B) */
    // const char *prefix = "Level Bat. ";
    // size_t p = strlen(prefix);

    // /* ensure buffer fits */
    // if (p + 4 + 3 >= ARRAY_SIZE(data->chars)) { /* prefix + up to 3 digits + space + percent */
    //     LOG_ERR("behavior_battery_printer: buffer too small for prefix");
    //     return ZMK_BEHAVIOR_OPAQUE;
    // }

    // /* copy prefix */
    // memcpy(data->chars, prefix, p);
    // data->chars_len = p;

    /* append digits of percent */
    uint8_t digitbuf[4];
    uint8_t digitlen = 0;
    uint_to_chars(percent, digitbuf, &digitlen);
    for (int i = 0; i < digitlen; i++) {
        data->chars[data->chars_len++] = digitbuf[i];
    }

    /* append space and percent sign */
    data->chars[data->chars_len++] = '%';
    data->chars[data->chars_len++] = ' ';

    /* start typing */
    data->current_idx = 0;
    data->key_pressed = false;
    send_key(data);
    return ZMK_BEHAVIOR_OPAQUE;
}

static int on_released(struct zmk_behavior_binding *binding, struct zmk_behavior_binding_event event) {
    return ZMK_BEHAVIOR_OPAQUE;
}

static const struct behavior_driver_api behavior_battery_printer_api = {
    .binding_pressed = on_pressed,
    .binding_released = on_released,
};

#define BAT_INST(idx) \
    static struct behavior_battery_printer_data behavior_battery_printer_data_##idx; \
    static const struct behavior_battery_printer_config behavior_battery_printer_config_##idx = { \
        .digit_keycodes = { \
            DT_INST_PROP_BY_IDX(idx, digit_keycodes, 0), \
            DT_INST_PROP_BY_IDX(idx, digit_keycodes, 1), \
            DT_INST_PROP_BY_IDX(idx, digit_keycodes, 2), \
            DT_INST_PROP_BY_IDX(idx, digit_keycodes, 3), \
            DT_INST_PROP_BY_IDX(idx, digit_keycodes, 4), \
            DT_INST_PROP_BY_IDX(idx, digit_keycodes, 5), \
            DT_INST_PROP_BY_IDX(idx, digit_keycodes, 6), \
            DT_INST_PROP_BY_IDX(idx, digit_keycodes, 7), \
            DT_INST_PROP_BY_IDX(idx, digit_keycodes, 8), \
            DT_INST_PROP_BY_IDX(idx, digit_keycodes, 9), \
        }, \
        .space_keycode = DT_INST_PROP(idx, space_keycode), \
        .dot_keycode = DT_INST_PROP(idx, dot_keycode), \
        .percent_keycode = DT_INST_PROP(idx, percent_keycode), \
    }; \
    BEHAVIOR_DT_INST_DEFINE(idx, behavior_battery_printer_init, NULL, \
                            &behavior_battery_printer_data_##idx, \
                            &behavior_battery_printer_config_##idx, \
                            POST_KERNEL, CONFIG_KERNEL_INIT_PRIORITY_DEFAULT, \
                            &behavior_battery_printer_api);

DT_INST_FOREACH_STATUS_OKAY(BAT_INST)


#if IS_ENABLED(CONFIG_ZMK_SPLIT)
#if IS_ENABLED(CONFIG_ZMK_SPLIT_BLE_CENTRAL_BATTERY_LEVEL_FETCHING)

static int bapp_peripheral_batt_lvl_listener(const zmk_event_t *eh) {
    const struct zmk_peripheral_battery_state_changed *ev =
        as_zmk_peripheral_battery_state_changed(eh);
    if (ev == NULL) {
        return ZMK_EV_EVENT_BUBBLE;
    }
    LOG_DBG("batt_lvl_ev soruce: %d state_of_charge: %d", ev->source, ev->state_of_charge);
    return ZMK_EV_EVENT_BUBBLE;
};

ZMK_LISTENER(bapp_peripheral_batt_lvl_listener, bapp_peripheral_batt_lvl_listener);
ZMK_SUBSCRIPTION(bapp_peripheral_batt_lvl_listener, zmk_peripheral_battery_state_changed);

#endif
#endif


#endif /* DT_HAS_COMPAT_STATUS_OKAY(DT_DRV_COMPAT) */
