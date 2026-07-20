
; =========================================================
; Snake Game - x64 MASM - Main Window
; =========================================================

;========================================
;WINDOWS API LIBS
;========================================

INCLUDE food_data.inc
INCLUDE snake_data.inc
INCLUDE hud_data.inc

;========================================
;EXTERNS
;========================================

EXTERN DrawRectangle:PROC

EXTERN SnakeTileSize: QWORD
EXTERN SnakeSize: QWORD
EXTERN SnakeSegments: SNAKESEGMENT

.data

PUBLIC GetFoodCount
PUBLIC IncreaseFoodCount
PUBLIC ResetFoodCount
PUBLIC SpawnFood

PUBLIC SpawnPointX
SpawnPointX QWORD 0

PUBLIC SpawnPointY
SpawnPointY QWORD 0

PUBLIC HasSpawnedFood
HasSpawnedFood QWORD 0

PUBLIC FoodCount
FoodCount QWORD 0

.code

GetFoodCount PROC
	mov rax, FoodCount
	ret
GetFoodCount ENDP

IncreaseFoodCount PROC
	mov rax, FoodCount
	inc rax
	mov FoodCount, rax
	ret
IncreaseFoodCount ENDP

ResetFoodCount PROC
	mov FoodCount, 0
	ret
ResetFoodCount ENDP

SpawnFood PROC

	push r12
	push r13
	push r14
	push rbx

	cmp HasSpawnedFood, 1
	je Finish

	mov rax, SpawnPointX

	test rax, rax
	jnz RandomGen

	mov rax, 1

	;========================
	; RANDOM GENERATOR
	;========================

	RandomGen:
		mov rcx, rax
		shl rcx, 13
		xor rax, rcx

		mov rcx, rax
		shr rcx, 7
		xor rax, rcx

		mov rcx, rax
		shl rcx, 17
		xor rax, rcx

		test rax, rax
		jnz SetSpawnPoint

		mov rax, 1

	;========================
	; SPAWN
	;========================

	SetSpawnPoint:
		mov SpawnPointX, rax
		mov SpawnPointY, rax

		xor rdx, rdx

		mov rcx, MAX_RANDOM_VALUE
		div rcx
		mov rax, rdx

		mov r12, rax

		mov rcx, MAX_RANDOM_VALUE
		div rcx
		mov rax, rdx

		mov r13, rax

		;====================
		;CHECK IF TOUCH SNAKE
		;====================

		xor r14, r14

		imul r12, SNAKE_MOVEMENT_CELL
		imul r13, SNAKE_MOVEMENT_CELL

		LoopSnake:
			
			cmp r14, SnakeSize
			je SaveSpawnPoint

			imul rbx, r14, SIZEOF SNAKESEGMENT

			cmp r12, SnakeSegments[rbx].X

			je CollisionX

			jmp NextCheck

			CollisionX:
				cmp r13, SnakeSegments[rbx].Y
				je CollisionY

				jmp NextCheck

			CollisionY:
				jmp RandomGen
		
			NextCheck:
				inc r14
				jmp LoopSnake

	;====================
	;SAVE THE SPAWN POINT
	;====================
	
	SaveSpawnPoint:
		mov SpawnPointX, r12
		mov SpawnPointY, r13

		mov HasSpawnedFood, 1

		jmp Finish

	Finish:
		pop rbx
		pop r14
		pop r13
		pop r12

		ret
	
SpawnFood ENDP

;============================
;DrawFood - Parameters Sheet
;
;RCX = Device Context
;============================

DrawFood PROC
	
	mov rdx, SpawnPointX
    mov r8, SpawnPointY
    add r8, HUD_AREA
    mov r9, 0000ddffh

	sub rsp, 28h
		call DrawRectangle
	add rsp, 28h

	ret
DrawFood ENDP

END