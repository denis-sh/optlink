		TITLE	ARRAYS - Copyright (c) SLR Systems 1994

		INCLUDE MACROS

		PUBLIC	LOCAL_PTR_INSTALL,INIT_PARALLEL_ARRAY,MARRAY_INIT,RELEASE_GARRAY
		PUBLIC	RELEASE_CV_LTYPE_GARRAY,RELEASE_CV_GTYPE_GARRAY


		.DATA

		EXTERNDEF	BUFFER_OFFSET:DWORD,STD_ALLOC_LOG:DWORD,STD_ALLOC_OFF:DWORD,GARRAY_BLOCK_CNT:DWORD
		EXTERNDEF	SYMBOL_LARRAY_TBL:DWORD,LNAME_LARRAY_TBL:DWORD,SEGMOD_LARRAY_TBL:DWORD,GROUP_LARRAY_TBL:DWORD
		EXTERNDEF	STD_RELEASED:DWORD

		EXTERNDEF	LNAME_LARRAY:LARRAY_STRUCT,SEGMOD_LARRAY:LARRAY_STRUCT,GROUP_LARRAY:LARRAY_STRUCT
		EXTERNDEF	SYMBOL_LARRAY:LARRAY_STRUCT

if	fg_cvpack
		EXTERNDEF	CV_GARRAY_OVERSIZE_CNT:DWORD,CV_GARRAY_OVERSIZE_LEFT:DWORD,CV_SPECIAL_BLOCK:DWORD
if	fg_cvpack

		EXTERNDEF       CV_LTYPE_OVERSIZE_CNT:DWORD,CV_LTYPE_SPECIAL_BLOCK:DWORD
		EXTERNDEF       CV_GTYPE_OVERSIZE_CNT:DWORD,CV_GTYPE_SPECIAL_BLOCK:DWORD
endif
		EXTERNDEF	CV_LTYPE_GARRAY:STD_PTR_S,CV_GTYPE_GARRAY:STD_PTR_S,CV_SPECIAL_BLOCK_PTR:DWORD
endif

		.CODE	PASS1_TEXT

		EXTERNDEF	_get_new_phys_blk:proc,INDEX_RANGE:PROC,ERR_ABORT:PROC,ALLOC_LOCAL:PROC,ERR_MAXINDEX_ABORT:PROC
		EXTERNDEF	TERR_ABORT:PROC,RELEASE_BLOCK:PROC,PAR_POWER_DSSI:PROC,PAR_POWER_ESDI:PROC,PAR_ODD_DSSI:PROC

		EXTERNDEF	STD_MAXINDEX_ERR:ABS,INDEX_RANGE_ERR:ABS,PAR_POWER_ERR:ABS

if	fg_cvpack
		EXTERNDEF	_release_large_segment:proc,RELEASE_CV_GTYPE_GARRAY:PROC,RELEASE_CV_LTYPE_GARRAY:PROC
endif

		PUBLIC	INIT_ARRAYS

INIT_ARRAYS	PROC
		;
		;NEW ALLOC STRATEGY:
		;
		;LARRAY HAS 32 BYTES TO STORE 8 PTRS TO 16K BLOCKS
		;	8 * 4K == 32K LIMIT FOR LOCAL PTRS
		;

		MOV	EAX,OFF LNAME_LARRAY
		CALL	LARRAY_INIT

		MOV	EAX,OFF SYMBOL_LARRAY
		CALL	LARRAY_INIT

		MOV	EAX,OFF SEGMOD_LARRAY
		CALL	LARRAY_INIT

		MOV	EAX,OFF GROUP_LARRAY
;		CALL	LARRAY_INIT
;		RET

INIT_ARRAYS	ENDP


LARRAY_INIT	PROC	NEAR
		;
		;EAX IS TABLE TO INITIALIZE
		;
		PUSH	EDI
		MOV	EDI,EAX

		MOV	ECX,SIZEOF LARRAY_STRUCT/4
		MOV	EDX,EAX

		XOR	EAX,EAX

		OPTI_STOSD

		LEA	EAX,[EDX].LARRAY_STRUCT._LARRAY_BASES
		POP	EDI

		MOV	[EDX].LARRAY_STRUCT._LARRAY_NEXT_BASE,EAX

		RET

LARRAY_INIT	ENDP


LOCAL_PTR_INSTALL	PROC
		;
		;ECX IS LARRAY
		;EAX IS VALUE TO STORE
		;
		ASSUME	ECX:PTR LARRAY_STRUCT

		PUSHM	ESI,EDX

		MOV	ESI,[ECX]._LARRAY_NEXT
		MOV	EDX,[ECX]._LARRAY_LIMIT

		TEST	ESI,ESI
		JZ	L1$
L19$:
		INC	DX			;(SE changed 6.11.97)
		JS	L2$

		MOV	[ESI],EAX
		MOV	[ECX]._LARRAY_LIMIT,EDX

		MOV	EDX,[ECX]._LARRAY_COUNT
		ADD	ESI,4

		DEC	EDX
		JZ	L3$
L39$:
		MOV	[ECX]._LARRAY_COUNT,EDX
		POP	EDX

		MOV	[ECX]._LARRAY_NEXT,ESI
		POP	ESI

		RET

