; =========================================================
; Snake Game - x64 MASM - Main Menu
; =========================================================

INCLUDELIB kernel32.lib
INCLUDELIB gdi32.lib

INCLUDE basic_data.inc
INCLUDE window_data.inc
INCLUDE render_data.inc
INCLUDE main_data.inc

;========================================
;EXTERNS
;========================================

EXTERN AdjustWindowRectEx:PROC
EXTERN CreateWindowExW:PROC
EXTERN UpdateWindow:PROC
EXTERN TranslateMessage:PROC
EXTERN ShowWindow:PROC
EXTERN SetTimer:PROC
EXTERN RegisterClassExW:PROC
EXTERN GetModuleHandleW:PROC
EXTERN GetMessageW:PROC
EXTERN GetLastError:PROC
EXTERN ExitProcess:PROC
EXTERN DispatchMessageW:PROC
EXTERN DefWindowProcW:PROC
EXTERN PostQuitMessage:PROC
EXTERN InvalidateRect:PROC

EXTERN SelectObject:PROC
EXTERN DeleteObject:PROC
EXTERN CreateFontW:PROC

EXTERN InitRender:PROC
EXTERN BeginPaint:PROC
EXTERN BeginRender:PROC
EXTERN GetRenderDC:PROC
EXTERN EndRender:PROC
EXTERN EndPaint:PROC

EXTERN DrawHUD:PROC
EXTERN FillRectangle:PROC

EXTERN HandleInput:PROC
EXTERN HandleGameState: PROC

EXTERN LoadIconW:PROC

.data

MenuTitleFont QWORD 0
MenuSubtitleFont QWORD 0

BlinkState QWORD 1

OldFont       QWORD 0
OldSubFont    QWORD 0  
hFont         QWORD 0

PUBLIC GameIcon
GameIcon QWORD 0

TitleFont dw 'K','a','r','m','a','t','i','c',' ','A','r','c','a','d','e',0
SubtitleFont dw 'K','r','i','s','t','e','n',' ','I','T','C',0

ClassName       dw 'M','a','i','n',0
WindowTitle     dw 'M','a','i','n',' ','M','e','n','u',' ','-',' ','S','n','a','k','e',' ','G','a','m','e',0

GameTitleLabel  dw "T","h","e"," ","S","n","a","k","e"," ","G","a","m","e",0
GameTitleRect RECT <0,120,600,600>

PressAnyKeyLabel  dw "P","r","e","s","s"," ","e","n","t","e","r"," ","o","r"," ","s","t","a","r","t"," ","k","e","y",0
PressAnyKeyRect RECT <0,420,600,600>

TopHalfRectangle RECT <0,0,600,285>
BottomHalfRectangle RECT <0,285,600,600>

PUBLIC timerValue
timerValue QWORD 16

Paint PAINTSTRUCT <>
WndClass db SIZEOF WNDCLASSEXW dup(0)

rc RECT <>

PUBLIC mainHWND
mainHWND HWND 0

hEditInstance HINSTANCE 0
hMainDeviceContext HDC 0
hDeviceContext HDC 0

isClassRegistered QWORD 0

mainRender RENDER_CONTEXT <0,0,0,0,600,600>

PUBLIC main

.data?

MsgData    db MSG_SIZE dup(?)

.code

