; =========================================================
; Snake Game - x64 MASM - Main Window
; =========================================================

;========================================
;WINDOWS API LIBS
;========================================

INCLUDELIB user32.lib
INCLUDELIB kernel32.lib

INCLUDE basic_data.inc
INCLUDE window_data.inc
INCLUDE render_data.inc
INCLUDE snake_data.inc
INCLUDE snake_state_data.inc
INCLUDE game_state_data.inc
INCLUDE hud_data.inc
INCLUDE main_data.inc

EXTERN GetModuleHandleW:PROC
EXTERN RegisterClassExW:PROC
EXTERN UnregisterClassW:PROC
EXTERN GetLastError:PROC
EXTERN AdjustWindowRectEx:PROC
EXTERN CreateWindowExW:PROC
EXTERN ShowWindow:PROC
EXTERN UpdateWindow:PROC
EXTERN DefWindowProcW:PROC
EXTERN GetMessageW:PROC
EXTERN TranslateMessage:PROC
EXTERN DispatchMessageW:PROC
EXTERN ExitProcess:PROC
EXTERN SetTimer:PROC
EXTERN KillTimer:PROC
EXTERN InvalidateRect:PROC
EXTERN UpdateWindow:PROC
EXTERN GetClientRect: PROC
EXTERN DestroyWindow:PROC

EXTERN BeginPaint: PROC
EXTERN EndPaint: PROC

EXTERN InitRender: PROC
EXTERN BeginRender: PROC
EXTERN GetRenderDC: PROC
EXTERN EndRender: PROC

EXTERN HandleSnakeState: PROC
EXTERN DrawSnake: PROC
EXTERN DrawRectangle: PROC
EXTERN FillRectangle: PROC

EXTERN HandleInput: PROC
EXTERN SetGameState: PROC

EXTERN SpawnFood: PROC
EXTERN DrawFood: PROC
EXTERN GetFoodCount: PROC
EXTERN GetSnakeSpeed: PROC

EXTERN HandleGameState: PROC
EXTERN CallMenu:PROC

EXTERN snakeCounter: QWORD
EXTERN SnakeSize: QWORD
EXTERN SnakeSegments: SNAKESEGMENT
EXTERN SpawnPointX: QWORD
EXTERN SpawnPointY: QWORD
EXTERN HasSpawnedFood: QWORD

EXTERN CurrentScore: QWORD
EXTERN ConvertIntToString: PROC
EXTERN ScoreText: QWORD
EXTERN FoodCountText: QWORD

EXTERN LiveText: QWORD
EXTERN SnakeLives: QWORD

EXTERN CurrentSpeed: QWORD
EXTERN SpeedText: QWORD
EXTERN FoodCountText: QWORD

EXTERN InputType: QWORD
EXTERN CurrentKeyPress: QWORD

EXTERN timerValue: QWORD

EXTERN DrawHUD: PROC

EXTERN ResetSnake:PROC
EXTERN ResetSnakeSpeed:PROC
EXTERN ResetSpeedLabel:PROC
EXTERN ResetScore:PROC
EXTERN ResetFoodCount:PROC
EXTERN SetSnakeState:PROC
EXTERN SetupSnake:PROC

EXTERN GameIcon:QWORD

.data

ClassName   dw 'G','a','m','e',0
WindowTitle     dw 'P','l','a','y','i','n','g',' ','-',' ','S','n','a','k','e',' ','G','a','m','e',0

ScoreLabel      dw "S","c","o","r","e",0
FoodLabel      dw "F","o","o","d",0
SpeedLabel      dw "S","p","e","e","d",0
LivesLabel      dw "L","i","v","e","s",0

XboxControllerLabel dw "X","B","O","X"," ","C","O","N","T","R","O","L","L","E","R",0
KeyboardLabel dw "K","E","Y","B","O","A","R","D",0