L1$:
		PUSH	EAX
		MOV	ESI,[ECX]._LARRAY_NEXT_BASE

		MOV	EAX,PAGE_SIZE
		CALL	ALLOC_LOCAL

		MOV	[ESI],EAX
		ADD	ESI,4

		MOV	[ECX]._LARRAY_NEXT_BASE,ESI
		MOV	ESI,EAX

		MOV	[ECX]._LARRAY_COUNT,PAGE_SIZE/4

		POP	EAX
		JMP	L19$

L2$:
		MOV	ESI,BUFFER_OFFSET
		CALL	INDEX_RANGE

L3$:
;		MOV	[ECX]._LARRAY_NEXT,EDX
		MOV	ESI,EDX			;(SE changed 6.11.97)

		JMP	L39$

LOCAL_PTR_INSTALL	ENDP


INIT_PARALLEL_ARRAY	PROC

		RET

INIT_PARALLEL_ARRAY	ENDP


MARRAY_INIT	PROC

		RET

MARRAY_INIT	ENDP

		public _release_garray
_release_garray	proc
		mov	EAX,4[ESP];
_release_garray	endp

RELEASE_GARRAY	PROC
		;
		;
		;
		PUSH	EDI
		MOV	EDX,EAX

		MOV	EDI,EAX
		MOV	ECX,STD_PTR_S._STD_PTRS/4

		XOR	EAX,EAX

		OPTI_STOSD

		XOR	EDX,EDX
		MOV	CL,16
L2$:
		MOV	EAX,[EDI]
		ADD	EDI,4

		TEST	EAX,EAX
		JZ	L3$

		MOV	[EDI-4],EDX
		CALL	RELEASE_BLOCK

		DEC	ECX
		JNZ	L2$
L3$:
		POP	EDI

		RET

RELEASE_GARRAY	ENDP

if	fg_cvpack

RELEASE_CV_GTYPE_GARRAY PROC NEAR

		MOV	EAX,OFF CV_GTYPE_GARRAY
                CALL	RELEASE_GARRAY

                MOV	ECX,CV_GTYPE_OVERSIZE_CNT
                TEST	ECX,ECX
                JNZ	L1$
		RET

L1$:
		PUSH	EDI

		XOR	EDX,EDX
                MOV	EDI,CV_GTYPE_SPECIAL_BLOCK
L2$:
		MOV	EAX,[EDI]
		ADD	EDI,4

		PUSHM	EDX,ECX
		push	EAX
		call	_release_large_segment
		add	ESP,4
		POPM	ECX,EDX

		MOV	[EDI-4],EDX
                SUB	ECX,4
		JNZ	L2$

                MOV	EAX,CV_GTYPE_SPECIAL_BLOCK
                MOV	CV_GTYPE_OVERSIZE_CNT,EDX
		CALL	RELEASE_BLOCK
		MOV	CV_GTYPE_SPECIAL_BLOCK,EDX

L3$:
		POP	EDI

		RET

RELEASE_CV_GTYPE_GARRAY ENDP


RELEASE_CV_LTYPE_GARRAY PROC NEAR
		;
		;
		;
		MOV	EAX,OFF CV_LTYPE_GARRAY
                CALL	RELEASE_GARRAY

                MOV	ECX,CV_LTYPE_OVERSIZE_CNT
                TEST	ECX,ECX
                JNZ	L1$
		RET

L1$:
		PUSH	EDI

		XOR	EDX,EDX
                MOV	EDI,CV_LTYPE_SPECIAL_BLOCK
L2$:
		MOV	EAX,[EDI]
		ADD	EDI,4

		PUSHM	EDX,ECX
		push	EAX
		call	_release_large_segment
		add	ESP,4
		POPM	ECX,EDX

		MOV	[EDI-4],EDX
                SUB	ECX,4
		JNZ	L2$

                MOV	EAX,CV_LTYPE_SPECIAL_BLOCK
                MOV	CV_LTYPE_OVERSIZE_CNT,EDX
		CALL	RELEASE_BLOCK
		MOV	CV_LTYPE_SPECIAL_BLOCK,EDX

L3$:
		POP	EDI

		RET

RELEASE_CV_LTYPE_GARRAY ENDP

endif

IF 0


INSTALL_RANDOM_POINTER	PROC
		;
		;CX IS INDEX #, AX:BX IS PTR, DGROUP:SI IS STRUCTURE
		;
		CMP	DGROUP:[SI]._STD_LIMIT,CX
		JAE	2$
		PUSHM	BX,AX
1$:
		XOR	AX,AX
		XOR	BX,BX
		CALL	DGROUP:[SI]._STD_INSTALL_ROUTINE
		CMP	DGROUP:[SI]._STD_LIMIT,CX
		JB	1$
		POPM	AX,BX
2$:
		XCHG	AX,CX
		CALL	DGROUP:[SI]._STD_INSTALL_RANDOM_ROUTINE
		RET

INSTALL_RANDOM_POINTER	ENDP


		ASSUME	DS:NOTHING

