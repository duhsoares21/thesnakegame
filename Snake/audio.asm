; =========================================================
; Snake Game - x64 MASM - Audio System
; =========================================================

;========================================
;INCLUDES
;========================================

INCLUDELIB kernel32.lib
INCLUDE audio_data.inc

;========================================
;EXTERNS
;========================================

EXTERN Beep: PROC

.data

PUBLIC PlayNote
PUBLIC PlayIntroBGM

.code

;===========================================
;PlayNote - Parameters Sheet
;
;RCX = Frequency of the beep
;RDX = Duration of the beep
;===========================================

PlayNote PROC
	sub rsp, 28h
		call Beep
	add rsp, 28h
	ret
PlayNote ENDP

PlayIntroBGM PROC
	mov rcx, NOTE_C4
	mov rdx, 1000

	sub rsp, 28h
		call PlayNote
	add rsp, 28h

	mov rcx, NOTE_E4
	mov rdx, 500
	sub rsp, 28h
		call PlayNote
	add rsp, 28h

	mov rcx, NOTE_G4
	mov rdx, 300
	sub rsp, 28h
		call PlayNote
	add rsp, 28h

	mov rcx, NOTE_A4
	mov rdx, 500
	sub rsp, 28h
		call PlayNote
	add rsp, 28h

	mov rcx, NOTE_F4
	mov rdx, 300
	sub rsp, 28h
		call PlayNote
	add rsp, 28h

	mov rcx, NOTE_F4
	mov rdx, 500
	sub rsp, 28h
		call PlayNote
	add rsp, 28h
	ret
PlayIntroBGM ENDP

END