SegmentColors dd 0FF0000h, 00FF00h, 0000FFh, 00FFFFh, 0FF00FFh

Paint PAINTSTRUCT <>

PUBLIC clientRect
clientRect RECT <>

ScoreLabelRect RECT <0,5,50,100>
ScoreRect RECT <0,25,90,100>

FoodLabelRect RECT <150, 5, 80, 100>
FoodRect RECT <150, 25, 80, 100>

SpeedLabelRect RECT <320, 5, 80, 100>
SpeedRect RECT <320, 25, 80, 100>

LivesLabelRect RECT <640, 5, 80, 100>
LivesRect RECT <640, 25, 80, 100>

InputTypeRect RECT <800, 15, 250, 100>

HUDRectangle RECT <0,0,600,HUD_AREA>

ScreenRectangle RECT <0,HUD_AREA,600,645>

rc RECT <>

PUBLIC gameHWND
gameHWND HWND 0

hMainDeviceContext HDC 0
hDeviceContext HDC 0
hEditInstance HINSTANCE 0

gameRender RENDER_CONTEXT <0,0,0,0,600,645>

isGameClassRegistered QWORD 0

totalSegments QWORD 0
isRendering QWORD 0 
currentPosition QWORD 0

elapsedTime QWORD 0

WndClass db SIZEOF WNDCLASSEXW dup(0)

PUBLIC Game

.data?

MsgData    db MSG_SIZE dup(?)


.code

Game PROC
    
    ; ----------------------------------------
    ; Seed for the Random Generator 
    ; ----------------------------------------

    rdtsc
    shl rdx, 32
    or rax, rdx
    
    test rax, rax
    jnz SetSpawnPointX
    
    mov rax, 1
    
    SetSpawnPointX:
        mov SpawnPointX, rax

    rdtsc
    shl rdx, 32
    or rax, rdx
    
    test rax, rax
    jnz SetSpawnPointY
    
    mov rax, 1

    SetSpawnPointY:
        mov SpawnPointY, rax

    mov HasSpawnedFood, 0

	; ----------------------------------------
    ; Fill WNDCLASSEXW
    ; ----------------------------------------

    sub rsp, 28h
        mov dword ptr [WndClass+WC_cbSize], SIZEOF WNDCLASSEXW
        mov dword ptr [WndClass+WC_style], 0

        lea rax, WndProc
        mov qword ptr [WndClass+WC_lpfnWndProc], rax

        xor rcx, rcx
        call GetModuleHandleW
    add rsp, 28h

    mov qword ptr [WndClass+WC_hInstance], rax
    mov hEditInstance, rax

    mov rax, GameIcon

    mov qword ptr [WndClass+WC_hIcon], rax
    mov qword ptr [WndClass+WC_hIconSm], rax
    mov qword ptr [WndClass+WC_hCursor], 0
    mov qword ptr [WndClass+WC_hbrBackground], 0
    mov qword ptr [WndClass+WC_lpszMenuName], 0

    lea rax, ClassName
    mov qword ptr [WndClass+WC_lpszClassName], rax

    cmp isGameClassRegistered, 1
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

    mov isGameClassRegistered, 1

    mov rc.left, 0
    mov rc.top, 0
    mov rc.right, 600
    mov rc.bottom, 645

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

    mov gameHWND, rax

     ; ----------------------------------------
    ; Show Window
    ; ----------------------------------------

    mov rcx, gameHWND
    mov rdx, SW_SHOW

    sub rsp, 28h
        call ShowWindow
    add rsp, 28h

    mov rcx, gameHWND

    sub rsp, 28h
        call UpdateWindow
    add rsp, 28h

    ret

Game ENDP

; =========================================================
; Window Procedure
; =========================================================

