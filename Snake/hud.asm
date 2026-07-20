; =========================================================
; Snake Game - x64 MASM - HUD
; =========================================================

;========================================
;INCLUDES
;========================================

INCLUDELIB user32.lib

INCLUDE basic_data.inc
INCLUDE hud_data.inc

;========================================
;EXTERNS
;========================================

EXTERN SetBkMode: PROC
EXTERN SetTextColor: PROC
EXTERN DrawTextW: PROC

.data

PUBLIC CurrentScore
CurrentScore QWORD 0

PUBLIC CurrentSpeed
CurrentSpeed QWORD START_SPEED_LABEL

PUBLIC ScoreText
ScoreText dw "0","0","0","0","0","0","0","0","0","0",0

PUBLIC FoodCountText
FoodCountText dw "0","0","0","0","0",0

PUBLIC LiveText
LiveText dw "0", 0

PUBLIC SpeedText
SpeedText dw "0", 0

PUBLIC AddScore
PUBLIC SetScore
PUBLIC ResetScore
PUBLIC ConvertIntToString
PUBLIC GetSpeedLabel
PUBLIC IncreaseSpeedLabel
PUBLIC ResetSpeedLabel
PUBLIC DrawHUD

.code

AddScore PROC
    mov rax, CurrentScore
    add rax, GET_FOOD_POINTS
    mov CurrentScore, rax
    ret
AddScore ENDP

;===========================================
;SetScore - Parameters Sheet
;
;RCX = Current Score Value
;===========================================

SetScore PROC
    mov CurrentScore, rcx
    ret
SetScore ENDP

ResetScore PROC
    mov CurrentScore, 0
    ret
ResetScore ENDP

;===========================================
;ConvertIntToString - Parameters Sheet
;
;RCX = value to be converted
;RDX = number of characters in the string
;R8  = address to the string
;===========================================

ConvertIntToString PROC

    push rbx
    push rdi

    mov rax, rcx
    mov r10, rdx

    mov r9, r10
    dec r9
    imul r9, 2

    mov rdi, r8
    add rdi, r9
    mov ecx, r10d

ConvertLoop:

    xor edx, edx
    mov ebx, r10d
    div ebx

    add dx, '0' ;'0' == 48 (ascii table) 
    mov [rdi], dx

    sub rdi, 2

    dec ecx
    jnz ConvertLoop

    pop rdi
    pop rbx
    ret

ConvertIntToString ENDP


GetSpeedLabel PROC
    mov rax, CurrentSpeed
    ret
GetSpeedLabel ENDP

IncreaseSpeedLabel PROC
    mov rax, CurrentSpeed
    inc rax
    mov CurrentSpeed, rax
    ret
IncreaseSpeedLabel ENDP

ResetSpeedLabel PROC
    mov CurrentSpeed, 1
    ret
ResetSpeedLabel ENDP

;=================================================
;DrawHUD - Parameters Sheet
;
;RCX = Device Context
;RDX = Address of the string
;R8  = Address of the Rectangle (string position)
;=================================================

DrawHUD PROC

    LOCAL lprc:RECT

    push r13
    push r14
    push r15

    mov r13, r9

    mov eax,[r8].RECT.left
    mov lprc.left, eax

    mov eax,[r8].RECT.top
    mov lprc.top, eax

    mov eax,[r8].RECT.right
    mov lprc.right, eax

    mov eax,[r8].RECT.bottom
    mov lprc.bottom, eax

    mov r14,rcx
    mov r15,rdx

    mov rcx,r14
    mov edx, TRANSPARENT

    sub rsp, 28h
        call SetBkMode
    add rsp, 28h

    mov rcx,r14
    mov rdx,r13

    sub rsp,28h
        call SetTextColor
    add rsp,28h

    sub rsp,38h

        mov rcx,r14
        mov rdx, r15
        mov r8,-1
        lea r9,lprc
        mov qword ptr [rsp+20h],DT_CENTER

        call DrawTextW

    add rsp,38h

    pop r13
    pop r14
    pop r15
    ret

DrawHUD ENDP

END