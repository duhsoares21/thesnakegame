; =========================================================
; Snake Game - x64 MASM - Game State Machine System
; =========================================================

INCLUDE basic_data.inc
INCLUDE game_state_data.inc
INCLUDE input_data.inc
INCLUDE window_data.inc

;========================================
;EXTERNS
;========================================

EXTERN timerValue: QWORD
EXTERN CurrentKeyPress: QWORD
EXTERN mainHWND: HWND
EXTERN gameHWND: HWND

EXTERN main:PROC
EXTERN Game:PROC
EXTERN SetTimer: PROC
EXTERN KillTimer: PROC
EXTERN ShowWindow:PROC
EXTERN PostMessageW:PROC
EXTERN DestroyWindow:PROC

;========================================
;ACTIONS
;========================================

EXTERN MoveRight: PROC;
EXTERN MoveLeft: PROC;
EXTERN MoveUp: PROC;
EXTERN MoveDown: PROC;

.data

PUBLIC HandleGameState
PUBLIC CallMenu

gameState QWORD GAME_STATE_MENU

isMainMenuClosed QWORD 0
paused QWORD 0

.code

SetGameState PROC
	mov gameState, rcx
	ret
SetGameState ENDP

CallMenu PROC
    jmp MenuLabel
CallMenu ENDP

HandleGameState PROC

	mov r8, CurrentKeyPress
    mov CurrentKeyPress, 0


	cmp gameState, GAME_STATE_MENU
	je MenuLabel

	cmp gameState, GAME_STATE_PLAYING
	je PlayingLabel
    
HandleGameState ENDP

cmp r8, 0
je Return

MenuLabel:
    test r8d, XINPUT_GAMEPAD_BACK
    jnz QuitMenu

    cmp isMainMenuClosed, 1
    je OpenMenu 

    cmp r8, VK_RETURN
    je StartGame

    test r8d, XINPUT_GAMEPAD_START
    jnz StartGame

    jmp Return

	StartGame: 

        mov rcx, mainHWND
        mov rdx, SW_HIDE

        sub rsp, 28h
            call ShowWindow
        add rsp, 28h

        mov isMainMenuClosed, 1

        sub rsp, 28h
            mov rcx, GAME_STATE_PLAYING
            call SetGameState
        add rsp, 28h

        sub rsp, 28h
            call Game
        add rsp, 28h

        jmp Return

        OpenMenu: 
        mov isMainMenuClosed, 0
            
        mov rcx, mainHWND
        mov rdx, SW_SHOW

        sub rsp, 28h
            call ShowWindow
        add rsp, 28h

        jmp Return

        QuitMenu:
        mov rcx, mainHWND

        sub rsp,28h
            call DestroyWindow
        add rsp,28h
                
        jmp Return

PlayingLabel:

    cmp r8, VK_RIGHT
    je MovePlayerRight

    cmp r8, VK_LEFT
    je MovePlayerLeft

    cmp r8, VK_UP
    je MovePlayerUp

    cmp r8, VK_DOWN
    je MovePlayerDown

    cmp r8, VK_ESCAPE
    je PauseGame

    test r8, XINPUT_GAMEPAD_DPAD_RIGHT
    jnz MovePlayerRight

    test r8, XINPUT_GAMEPAD_DPAD_LEFT
    jnz MovePlayerLeft

    test r8, XINPUT_GAMEPAD_DPAD_UP
    jnz MovePlayerUp

    test r8, XINPUT_GAMEPAD_DPAD_DOWN
    jnz MovePlayerDown

    test r8d, XINPUT_GAMEPAD_START
    jnz PauseGame

    test r8d, XINPUT_GAMEPAD_BACK
    jnz QuitGame

	MovePlayerRight:
        sub rsp, 28h
            call MoveRight
        add rsp, 28h
        ret

    MovePlayerLeft:
        sub rsp, 28h
            call MoveLeft
        add rsp, 28h
        ret

    MovePlayerUp:
        sub rsp, 28h
            call MoveUp
        add rsp, 28h
        ret

    MovePlayerDown:
        sub rsp, 28h
            call MoveDown
        add rsp, 28h
        ret

    PauseGame:
    
        cmp paused, 0
        je DoPause

        DoResume: 

            mov paused, 0

            mov rcx, gameHWND
            mov rdx, GAME_INPUT_TIMER_ID
            mov r8, timerValue
            xor r9, r9

            sub rsp, 28h
                call SetTimer
            add rsp, 28h

            jmp return

        DoPause:
            mov paused, 1

            mov rcx, gameHWND
            mov rdx, GAME_INPUT_TIMER_ID
            sub rsp, 28h
                call KillTimer
            add rsp, 28h

            jmp return

        QuitGame:
            mov rcx, gameHWND
            mov edx, WM_CLOSE
            xor r8d, r8d
            xor r9d, r9d

            sub rsp,28h
                call PostMessageW
            add rsp,28h

            mov r8, CurrentKeyPress

            jmp MenuLabel

Return:
    ret

END