WndProc PROC

    mov gameHWND, rcx

    cmp edx, WM_NCHITTEST
    je HitTest

    cmp edx, WM_CLOSE
    je CloseGame

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

    Input:
       
        mov rcx, 1
        mov rdx, r8

        sub rsp, 28h
            call HandleInput
        add rsp, 28h

        ret

    CreateWindow:  
        mov rcx, gameHWND
        lea rdx, gameRender

        sub rsp,28h
            call InitRender
        add rsp,28h

        mov rcx, gameHWND
        mov rdx, GAME_INPUT_TIMER_ID
        mov r8, timerValue
        xor r9, r9

        sub rsp, 28h
            call SetTimer
        add rsp, 28h

        xor rax, rax
        ret

    GameLoop:

        mov rcx, 2
        mov rdx, r8

        sub rsp, 28h
            call HandleInput
        add rsp, 28h

        mov rcx, gameHWND
        xor rdx, rdx
        xor r8, r8
        
        sub rsp, 28h
            call InvalidateRect
        add rsp, 28h

        mov rax, elapsedTime
        add rax, timerValue
        mov elapsedTime, rax

        sub rsp, 28h
            call GetSnakeSpeed
        add rsp, 28h

        cmp elapsedTime, rax
        jl Continue

        sub rsp, 28h
            call HandleSnakeState
            mov elapsedTime, 0  
        add rsp, 28h

        ;sub rsp, 28h
            ;call HandleGameState
            ;mov elapsedTime, 0
        ;add rsp, 28h

        Continue:
            xor rax, rax
            ret
        
    Render:     
        
        mov rcx, gameHWND
        ; --- BeginPaint ---
        lea rdx, Paint
        
        sub rsp, 28h
            call BeginPaint
        add rsp, 28h

        mov hMainDeviceContext, rax

        lea rcx, gameRender
        mov edx, rc.right
        mov r8d, rc.bottom

        sub rsp, 28h
            call BeginRender
        add rsp, 28h

        lea rcx, gameRender

        sub rsp, 28h
            call GetRenderDC
        add rsp, 28h

        mov hDeviceContext, rax

    LabelDrawHUD:
        
        sub rsp, 28h

            mov rcx, hDeviceContext
            lea rdx, ScreenRectangle
            mov r8d, 00FFFFFFh  ; Color

            call FillRectangle

        add rsp, 28h

        sub rsp, 28h

            mov rcx, hDeviceContext
            lea rdx, HUDRectangle
            mov r8d, 00000000h  ; Color

            call FillRectangle

        add rsp, 28h

        ;========================
        ;SCORE LABEL
        ;========================

        mov rcx, hDeviceContext
        lea rdx, ScoreLabel
        lea r8, ScoreLabelRect
        mov r9, 00FFFFFFh

        sub rsp, 28h
            call DrawHUD
        add rsp, 28h

        sub rsp, 28h
            mov rcx, CurrentScore
            mov rdx, 10
            lea r8, ScoreText
            call ConvertIntToString
        add rsp, 28h

        mov rcx, hDeviceContext
        lea rdx, ScoreText
        lea r8, ScoreRect
        mov r9, 00FFFFFFh

        sub rsp, 28h
            call DrawHUD
        add rsp, 28h

        ;=========================
        ;FOOD LABEL
        ;=========================

        mov rcx, hDeviceContext
        lea rdx, FoodLabel
        lea r8, FoodLabelRect
        mov r9, 00FFFFFFh

        sub rsp, 28h
            call DrawHUD
        add rsp, 28h

        sub rsp, 28h
            call GetFoodCount
        add rsp, 28h

        mov rcx, rax
        mov rdx, 5
        lea r8, FoodCountText

        sub rsp, 28h
            call ConvertIntToString
        add rsp, 28h

        mov rcx, hDeviceContext
        lea rdx, FoodCountText
        lea r8, FoodRect
        mov r9, 00FFFFFFh

        sub rsp, 28h
            call DrawHUD
        add rsp, 28h

        ;=========================
        ;SPEED LABEL
        ;=========================

        mov rcx, hDeviceContext
        lea rdx, SpeedLabel
        lea r8, SpeedLabelRect
        mov r9, 00FFFFFFh

        sub rsp, 28h
            call DrawHUD
        add rsp, 28h

        mov rcx, hDeviceContext
        
        mov rdx, CurrentSpeed
        add dx, '0' ;'0' == 48 (ascii table)
        mov SpeedText, rdx

        lea rdx, SpeedText
        lea r8, SpeedRect
        mov r9, 00FFFFFFh

        sub rsp, 28h
            call DrawHUD
        add rsp, 28h

        mov rcx, hDeviceContext
        lea rdx, LivesLabel
        lea r8, LivesLabelRect
        mov r9, 00FFFFFFh

        sub rsp, 28h
            call DrawHUD
        add rsp, 28h

        mov rcx, hDeviceContext
        
        mov rdx, SnakeLives
        add dx, '0' ;'0' == 48 (ascii table)
        mov LiveText, rdx

        lea rdx, LiveText
        lea r8, LivesRect
        mov r9, 00FFFFFFh

        sub rsp, 28h
            call DrawHUD
        add rsp, 28h

        mov rcx, hDeviceContext

        cmp InputType, 1
        je KeyboardType

        cmp InputType, 2
        je XboxControllerType

        KeyboardType:
            lea rdx, KeyboardLabel
            jmp DrawInputType

        XboxControllerType:
            lea rdx, XboxControllerLabel

        DrawInputType:
            
            lea r8, InputTypeRect
            mov r9, 00FFFFFFh

            sub rsp, 28h
                call DrawHUD
            add rsp, 28h
    
    DrawFoodLabel: 
        sub rsp, 28h
            mov rcx, hDeviceContext
            call DrawFood
        add rsp, 28h

        jmp ContinueCode

        BadSpawn:
            int 3
        
        ContinueCode:
            mov snakeCounter, 0

        xor rax, rax

    LabelDrawSnake:

        cmp rax, SnakeSize
        jge LabelEndPaint  

        mov rcx, hDeviceContext

        sub rsp, 28h
            call DrawSnake
        add rsp, 28h
        
        mov rax, snakeCounter
        inc rax
        mov snakeCounter, rax
        jmp LabelDrawSnake

    LabelEndPaint:
        mov rcx, hMainDeviceContext
        lea rdx, gameRender

        sub rsp,28h
            call EndRender
        add rsp,28h

        ; --- EndPaint ---
        mov rcx, gameHWND
        lea rdx, Paint

        sub rsp, 28h
            call EndPaint
        add rsp, 28h

        xor rax, rax
        ret

    CloseGame: 

        mov rcx, gameHWND

        mov rdx, GAME_INPUT_TIMER_ID
        sub rsp, 28h
            call KillTimer
        add rsp, 28h

        sub rsp, 28h
			call ResetSnake
		add rsp, 28h

		sub rsp, 28h
			call ResetScore
		add rsp, 28h

		sub rsp, 28h
			call ResetFoodCount
		add rsp, 28h

        mov HasSpawnedFood, 0

		sub rsp, 28h
			call ResetSnakeSpeed
		add rsp, 28h

		sub rsp, 28h
			call ResetSpeedLabel
		add rsp, 28h

        sub rsp, 28h
            mov rcx, SNAKE_STATE_START
            call SetSnakeState
        add rsp, 28h

        sub rsp, 28h
            call SetupSnake
        add rsp, 28h

        mov CurrentKeyPress, 0

        sub rsp, 28h
            mov rcx, gameHWND
            call DestroyWindow
        add rsp, 28h

        sub rsp, 28h
            mov rcx, GAME_STATE_MENU
            call SetGameState
        add rsp, 28h

        mov r8, CurrentKeyPress

        sub rsp, 28h
            call CallMenu
        add rsp, 28h

        xor eax, eax
        
    Return:
        ret


WndProc ENDP

END