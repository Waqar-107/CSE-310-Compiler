.MODEL SMALL
.STACK 100H
.DATA
	a2 DW ?
	b2 DW ?
	i2 DW ?
	T1 DW ?
	T2 DW ?
	T3 DW ?
	T4 DW ?
.CODE
PRINT_ID PROC

	;SAVE IN STACK
	PUSH AX
	PUSH BX
	PUSH CX
	PUSH DX

	;CHECK IF NEGATIVE
	OR AX, AX
	JGE PRINT_NUMBER

	;PRINT MINUS SIGN
	PUSH AX
	MOV AH, 2
	MOV DL, '-'
	INT 21H
	POP AX

	NEG AX

	PRINT_NUMBER:
	XOR CX, CX
	MOV BX, 10D

	REPEAT_CALC:

		;AX:DX- QUOTIENT:REMAINDER
		XOR DX, DX
		DIV BX  ;DIVIDE BY 10
		PUSH DX ;PUSH THE REMAINDER IN STACK

		INC CX

		OR AX, AX
		JNZ REPEAT_CALC

	MOV AH, 2

	PRINT_LOOP:
		POP DX
		ADD DL, 30H
		INT 21H
		LOOP PRINT_LOOP

	;NEWLINE
	MOV AH, 2
	MOV DL, 0AH
	INT 21H
	MOV DL, 0DH
	INT 21H

	POP AX
	POP BX
	POP CX
	POP DX

	RET
PRINT_ID ENDP

MAIN PROC

	;INITIALIZE DATA SEGMENT
	MOV AX, @DATA
	MOV DS, AX


	MOV AX, 0
	MOV b2, AX

	MOV AX, 0
	MOV i2, AX
L5:

	MOV AX, i2
	CMP AX, 4
	JL L1

	MOV T1, 0
	JMP L2

	L1:
	MOV T1, 1

	L2:
	MOV AX, T1
	CMP AX, 0
	JE L6

	MOV AX, 3
	MOV a2, AX
L3:
	MOV AX, a2
	MOV T2, AX
	DEC AX
	MOV a2, AX
	MOV AX, T2
	CMP AX, 0
	JE L4
	MOV AX, b2
	INC AX
	MOV b2, AX
	JMP L3
	L4:
	MOV AX, i2
	INC AX
	MOV i2, AX
	JMP L5
	L6:

	MOV AX, a2
	CALL PRINT_ID

	MOV AX, b2
	CALL PRINT_ID

	MOV AX, i2
	CALL PRINT_ID

	MOV AX, 5
	MOV a2, AX
	MOV AX, a2
	MOV T3, AX
	DEC AX
	MOV a2, AX
	MOV AX, a2
	MOV T4, AX
	DEC AX
	MOV a2, AX

	MOV AX, a2
	CALL PRINT_ID

	MOV AX, 4CH
	INT 21H
MAIN ENDP

END MAIN