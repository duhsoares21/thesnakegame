; =========================================================
; Snake Game - x64 MASM - Render System
; Double Buffered GDI Renderer
; =========================================================

;========================================
;WINDOWS API LIBS
;========================================

INCLUDELIB user32.lib
INCLUDELIB gdi32.lib
INCLUDELIB kernel32.lib

INCLUDE basic_data.inc
INCLUDE game_data.inc
INCLUDE render_data.inc

;========================================
;EXTERNS
;========================================

EXTERN CreateCompatibleDC: PROC
EXTERN CreateCompatibleBitmap: PROC
EXTERN SelectObject: PROC
EXTERN DeleteDC: PROC
EXTERN DeleteObject: PROC
EXTERN BitBlt: PROC

EXTERN CreateSolidBrush: PROC
EXTERN FillRect: PROC

EXTERN GetDC: PROC
EXTERN ReleaseDC: PROC

EXTERN SnakeTileSize: DWORD


;========================================
;DATA
;========================================

.data

PUBLIC InitRender
PUBLIC BeginRender
PUBLIC EndRender
PUBLIC DrawRectangle
PUBLIC GetRenderDC

Rectangle RECT <>

BlackColor      DWORD 00000000h

hBrush QWORD 0

;========================================
;CODE
;========================================

.code

;=========================================================
; InitRenderer
;
; RCX = HWND
; RDX = RENDER CONTEXT
;=========================================================

InitRender PROC
    
    push r12
    sub rsp, 8h

    mov r12, rdx

    sub rsp,28h
        call GetDC
    add rsp,28h

    mov [r12].RENDER_CONTEXT.WindowDC, rax

    mov rcx, [r12].RENDER_CONTEXT.WindowDC

    sub rsp,28h
        call CreateCompatibleDC
    add rsp,28h

    mov [r12].RENDER_CONTEXT.RenderDC, rax

    mov rcx, [r12].RENDER_CONTEXT.WindowDC
    mov rdx, [r12].RENDER_CONTEXT.ScreenWidth
    mov r8, [r12].RENDER_CONTEXT.ScreenHeight

    sub rsp,28h
        call CreateCompatibleBitmap
    add rsp,28h

    mov [r12].RENDER_CONTEXT.BackBitmap, rax

    mov rcx, [r12].RENDER_CONTEXT.RenderDC
    mov rdx, [r12].RENDER_CONTEXT.BackBitmap

    sub rsp,28h
        call SelectObject
    add rsp,28h

    mov [r12].RENDER_CONTEXT.OldBitmap, rax

    add rsp, 8h
    pop r12

    ret

InitRender ENDP

;=========================================================
; BeginRender
;
; Clears back buffer
; RCX = RENDER CONTEXT
;=========================================================

BeginRender PROC
    push r14
    push r12

    mov r12, rcx
    
    mov Rectangle.left,0
    mov Rectangle.top,0

    mov rax,rdx
    mov Rectangle.right,eax

    mov rax,r8
    mov Rectangle.bottom,eax

    xor ecx,ecx

    sub rsp,28h
        call CreateSolidBrush
    add rsp,28h

    mov r14,rax

    mov rcx,[r12].RENDER_CONTEXT.RenderDC
    lea rdx,Rectangle
    mov r8,r14

    sub rsp,28h
        call FillRect
    add rsp,28h

    mov rcx,r14

    sub rsp,28h
        call DeleteObject
    add rsp,28h

    pop r12
    pop r14

    ret

BeginRender ENDP

;=========================================================
; EndRender
;
; Copies back buffer to window
; RCX = HWND
; RDX = RENDER CONTEXT
;=========================================================

EndRender PROC
    push r12
    mov r12, rdx

    sub rsp,48h

    xor edx,edx            ; x
    xor r8d,r8d             ; y

    mov r9,[r12].RENDER_CONTEXT.ScreenWidth

    mov rax, [r12].RENDER_CONTEXT.ScreenHeight
    mov qword ptr [rsp+20h],rax

    mov rax, [r12].RENDER_CONTEXT.RenderDC
    mov qword ptr [rsp+28h],rax

    mov qword ptr [rsp+30h],0
    mov qword ptr [rsp+38h],0
    mov qword ptr [rsp+40h],00CC0020h ; SRCCOPY

    call BitBlt
    
    add rsp,48h

    pop r12

    ret

EndRender ENDP

;=========================================================
; GetRenderDC
;
; Returns current drawing DC
; RCX = RENDER CONTEXT
;=========================================================

GetRenderDC PROC
    mov rax,[rcx].RENDER_CONTEXT.RenderDC
    ret
GetRenderDC ENDP

;=========================================================
; DrawRectangle
;
; RCX = HDC
; RDX = X
; R8  = Y
; R9  = Color
;=========================================================

DrawRectangle PROC

    push r14
    push rsi

    mov r14,rcx

    mov eax,edx
    mov Rectangle.left,eax

    add eax,SnakeTileSize
    mov Rectangle.right,eax

    mov eax,r8d
    mov Rectangle.top,eax

    add eax,SnakeTileSize
    mov Rectangle.bottom,eax

    mov ecx,r9d

    sub rsp,28h
        call CreateSolidBrush
    add rsp,28h

    mov rsi,rax

    mov rcx,r14
    lea rdx,Rectangle
    mov r8,rsi

    sub rsp,28h
        call FillRect
    add rsp,28h

    mov rcx,rsi

    sub rsp,28h
        call DeleteObject
    add rsp,28h

    pop rsi
    pop r14

    ret
DrawRectangle ENDP

;=======================================
;FillRectangle - Parameters Sheet
;
;RCX = Device Context
;RDX = Rectangle
;R8 = Color of rectangle
;======================================

FillRectangle PROC
    LOCAL LRectangle: RECT
    LOCAL LBrush: QWORD

    push r14
    push r15
    push rsi

    mov r14, rcx        ; HDC
    mov r15, r8         ; COLOR

    lea rsi, LRectangle

    ; RECT.left
    mov eax, [rdx].RECT.left
    mov LRectangle.left, eax

    ; RECT.top
    mov eax,[rdx].RECT.top
    mov LRectangle.top, eax
    
    mov eax, [rdx].RECT.right
    mov LRectangle.right, eax
        
    mov eax, [rdx].RECT.bottom
    mov LRectangle.bottom, eax

    ; -------------------------
    ; CreateSolidBrush
    ; -------------------------

    mov ecx, r15d

    sub rsp, 28h
        call CreateSolidBrush
    add rsp, 28h

    mov LBrush, rax

    ; -------------------------
    ; FillRect
    ; -------------------------

    mov rcx, r14
    lea rdx, LRectangle
    mov r8, LBrush

    sub rsp, 28h
        call FillRect
    add rsp, 28h

    ; -------------------------
    ; Delete brush
    ; -------------------------

    mov rcx, LBrush

    sub rsp, 28h
        call DeleteObject
    add rsp, 28h

    pop rsi
    pop r15
    pop r14

    ret

FillRectangle ENDP

END