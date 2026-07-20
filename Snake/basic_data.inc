; =========================================================
;STRUCTS
; =========================================================

RECT STRUCT
    left    SDWORD ?
    top     SDWORD ?
    right   SDWORD ?
    bottom  SDWORD ?
RECT ENDS

PAINTSTRUCT STRUCT
    hdc         QWORD      ?      ; HDC is a pointer
    fErase      DWORD      ?
    _padding1   DWORD      ?      ; Align RECT on 8-byte boundary
    rcPaint     RECT       <>
    fRestore    DWORD      ?
    fIncUpdate  DWORD      ?
    rgbReserved BYTE 32 DUP(?)
PAINTSTRUCT ENDS

; =========================================================
; Constants
; =========================================================

DT_CENTER           equ 0000001h
MSG_SIZE            equ 30h

; =========================================================
; TYPEDEFS
; =========================================================

HWND        TYPEDEF QWORD
HDC         TYPEDEF QWORD
HINSTANCE   TYPEDEF QWORD

BLINK_TIMER_ID equ 1
BLINK_FREQUENCY_MS equ 500

MAIN_INPUT_TIMER_ID equ 2
GAME_INPUT_TIMER_ID equ 3
INPUT_FREQUENCY_MS equ 16