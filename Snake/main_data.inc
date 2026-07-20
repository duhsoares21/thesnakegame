; =========================================================
; Font Weight
; =========================================================
FW_DONTCARE    equ 0
FW_THIN        equ 100
FW_EXTRALIGHT  equ 200
FW_LIGHT       equ 300
FW_NORMAL      equ 400
FW_MEDIUM      equ 500
FW_SEMIBOLD    equ 600
FW_BOLD        equ 700
FW_EXTRABOLD   equ 800
FW_HEAVY       equ 900

; =========================================================
; Character Set
; =========================================================
ANSI_CHARSET        equ 0
DEFAULT_CHARSET     equ 1
SYMBOL_CHARSET      equ 2
SHIFTJIS_CHARSET    equ 128
HANGEUL_CHARSET     equ 129
GB2312_CHARSET      equ 134
CHINESEBIG5_CHARSET equ 136
OEM_CHARSET         equ 255

; =========================================================
; Output Precision
; =========================================================
OUT_DEFAULT_PRECIS      equ 0
OUT_STRING_PRECIS       equ 1
OUT_CHARACTER_PRECIS    equ 2
OUT_STROKE_PRECIS       equ 3
OUT_TT_PRECIS           equ 4
OUT_DEVICE_PRECIS       equ 5
OUT_RASTER_PRECIS       equ 6
OUT_TT_ONLY_PRECIS      equ 7
OUT_OUTLINE_PRECIS      equ 8
OUT_SCREEN_OUTLINE_PRECIS equ 9
OUT_PS_ONLY_PRECIS      equ 10

; =========================================================
; Clip Precision
; =========================================================
CLIP_DEFAULT_PRECIS     equ 0
CLIP_CHARACTER_PRECIS   equ 1
CLIP_STROKE_PRECIS      equ 2
CLIP_MASK               equ 0Fh
CLIP_LH_ANGLES          equ 10h
CLIP_TT_ALWAYS          equ 20h
CLIP_DFA_DISABLE        equ 40h
CLIP_EMBEDDED           equ 80h

; =========================================================
; Quality
; =========================================================
DEFAULT_QUALITY         equ 0
DRAFT_QUALITY           equ 1
PROOF_QUALITY           equ 2
NONANTIALIASED_QUALITY  equ 3
ANTIALIASED_QUALITY     equ 4
CLEARTYPE_QUALITY       equ 5
CLEARTYPE_NATURAL_QUALITY equ 6

; =========================================================
; Pitch
; =========================================================
DEFAULT_PITCH   equ 0
FIXED_PITCH     equ 1
VARIABLE_PITCH  equ 2
MONO_FONT       equ 8

; =========================================================
; Font Family
; =========================================================
FF_DONTCARE     equ 00h
FF_ROMAN        equ 10h
FF_SWISS        equ 20h
FF_MODERN       equ 30h
FF_SCRIPT       equ 40h
FF_DECORATIVE   equ 50h

IDI_ICON equ 101