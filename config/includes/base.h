// ZMK Core Includes
#include <behaviors.dtsi>
#include <dt-bindings/zmk/keys.h>
#include <dt-bindings/zmk/bt.h>
#include <dt-bindings/zmk/outputs.h>

// Layers
#define DEF 0
#define SYM 1
#define NAV 2
#define EXT 3
#define GAM 4
#define GFN 5
#define FN  6
#define MSE 7
#define ADJ 8
#define SNPR 9  // for trackball
#define SCRL 10 // for trackball

// Behaviors Constants
#define TAPPING_TERM_MS 200
#define TAPPING_TERM_HRM_MS 280
#define QUICK_TAP_MS 175
#define REQUIRE_PRIOR_IDLE_MS 150
#define RELEASE_AFTER_MS 900

// Combos Constants
#define COMBO_TERM 20
#define COMBO_IDLE 100

// Keys
#define SPACE_N   LC(RIGHT)     // Ctrl+->      - Space next
#define SPACE_P   LC(LEFT)      // Ctrl+<-      - Space prev
#define SPACE_U   LC(UP)        // Ctrl+Up      - Mission Control
#define SPACE_D   LC(DOWN)      // Ctrl+Down    - Show windows
#define TAB_N     LC(TAB)       // Ctrl+Tab     - Tab next
#define TAB_P     LC(LS(TAB))   // Ctrl+Shft+Tab- Tab prev
#define WIN_N     LG(TAB)       // Cmd+Tab      - Win next
#define WIN_P     LG(LS(TAB))   // Cmd+Shft+Tab - Win prev

#define _ &kp
#define XXX &none
#define ___ &trans

#define MEH(key) LS(LC(LA(key)))

#include "zmk-helpers/helper.h"
#include "universal_layout.h"

#define ZMK_BEHAVIOR_CORE_smart_toggle    compatible = "zmk,behavior-smart-toggle";    #binding-cells = <0>

#define ZMK_SMART_TOGGLE(name, ...) ZMK_BEHAVIOR(name, smart_toggle, __VA_ARGS__)

#define MAKE_HRM(NAME, HOLD, TAP, TRIGGER_POS) ZMK_HOLD_TAP(NAME, \
    flavor = "balanced"; \
    tapping-term-ms = <TAPPING_TERM_HRM_MS>; \
    require-prior-idle-ms = <REQUIRE_PRIOR_IDLE_MS>; \
    quick-tap-ms = <QUICK_TAP_MS>; \
    hold-trigger-on-release; \
    bindings = <HOLD>, <TAP>; \
    hold-trigger-key-positions = <TRIGGER_POS>; \
)

// Dongle Screen
// Keycode that toggles the screen off and on
#define DNGL_BR_TOG F22
// Keycode for increasing screen brightness
#define DNGL_BR_INC F24
// Keycode for decreasing screen brightness
#define DNGL_BR_DEC F23
