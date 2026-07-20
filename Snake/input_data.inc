; =========================================================
; Snake Game - x64 MASM - Input System Data
; =========================================================

VK_LEFT             equ 25h
VK_UP               equ 26h
VK_RIGHT            equ 27h
VK_DOWN             equ 28h

VK_RETURN           equ 0Dh
VK_ESCAPE           equ 1Bh

XINPUT_GAMEPAD_DPAD_UP     equ 0001h
XINPUT_GAMEPAD_DPAD_DOWN   equ 0002h
XINPUT_GAMEPAD_DPAD_LEFT   equ 0004h
XINPUT_GAMEPAD_DPAD_RIGHT  equ 0008h

XINPUT_GAMEPAD_START            equ 0010h

; =========================================================
; Snake Game - x64 MASM - Input Structs
; =========================================================

XINPUT_STATE STRUCT
    dwPacketNumber DWORD ?
    wButtons WORD ?
    bLeftTrigger BYTE ?
    bRightTrigger BYTE ?
    sThumbLX WORD ?
    sThumbLY WORD ?
    sThumbRX WORD ?
    sThumbRY WORD ?
XINPUT_STATE ENDS