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

// Behaviors Constants
#define TAPPING_TERM_MS 280
#define QUICK_TAP_MS 200
#define REQUIRE_PRIOR_IDLE_MS 150
#define RELEASE_AFTER_KEY_MS 2000

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

#define XXX &none
#define ___ &trans

#include "zmk-helpers/helper.h"
#include "universal_layout.h"