MICRO_STD_PTR_INSTALL	PROC
		;
		;
		;
		PUSH	DI
		MOV	DI,DGROUP:[SI]._STD_NEXT.OFFS
		MOV	DGROUP:[DI+2],AX
		MOV	AX,DGROUP:[SI]._STD_LIMIT
		MOV	DGROUP:[DI],BX
		ADD	DI,4
		INC	AX
		MOV	DGROUP:[SI]._STD_NEXT.OFFS,DI
		POP	DI
		DEC	DGROUP:[SI]._STD_COUNT		;# LEFT TO ALLOCATE HERE
		MOV	DGROUP:[SI]._STD_LIMIT,AX
		JZ	EXPAND_MICRO_STD_PTRS
		RET

EXPAND_MICRO_STD_PTRS:
		;
		;
		;
		CAPTURE	TCONVERT_SEM

		PUSHM	DS,ES,DI,CX,BX,AX
		FIXDS
		MOV	AX,1024
		CALL	DGROUP:[SI]._STD_ALLOC_ROUTINE
		PUSH	SI
		MOV	BX,DI
		LEA	SI,[SI]._STD_PTRS
		MOV	CX,32
		REP	MOVSW
		POP	SI

		MOV	DGROUP:[SI]._STD_PTRS.OFFS,BX		;PTR TO FIRST BLOCK
		MOV	DGROUP:[SI]._STD_PTRS.SEGM,AX

		MOV	DGROUP:[SI]._STD_NEXT.OFFS,DI		;PLACE TO STORE NEXT POINTER
		MOV	DGROUP:[SI]._STD_NEXT.SEGM,AX
		LEA	AX,[SI]._STD_PTRS+4
		MOV	DGROUP:[SI]._STD_BASE_NEXT.OFFS,AX	;PLACE TO STORE NEXT BLOCK POINTER

		MOV	DGROUP:[SI]._STD_COUNT,256-16		;# LEFT IN THAT BLOCK

		MOV	DGROUP:[SI]._STD_INSTALL_ROUTINE.OFFS,OFF MINI_STD_PTR_INSTALL
		MOV	DGROUP:[SI]._STD_INSTALL_RANDOM_ROUTINE.OFFS,OFF MINI_STD_RANDOM
		MOV	DGROUP:[SI]._STD_AX_TO_DSSI.OFFS,OFF MINI_STD_PTR_DSSI
		MOV	DGROUP:[SI]._STD_AX_TO_ESDI.OFFS,OFF MINI_STD_PTR_ESDI
if	fgh_os2
		MOV	DGROUP:[SI]._STD_AX_TO_DSSI_THREAD.OFFS,OFF MINI_STD_PTR_DSSI_THREAD
endif

		RELEASE	TCONVERT_SEM

		POPM	AX,BX,CX,DI,ES,DS
		RET

		ASSUME	DS:NOTHING

MICRO_STD_PTR_INSTALL	ENDP


		ASSUME	DS:NOTHING

MINI_STD_PTR_INSTALL	PROC
		;
		;SI IS STUFF
		;USE DS:DI
		;
		PUSHM	DS,DI
		LDS	DI,DGROUP:[SI]._STD_NEXT
		SYM_CONV_DS_AX
		MOV	DS:[DI+2],AX
		MOV	AX,DGROUP:[SI]._STD_LIMIT
		MOV	DS:[DI],BX
		INC	AX
		ADD	DI,4
		MOV	DGROUP:[SI]._STD_NEXT.OFFS,DI
		POPM	DI,DS
		DEC	DGROUP:[SI]._STD_COUNT		;# LEFT TO ALLOCATE HERE
		MOV	DGROUP:[SI]._STD_LIMIT,AX
		JZ	MINI_EXPAND_STD_PTRS
		RET

MINI_EXPAND_STD_PTRS	LABEL	PROC
		;
		;NORMALLY, WE JUST NEED ANOTHER BLOCK...
		;
		PUSHM	ES,DI,BX,AX
		CMP	AX,16*256
		JZ	MINI_EXPAND_STD_MAJOR
		MOV	BX,DGROUP:[SI]._STD_BASE_NEXT.OFFS
		MOV	AX,1024
		CALL	DGROUP:[SI]._STD_ALLOC_ROUTINE
		MOV	DGROUP:[BX].OFFS,DI
		MOV	DGROUP:[BX].SEGM,AX
		ADD	BX,4
		MOV	DGROUP:[SI]._STD_NEXT.OFFS,DI
		MOV	DGROUP:[SI]._STD_NEXT.SEGM,AX
		MOV	DGROUP:[SI]._STD_BASE_NEXT.OFFS,BX
		POPM	AX,BX,DI,ES
		MOV	DGROUP:[SI]._STD_COUNT,256
		MOV	DGROUP:[SI]._STD_AX_TO_DSSI.OFFS,OFF MIDI_STD_PTR_DSSI
		MOV	DGROUP:[SI]._STD_AX_TO_ESDI.OFFS,OFF MIDI_STD_PTR_ESDI
		MOV	DGROUP:[SI]._STD_INSTALL_RANDOM_ROUTINE.OFFS,OFF MIDI_STD_RANDOM
if	fgh_os2
		MOV	DGROUP:[SI]._STD_AX_TO_DSSI_THREAD.OFFS,OFF MIDI_STD_PTR_DSSI_THREAD
