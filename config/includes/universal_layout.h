// На основе раскладки Universal Layout Ortho
// Здесь в комментариях 'A|B' значит что символ 'A' в английской раскладке, 'B' в русской.

// Смещения и замены стандартной раскладки:
// O|Щ -> O|З
// P|З -> P|Х

#define UL_COMMA    LBKT            // -> ','   shift: ';'   alt: ','   shift+alt: ';'
#define UL_DOT      RBKT            // -> '.'   shift: ':'   alt: '.'   shift+alt: ':'
#define UL_TILDE    SEMI            // -> ~|ж   shift: ≈|Ж   alt: '»'   shift+alt: '→'
#define UL_AMPS     COMMA           // -> &|б   shift: &|Б   alt: '&'   shift+alt: '…'
#define UL_LBKT     DOT             // -> [|ю   shift: {|Ю   alt: '['   shift+alt: '{'
#define UL_RBKT     FSLH            // -> ]|э   shift: }|Э   alt: ']'   shift+alt: '}'
#define UL_LBRC     LS(DOT)         // -> {|Ю                alt: '{'
#define UL_RBRC     LS(FSLH)        // -> }|Э                alt: '}'

#define UL_SQT      GRAVE           // -> '''   shift: '"'   alt: '`'   shift+alt: '•'
#define UL_DQT      LS(GRAVE)       // -> '"'                alt: '•'
#define UL_GRAVE    LA(GRAVE)       // -> '`'   shift: '•'

#define UL_FSLH     BSLH            // -> '/'   shift: '|'   alt: '\'   shift+alt: '¦'
#define UL_BSLH     LA(BSLH)        // -> '\'   shift: '¦'
#define UL_PIPE     LS(BSLH)        // -> '|'                alt: '¦'
#define UL_DPIPE    LS(LA(BSLH))    // -> '¦'

#define UL_N1       LS(N1)          // -> '1'                alt: '¡'
#define UL_N2       LS(N2)          // -> '2'                alt: '½'
#define UL_N3       LS(N3)          // -> '3'                alt: '⅓'
#define UL_N4       LS(N4)          // -> '4'                alt: '¼'
#define UL_N5       LS(N5)          // -> '5'                alt: '‰'
#define UL_N6       LS(N6)          // -> '6'                alt: 'ˆ'
#define UL_N7       LS(N7)          // -> '7'                alt: '⁈'
#define UL_N8       LS(N8)          // -> '8'                alt: '∞'
#define UL_N9       LS(N9)          // -> '9'                alt: '“'
#define UL_N0       LS(N0)          // -> '0'                alt: '”'

#define UL_EXCL     N1              // -> '!'   shift: '1'   alt: '¹'   shift+alt: '¡'
#define UL_AT       N2              // -> '@'   shift: '2'   alt: '²'   shift+alt: '½'
#define UL_HASH     N3              // -> '#'   shift: '3'   alt: '³'   shift+alt: '⅓'
#define UL_DLLR     N4              // -> '$'   shift: '4'   alt: '⁴'   shift+alt: '¼'
#define UL_PRCNT    N5              // -> '%'   shift: '5'   alt: '‰'   shift+alt: '‰'
#define UL_CARET    N6              // -> '^'   shift: '6'   alt: 'ˆ'   shift+alt: 'ˆ'
#define UL_QSTM     N7              // -> '?'   shift: '7'   alt: '¿'   shift+alt: '⁈'
#define UL_ASTRK    N8              // -> '*'   shift: '8'   alt: '∞'   shift+alt: '∞'
#define UL_LPAR     N9              // -> '('   shift: '9'   alt: '‘'   shift+alt: '“'
#define UL_RPAR     N0              // -> ')'   shift: '0'   alt: '’'   shift+alt: '”'

//                  K                  -> k|л   shift: K|Л   alt: '=>'  shift+alt: '->'

#define UL_NBSP     LA(SPACE)       // No-break-space
