@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
@
@        Library Name:           
@								Robomal (for RealDigital Blackboard)
@        
@        Version:                
@								1.0.0 
@
@        Contributor(s):         
@								Koby Miller
@
@        Date last modified:     
@								March 7th, 2024
@
@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
.ifndef ROBOMAL_S_
.set ROBOMAL_S_, 1

.include "../src/klibio.S"

.data

@ Main operation jump-table
r_operation: .word r_dataJump, r_arithmeticJump,r_branchJump,r_controlJump
@ Suboperation jump-table
r_dataJump: .word r_read, r_write, r_load, r_store
r_arithmeticJump: .word r_add, r_sub, r_mul
r_branchJump: .word r_branch, r_brancheq, r_branchne, r_halt
r_controlJump: .word r_left, r_right, r_forward, r_backward, r_brake

@ Arbitrary instructions and data
instructSet: .hword 0x1000, 0x1100, 0x1200, 0x1300, 0x2000, 0x2100, 0x2200, 0x3000, 0x3100, 0x3200, 0x3300, 0x4000, 0x4100, 0x4200, 0x4300, 0x4400
dataSet: .hword 0x1111

@ ROBOMAL Register File 
@ r5 = accumulator register
@ r6 = program counter register
@ r7 = instruction register
@ r8 = opcode register
@ r9 = operand register
@ r10 = multiply top half solution register

.text 

@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
@ runRobomal
@
@	Loopy
@
@ Last modified: March 6th, 2024
@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
runRobomal:
	push {lr}
	
	mov r6, #0
	
	runRobomalLoop:
		bl simClockCycle
	cmp r8, #0x33
	bne runRobomalLoop
	
	pop {lr}
bx lr

@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
@ simClockCycle
@
@	Simulate a single "fetch, decode, and execute" cycle
@
@ Last modified: March 6th, 2024
@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
simClockCycle:
	push {lr}
	
	bl r_fetch
	bl r_decode
	bl r_execute

	pop {lr}
bx lr 

@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
@ r_fetch
@
@ 		r6 -> program counter
@		r7 -> instruction register
@
@ Last modified: March 6th, 2024
@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
r_fetch:
	push {r0}
	
	ldr r0, =instructSet
	
	ldrh r7, [r0,r6]
	
	add r6, r6, #0x2
	
	pop {r0}
bx lr

@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
@ r_decode
@
@ 		r7 -> instruction register
@ 		r8 -> opcode register
@ 		r9 -> operand register
@
@ Last modified: March 6th, 2024
@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
r_decode:

	lsr r8, r7, #8
	
	and r9, r7, #0xFF

bx lr

@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
@ r_execute
@
@ 		r5 -> accumulator register
@ 		r6 -> program counter register (if we are doing a branch)
@ 		r8 -> opcode register
@ 		r9 -> operand register
@		r10 -> multiply top half solution register
@
@ Last modified: March 7th, 2024
@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
r_execute:
	push {r0,r1,lr}

	@ determine first hex digit of opcode
	mov r1, r8 @ create copy
	and r1, #0xF0 @ mask off first digit
	sub r1, r1, #0x10
	lsr r1, #2 @ make appropriate size to index a word array (right shift because must first be shifted 4 due to hex, then multiplied by 4 for index)
	ldr r0, =r_operation @ load operation jump-table
	ldr r0, [r0, r1] @ index jump-table by first digit, which should store sub-jump-table in r0

	@ determine second hex digit of opcode
	mov r1, r8 @ create copy
	and r1, #0xF @ mask off second digit
	lsl r1, #2 @ make appropriate size to index a word array
	ldr r0, [r0, r1] @ index sub-jump-table by second digit
	bx r0
	
	@ +-+-+-+-+-+-+-+-+-+-+-+-+-+-+ Operations +-+-+-+-+-+-+-+-+-+-+-+-+-+-+
	r_read:
		mov r1, #1 @ read from bottom row
		bl pmodRead @ get pmod value returned in r0
		ldr r1, =dataSet @ get address of dataSet start
		strh r0, [r1, r9] @ store pmod value in r1 offset r9
	b leave_r_execute
	
	
	r_write:
		ldr r0, =dataSet @ get address of dataSet start
		ldrh r1, [r0, r9] @ store pmod value in r1 offset r9
		mov r2, r1 @ set data to write
		mov r1, #0 @ write to top row
		bl pmodWrite @ get pmod value returned in r0
	b leave_r_execute
	
	
	r_load:
		ldr r0, =dataSet @ get address of dataSet start
		ldrh r5, [r0, r9] @ load from value in dataSet offset r9
	b leave_r_execute
	
	
	r_store:
		ldr r0, =dataSet @ get address of dataSet start
		strh r5, [r0, r9] @ set r5 to value in dataSet offset r9
	b leave_r_execute
	
	
	r_add:
		ldr r0, =dataSet @ get address of dataSet start
		ldrh r0, [r0, r9] @ load from value in dataSet offset r9
		add r5, r5, r0 
	b leave_r_execute
	
	
	r_sub:
		ldr r0, =dataSet @ get address of dataSet start
		ldrh r0, [r0, r9] @ load from value in dataSet offset r9
		sub r5, r5, r0 
	b leave_r_execute
	
	
	r_mul:
		ldr r0, =dataSet @ get address of dataSet start
		ldrh r0, [r0, r9] @ load from value in dataSet offset r9
		mul r5, r5, r0 
	b leave_r_execute
	
	
	r_branch:
		mov r6, r9 @ set program counter to argument
	b leave_r_execute
	
	
	r_brancheq:
		cmp r5, #0 @ compare to zero
		moveq r6, r9 @ set program counter to argument if zero
	b leave_r_execute
	
	
	r_branchne:
		cmp r5, #0 @ compare to zero
		movne r6, r9 @ set program counter to argument if NOT zero
	b leave_r_execute
	
	
	r_halt:
		@ stop in tracks
		mov r1, #1
		bl outputToSevSeg
	b leave_r_execute
	
	
	r_left:
		@ turn left
		mov r1, #2
		bl outputToSevSeg
	b leave_r_execute
	
	
	r_right:
		@ turn right
		mov r1, #3
		bl outputToSevSeg
	b leave_r_execute
	
	
	r_forward:
		@ move forward
		mov r1, #4
		bl outputToSevSeg
	b leave_r_execute
	
	
	r_backward:
		@ move backward
		mov r1, #5
		bl outputToSevSeg
	b leave_r_execute
	
	
	r_brake:
		@ brake
		mov r1, #6
		bl outputToSevSeg
	@b leave_r_execute
	
	@ +-+-+-+-+-+-+-+-+-+-+-+-+-+ End Operations +-+-+-+-+-+-+-+-+-+-+-+-+-+
	leave_r_execute:
	pop {r0,r1,lr}
bx lr
.endif
