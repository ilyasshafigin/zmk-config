#ifndef ZMK_CONFIG_SHARED_UNIVERSAL_LAYOUT_H
#define ZMK_CONFIG_SHARED_UNIVERSAL_LAYOUT_H

#include <dt-bindings/zmk/keys.h>

// На основе раскладки Universal Layout Ortho
// Здесь в комментариях 'A|B' значит что символ 'A' в английской раскладке, 'B' в русской.

// Смещения и замены стандартной раскладки:
// O|Щ -> O|З
// P|З -> P|Х
// ''' (SQT|APOS) -> не используется

#define U_COMMA    LBKT            // '[' -> ','   shift: ';'   alt: ','   shift+alt: ';'
#define U_SEMI     LS(LBKT)        // '{' -> ';'                alt: ';'

#define U_DOT      RBKT            // ']' -> '.'   shift: ':'   alt: '.'   shift+alt: ':'
#define U_COLON    LS(RBKT)        // '}' -> ':'                alt: ':'

#define U_TILDE    SEMI            // ';' -> ~|ж   shift: ≈|Ж   alt: '»'   shift+alt: '→'
#define U_AMPS     COMMA           // ',' -> &|б   shift: &|Б   alt: '&'   shift+alt: '…'

#define U_LBKT     DOT             // '.' -> [|ю   shift: {|Ю   alt: '['   shift+alt: '{'
#define U_LBRC     LS(DOT)         // '>' -> {|Ю                alt: '{'

#define U_RBKT     FSLH            // '/' -> ]|э   shift: }|Э   alt: ']'   shift+alt: '}'
#define U_RBRC     LS(FSLH)        // '?' -> }|Э                alt: '}'

#define U_SQT      GRAVE           // '`' -> '''   shift: '"'   alt: '`'   shift+alt: '•'
#define U_DQT      LS(GRAVE)       // '~' -> '"'                alt: '•'
#define U_GRAVE    LA(GRAVE)       //     -> '`'   shift: '•'

#define U_FSLH     BSLH            // '\' -> '/'   shift: '|'   alt: '\'   shift+alt: '¦'
#define U_BSLH     LA(BSLH)        //     -> '\'   shift: '¦'
#define U_PIPE     LS(BSLH)        // '|' -> '|'                alt: '¦'
#define U_DPIPE    LS(LA(BSLH))    //     -> '¦'

#define U_EQUAL    EQUAL           // -> '='       shift: '+'   alt: '≠'   shift+alt: '±'
#define U_PLUS     PLUS            // -> '+'                    alt: '±'
#define U_MINUS    MINUS           // -> '-'       shift: '_'   alt: '–'   shift+alt: '—'
#define U_UNDER    UNDER           // -> '_'                    alt: '—'

#define U_N1       LS(N1)          // -> '1'                alt: '¡'
#define U_N2       LS(N2)          // -> '2'                alt: '½'
#define U_N3       LS(N3)          // -> '3'                alt: '⅓'
#define U_N4       LS(N4)          // -> '4'                alt: '¼'
#define U_N5       LS(N5)          // -> '5'                alt: '‰'
#define U_N6       LS(N6)          // -> '6'                alt: 'ˆ'
#define U_N7       LS(N7)          // -> '7'                alt: '⁈'
#define U_N8       LS(N8)          // -> '8'                alt: '∞'
#define U_N9       LS(N9)          // -> '9'                alt: '“'
#define U_N0       LS(N0)          // -> '0'                alt: '”'

#define U_EXCL     N1              // -> '!'   shift: '1'   alt: '¹'   shift+alt: '¡'
#define U_AT       N2              // -> '@'   shift: '2'   alt: '²'   shift+alt: '½'
#define U_HASH     N3              // -> '#'   shift: '3'   alt: '³'   shift+alt: '⅓'
#define U_DLLR     N4              // -> '$'   shift: '4'   alt: '⁴'   shift+alt: '¼'
#define U_PRCNT    N5              // -> '%'   shift: '5'   alt: '‰'   shift+alt: '‰'
#define U_CARET    N6              // -> '^'   shift: '6'   alt: 'ˆ'   shift+alt: 'ˆ'
#define U_QSTM     N7              // -> '?'   shift: '7'   alt: '¿'   shift+alt: '⁈'
#define U_ASTRK    N8              // -> '*'   shift: '8'   alt: '∞'   shift+alt: '∞'
#define U_LPAR     N9              // -> '('   shift: '9'   alt: '‘'   shift+alt: '“'
#define U_RPAR     N0              // -> ')'   shift: '0'   alt: '’'   shift+alt: '”'

//                  K                  -> k|л   shift: K|Л   alt: '=>'  shift+alt: '->'
#define U_ARROW    LS(LA(K))       // -> '->'
#define U_DARROW   LA(K)           // -> '=>'  shift: '->'

#define U_NBSP     LA(SPACE)       // No-break-space

#endif // ZMK_CONFIG_SHARED_UNIVERSAL_LAYOUT_H