endif
		RET

MINI_EXPAND_STD_MAJOR	LABEL	PROC
		;
		;OK, WE ARE CHANGING TO MAXI TYPE
		;
		CAPTURE	TCONVERT_SEM

		PUSHM	DS,CX
		FIXDS
		MOV	DGROUP:[SI]._STD_INSTALL_ROUTINE.OFFS,OFF MAXI_STD_PTR_INSTALL
		MOV	DGROUP:[SI]._STD_INSTALL_RANDOM_ROUTINE.OFFS,OFF MAXI_STD_RANDOM
		MOV	DGROUP:[SI]._STD_AX_TO_DSSI.OFFS,OFF MAXI_STD_PTR_DSSI
		MOV	DGROUP:[SI]._STD_AX_TO_ESDI.OFFS,OFF MAXI_STD_PTR_ESDI
if	fgh_os2
		MOV	DGROUP:[SI]._STD_AX_TO_DSSI_THREAD.OFFS,OFF MAXI_STD_PTR_DSSI_THREAD
endif
		MOV	AX,1024				;GET 1024-BYTE PLACE FOR POINTERS TO POINTERS
		CALL	ALLOC_LOCKED
		PUSH	SI
		MOV	BX,DI
		LEA	SI,[SI]._STD_PTRS
		MOV	CX,32
		REP	MOVSW
		POP	SI
		MOV	DGROUP:[SI]._STD_PTRS.OFFS,BX	;PTR TO MASTER BLOCK
		MOV	DGROUP:[SI]._STD_PTRS.SEGM,AX

		MOV	DGROUP:[SI]._STD_BASE_NEXT.OFFS,DI	;PLACE TO STORE NEXT BLOCK POINTER
		MOV	DGROUP:[SI]._STD_BASE_NEXT.SEGM,ES

		MOV	DGROUP:[SI]._STD_COUNT,256

		MOV	AX,1024
		CALL	DGROUP:[SI]._STD_ALLOC_ROUTINE	;

		MOV	DGROUP:[SI]._STD_NEXT.OFFS,DI
		MOV	DGROUP:[SI]._STD_NEXT.SEGM,AX

		LDS	BX,DGROUP:[SI]._STD_BASE_NEXT
		ASSUME	DS:NOTHING
		MOV	[BX].OFFS,DI
		MOV	[BX].SEGM,AX
		ADD	BX,4
		MOV	DGROUP:[SI]._STD_BASE_NEXT.OFFS,BX

		RELEASE	TCONVERT_SEM

		POPM	CX,DS,AX,BX,DI,ES
		RET

MINI_STD_PTR_INSTALL	ENDP


		ASSUME	DS:NOTHING

MAXI_STD_PTR_INSTALL	PROC
		;
		;SI IS STUFF
		;USE DS:DI
		;
		PUSHM	DS,DI
		LDS	DI,DGROUP:[SI]._STD_NEXT
		SYM_CONV_DS_AX
		MOV	DS:[DI+2],AX
		MOV	AX,DGROUP:[SI]._STD_LIMIT
		MOV	DS:[DI],BX
		INC	AX
		ADD	DI,4
		MOV	DGROUP:[SI]._STD_NEXT.OFFS,DI
		POPM	DI,DS
		DEC	DGROUP:[SI]._STD_COUNT		;# LEFT TO ALLOCATE HERE
		MOV	DGROUP:[SI]._STD_LIMIT,AX
		JZ	MAXI_EXPAND_STD_PTRS
		RET

MAXI_EXPAND_STD_PTRS	LABEL	PROC

		OR	AX,AX				;64K ITEMS?
		JZ	9$
		PUSHM	AX,BX,DI,ES,DS
		MOV	DGROUP:[SI]._STD_COUNT,256	;CAN STORE 256 MORE

		MOV	AX,1024
		CALL	DGROUP:[SI]._STD_ALLOC_ROUTINE

		MOV	DGROUP:[SI]._STD_NEXT.OFFS,DI
		LDS	BX,DGROUP:[SI]._STD_BASE_NEXT
		MOV	DGROUP:[SI]._STD_NEXT.SEGM,AX
		MOV	DS:[BX].OFFS,DI
		MOV	DS:[BX].SEGM,AX
		POP	DS
		ADD	BX,4
		POPM	ES,DI
		MOV	DGROUP:[SI]._STD_BASE_NEXT.OFFS,BX
		POPM	BX,AX

		RET

9$:
		RELEASE	TCONVERT_SEM

		MOV	CL,STD_MAXINDEX_ERR
		CALL	ERR_MAXINDEX_ABORT

MAXI_STD_PTR_INSTALL	ENDP


		ASSUME	DS:NOTHING

MICRO_STD_RANDOM	PROC
		;
		;
		;
		SHLI	AX,2
		ADD	SI,AX
		MOV	DGROUP:[SI]._STD_PTRS.OFFS-4,BX
		MOV	DGROUP:[SI]._STD_PTRS.SEGM-4,CX
		RET

MICRO_STD_RANDOM	ENDP


		ASSUME	DS:NOTHING

