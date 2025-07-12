.MODEL SMALL
.STACK 1000H
.Data
	number DB "00000$"
	i DW 1 DUP (0000H)
	j DW 1 DUP (0000H)
	k DW 1 DUP (0000H)
.CODE
main PROC
	MOV AX, @DATA
	MOV DS, AX
	PUSH BP
	MOV BP, SP
	MOV AX, 3       ; Line 5
	MOV i, AX
L1:
	MOV AX, 8       ; Line 6
	MOV j, AX
L2:
	MOV AX, 6       ; Line 7
	MOV k, AX
L3:
	MOV AX, 3       ; Line 10
	MOV DX, AX
	MOV AX, i       ; Line 10
	CMP AX, DX
	JE L4
	JMP L6
L4:
	MOV AX, j       ; Line 11
	CALL print_output
	CALL new_line
L5:
L6:
	MOV AX, 8       ; Line 14
	MOV DX, AX
	MOV AX, j       ; Line 14
	CMP AX, DX
	JL L7
	JMP L9
L7:
	MOV AX, i       ; Line 15
	CALL print_output
	CALL new_line
L8:
	JMP L11
L9:
	MOV AX, k       ; Line 18
	CALL print_output
	CALL new_line
L10:
L11:
	MOV AX, 6       ; Line 21
	MOV DX, AX
	MOV AX, k       ; Line 21
	CMP AX, DX
	JNE L12
	JMP L14
L12:
	MOV AX, k       ; Line 22
	CALL print_output
	CALL new_line
L13:
	JMP L23
L14:
	MOV AX, 8       ; Line 24
	MOV DX, AX
	MOV AX, j       ; Line 24
	CMP AX, DX
	JG L15
	JMP L17
L15:
	MOV AX, j       ; Line 25
	CALL print_output
	CALL new_line
L16:
	JMP L23
L17:
	MOV AX, 5       ; Line 27
	MOV DX, AX
	MOV AX, i       ; Line 27
	CMP AX, DX
	JL L18
	JMP L20
L18:
	MOV AX, i       ; Line 28
	CALL print_output
	CALL new_line
L19:
	JMP L23
L20:
	MOV AX, 0       ; Line 31
	MOV k, AX
L21:
	MOV AX, k       ; Line 32
	CALL print_output
	CALL new_line
L22:
L23:
	MOV AX, 0       ; Line 36
	JMP L25
L24:
L25:
	POP BP
	MOV AX,4CH
	INT 21H
main ENDP
;-------------------------------
;         print library         
;-------------------------------
;-------------------------------
END main
