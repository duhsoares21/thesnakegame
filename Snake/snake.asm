
; =========================================================
; Snake Game - x64 MASM - Snake System
; =========================================================

INCLUDE basic_data.inc
INCLUDE game_data.inc
INCLUDE snake_data.inc
INCLUDE snake_state_data.inc
INCLUDE hud_data.inc

;========================================
;EXTERNS
;========================================

EXTERN SpawnFood: PROC
EXTERN DrawRectangle: PROC
EXTERN GetSnakeState: PROC

EXTERN lockInput: QWORD
EXTERN ClientRect: RECT

.data

PUBLIC ResetSnake
PUBLIC SetupSnake

PUBLIC MoveSnake
PUBLIC DrawSnake
PUBLIC GrowSnake
PUBLIC ShrinkSnake
PUBLIC ResetSnakeSize

PUBLIC GetLivesSnake
PUBLIC AddLiveSnake
PUBLIC RemoveLiveSnake

PUBLIC GetSnakeSpeed
PUBLIC SetSnakeSpeed
PUBLIC ResetSnakeSpeed
PUBLIC IncreaseSnakeSpeed

PUBLIC SnakeSegments
SnakeSegments SNAKESEGMENT 50 dup(<>)

PUBLIC SnakeDirection
SnakeDirection QWORD SNAKE_DEFAULT_DIRECTION

PUBLIC SnakeTileSize
SnakeTileSize DWORD SNAKE_TILE_SIZE

PUBLIC SnakeX
SnakeX QWORD SNAKE_MOVEMENT_CELL

PUBLIC SnakeY
SnakeY QWORD 0

PUBLIC SnakeLives
SnakeLives QWORD SNAKE_INITIAL_LIVES

PUBLIC SnakeSize
SnakeSize QWORD SNAKE_INITIAL_SIZE

SnakeSpeed QWORD SNAKE_DEFAULT_SPEED

PUBLIC SnakeHeadX
SnakeHeadX QWORD 0

PUBLIC SnakeHeadY
SnakeHeadY QWORD 0

previousSegmentX QWORD 0
previousSegmentY QWORD 0

previousSnakeSegment QWORD 0

PUBLIC snakeCounter
snakeCounter QWORD 0

.code

ResetSnake PROC
    mov SnakeLives, SNAKE_INITIAL_LIVES
    mov SnakeSize, SNAKE_INITIAL_SIZE
    mov SnakeSpeed, SNAKE_DEFAULT_SPEED
    ret
ResetSnake ENDP

SetupSnake PROC
    
    push r14
    push r15

    xor r14, r14

    mov SnakeDirection, SNAKE_DEFAULT_DIRECTION
    mov SnakeX, SNAKE_MOVEMENT_CELL
    mov SnakeY, 0

    mov r15, SnakeSize
    dec r15
    imul r15d, SnakeTileSize

    add r15, SNAKE_START_X

LoopSnake:

    cmp r14, SnakeSize
    je Finish

    imul rdx, r14, SIZEOF SNAKESEGMENT

    mov rax, r15
    mov SnakeSegments[rdx].X, rax
    mov SnakeSegments[rdx].Y, SNAKE_START_Y

    cmp r14, 0
    jne ContinueLoop

    SetSnakeHead: 
        mov SnakeHeadX, r15
        mov SnakeHeadY, 0

    ContinueLoop:

        sub r15, snakeX
        inc r14
        jmp LoopSnake   

Finish:
    sub rsp, 20h
        call SpawnFood
    add rsp, 20h

    pop r15
    pop r14
    ret

SetupSnake ENDP

MoveSnake PROC

    push rbx
    push r12
    push r13
    push r14
    push r15

    mov r12, SnakeX ; X
    mov r13, SnakeY ; Y
    mov r15, SnakeDirection

    xor r14, r14

    imul rbx, r14, SIZEOF SNAKESEGMENT

    mov r10, SnakeSegments[rbx].X
    mov r11, SnakeSegments[rbx].Y

    cmp r15, SNAKE_RIGHT_DIRECTION
    je RIGHT

    cmp r15, SNAKE_LEFT_DIRECTION
    je LEFT

    cmp r15, SNAKE_UP_DIRECTION
    je UP

    cmp r15, SNAKE_DOWN_DIRECTION
    je DOWN
        
    RIGHT:
        mov rax, SnakeSegments[rbx].X
        add rax, r12
        jmp SetX

    LEFT:
        mov rax, SnakeSegments[rbx].X
        sub rax, r12
        jmp SetX
    
    SetX:

    mov SnakeSegments[rbx].X, rax
    
    UP:
        mov rax, SnakeSegments[rbx].Y
        sub rax, r13
        jmp SetY

    DOWN:
        mov rax, SnakeSegments[rbx].Y
        add rax, r13
        jmp SetY

    SetY:
        mov SnakeSegments[rbx].Y, rax

    cmp r14, 0
    je SetSnakeHead

    jmp Increment

    SetSnakeHead:
        mov rax, SnakeSegments[rbx].X
        mov SnakeHeadX, rax

        mov rax, SnakeSegments[rbx].Y
        mov SnakeHeadY, rax

    Increment:
        inc r14