MICRO_STD_PTR_DSSI	PROC
		;
		;
		;
if	debug
		DEC	AX
		CMP	DGROUP:[SI]._STD_LIMIT,AX
		JBE	IR_2
		INC	AX
endif
		SHLI	AX,2
		ADD	SI,AX
		LDS	SI,DGROUP:[SI]._STD_PTRS-4
		SYM_CONV_DS
		RET

MICRO_STD_PTR_DSSI	ENDP

IR_STD:
		MOV	SI,BUFFER_OFFSET
		JMP	INDEX_RANGE


		ASSUME	DS:NOTHING

MICRO_STD_PTR_ESDI	PROC
		;
		;
		;
if	debug
		DEC	AX
		CMP	DGROUP:[DI]._STD_LIMIT,AX
		JBE	IR_2
		INC	AX
endif
		SHLI	AX,2
		ADD	DI,AX
		LES	DI,DGROUP:[DI]._STD_PTRS-4
		SYM_CONV_ES
		RET

MICRO_STD_PTR_ESDI	ENDP


IR_2:
		JMP	IR_STD


		ASSUME	DS:NOTHING

MINI_STD_RANDOM	PROC
		;
		;
		;
		PUSH	DS
		DEC	AX
		LDS	SI,DGROUP:[SI]._STD_PTRS
		SHLI	AX,2
		ADD	SI,AX
		SYM_CONV_DS
		MOV	[SI].OFFS,BX
		MOV	[SI].SEGM,CX
		POP	DS
		RET

MINI_STD_RANDOM	ENDP


		ASSUME	DS:NOTHING

MINI_STD_PTR_DSSI	PROC
		;
		;
		;
		DEC	AX
if	debug
		CMP	DGROUP:[SI]._STD_LIMIT,AX
		JBE	IR_2
endif
		LDS	SI,DGROUP:[SI]._STD_PTRS
		SHLI	AX,2
		ADD	SI,AX
		SYM_CONV_DS
		LDS	SI,[SI]
		SYM_CONV_DS
		RET

MINI_STD_PTR_DSSI	ENDP


		ASSUME	DS:NOTHING

MINI_STD_PTR_ESDI	PROC
		;
		;
		;
		DEC	AX
if	debug
		CMP	DGROUP:[DI]._STD_LIMIT,AX
		JBE	IR_2
endif
		LES	DI,DGROUP:[DI]._STD_PTRS
		SHLI	AX,2
		ADD	DI,AX
		SYM_CONV_ES
		LES	DI,ES:[DI]
		SYM_CONV_ES
		RET

MINI_STD_PTR_ESDI	ENDP


		ASSUME	DS:NOTHING

MIDI_STD_RANDOM	PROC
		;
		;MUST HANDLE UP TO 64K INDEXES
		;
		DEC	AX
		PUSH	DS
		PUSH	AX
		MOV	AL,AH
		XOR	AH,AH
		SHLI	AX,2
		ADD	SI,AX
		LDS	SI,DGROUP:[SI]._STD_PTRS
		SYM_CONV_DS
		POP	AX
		XOR	AH,AH
		SHLI	AX,2
		ADD	SI,AX
		MOV	[SI].OFFS,BX
		MOV	[SI].SEGM,CX
		POP	DS
		RET

MIDI_STD_RANDOM	ENDP


		ASSUME	DS:NOTHING

MIDI_STD_PTR_ESDI	PROC
		;
		;MUST HANDLE UP TO 64K INDEXES
		;
		DEC	AX
if	debug
		CMP	DGROUP:[DI]._STD_LIMIT,AX
.EN CJ
		JBE	IR_2
.DS CJ
endif
		PUSH	AX
		MOV	AL,AH
		XOR	AH,AH
		SHLI	AX,2
		ADD	DI,AX
		LES	DI,DGROUP:[DI]._STD_PTRS
		SYM_CONV_ES
		POP	AX
		XOR	AH,AH
		SHLI	AX,2
		ADD	DI,AX
		LES	DI,ES:[DI]
		SYM_CONV_ES
		RET

MIDI_STD_PTR_ESDI	ENDP


		ASSUME	DS:NOTHING

MIDI_STD_PTR_DSSI	PROC
		;
		;MUST HANDLE UP TO 64K INDEXES
		;
		DEC	AX
if	debug
		CMP	DGROUP:[SI]._STD_LIMIT,AX
		JBE	IR_4
endif
		PUSH	AX
		MOV	AL,AH
		XOR	AH,AH
		SHLI	AX,2
		ADD	SI,AX
		LDS	SI,DGROUP:[SI]._STD_PTRS
		SYM_CONV_DS
		POP	AX
		XOR	AH,AH
		SHLI	AX,2
		ADD	SI,AX
		LDS	SI,[SI]
		SYM_CONV_DS
		RET

MIDI_STD_PTR_DSSI	ENDP

IR_4:
		JMP	IR_STD


		ASSUME	DS:NOTHING

