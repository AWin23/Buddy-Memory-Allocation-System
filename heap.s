		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table
HEAP_TOP	EQU		0x20001000
HEAP_BOT	EQU		0x20004FE0
MAX_SIZE	EQU		0x00004000		; 16KB = 2^14
MIN_SIZE	EQU		0x00000020		; 32B  = 2^5
	
MCB_TOP		EQU		0x20006800      ; 2^10B = 1K Space
MCB_BOT		EQU		0x20006BFE
MCB_ENT_SZ	EQU		0x00000002		; 2B per entry
MCB_TOTAL	EQU		512				; 2^9 = 512 entries
	
INVALID		EQU		-1				; an invalid id
	
;
; Each MCB Entry
; FEDCBA9876543210
; 00SSSSSSSSS0000U					S bits are used for Heap size, U=1 Used U=0 Not Used

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Memory Control Block Initialization
; void _kinit( )
; this routine must be called from Reset_Handler in startup_TM4C129.s
; before you invoke main( ) in driver_keil
		EXPORT	_kinit
_kinit
		; you must correctly set the value of each MCB block
		; complete your code		
		
		LDR		R1, =MCB_TOP	; 0x20006800
		LDR		R3, =MCB_BOT ; load 0x20006BFE into R6
		MOV		R2, #MAX_SIZE	; must write 0x400 into mcb[0]. so r2 stores the maxsize
		STR		R2, [R1]
knit_loop
		CMP		R1, R3
		BGE		knit_loop_end
		ADD 	R1, R1, #2
		MOV		R5, #0x0	;write value of 0 into r5
		STR		R5, [R1]	;store 0 into adress of r3
		;ADD		R3, R3, #4	;increment the ptr for r3 by 4 each time
		
		B		knit_loop	;keep bracnhing to the top loop until r3 hits r4. 

knit_loop_end
		
		BX		lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Kernel Memory Allocation
; void* _k_alloc( int size )
		EXPORT	_kalloc
_kalloc
		; complete your code
		; return value should be saved into r0
		PUSH {lr}
		LDR		R1, =MCB_TOP	; load the value of MCB_TOP into register 1
		LDR		R2, =MCB_BOT	; load the value of MCB_BOT into register 2 
		;PUSH {r1-r12,lr}
		
		BL		_ralloc	;  branch link into the ralloc function(recursivly call ralloc) 
		;POP		{r1-r12, lr}
		POP	{lr}
		MOV		R0, R8 ; return value is then stored into r0
		BX		lr

_ralloc
		;PUSH {r1-r12,lr}
		PUSH {lr}
		; ** REGISTER DECLARATIONS **
		 ;R0 = int size
		 ;R1 = left_mcb_addr
		 ;R2 = int right_mcb_addr
		 ;R3 = int MCB_ENT_SZ
		; INPUT/ PARAMETER
		
		;R4 = int entire_mcb_addr_space
		LDR			R3, =MCB_ENT_SZ	; load value of ENT_SZ into register 3
		SUBS		R4, R2, R1 ; right_mcb_addr - left_mcb_addr
		ADDS		R4, R4, R3	
		
		;R5 = int half_mcb_addr_space	
		ASRS		R5, R4, #1	
		
		;R6 = int midpoint_mcb_addr 
		ADDS		R6, R1, R5	
		
		;R8 = int heap_addr ;(this is the return register that is then stored into r0)
		MOV		R8, #0 
		
		;R9 = int act_entire_heap_size
		LSLS		R9, R4, #4 
		 
		;R10 = int act_half_heap_size
		LSLS		R10, R5, #4 
		
		; will the requested fir in half of the available size 
		; check if we can allocate to left partition
		;R10 = int act_half_heap_size
		; BASE CASE
		CMP R0, R10 
		BLE left_partition
		
		; do a bitwise operation AND to check if its LSB is == to 0
		; R6 = midpoint_mcb_addr
		LDRH	R11, [R1]	
		AND	R11, R11, #0x01 
		
		; check if the space is still avaliable 
		CMP	R11, #0x0
		BNE	return_zero ; then the left space is used
		BEQ	_if_space_is_available
		;MOV	R8, #0x0
		

