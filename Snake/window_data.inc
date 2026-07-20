WC_cbSize           equ 00h
WC_style            equ 04h
WC_lpfnWndProc      equ 08h
WC_cbClsExtra       equ 10h
WC_cbWndExtra       equ 14h
WC_hInstance        equ 18h
WC_hIcon            equ 20h
WC_hCursor          equ 28h
WC_hbrBackground    equ 30h
WC_lpszMenuName     equ 38h
WC_lpszClassName    equ 40h
WC_hIconSm          equ 48h

CW_X                equ 20h
CW_Y                equ 28h
CW_WIDTH            equ 30h
CW_HEIGHT           equ 38h
CW_PARENT           equ 40h
CW_MENU             equ 48h
CW_INSTANCE         equ 50h
CW_PARAM            equ 58h

WS_OVERLAPPEDWINDOW equ 0CF0000h
WS_OVERLAPPED       equ 0000000h
WS_CAPTION          equ 00C0000h
WS_THICKFRAME       equ 0004000h
WS_SYSMENU          equ 0008000h
WS_MINIMIZEBOX      equ 0002000h

WM_CREATE           equ 0001h
WM_DESTROY          equ 0002h
WM_QUIT             equ 0012h
WM_ERASEBKGND       equ 0014h
WM_KEYDOWN          equ 0100h
WM_TIMER            equ 0113h
WM_PAINT            equ 000Fh

SW_SHOW             equ 0005h

; =========================================================
;STRUCTS
; =========================================================

WNDCLASSEXW STRUCT
    cbSize         DWORD ?
    style          DWORD ?
    lpfnWndProc    QWORD ?
    cbClsExtra     DWORD ?
    cbWndExtra     DWORD ?
    hInstance      QWORD ?
    hIcon          QWORD ?
    hCursor        QWORD ?
    hbrBackground  QWORD ?
    lpszMenuName   QWORD ?
    lpszClassName  QWORD ?
    hIconSm        QWORD ?
WNDCLASSEXW ENDS