MAXI_STD_RANDOM	PROC
		;
		;MUST HANDLE UP TO 64K INDEXES
		;
		DEC	AX
		PUSH	DS
		PUSH	AX
		LDS	SI,DGROUP:[SI]._STD_PTRS	;PTR TO BASE PTRS, TRUE PHYSICAL ADDRESS
		MOV	AL,AH
		XOR	AH,AH
		SHLI	AX,2
		ADD	SI,AX
		LDS	SI,[SI]
		SYM_CONV_DS
		POP	AX
		XOR	AH,AH
		SHLI	AX,2
		ADD	SI,AX
		MOV	[SI].OFFS,BX
		MOV	[SI].SEGM,CX
		POP	DS
		RET

MAXI_STD_RANDOM	ENDP


		ASSUME	DS:NOTHING

MAXI_STD_PTR_ESDI	PROC
		;
		;MUST HANDLE UP TO 64K INDEXES
		;
		DEC	AX
if	debug
		CMP	DGROUP:[DI]._STD_LIMIT,AX
		JBE	IR_4
endif
		PUSH	AX
		LES	DI,DGROUP:[DI]._STD_PTRS	;PTR TO BASE PTRS, TRUE PHYSICAL ADDRESS
		MOV	AL,AH
		XOR	AH,AH
		SHLI	AX,2
		ADD	DI,AX
		LES	DI,ES:[DI]
		SYM_CONV_ES
		POP	AX
		XOR	AH,AH
		SHLI	AX,2
		ADD	DI,AX
		LES	DI,ES:[DI]
		SYM_CONV_ES
		RET

MAXI_STD_PTR_ESDI	ENDP


		ASSUME	DS:NOTHING

MAXI_STD_PTR_DSSI	PROC
		;
		;MUST HANDLE UP TO 64K INDEXES
		;
		DEC	AX
if	debug
		CMP	DGROUP:[SI]._STD_LIMIT,AX
		JBE	IR_4
endif
		PUSH	AX
		LDS	SI,DGROUP:[SI]._STD_PTRS	;PTR TO BASE PTRS, TRUE PHYSICAL ADDRESS
		MOV	AL,AH
		XOR	AH,AH
		SHLI	AX,2
		ADD	SI,AX
		LDS	SI,[SI]
		SYM_CONV_DS
		POP	AX
		XOR	AH,AH
		SHLI	AX,2
		ADD	SI,AX
		LDS	SI,[SI]
		SYM_CONV_DS
		RET

MAXI_STD_PTR_DSSI	ENDP


if	fgh_os2

		ASSUME	DS:NOTHING,ES:DGROUP,SS:NOTHING

MICRO_STD_PTR_DSSI_THREAD	PROC
		;
		;
		;
if	debug
		DEC	AX
		CMP	DGROUP:[SI]._STD_LIMIT,AX
		JBE	IR_3
		INC	AX
endif
		SHLI	AX,2
		ADD	SI,AX
		LDS	SI,DGROUP:[SI]._STD_PTRS-4
		RET

MICRO_STD_PTR_DSSI_THREAD	ENDP


		ASSUME	DS:NOTHING,ES:DGROUP,SS:NOTHING

MINI_STD_PTR_DSSI_THREAD	PROC
		;
		;
		;
		DEC	AX
if	debug
		CMP	DGROUP:[SI]._STD_LIMIT,AX
		JBE	IR_3
endif
		LDS	SI,DGROUP:[SI]._STD_PTRS
		ASSUME	DS:NOTHING
		SHLI	AX,2
		ADD	SI,AX
		LDS	SI,[SI]
		RET

MINI_STD_PTR_DSSI_THREAD	ENDP


IR_3:
		MOV	CL,INDEX_RANGE_ERR
		CALL	TERR_ABORT


		ASSUME	DS:NOTHING,ES:DGROUP,SS:NOTHING

MIDI_STD_PTR_DSSI_THREAD	PROC
		;
		;MUST HANDLE UP TO 64K INDEXES
		;
		DEC	AX
if	debug
		CMP	DGROUP:[SI]._STD_LIMIT,AX
		JBE	IR_3
endif
		PUSH	AX
		MOV	AL,AH
		XOR	AH,AH
		SHLI	AX,2
		ADD	SI,AX
		POP	AX
		LDS	SI,DGROUP:[SI]._STD_PTRS
		XOR	AH,AH
		SHLI	AX,2
		ADD	SI,AX
		LDS	SI,[SI]
		RET

MIDI_STD_PTR_DSSI_THREAD	ENDP


		ASSUME	DS:NOTHING,ES:DGROUP,SS:NOTHING

MAXI_STD_PTR_DSSI_THREAD	PROC
		;
		;MUST HANDLE UP TO 64K INDEXES
		;
		DEC	AX
if	debug
		CMP	DGROUP:[SI]._STD_LIMIT,AX
		JBE	IR_3
endif
		PUSH	AX
		LDS	SI,DGROUP:[SI]._STD_PTRS	;PTR TO BASE PTRS, TRUE PHYSICAL ADDRESS
		MOV	AL,AH
		XOR	AH,AH
		SHLI	AX,2
		ADD	SI,AX
		POP	AX
		LDS	SI,[SI]
		XOR	AH,AH
		SHLI	AX,2
		ADD	SI,AX
		LDS	SI,[SI]
		RET

MAXI_STD_PTR_DSSI_THREAD	ENDP

		ASSUME	SS:DGROUP,ES:NOTHING