_if_space_is_available ; "avaliable space"
	
		; check these avaliable space thats saved in at left MCB is the same w actual size
		; check if the whole space is avsilable.
		; R1 = int left_mcb_addr. R9 = int act_entire_heap_size
		LDR R11, [R1]
		CMP	R11, R9 
		BLT	return_zero  ; if ( *(short *)&array[ m2a( left_mcb_addr ) ] < act_entire_heap_size )
		
		; changing avaliabilty of the mcb space that we searching in
		;R9 = int act_entire_heap_size		
		ORRS R11, R9, #0x01	
		STR	 R11, [R1] 	; R1 = left_mcb_addr
			
		LDR	R12, =MCB_TOP
		LDR	R8, =HEAP_TOP
		; return heap_top + ( left_mcb_addr - mcb_top ) * 16 is value of heap_address after whole operation
		SUBS R12, R1, R12 ;
		LSLS R12, R12, #4	; 
		ADDS R12, R12, R8
		
		; Successfully allocate the requested space - R0
		MOV	 R8, R12 
		BL ralloc_done


left_partition
		; allocate requested memory from the left partition 
		PUSH {r1-r7, r9-r12}
		SUB	R2, R6, R3 ; 
		;STR	R2, [R8]
		BL _ralloc
		POP {r1-r7, r9-r12}
		
		; after recursive call, i should have heap_adresss stored in R8
		; check if the heap_adress is succesfully allocated, R8 != 0
		CMP	R8, #0x0 
		BEQ	right_partition ; failed to allocate to left, now we seearch right partition
		
		; check if space of right buddy is still avaliable 
		; R6 = midpoint_mcb_addr
		LDR	R11, [R6] 
		AND	R11, R11, #1
		CMP	R11, #0x0	; 	if ( ( array[ m2a( midpoint_mcb_addr ) ] & 0x01 ) == 0 )
		BNE ralloc_done 
		
		; else WE save avalable half into midpoint
		; R10 = int act_half_heap_size. R6 = int midpoint_mcb_addr 
		STRH	R10, [R6]
		B ralloc_done
		
right_partition ;return _ralloc(size, midpoint_mcb_addr, right_mcb_addr);
		; that means the middle is now the "left side" 
		PUSH {r1-r7, r9-r12}
		MOV	R1, R6
		BL	_ralloc
		POP {r1-r7, r9-r12}
		BL	ralloc_done
		
return_zero
		MOV	R8, #0
		BL	ralloc_done
		
ralloc_done 
		POP	{lr}				; R0 is the final return value. R8 is the 2nd return value. Dont use R7.	
		BX LR 
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Kernel Memory De-allocation
; void *_kfree( void *ptr )	
		EXPORT	_kfree
_kfree
		; complete your code
		; return value should be saved into r0
		;** I declared these registers based on the order of the C code. **
		;	R0 = int mcb_addr
		;	R1 = int mcb_contents
		;	R2 = int mcb_index
		;	R3 = int mcb_disp
		;	R4 = int my_size
		;	R5 = MCB_TOP
		;	R6 = MCB_BOT
		PUSH	{lr}
		MOV	R1, R0				;deference of ptr
		LDR		R8,=HEAP_TOP
		LDR		R9, =HEAP_BOT
		LDR		R5, =MCB_TOP
		
		CMP	R1, R8	;if ( addr < heap_top ). R0= addr. R8=heap_top

		BLT	its_null ;if addr is less than heap_top, we branch null function which returns null
		
		CMP	R1, R9	; if (addr > heap_bot) R0=addr R9=HEAP_BOT
		BGT	its_null	 ; OR if R0 is greater than R9, we also branch to the null function
		
		SUB R10, R1, R8		;  ( addr - heap_top ). stores into temp register of #10 
		ASR	R10, R10, #4 ; divides result of addr - heap_top by 16 wit value of #4
		ADD R10, R5, R10	;R0 is now officially the mcb_address
		MOV	R0, R10
		
		PUSH{r1-r12}
		BL	_rfree	;"recursivly" call _rfree
		POP	{r1-r12}
		CMP R0, #0 ; if ( _rfree( mcb_addr ) == 0 )	. branch link to rfree and compare its mcb_addrr to 0. R0=mcb_addr
		BEQ	its_null	; if mcb_addr is 0, we branch to return null function
		BL	_kfreedone
		
