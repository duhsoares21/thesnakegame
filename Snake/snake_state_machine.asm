; =========================================================
; Snake Game - x64 MASM - Snake State Machine System
; =========================================================

INCLUDE snake_data.inc
INCLUDE snake_state_data.inc
INCLUDE audio_data.inc
INCLUDE hud_data.inc

;========================================
;EXTERNS
;========================================

EXTERN SnakeSize: QWORD

EXTERN SetupSnake: PROC
EXTERN ResetSnake: PROC
EXTERN ResetScore: PROC
EXTERN MoveSnake: PROC
EXTERN GrowSnake: PROC
EXTERN ShrinkSnake: PROC
EXTERN ResetSnakeSize: PROC
EXTERN GetLivesSnake: PROC
EXTERN SetLivesSnake: PROC
EXTERN RemoveLiveSnake: PROC
EXTERN ResetFoodCount: PROC
EXTERN IncreaseSnakeSpeed: PROC
EXTERN GetSpeedLabel: PROC
EXTERN ResetSnakeSpeed: PROC
EXTERN IncreaseSpeedLabel: PROC
EXTERN ResetSpeedLabel: PROC

EXTERN SpawnFood: PROC

EXTERN AddScore:PROC
EXTERN PlayNote: PROC
EXTERN PlayIntroBGM: PROC

EXTERN WallCollision: PROC
EXTERN SelfCollision: PROC
EXTERN FoodCollision: PROC

EXTERN HasSpawnedFood: QWORD

.data
	PUBLIC GetSnakeState
	PUBLIC SetSnakeState
	PUBLIC HandleSnakeState

	SnakeState QWORD SNAKE_STATE_START

.code

	GetSnakeState PROC
		mov rax, SnakeState
		ret
	GetSnakeState ENDP

	;==================================
	;SetSnakeState - Parameters Sheet
	;
	;RCX = State of the snake
	;==================================

	SetSnakeState PROC
		mov SnakeState, rcx		
		ret
	SetSnakeState ENDP

	HandleSnakeState PROC
		cmp SnakeState, SNAKE_STATE_START
		je SnakeStart

		cmp SnakeState, SNAKE_STATE_ALIVE
		je SnakeALive

		cmp SnakeState, SNAKE_STATE_HIT
		je SnakeHit

		cmp SnakeState, SNAKE_STATE_EATING
		je SnakeEating

		cmp SnakeState, SNAKE_STATE_DEAD
		je SnakeDead

		SnakeStart:
			sub rsp, 28h
				call SetupSnake
			add rsp, 28h

			mov rcx, SNAKE_STATE_ALIVE

			sub rsp, 28h
				call SetSnakeState
			add rsp, 28h

			sub rsp, 28h
				call PlayIntroBGM
			add rsp, 28h

			ret

		SnakeAlive:
			sub rsp, 28h
				call WallCollision
			add rsp, 28h

			sub rsp, 28h
				call SelfCollision
			add rsp, 28h

			cmp SnakeState, SNAKE_STATE_HIT
			je CollisionDetected

			sub rsp, 28h
				call MoveSnake
			add rsp, 28h

			sub rsp, 28h
				call FoodCollision
			add rsp, 28h

			mov rcx, NOTE_D6
			mov rdx, 50

			sub rsp, 28h
				call PlayNote
			add rsp, 28h

			CollisionDetected:

			ret

		SnakeHit: 
			sub rsp, 28h
				call SetupSnake
			add rsp, 28h

			sub rsp, 28h
				call ShrinkSnake
			add rsp, 28h

			sub rsp, 28h
				call GetLivesSnake
			add rsp, 28h

			dec rax
			mov rcx, rax

			sub rsp, 28h
				call SetLivesSnake
			add rsp, 28h

			sub rsp, 28h
				call GetLivesSnake
			add rsp, 28h

			cmp rax, 0
			je SnakeDead

			mov rcx, SNAKE_STATE_ALIVE

			sub rsp, 28h
				call SetSnakeState
			add rsp, 28h

			ret

		SnakeEating:
			
			sub rsp, 28h
				call GrowSnake
			add rsp, 28h

			mov rax, SnakeSize

			xor rdx, rdx
			mov rcx, SNAKE_GROWING_SPEED

			div rcx             

			test rdx, rdx
			jz SpeedUp    
			
			jmp DontSpeedUp

			SpeedUp:
				sub rsp, 28h
					call GetSpeedLabel
				add rsp, 28h

				cmp rax, MAXIMUM_SPEED_LABEL
				je DontSpeedUp

				sub rsp, 28h
					call IncreaseSnakeSpeed
				add rsp, 28h

				sub rsp, 28h
					call IncreaseSpeedLabel
				add rsp, 28h

				sub rsp, 28h
					call ResetSnakeSize
				add rsp, 28h

			DontSpeedUp:

			sub rsp, 28h
				call AddScore
			add rsp, 28h

			mov HasSpawnedFood, 0

			sub rsp, 28h
				call SpawnFood
			add rsp, 28h

			mov rcx, SNAKE_STATE_ALIVE

			sub rsp, 28h
				call SetSnakeState
			add rsp, 28h

			mov rcx, NOTE_DS6
			mov rdx, 25

			sub rsp, 28h
				call PlayNote
			add rsp, 28h

			mov rcx, NOTE_GS6
			mov rdx, 25

			sub rsp, 28h
				call PlayNote
			add rsp, 28h

			ret

		SnakeDead:
			sub rsp, 28h
				call ResetSnake
			add rsp, 28h

			sub rsp, 28h
				call ResetScore
			add rsp, 28h

			sub rsp, 28h
				call ResetFoodCount
			add rsp, 28h

			sub rsp, 28h
				call ResetSnakeSpeed
			add rsp, 28h

			sub rsp, 28h
				call ResetSpeedLabel
			add rsp, 28h

			sub rsp, 28h
				call SetupSnake
			add rsp, 28h

			mov HasSpawnedFood, 0

			sub rsp, 28h
				call SpawnFood
			add rsp, 28h

			mov rcx, SNAKE_STATE_ALIVE

			sub rsp, 28h
				call SetSnakeState
			add rsp, 28h

			ret

	HandleSnakeState ENDP

END