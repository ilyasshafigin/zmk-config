// На основе раскладки Universal Layout Ortho

// O|Щ -> tap O|З
// P|З -> tap P|Х

#define UL_COMMA    LBKT            // -> tap: ',', shifted: ';'
#define UL_DOT      RBKT            // -> tap: '.', shifted: ':'
#define UL_TILDE    SEMI            // -> tap: ~|ж, shifted: ≈|Ж
#define UL_AMPS     COMMA           // -> tap: &|б, shifted: &|Б
#define UL_LBKT     DOT             // -> tap: [|ю, shifted: {|Ю, alted: [, shifted+alted: {
#define UL_RBKT     FSLH            // -> tap: ]|э, shifted: }|Э, alted: ], shifted+alted: }
#define UL_LBRC     LS(DOT)         // -> {|Ю, alted: {
#define UL_RBRC     LS(FSLH)        // -> }|Э, alted: }

#define UL_SQT      GRAVE           // -> '''
#define UL_DQT      LS(GRAVE)       // -> '"'
#define UL_GRAVE    LA(GRAVE)       // -> '`'

#define UL_BSLH     LA(BSLH)        // -> '\'
#define UL_FSLH     BSLH            // -> '/'
#define UL_PIPE     LS(BSLH)        // -> '|'
#define UL_DPIPE    LS(LA(BSLH))    // -> '¦'

#define UL_NBSP     LA(SPACE)       // No-break-space

#define UL_N1       LS(N1)  // -> 1
#define UL_N2       LS(N2)  // -> 2
#define UL_N3       LS(N3)  // -> 3
#define UL_N4       LS(N4)  // -> 4
#define UL_N5       LS(N5)  // -> 5
#define UL_N6       LS(N6)  // -> 6
#define UL_N7       LS(N7)  // -> 7
#define UL_N8       LS(N8)  // -> 8
#define UL_N9       LS(N9)  // -> 9
#define UL_N0       LS(N0)  // -> 0

#define UL_EXCL     N1      // -> !, shifted: 1
#define UL_AT       N2      // -> @, shifted: 2
#define UL_HASH     N3      // -> #, shifted: 3
#define UL_DLLR     N4      // -> $, shifted: 4
#define UL_PRCNT    N5      // -> %, shifted: 5
#define UL_CARET    N6      // -> ^, shifted: 6
#define UL_QSTM     N7      // -> ?, shifted: 7
#define UL_ASTRK    N8      // -> *, shifted: 8
#define UL_LPAR     N9      // -> (, shifted: 9
#define UL_RPAR     N0      // -> ), shifted: 0