endif


		ASSUME	DS:NOTHING

INIT_PARALLEL_ARRAY	PROC
		;
		;INITIALIZE A PARALLEL ARRAY
		;SI POINTS TO _PAR_ STRUCT
		;AX IS ELEMENT SIZE
		;
		PUSHM	ES,DI,DX,CX,BX
		MOV	BX,AX
		MOV	DX,-1
1$:
		INC	DX
		SHR	AX,1
		JNC	1$
		JNZ	5$
		MOV	CH,DL
		MOV	CL,PAGE_POWER
		SUB	CL,CH
		MOV	DGROUP:[SI]._PAR_SHIFTS,CX
		INC	AX
		SHL	AX,CL
		DEC	AX
		MOV	DGROUP:[SI]._PAR_MASK,AX
		SUB	CL,16
		NEG	CL
		MOV	AX,1
		SHL	AX,CL			;# OF BLOCKS NEEDED MAX...
		MOV	DGROUP:[SI]._PAR_TO_DSSI.OFFS,OFF PAR_POWER_DSSI
		MOV	DGROUP:[SI]._PAR_TO_ESDI.OFFS,OFF PAR_POWER_ESDI
if	@CodeSize
		MOV	DGROUP:[SI]._PAR_TO_DSSI.SEGM,SEG PAR_POWER_DSSI
		MOV	DGROUP:[SI]._PAR_TO_ESDI.SEGM,SEG PAR_POWER_ESDI
endif
3$:
		MOV	DGROUP:[SI]._PAR_BLOCKS,AX
		MOV	CX,AX
		ADD	AX,AX
		CALL	ALLOC_LOCKED
		MOV	DGROUP:[SI]._PAR_PTRS_PTR.OFFS,DI
		MOV	DGROUP:[SI]._PAR_PTRS_PTR.SEGM,ES
		XOR	AX,AX
		REP	STOSW
8$:
		POPM	BX,CX,DX,DI,ES
		RET

5$:
		;
		;BX IS ELEMENT SIZE THAT IS NOT A POWER OF 2 ...
		;
		MOV	DGROUP:[SI]._PAR_MASK,BX
		XOR	DX,DX
		MOV	AX,PAGE_SIZE
		DIV	BX
		MOV	DGROUP:[SI]._PAR_SHIFTS,AX	;# OF ELEMENTS PER PAGE_SIZE BLOCK
		MOV	BX,AX
		MOV	DX,1
		XOR	AX,AX
		DIV	BX
		MOV	DGROUP:[SI]._PAR_TO_DSSI.OFFS,OFF PAR_ODD_DSSI
		MOV	DGROUP:[SI]._PAR_TO_ESDI.OFFS,OFF PAR_ODD_ESDI
if	@CodeSize
		MOV	DGROUP:[SI]._PAR_TO_DSSI.SEGM,SEG PAR_ODD_DSSI
		MOV	DGROUP:[SI]._PAR_TO_ESDI.SEGM,SEG PAR_ODD_ESDI
endif
		JMP	3$

INIT_PARALLEL_ARRAY	ENDP


		ASSUME	DS:NOTHING

RELEASE_PARALLEL_ARRAY	PROC
		;
		;RELEASE MEMORY ALLOCATED TO A PARALLEL ARRAY
		;
		PUSHM	DS,SI,CX
		MOV	CX,DGROUP:[SI]._PAR_BLOCKS
		LDS	SI,DGROUP:[SI]._PAR_PTRS_PTR
		MOV	AX,DS
		OR	AX,AX
		JZ	8$
		PUSHM	DS,SI,CX
1$:
		LODSW
		OR	AX,AX
		JZ	2$
		CALL	RELEASE_BLOCK
2$:
		LOOP	1$
		POPM	CX,SI,DS
		ADD	CX,CX
		MOV	[SI],CX			;STORE SIZE
		CALL	RELEASE_LOCKED		;RELEASE THE MEMORY
8$:
		POPM	CX,SI,DS
		XOR	AX,AX
		MOV	DGROUP:[SI]._PAR_PTRS_PTR.SEGM,AX
		RET

RELEASE_PARALLEL_ARRAY	ENDP

		ASSUME	DS:NOTHING

ALLOC_LOCKED	PROC
		;
		;AX IS NUMBER OF BYTES TO ALLOCATE FROM LOCKED STORAGE
		;
		;RETURNS ES:DI IS POINTER, AX IS LOGICAL (PHYSICAL)
		;
		INC	AX
		AND	AL,0FEH
		LEA	DI,LOCKED_STUFF._LKD_AVAIL_1K
		CMP	AX,1024
		JZ	AL_TRY_1K
		CMP	AX,2048
		LEA	DI,LOCKED_STUFF._LKD_AVAIL_2K
		JNZ	AL_TRY_MISC
AL_TRY_1K:
		CMP	DGROUP:[DI].SEGM,0
		JZ	AL_TRY_MISC
		PUSH	BX
		MOV	BX,DI
		LES	DI,DGROUP:[DI]
		MOV	AX,ES:2[DI].OFFS
		MOV	DGROUP:[BX].OFFS,AX
		MOV	AX,ES:2[DI].SEGM
		MOV	DGROUP:[BX].SEGM,AX
		POP	BX
		MOV	AX,ES
		RET

