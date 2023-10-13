		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void _bzero( void *s, int n )
; Parameters
;	s 		- pointer to the memory location to zero-initialize
;	n		- a number of bytes to zero-initialize
; Return value
;   none
		EXPORT	_bzero
_bzero
		; r0 = s
		; r1 = n
		PUSH {r1-r12,lr}		
		; you need to add some code here for part 1 implmentation
		mov r2, #0 ;value used to transfigure the target values
loop_bzero_start
		BLT loop_bzero_finish	; if n < 0, then that means we end the loop 
		cmp	r1, #0 ; start at a value and compare if iists zero
		beq	loop_bzero_finish	;if the r1 no longer has any values, then branch to end of loop.
		strb	r2, [r0] ; store value of #0 in r2 to src value in r0. transfigure it to zero
		sub	r1,r1,	#1	;decrement number of bytes to zero-initialize 
		add	r0,	r0,	#1	;move over 1
		b	loop_bzero_start	;	turn the next value zero, and keep loopng as "n" says so
		
loop_bzero_finish	;ends the program looping 
		POP {r1-r12,lr}	
		BX		lr



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; char* _strncat( char* dest, char* src, int size )
; Parameters
;   dest 	- pointer to the destination array
;	src		- pointer to string to be appended
;	size	- Maximum number of characters to be appended
; Return value
;   dest
		EXPORT	_strncat
_strncat
		; r0 = dest
		; r1 = src
		; r2 = size
		PUSH {r1-r12,lr}		
		; you need to add some code here for part 1 implmentation
dest_loop		; loop to the back of r0(destination). then append the values with operation below 
		LDRB R4, [R0]	;load value at R0 into new Regitster 4. loads the new value each loop. 
		CMP	R4, #0	;compare if value of R0 is 0.
		BEQ	dest_finish_loop	;if the value at R0 is == to 0. We end the loop and proceed wit next operation. 
		 ADD R0, R0, #1 ;set up a counter to loop to r0's end and keep incrementing
		 B	dest_loop	;branch back up to the dest_loop. 
dest_finish_loop 	;terminate loop of R0 to traverse to end of R0. 

loop	
		LDRB	R3, [R1]; grab value from R1 from src and load it into middleman.
		; then put it into the destination
		CMP	R2, #0 ; compare if r0 is the size of r2. 
		BEQ	loop_finish	; if they are equal then we end the loop.
		STRB	R3, [R0] ; store value of R1 into address of R3.
		ADD	R0, R0, #1; ;r0=r0+1
		ADD	R1, R1, #1	;r1=r1+1
		SUB	R2, R2, #1	;r2=r2-1, decrements the counter. 
		B	loop	;bracnh back to upper loop once conditions are met. 
loop_finish
		POP {r1-r12,lr}	
		BX		lr
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void* _malloc( int size )
; Parameters
;	size	- #bytes to allocate
; Return value
;   void*	a pointer to the allocated space
		EXPORT	_malloc
_malloc
		; r0 = size
		PUSH {r1-r12,lr}		
		; you need to add some code here for part 2 implmentation
		MOV	R7, #0x1 ; move syscall value of 1 into Register 7
		SVC	#0x0	; calls the malloc
		POP {r1-r12,lr}	
		BX		lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void _free( void* addr )
; Parameters
;	size	- the address of a space to deallocate
; Return value
;   none
		EXPORT	_free
_free
		; r0 = addr
		PUSH {r1-r12,lr}		
		; you need to add some code here for part 2 implmentation
		MOV	R7, #0x2 ; moves syscall value of 2(_free) into register 7
		SVC	#0x0	; calls _free. 
		POP {r1-r12,lr}	
		BX		lr 