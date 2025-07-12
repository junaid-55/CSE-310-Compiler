.MODEL SMALL
.STACK 1000H
.Data
	number DB "00000$"
.CODE
main PROC
	MOV AX, @DATA
	MOV DS, AX
	PUSH BP
	MOV BP, SP
	SUB SP, 2
	SUB SP, 2
	SUB SP, 2
	SUB SP, 2
L1:
	MOV AX, 4       ; Line 9
	MOV [BP-6], AX
	PUSH AX
	POP AX
L2:
	MOV AX, 6       ; Line 10
	MOV [BP-8], AX
	PUSH AX
	POP AX
L3:
L4:
	MOV AX, 0       ; Line 11
	MOV DX, AX
	MOV AX, [BP-6]       ; Line 11
	CMP AX, DX
	JG L5
	JMP L8
L5:
	MOV AX, 3       ; Line 12
	MOV DX, AX
	MOV AX, [BP-8]       ; Line 12
	ADD AX, DX
	PUSH AX
	POP AX       ; Line 12
	MOV [BP-8], AX
	PUSH AX
	POP AX
L6:
	MOV AX, [BP-6]       ; Line 13
	PUSH AX
	DEC AX
	MOV [BP-6], AX
	POP AX
L7:
	JMP L4
L8:
	MOV AX, [BP-8]       ; Line 16
	CALL print_output
	CALL new_line
L9:
	MOV AX, [BP-6]       ; Line 17
	CALL print_output
	CALL new_line
L10:
	MOV AX, 4       ; Line 19
	MOV [BP-6], AX
	PUSH AX
	POP AX
L11:
	MOV AX, 6       ; Line 20
	MOV [BP-8], AX
	PUSH AX
	POP AX
L12:
L13:
	MOV AX, [BP-6]       ; Line 22
	PUSH AX
	DEC AX
	MOV [BP-6], AX
	POP AX       ; Line 22
	CMP AX, 0
	JNE L14
	JMP L16
L14:
	MOV AX, 3       ; Line 23
	MOV DX, AX
	MOV AX, [BP-8]       ; Line 23
	ADD AX, DX
	PUSH AX
	POP AX       ; Line 23
	MOV [BP-8], AX
	PUSH AX
	POP AX
L15:
	JMP L13
L16:
	MOV AX, [BP-8]       ; Line 26
	CALL print_output
	CALL new_line
L17:
	MOV AX, [BP-6]       ; Line 27
	CALL print_output
	CALL new_line
L18:
	MOV AX, 0       ; Line 30
	JMP L20
L19:
L20:
	ADD SP, 8
	POP BP
	MOV AX,4CH
	INT 21H
main ENDP
;-------------------------------
;         print library         
;-------------------------------
;-------------------------------
END main