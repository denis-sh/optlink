		TITLE	CVPUB4 - Copyright (c) SLR Systems 1994

		INCLUDE	MACROS
		INCLUDE	SYMBOLS
		INCLUDE	MODULES
		INCLUDE	SEGMENTS
if	fg_pe
		INCLUDE	PE_STRUC
endif

		PUBLIC	CV_PUBLICS_4


		.DATA

		EXTERNDEF	CV_TEMP_RECORD:BYTE

		EXTERNDEF	CURNMOD_GINDEX:DWORD,BYTES_SO_FAR:DWORD,PE_BASE:DWORD

		EXTERNDEF	MODULE_GARRAY:STD_PTR_S,SYMBOL_GARRAY:STD_PTR_S,SEGMENT_GARRAY:STD_PTR_S,PE_OBJECT_GARRAY:STD_PTR_S

		EXTERNDEF	CV_DWORD_ALIGN:DWORD


		.CODE	PASS2_TEXT

		EXTERNDEF	MOVE_TEXT_TO_OMF:PROC,HANDLE_CV_INDEX:PROC,FLUSH_CV_TEMP:PROC


CV_PUBLICS_4	PROC
		;
		;OUTPUT PUBLIC SYMBOLS FOR CURNMOD
		;
		MOV	EAX,CURNMOD_GINDEX
		CONVERT	EAX,EAX,MODULE_GARRAY
		ASSUME	EAX:PTR MODULE_STRUCT

		MOV	CL,[EAX]._M_FLAGS
		MOV	EAX,[EAX]._M_FIRST_PUB_GINDEX

		AND	CL,MASK M_OMIT_$$PUBLICS	;DID LNKDIR PCODE DIRECTIVE SAY NO?
		JZ	PMOD_LOOP
L9$:
		RET

		ASSUME	EAX:PTR SYMBOL_STRUCT

PPUB_SKIP:
		MOV	EAX,[EAX]._S_NEXT_SYM_GINDEX
PMOD_LOOP:
		;
		;ONLY WANT INDEX IF THERE IS AT LEAST ONE PUBLIC SYMBOL
		;
		TEST	EAX,EAX
		JZ	L9$			;REAL RARE THAT A MODULE HAS

		CONVERT	EAX,EAX,SYMBOL_GARRAY
		ASSUME	EAX:PTR SYMBOL_STRUCT

		MOV	CL,[EAX]._S_REF_FLAGS

		AND	CL,MASK S_SPACES + MASK S_NO_CODEVIEW
		JNZ	PPUB_SKIP
		;
		;OK, DEFINITELY PUBLICS FROM THIS MODULE
		;
		PUSHM	EDI,ESI,EBX
		MOV	ESI,EAX

		CALL	CV_DWORD_ALIGN

		MOV	EDI,OFF CV_TEMP_RECORD+4	;PLACE TO BUILD RECORD
		MOV	EAX,BYTES_SO_FAR

		MOV	ECX,1
		PUSH	EAX

		MOV	[EDI-4],ECX
		JMP	PPUB_1

NEXT_PPUB_1:
		MOV	ESI,ECX
		JMP	NEXT_PPUB

PPUB_LOOP:
		CONVERT	ESI,ESI,SYMBOL_GARRAY
		ASSUME	ESI:PTR SYMBOL_STRUCT
PPUB_1:
		MOV	AL,[ESI]._S_REF_FLAGS
		MOV	ECX,[ESI]._S_NEXT_SYM_GINDEX

		TEST	AL,MASK S_SPACES + MASK S_NO_CODEVIEW
		JNZ	NEXT_PPUB_1

		PUSH	ECX
		MOV	EDX,[ESI]._S_SEG_GINDEX

		MOV	EAX,[ESI]._S_OFFSET
		GETT	CL,OUTPUT_PE

		TEST	EDX,EDX
		JZ	L4$

		CONVERT	EDX,EDX,SEGMENT_GARRAY
		ASSUME	EDX:PTR SEGMENT_STRUCT

		OR	CL,CL
		JNZ	L1$

		MOV	ECX,[EDX]._SEG_OFFSET
		MOV	EDX,[EDX]._SEG_CV_NUMBER

		SUB	EAX,ECX
		JMP	L4$

L1$:
		MOV	ECX,[EDX]._SEG_PEOBJECT_GINDEX
		MOV	EDX,[EDX]._SEG_PEOBJECT_NUMBER

		CONVERT	ECX,ECX,PE_OBJECT_GARRAY
		ASSUME	ECX:PTR PE_OBJECT_STRUCT

		SUB	EAX,PE_BASE
		SUB	EAX,[ECX]._PEOBJECT_RVA
		ASSUME	ECX:NOTHING

L4$:
		MOV	EBX,EDI

		MOV	ECX,103H			;ASSUME	16BIT?
		MOV	[EDI+4],EAX

		ADD	EDI,10
		GETT	AL,OUTPUT_32BITS

		OR	AL,AL
		JZ	DO_16

		ADD	EDI,2
		MOV	CH,2				;ECX=203H
DO_16:
		MOV	WPTR [EBX+2],CX
		LEA	ESI,[ESI]._S_NAME_TEXT

		MOV	[EDI-4],EDX
		CALL	MOVE_TEXT_TO_OMF

		LEA	EAX,[EDI-2]
		POP	ESI			;NEXT SYMBOL, MODULE ORDER

		SUB	EAX,EBX
		CMP	EDI,OFF CV_TEMP_RECORD+CV_TEMP_SIZE-SYMBOL_TEXT_SIZE-8

		MOV	WPTR [EBX],AX			;RECORD LENGTH
		JNC	PPUB_FLUSH		;CAN WE FIT ANOTHER IF IT IS MAX-SIZE?
NEXT_PPUB:

		TEST	ESI,ESI
		JNZ	PPUB_LOOP
		;
		;FLUSH PARTIAL BUFFER
		;
		CALL	FLUSH_CV_TEMP
		;
		;NOW, DO INDEX ENTRY
		;
		POP	EAX
		MOV	ECX,123H

		POP	EBX
		CALL	HANDLE_CV_INDEX

		POPM	ESI,EDI

		JMP	CV_DWORD_ALIGN

PPUB_FLUSH:
		CALL	FLUSH_CV_TEMP
		JMP	NEXT_PPUB

CV_PUBLICS_4	ENDP


		END

