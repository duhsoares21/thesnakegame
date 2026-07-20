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