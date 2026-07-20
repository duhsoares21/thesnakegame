; =========================================================
; Snake Game - x64 MASM - Collision System
; =========================================================

;========================================
;INCLUDES
;========================================

INCLUDELIB user32.lib

INCLUDE basic_data.inc
INCLUDE snake_data.inc
INCLUDE snake_state_data.inc
INCLUDE hud_data.inc

;========================================
;EXTERNS
;========================================

EXTERN GetClientRect: PROC
EXTERN GetLastError: PROC

EXTERN SetupSnake: PROC
EXTERN SetSnakeState: PROC

EXTERN GetFoodCount:PROC
EXTERN IncreaseFoodCount: PROC
EXTERN ResetFoodCount: PROC

EXTERN gameHWND:HWND
EXTERN SnakeHeadX: QWORD
EXTERN SnakeHeadY: QWORD
EXTERN SnakeSegments: SNAKESEGMENT
EXTERN SnakeSize: QWORD
EXTERN SnakeX: QWORD
EXTERN SnakeY: QWORD
EXTERN SnakeDirection: QWORD

EXTERN SpawnPointX: QWORD
EXTERN SpawnPointY: QWORD

.data

PUBLIC ClientRect
ClientRect RECT <>

.code

WallCollision PROC
	push rbx
	push r14

	mov rcx, gameHWND
	lea rdx, ClientRect

	sub rsp, 28h
		call GetClientRect
	add rsp, 28h

	test rax, rax
	jnz Continue

	sub rsp, 28h
		call GetLastError
	add rsp, 28h

	int 3; Error

	Continue:
		
		mov rax, SnakeHeadX
		mov rdx, SnakeHeadY

		cmp SnakeDirection, SNAKE_RIGHT_DIRECTION
		je NextRight

		cmp SnakeDirection, SNAKE_LEFT_DIRECTION
		je NextLeft

		cmp SnakeDirection, SNAKE_UP_DIRECTION
		je NextUp

		cmp SnakeDirection, SNAKE_DOWN_DIRECTION
		je NextDown

		NextRight:
			add rax, SNAKE_MOVEMENT_CELL
			jmp CheckBounds
		NextLeft:
			sub rax, SNAKE_MOVEMENT_CELL
			jmp CheckBounds
		NextUp:
			sub rdx, SNAKE_MOVEMENT_CELL
			jmp CheckBounds
		NextDown:
			add rdx, SNAKE_MOVEMENT_CELL
			jmp CheckBounds

		CheckBounds:
			mov r10d, ClientRect.right
			sub r10d, SNAKE_MOVEMENT_CELL

			mov r11d, ClientRect.bottom
			sub r11d, HUD_AREA
			sub r11d, SNAKE_MOVEMENT_CELL

			cmp rax, 0
			jl Hit
		
			cmp rax, r10
			jg Hit

			cmp rdx, 0
			jl Hit

			cmp rdx, r11
			jg Hit

			jmp NotHit

		Hit:	
			sub rsp, 28h
				mov rcx, SNAKE_STATE_HIT
				call SetSnakeState
			add rsp, 28h
			jmp Cleanup

		NotHit:

			jmp Cleanup

		Cleanup:
			
			pop r14
			pop rbx

			ret

WallCollision ENDP

SelfCollision PROC

push r14
push rbx

mov r14, 1

LoopSnake:

    cmp r14, SnakeSize
    je Finish

    imul rbx, r14, SIZEOF SNAKESEGMENT

    mov rax, SnakeHeadX
	cmp rax, SnakeSegments[rbx].X

	je CollisionX

	jmp NextCheck

	CollisionX:
		mov rcx, SnakeHeadY
		cmp rcx, SnakeSegments[rbx].Y
		je CollisionY

		jmp NextCheck

	CollisionY:
		sub rsp, 28h
			mov rcx, SNAKE_STATE_HIT
			call SetSnakeState
		add rsp, 28h

		jmp Finish
		
	NextCheck:
		inc r14

		jmp LoopSnake

Finish:

	pop rbx
    pop r14
    ret

SelfCollision ENDP

FoodCollision PROC
	mov rax, SnakeHeadX
	
	mov rcx, SpawnPointX

	cmp rax, rcx
	je CheckY

	jmp NotHit

	CheckY:
		mov rax, SnakeHeadY
		mov rcx, SpawnPointY

		cmp rax, rcx
		je Hit

		jmp NotHit

	Hit:
		sub rsp, 28h
			mov rcx, SNAKE_STATE_EATING
			call SetSnakeState
		add rsp, 28h

		sub rsp, 28h
			call IncreaseFoodCount
		add rsp, 28h
		ret

	NotHit:
		ret
FoodCollision ENDP

END