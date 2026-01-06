#include <dt-bindings/zmk/keys.h>
#include <dt-bindings/zmk/bt.h>
#include <dt-bindings/zmk/outputs.h>
#include "universal_layout.h"

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

// Dongle Screen
// Keycode that toggles the screen off and on
#define DNGL_BR_TOG F22
// Keycode for increasing screen brightness
#define DNGL_BR_INC F24
// Keycode for decreasing screen brightness
#define DNGL_BR_DEC F23
