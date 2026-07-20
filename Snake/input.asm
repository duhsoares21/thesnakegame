; =========================================================
; Snake Game - x64 MASM - Input System
; =========================================================

;========================================
;INCLUDES
;========================================

INCLUDELIB xinput.lib
INCLUDELIB kernel32.lib 

INCLUDE game_data.inc
INCLUDE input_data.inc

;========================================
;EXTERNS
;========================================

EXTERN XInputGetState: PROC
EXTERN HandleGameState: PROC

.data

PUBLIC HandleInput

PUBLIC InputType
InputType QWORD 1

CurrentInputType QWORD 1

PUBLIC CurrentKeyPress
CurrentKeyPress QWORD 0

ControllerState XINPUT_STATE <>

PUBLIC lockInput
lockInput QWORD 0

.code

;========================================================
;HandleInput - Parameters Sheet
;
;RCX = Type of input (1 = Keyboard, 2 = Xbox controller
;RDX = Key pressed (Keyboard Only)
;========================================================

HandleInput PROC
    mov r8, rcx
    mov r9, rdx

    cmp r8, 1
    je UseKeyboard
    
    cmp r8, 2
    je UseController
    jne Return

    UseKeyboard:
        
        mov rcx, r9

        sub rsp, 28h
            call KeyboardInput
        add rsp, 28h
        ret

    UseController: 
        mov rcx, 0              ; Controller 0
        lea rdx, ControllerState

        sub rsp, 28h
            call XInputGetState
        add rsp, 28h

        test eax,eax
        jnz EndInput

        mov ax, ControllerState.wButtons
        mov rcx, rax

        sub rsp, 28h
            call ControllerInput
        add rsp, 28h

        Return:
            ret

HandleInput ENDP

;========================================================
;ControllerInput - Parameters Sheet
;
;RCX = Key Pressed
;========================================================

ControllerInput PROC
    mov rax, lockInput

    cmp rax, 1
    je Return

    mov r8, rcx
    mov CurrentInputType, 2
    
    cmp r8d, XINPUT_GAMEPAD_DPAD_RIGHT
    je HandleGameStateLabel

    cmp r8d, XINPUT_GAMEPAD_DPAD_LEFT
    je HandleGameStateLabel

    cmp r8d, XINPUT_GAMEPAD_DPAD_UP
    je HandleGameStateLabel

    cmp r8d, XINPUT_GAMEPAD_DPAD_DOWN
    je HandleGameStateLabel

    Return:
        ret

ControllerInput ENDP

;========================================================
;KeyboardInput - Parameters Sheet
;
;RCX = Key Pressed
;========================================================

KeyboardInput PROC
    mov rax, lockInput

    cmp rax, 1
    je Return

    mov r8, rcx
    mov CurrentInputType, 1
    
    cmp r8, VK_RIGHT
    je HandleGameStateLabel

    cmp r8, VK_LEFT
    je HandleGameStateLabel

    cmp r8, VK_UP
    je HandleGameStateLabel

    cmp r8, VK_DOWN
    je HandleGameStateLabel

    cmp r8, VK_RETURN
    je HandleGameStateLabel

    cmp r8, VK_ESCAPE
    je HandleGameStateLabel

    Return:
        ret
KeyboardInput ENDP

LockInputLabel: 
    jmp EndInput

HandleGameStateLabel:
    mov CurrentKeyPress, r8

    sub rsp, 28h
        call HandleGameState
    add rsp, 28h
    
    mov rax, CurrentInputType
    mov InputType, rax
    mov lockInput, 1
    ret

EndInput:
    ret

END