AL_TRY_MISC:
		;
		;SCAN DOWN THE LIST OF RELEASED PIECES
		;
		CMP	LOCKED_STUFF._LKD_AVAIL_MISC.SEGM,0
		JZ	AL_CONT
		FIXES
		LEA	DI,LOCKED_STUFF._LKD_AVAIL_MISC-2
		PUSHM	DX,CX
1$:
		MOV	DX,ES
		MOV	CX,DI
		LES	DI,ES:2[DI]
		CMP	ES:[DI],AX
		JAE	3$
		CMP	ES:2[DI].SEGM,0
		JNZ	1$
		POPM	CX,DX
AL_CONT:
		SUB	LOCKED_STUFF._LKD_ALLOC_CNT,AX
		JC	AL_FIX
		LES	DI,LOCKED_STUFF._LKD_ALLOC_PTR
		ADD	AX,DI
		MOV	LOCKED_STUFF._LKD_ALLOC_PTR.OFFS,AX
		MOV	AX,ES
		RET

3$:
		PUSHM	ES,DI
		PUSHM	ES:2[DI].OFFS,ES:2[DI].SEGM
		MOV	ES,DX
		MOV	DI,CX
		POPM	ES:2[DI].SEGM,ES:2[DI].OFFS
		POPM	DI,ES
		XCHG	AX,ES:[DI]
		POP	CX
		SUB	AX,ES:[DI]
		POP	DX
		CMP	AX,32		;MORE THAN 32 BYTES LEFT?
		JAE	4$
		MOV	AX,ES
		RET

4$:
		PUSH	DS
		PUSH	ES
		POP	DS
		PUSH	SI
		MOV	SI,DI
		ADD	SI,ES:[DI]
		MOV	DS:[SI],AX
		CALL	RELEASE_LOCKED
		POP	SI
		POP	DS
		MOV	AX,ES
		RET

AL_FIX:
		PUSH	AX
		CALL	GET_NEW_LOG_BLK
		PUSH	BX
		MOV	BX,LOCKED_STUFF._LKD_BLKS_COUNT2
		MOV	ES,AX
		MOV	LOCKED_STUFF[BX]._LKD_BLKS_OWNED,AX
		ADD	BX,2
		MOV	LOCKED_STUFF._LKD_BLKS_COUNT2,BX
		CONV_ES
		LOCKIT
		POP	BX
		MOV	LOCKED_STUFF._LKD_ALLOC_PTR.SEGM,ES
		MOV	LOCKED_STUFF._LKD_ALLOC_PTR.OFFS,0
		MOV	LOCKED_STUFF._LKD_ALLOC_CNT,PAGE_SIZE
		POP	AX
		JMP	AL_CONT

ALLOC_LOCKED	ENDP


		ASSUME	DS:NOTHING

RELEASE_LOCKED	PROC
		;
		;DS:SI IS LOCKED MEMORY TO RELEASE, DS:[SI] IS SIZE OF BLOCK
		;
		PUSHM	DI,AX
		LEA	DI,LOCKED_STUFF._LKD_AVAIL_1K
		MOV	AX,[SI]
		CMP	AX,1024
		JZ	1$
		LEA	DI,LOCKED_STUFF._LKD_AVAIL_2K
		CMP	AX,2048
		JNZ	3$			;FOR NOW I ONLY RELEASE 1K AND 2K BLOCKS...
1$:
		MOV	AX,SI
		XCHG	DGROUP:[DI].OFFS,AX
		MOV	2[SI].OFFS,AX

		MOV	AX,DS
		XCHG	DGROUP:[DI].SEGM,AX
		MOV	2[SI].SEGM,AX
9$:
		POPM	AX,DI
		RET

3$:
		;
		;ODD SIZE...
		;
		PUSHM	DX,CX
		PUSHM	DS,SI
		MOV	2[SI].SEGM,0		;ASSUME HE IS LAST IN LIST
		FIXDS
		LEA	SI,LOCKED_STUFF._LKD_AVAIL_MISC-2
		JMP	5$

		ASSUME	DS:NOTHING
4$:
		MOV	DX,DS
		MOV	CX,SI
		LDS	SI,2[SI]
		CMP	[SI],AX
		JAE	6$
5$:
		CMP	2[SI].SEGM,0
		JNZ	4$
		POPM	2[SI].OFFS,2[SI].SEGM
		POPM	CX,DX
		POPM	AX,DI
		RET

6$:
		;
		;MY BRAIN HURTS
		;
		MOV	DS,DX
		MOV	SI,CX
		POPM	CX,DX
		MOV	AX,CX
		PUSH	BX
		MOV	BX,DX
		XCHG	2[SI].OFFS,AX
		XCHG	2[SI].SEGM,BX
		MOV	DS,DX
		MOV	SI,CX
		MOV	2[SI].OFFS,AX
		MOV	2[SI].SEGM,BX
		POP	BX
		POPM	CX,DX
		POPM	AX,DI
		RET

RELEASE_LOCKED	ENDP


ENDIF


		END