its_null	;fucntion to RETURN 0 
		MOV	R0, #0 ; move zero into mcb_addrr and then finish program the following line 
		BL	_kfreedone	
		
_kfreedone ;else statement 
		POP {lr}
		BX	lr

_rfree
		PUSH {lr}
		;return value stored into r0
		;	R0 = int mcb_addr
		;	R1 = int mcb_contents
		;	R2 = int mcb_index
		;	R3 = int mcb_disp
		;	R4 = int my_size
		;	R5 = int MCB_TOP
		;	R6 = int MCB_BOT
		;	R7 = another temp register 
		; R8 = another return register (this for first big else statement ) 
		;	R9 = temp register
		;	R10 = another temp rsgister 
		;	R11 = another temp register
		LDR	R5, =MCB_TOP
		LDR	R6, =MCB_BOT
		LDR	R1, [R0] ;short mcb_contents = *(short *)&array[ m2a( mcb_addr ) ]. load the mcb_addr into the mcb_contents. maybe use LDRH?
		SUB	R2, R0, R5 ;int mcb_index = mcb_addr - mcb_top. subtract mcb_addr and mcb_top, then store into R2(mcb_index)
		ASR	R1, R1, #4				; int mcb_disp = ( mcb_contents /= 16 ). arithmetic shift right the mcb_contents by 4(divide by 16)
		MOV	R3, R1	; move the result of mcb_contents/16 into mcb_disp
		LSL	R1, R1, #4 ; int my_size = ( mcb_contents *= 16 )
		MOV	R4, R1 ; move results of mcb_contents *=16, and STORE INTO R4, my_size
		
		
		STR	R1, [R0] ; *(short *)&array[ m2a( mcb_addr ) ] = mcb_contents. load mcb_contents into array address of mcb
		SDIV R7, R2, R3		; if ( ( mcb_index / mcb_disp ) % 2 == 0 ) { **
		AND  R10, R7,#1
		
		CMP	R10, #0x0	; if ( ( mcb_index / mcb_disp ) % 2 == 0 )
		 
		BNE is_not_even ; iif the statement above is not even, then I just branch to this function
		BEQ	rfree_equal_zeroone ; if above is true tho, we branch to the "return zero" function
		
kfree_equal_zero	; if ( ( mcb_buddy & 0x0001 ) == 0 )
		ASRS R6, R6, #5 		; ( mcb_buddy / 32 );
		LSLS	R6, R6, #5			; mcb_buddy = ( mcb_buddy / 32 ) * 32;
		CMP	R6, R4		; if ( mcb_buddy == my_size ) {
		BEQ	return_address	;if above are equal, then we branch to the return_address function **if ( mcb_buddy == my_size ) { is TRUE**
		BL rfree_done	; fbranch to finihs program 
		
kfree_equal_zero_two
		SUBS	R8, R0, R3	;( mcb_addr - mcb_disp )
		LDR	R12, [R8] 	; short mcb_buddy = *(short *)&array[m2a(mcb_addr - mcb_disp) ]
		AND	R12, R12, #0x0001 ; if((mcb_buddy & 0x0001 ) == 0) {
		CMP R12, #0
		BNE	rfree_done
		
		ASRS R12, R12, #5	; ( mcb_buddy / 32 )
		LSLS R12, R12, #5 ; mcb_buddy = ( mcb_buddy / 32 ) * 32
		
		CMP	R12, R4 ; if(mcb_buddy == my_size)
		BEQ	return_address_two
		BL	rfree_done
		
		
return_address_two ; if MCB_buddy is == my_size
	;	R0 = int mcb_addr
		MOV	R12, #0x0 ;*(short *)&array[ m2a( mcb_addr ) ] = 0;
		STR	R12, [R0]
		
		LSL R4, R4, #1 ; my_size *= 2
		SUB R12, R0, R3	 ; *(short *)&array[m2a(mcb_addr - mcb_disp) ] = my_size
		STR R4, [R12] ; 	*(short *)&array[ m2a( mcb_addr - mcb_disp ) ] = my_size;
		
		PUSH {r0-r12}
		SUB	r0,r0,r3
		BL	_rfree 	;return _rfree( mcb_addr - mcb_disp );
		POP {r0-r12}
		BL rfree_done ;? 
		
return_address	 ;**if ( mcb_buddy == my_size ) { is TRUE**
		ADD R8, R0, R3;  R8 = mcb_addr + mcb_disp 
		MOV R11, #0 ; *(short *)&array[ m2a( mcb_addr + mcb_disp ) ] = 0; . R8 = mcb_addr + mcb_disp 
		STR	R11, [R8] ; 2nd part  *(short *)&array[ m2a( mcb_addr + mcb_disp ) ] = 0;
		LSL R4, R4, #1 ; 	my_size *= 2;. doublple the size allocated	
		STR R4, [R0] ; *(short *)&array[ m2a( mcb_addr ) ] = my_size;. store address of my_szie into the mcb_addr
		
		PUSH{r0-r12}
		BL _rfree	;return _rfree( mcb_addr );	
		POP {r0-r12}
		BL	rfree_done ;  
		
rfree_equal_zeroone
		ADD	R3, R3, R0 ; 	if ( mcb_addr + mcb_disp. mcb_addr = R0, mcb_disp is R3
		CMP	R3, R6	; ( mcb_addr + mcb_disp >= mcb_bot)
		BGE	rfree_return_zero	; if its zero. just branch to return zero
		BLT	less_than_mcb_bot
		
less_than_mcb_bot
		ADD	R8, R0, R3	;( mcb_addr + mcb_disp )
		LDR	R6, [R8] ; short mcb_buddy = *(short *)&array[ m2a( mcb_addr + mcb_disp ) ]; R6 = MCB_BUDDY
				;	if ( ( mcb_buddy & 0x0001 ) == 0 ) { how do you implementt this 
		AND	R6, R6, #0x0001	; R6 = MCB_BUDDY. perform bitwsie op to check if LSB of R6 is 0x0001
		CMP	R6, #0	; if ( ( mcb_buddy & 0x0001 ) == 0 )
		BEQ	kfree_equal_zero ; i
		BL	rfree_done
		
rfree_return_zero
		MOV	R0, #0	; return 0;
		BL	rfree_done	;	; recrusivly call return _rfree( mcb_addr - mcb_disp );
	
		; ** START LOGIC FOR IF MODULO IS NOT EVEN** else {  **
is_not_even 
	;else { 
		SUB R8, R0, R3 ; mcb_addr - mcb_disp then store into R8. R8 = mcb_buddy
		CMP	R8, R5	; if ( mcb_addr - mcb_disp < mcb_top )
		BLT	return_zero_two ; if mcb_addr - mcb_disp is RLLY less than mcb_top. branch to a return zero statement
		; **implemnt a greater_than function for if mcb_addr - mcb_dsip is !< to mcb_top**
		; start of ELSE of if ( mcb_addr - mcb_disp < mcb_top ). 
		LDR	R11, [R8]
		AND	R8, R8, #0x0001 ;if ( ( mcb_buddy & 0x0001 ) ) {	**IDK HOW TO DO THIS PART**
		CMP	R8, #0 ; if ( ( mcb_buddy & 0x0001 ) == 0 )
		BEQ	kfree_equal_zero
		BL	rfree_done
		
return_zero_two
		MOV	R0, #0 ; return zero;
		B rfree_done ; branch link to the finishing statement of this line

rfree_done ; done function for rfree
		POP {lr} ; pops it
		BX	lr


		END