LoopSnake:

    cmp r14, SnakeSize
    je Finish

    imul rbx, r14, SIZEOF SNAKESEGMENT

    mov r8, SnakeSegments[rbx].X
    mov r9, SnakeSegments[rbx].Y

    mov SnakeSegments[rbx].X, r10
    mov SnakeSegments[rbx].Y, r11

    mov r10, r8
    mov r11, r9

    inc r14
    jmp LoopSnake

Finish:

    mov lockInput, 0

    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx

    ret

MoveSnake ENDP

;========================================================
;DrawSnake - Parameters Sheet
;
;RCX = Device Context
;========================================================

DrawSnake PROC
    
    sub rsp, 28h
        call GetSnakeState
    add rsp, 28h

    cmp rax, SNAKE_STATE_DEAD
    je Finish

    mov r10, rcx ;hDeviceContext
          
    mov rax, snakeCounter
    and rax, 1

    test rax, rax
    jz DarkColor

    LightColor:
        mov r9d, 0077ff00h
        jmp DrawRect

    DarkColor:
        mov r9d, 0000bb00h
        
    DrawRect:
        mov r11, snakeCounter
        imul r11, SIZEOF SNAKESEGMENT
        lea rax, SnakeSegments
        add rax, r11

        mov rcx, r10
        mov rdx, [rax].SNAKESEGMENT.X
        mov r8, [rax].SNAKESEGMENT.Y
        add r8, HUD_AREA

        sub rsp, 28h
            call DrawRectangle
        add rsp, 28h

        Finish:
            ret

DrawSnake ENDP

GrowSnake PROC

    mov rax, SnakeSize

    mov rbx, rax
    dec rbx
    imul rbx, SIZEOF SNAKESEGMENT

    mov rcx, rax
    imul rcx, SIZEOF SNAKESEGMENT

    mov rdx, SnakeSegments[rbx].X
    mov SnakeSegments[rcx].X, rdx

    mov rdx, SnakeSegments[rbx].Y
    mov SnakeSegments[rcx].Y, rdx

    inc rax
    mov SnakeSize, rax

    ret

GrowSnake ENDP

ShrinkSnake PROC

    mov rax, SnakeSize

    mov rbx, rax
    inc rbx
    imul rbx, SIZEOF SNAKESEGMENT

    mov rcx, rax
    imul rcx, SIZEOF SNAKESEGMENT

    mov rdx, SnakeSegments[rbx].X
    mov SnakeSegments[rcx].X, rdx

    mov rdx, SnakeSegments[rbx].Y
    mov SnakeSegments[rcx].Y, rdx

    mov rax, SnakeSize

    mov rcx, rax            
    shr rcx, 1              

    sub rax, rcx            

    mov SnakeSize, rax

    ret

ShrinkSnake ENDP

ResetSnakeSize PROC
    cmp SnakeSize, SNAKE_INITIAL_SIZE
    jle Return

    mov rax, SNAKE_INITIAL_SIZE
    mov SnakeSize, rax
    
    Return:
        ret
ResetSnakeSize ENDP

AddLiveSnake PROC
    mov rax, SnakeLives
    inc rax
    mov SnakeLives, rax
    ret
AddLiveSnake ENDP

RemoveLiveSnake PROC
    mov rax, SnakeLives
    dec rax
    mov SnakeLives, rax
    ret
RemoveLiveSnake ENDP

;==================================
;SetLivesSnake - Parameters Sheet
;
;RCX = Number of lives
;==================================

SetLivesSnake PROC
    mov SnakeLives, rcx
    ret
SetLivesSnake ENDP

GetLivesSnake PROC
    mov rax, SnakeLives
    ret
GetLivesSnake ENDP

GetSnakeSpeed PROC
    mov rax, SnakeSpeed
    ret
GetSnakeSpeed ENDP

;==================================
;SetLivesSnake - Parameters Sheet
;
;RCX = Snake Speed
;==================================

SetSnakeSpeed PROC
    mov SnakeSpeed, rcx
    ret
SetSnakeSpeed ENDP

ResetSnakeSpeed PROC
    mov SnakeSpeed, SNAKE_DEFAULT_SPEED
    ret
ResetSnakeSpeed ENDP

IncreaseSnakeSpeed PROC
    mov rax, SnakeSpeed
    sub rax, SNAKE_SPEED_INCREMENT
    mov SnakeSpeed, rax
    ret
IncreaseSnakeSpeed ENDP

END