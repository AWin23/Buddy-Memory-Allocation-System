		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table
SYSTEMCALLTBL	EQU		0x20007B00
SYS_EXIT		EQU		0x0		; address 20007B00
SYS_MALLOC		EQU		0x1		; address 20007B04
SYS_FREE		EQU		0x2		; address 20007B08

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table Initialization
		EXPORT	_systemcall_table_init 
_systemcall_table_init
		LDR		r0, = SYSTEMCALLTBL
		
		
		; Initialize SYSTEMCALLTBL[0] = _sys_exit
		LDR		r1, = _sys_exit
		STR		r1, [r0]

		; Initialize_SYSTEMCALLTBL[1] = _sys_malloc
		; add your code here
		LDR		r2, =_sys_malloc
		STR		r2, [r0,#4]	
	
		; Initialize_SYSTEMCALLTBL[2] = _sys_free
		; add your code here
		LDR		r3,	=_sys_free
		STR		r3, [r0, #8]
		BX		lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table Jump Routine
; this is the function that will be callsed by SVC
        EXPORT	_systemcall_table_jump
_systemcall_table_jump
		LDR		r11, = SYSTEMCALLTBL	; load the starting address of SYSTEMCALLTBL
		MOV		r10, r7			; copy the system call number into r10
		LSL		r10, #0x2		; system call number * 4
		; complete the rest of the code
		; malloc #1
		; free #2
		CMP	r10, #4
		BEQ	_sys_malloc
		BLT	_sys_exit 
		BGT	_sys_free
		
		CMP	r7, #0 
		BEQ	_sys_exit
		CMP r7, #1	; 
		BEQ	_sys_malloc ; 
		CMP	r7, #2 ;
		BEQ	_sys_free ; 
		BX		lr				; return to SVC_Handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call 
; provided for you to use

_sys_exit
		PUSH 	{lr}		; save lr
		BLX		r11	
		POP 	{lr}		; resume lr
		BX		lr
		
_sys_malloc
		IMPORT	_kalloc
		LDR		r11, = _kalloc	
		PUSH 	{lr}		; save lr
		BLX		r11			; call the _kalloc function 
		POP 	{lr}		; resume lr
		BX		lr
		
_sys_free
		IMPORT	_kfree
		LDR		r11, = _kfree	
		PUSH 	{lr}		; save lr
		BLX		r11			; call the _kfree function 
		POP 	{lr}		; resume lr
		BX		lr
		
		END


		