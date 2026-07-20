
; =========================================================
; Snake Game - x64 MASM - Snake Controller
; =========================================================

INCLUDE snake_data.inc

; =========================================================
; EXTERNS
; =========================================================

EXTERN SnakeDirection: QWORD
EXTERN SnakeX: QWORD
EXTERN SnakeY: QWORD

; =========================================================
; DATA
; =========================================================

.data

; =========================================================
; CODE
; =========================================================

.code 

MoveRight PROC
    cmp SnakeDirection, SNAKE_LEFT_DIRECTION
    je EndInput

    mov SnakeDirection, SNAKE_RIGHT_DIRECTION
    mov SnakeX, SNAKE_MOVEMENT_CELL
    mov SnakeY, 0
    
    EndInput:
        ret
MoveRight ENDP

MoveLeft PROC
cmp SnakeDirection, SNAKE_RIGHT_DIRECTION
    je EndInput

    mov SnakeDirection, SNAKE_LEFT_DIRECTION
    mov SnakeX, SNAKE_MOVEMENT_CELL
    mov SnakeY, 0

    EndInput:
        ret
MoveLeft ENDP

MoveUp PROC
    cmp SnakeDirection, SNAKE_DOWN_DIRECTION
    je EndInput

    mov SnakeDirection, SNAKE_UP_DIRECTION
    mov SnakeX, 0
    mov SnakeY, SNAKE_MOVEMENT_CELL

    EndInput:
        ret
MoveUp ENDP

MoveDown PROC
    cmp SnakeDirection, SNAKE_UP_DIRECTION
    je EndInput

    mov SnakeDirection, SNAKE_DOWN_DIRECTION
    mov SnakeX, 0
    mov SnakeY, SNAKE_MOVEMENT_CELL

    EndInput:
        ret
MoveDown ENDP

END