main PROC
	; ----------------------------------------
    ; Fill WNDCLASSEXW
    ; ----------------------------------------

    sub rsp, 28h
        mov dword ptr [WndClass+WC_cbSize], SIZEOF WNDCLASSEXW
        mov dword ptr [WndClass+WC_style], 0

        lea rax, MainWndProc
        mov qword ptr [WndClass+WC_lpfnWndProc], rax

        xor rcx, rcx
        call GetModuleHandleW
    add rsp, 28h

    mov qword ptr [WndClass+WC_hInstance], rax
    mov hEditInstance, rax

    mov rcx, hEditInstance
    mov rdx, IDI_ICON

    sub rsp,28h
        call LoadIconW
    add rsp,28h

    mov GameIcon, rax

    mov qword ptr [WndClass+WC_hIcon], rax
    mov qword ptr [WndClass+WC_hIconSm], rax
    mov qword ptr [WndClass+WC_hCursor], 0
    mov qword ptr [WndClass+WC_hbrBackground], 0
    mov qword ptr [WndClass+WC_lpszMenuName], 0

    lea rax, ClassName
    mov qword ptr [WndClass+WC_lpszClassName], rax

    cmp isClassRegistered, 1
    je RegisterClassExW_OK

    lea rcx, WndClass

    sub rsp, 28h
        call RegisterClassExW
    add rsp, 28h

    ; ----------------------------------------
    ; Create Window
    ; ----------------------------------------

    test eax,eax
    jnz RegisterClassExW_OK

    sub rsp, 28h
        call GetLastError
    add rsp, 28h
    int 3            ; Registration failed

    RegisterClassExW_OK:

    mov isClassRegistered, 1

    mov rc.left, 0
    mov rc.top, 0
    mov rc.right, 600
    mov rc.bottom, 600

    sub rsp, 28h

        lea rcx, rc
        mov rdx, WS_OVERLAPPEDWINDOW
        xor r8, r8
        xor r9, r9

        call AdjustWindowRectEx

    add rsp, 28h
    
    mov rcx, 0
    lea rdx, ClassName
    lea r8, WindowTitle 
    mov r9d, WS_CAPTION OR WS_SYSMENU OR WS_MINIMIZEBOX

    sub rsp, 68h

        mov eax, rc.left
        mov qword ptr [rsp+CW_X],      650

        mov eax, rc.top
        mov qword ptr [rsp+CW_Y],      200
    
        mov eax, rc.right
        sub eax, rc.left

        mov qword ptr [rsp+CW_WIDTH],  rax

        mov eax, rc.bottom
        sub eax, rc.top

        mov qword ptr [rsp+CW_HEIGHT], rax

        mov qword ptr [rsp+CW_PARENT], 0
        mov qword ptr [rsp+CW_MENU],   0
    
        mov rax, hEditInstance
        mov qword ptr [rsp+CW_INSTANCE], rax

        mov qword ptr [rsp+CW_PARAM],  0

        call CreateWindowExW

    add rsp, 68h

    test rax,rax
    jnz CreateWindowExW_OK

    int 3            ; Window creation failed

    CreateWindowExW_OK:

    mov mainHWND, rax

    ;========================================
    ; Show Window
    ;========================================

    mov rcx, mainHWND
    mov rdx, SW_SHOW

    sub rsp, 28h
        call ShowWindow
    add rsp, 28h

    mov rcx, mainHWND

    sub rsp, 28h
        call UpdateWindow
    add rsp, 28h

    MessageLoop:

        lea rcx, MsgData
        xor rdx, rdx
        xor r8, r8
        xor r9, r9

        sub rsp, 28h
            call GetMessageW
        add rsp, 28h

        test eax, eax
        jz ExitProgram

        lea rcx, MsgData
        sub rsp, 28h
            call TranslateMessage
        add rsp, 28h

        lea rcx, MsgData

        sub rsp, 28h
            call DispatchMessageW
        add rsp, 28h

        jmp MessageLoop

    ExitProgram:

        xor ecx, ecx
        sub rsp, 28h
            call ExitProcess
        add rsp, 28h

	    ret
	ret
main ENDP

; =========================================================
; Window Procedure
; =========================================================

