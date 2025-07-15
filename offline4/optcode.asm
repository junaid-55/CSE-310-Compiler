.MODEL SMALL
.STACK 1000H
.Data
	number DB "00000$"
.CODE
check PROC
	PUSH BP
	MOV BP, SP
	SUB SP, 2
L1:
	MOV AX, 12       ; Line 3
	MOV [BP-2], AX
L2:
	MOV AX, 0       ; Line 4
	MOV DX, AX
	MOV AX, [BP+4]       ; Line 4
	CMP AX, DX
	JE L3
	JMP L8
L3:
	SUB SP, 2
L4:
	MOV AX, 1       ; Line 6
	MOV [BP-4], AX
L5:
	MOV AX, [BP-4]       ; Line 7
	CALL print_output
	CALL new_line
L6:
	MOV AX, [BP-4]       ; Line 8
	JMP L18
L7:
	JMP L13
L8:
	SUB SP, 2
	SUB SP, 2
L9:
	MOV AX, 1       ; Line 12
	MOV [BP-6], AX
L10:
	MOV AX, 2       ; Line 13
	MOV [BP-8], AX
L11:
	MOV AX, [BP-6]       ; Line 14
	MOV DX, AX
	MOV AX, [BP+4]       ; Line 14
	ADD AX, DX
	PUSH AX
	MOV AX, [BP-8]       ; Line 14
	MOV DX, AX
	POP AX       ; Line 14
	ADD AX, DX
	PUSH AX
	POP AX       ; Line 14
	JMP L18
L12:
L13:
	SUB SP, 2
L14:
	MOV AX, 3       ; Line 17
	MOV [BP-10], AX
L15:
	MOV AX, [BP-10]       ; Line 18
	CALL print_output
	CALL new_line
L16:
	MOV AX, [BP-10]       ; Line 19
	JMP L18
L17:
L18:
	ADD SP, 10
	POP BP
	RET 2
check ENDP
main PROC
	MOV AX, @DATA
	MOV DS, AX
	PUSH BP
	MOV BP, SP
	SUB SP, 2
L19:
	MOV AX, 0       ; Line 24
	PUSH AX
	CALL check
	PUSH AX
	POP AX       ; Line 24
	MOV [BP-2], AX
L20:
	MOV AX, [BP-2]       ; Line 25
	CALL print_output
	CALL new_line
L21:
	MOV AX, 0       ; Line 26
	JMP L23
L22:
L23:
	ADD SP, 2
	POP BP
	MOV AX,4CH
	INT 21H
main ENDP
;-------------------------------
;         print library         
;-------------------------------
;-------------------------------
END main