MainWndProc PROC
    mov mainHWND, rcx

    cmp edx, WM_NCHITTEST
    je HitTest

    cmp edx, WM_DESTROY
    je DestroyWindow

    cmp edx, WM_CREATE
    je CreateWindow

    cmp edx, WM_TIMER
    je GameLoop

    cmp edx, WM_PAINT
    je Render

    cmp edx, WM_KEYDOWN
    je Input

    cmp edx, WM_ERASEBKGND
    je Return

    sub rsp, 28h
        call DefWindowProcW
    add rsp, 28h

    ret

    HitTest:

    sub rsp,28h
        call DefWindowProcW
    add rsp,28h

    cmp eax, HTLEFT
    je BlockResize

    cmp eax, HTRIGHT
    je BlockResize

    cmp eax, HTTOP
    je BlockResize

    cmp eax, HTBOTTOM
    je BlockResize

    cmp eax, HTTOPLEFT
    je BlockResize

    cmp eax, HTTOPRIGHT
    je BlockResize

    cmp eax, HTBOTTOMLEFT
    je BlockResize

    cmp eax, HTBOTTOMRIGHT
    je BlockResize

    ret

    BlockResize:
        mov eax, HTCLIENT
        ret

     CreateWindow:

        mov rcx, mainHWND
        mov rdx, 1            ; Timer ID
        mov r8d, 500          ; 500 ms
        xor r9, r9

        sub rsp,28h
            call SetTimer
        add rsp,28h
        
        ;=======================================================
        ; FONT CREATION
        ;=======================================================
        mov ecx, -42          ; Negative = character height
        xor edx, edx          ; Width (default)
        xor r8d, r8d          ; Escapement
        xor r9d, r9d          ; Orientation

        sub rsp, 78h

        mov qword ptr [rsp+20h], FW_BOLD
        mov qword ptr [rsp+28h], 0
        mov qword ptr [rsp+30h], 0
        mov qword ptr [rsp+38h], 0
        mov qword ptr [rsp+40h], DEFAULT_CHARSET
        mov qword ptr [rsp+48h], OUT_DEFAULT_PRECIS
        mov qword ptr [rsp+50h], CLIP_DEFAULT_PRECIS
        mov qword ptr [rsp+58h], DEFAULT_QUALITY
        mov qword ptr [rsp+60h], DEFAULT_PITCH or FF_DONTCARE
        lea rax, TitleFont
        mov qword ptr [rsp+68h], rax

        call CreateFontW

        add rsp, 78h

        mov MenuTitleFont, rax

        mov ecx, -32          ; Negative = character height
        xor edx, edx          ; Width (default)
        xor r8d, r8d          ; Escapement
        xor r9d, r9d          ; Orientation

        sub rsp, 78h

        mov qword ptr [rsp+20h], FW_BOLD
        mov qword ptr [rsp+28h], 0
        mov qword ptr [rsp+30h], 0
        mov qword ptr [rsp+38h], 0
        mov qword ptr [rsp+40h], DEFAULT_CHARSET
        mov qword ptr [rsp+48h], OUT_DEFAULT_PRECIS
        mov qword ptr [rsp+50h], CLIP_DEFAULT_PRECIS
        mov qword ptr [rsp+58h], DEFAULT_QUALITY
        mov qword ptr [rsp+60h], DEFAULT_PITCH or FF_DONTCARE
        lea rax, SubtitleFont
        mov qword ptr [rsp+68h], rax

        call CreateFontW

        add rsp, 78h

        mov MenuSubtitleFont, rax

        ;=======================================================
        ; INITIALIZE RENDER
        ;=======================================================

        mov rcx, mainHWND
        lea rdx, mainRender

        sub rsp,28h
            call InitRender
        add rsp,28h

        xor rax, rax
        ret
     DestroyWindow:
        mov rcx, MenuTitleFont

        sub rsp, 28h
            call DeleteObject
        add rsp, 28h

        mov rcx, MenuSubtitleFont

        sub rsp, 28h
            call DeleteObject
        add rsp, 28h

        xor rcx, rcx
        sub rsp, 28h
            call PostQuitMessage
        add rsp, 28h

        xor eax, eax
        ret
     GameLoop:
        xor BlinkState, 1

        mov rcx, mainHWND
        xor rdx, rdx
        xor r8, r8

        sub rsp,28h
            call InvalidateRect
        add rsp,28h

        xor eax,eax
        ret
     Render:
        mov rcx, mainHWND
        lea rdx, Paint
        
        sub rsp, 28h
            call BeginPaint
        add rsp, 28h

        mov hMainDeviceContext, rax

        lea rcx, mainRender
        mov edx, rc.right
        mov r8d, rc.bottom

        sub rsp, 28h
            call BeginRender
        add rsp, 28h

        lea rcx, mainRender

        sub rsp, 28h
            call GetRenderDC
        add rsp, 28h

        mov hDeviceContext, rax

        mov rcx, hDeviceContext
        mov rdx, MenuTitleFont

        sub rsp, 28h
            call SelectObject
        add rsp, 28h

        mov OldFont, rax     ; Save previous font

        sub rsp, 28h

            mov rcx, hDeviceContext
            lea rdx, TopHalfRectangle
            mov r8d, 00001100h  ; Color

            call FillRectangle

        add rsp, 28h

        sub rsp, 28h

            mov rcx, hDeviceContext
            lea rdx, BottomHalfRectangle
            mov r8d, 0077ff00h  ; Color

            call FillRectangle

        add rsp, 28h

        mov rcx, hDeviceContext
        lea rdx, GameTitleLabel
        lea r8, GameTitleRect
        mov r9, 0077ff00h

        sub rsp, 28h
            call DrawHUD
        add rsp, 28h

        mov rcx, hDeviceContext
        mov rdx, MenuSubtitleFont

        sub rsp, 28h
            call SelectObject
        add rsp, 28h

        mov OldSubFont, rax     ; Save previous font

        cmp BlinkState, 0
        je SkipPressText

        mov rcx, hDeviceContext
        lea rdx, PressAnyKeyLabel
        lea r8, PressAnyKeyRect
        mov r9, 00001100h

        sub rsp,28h
        call DrawHUD
        add rsp,28h

        SkipPressText:

        mov rcx, hDeviceContext
        mov rdx, OldFont

        sub rsp, 28h
            call SelectObject
        add rsp, 28h

        mov rcx, hMainDeviceContext
        lea rdx, mainRender

        sub rsp,28h
            call EndRender
        add rsp,28h

        mov rcx, mainHWND
        lea rdx, Paint

        sub rsp, 28h
            call EndPaint
        add rsp, 28h

        xor rax, rax
        ret
     Input:
        mov rcx, 1
        mov rdx, r8

        sub rsp, 28h
            call HandleInput
        add rsp, 28h

        ret
     Return:
        ret
MainWndProc ENDP

END