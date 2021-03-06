#
# asmStart.s
#  startup and other assembler functions.
#
#
.text
.code 32

.global start_asm
start_asm:
		ldr			r0,	=LinuxMachineType		@ Save to pass to kernel
		str			r1, [r0]
		ldr			r0,	=AtagsAddress				@ Save to pass to kernel
		str			r2, [r0]

		mrs			r4, cpsr
		bic			r4, r4, #0x1f						@ r4 has the mode cleared

		# initialize Stack pointer for exception modes
		mrs			r4, cpsr
		bic			r4, r4, #0x1f

		#FIQ Mode
		orr			r3, r4, #0x11
		msr			cpsr_c, r3
		ldr			sp, =exc_stack

		#IRQ Mode
		orr			r3, r4, #0x12
		msr			cpsr_c, r3
		ldr			sp, =exc_stack

		#ABORT Mode
		orr			r3, r4, #0x17
		msr			cpsr_c, r3
		ldr			sp, =exc_stack
		mov			r0, #0x0000
		ldr			r1, =AbortInterrupt
		str			r1, [r0, #0x0010]
		str			r1, [r0, #0x000C]
	
		#UNDEFINED Mode
		orr			r3, r4, #0x1b
		msr			cpsr_c, r3
		ldr			sp, =exc_stack
		ldr			r1, =UndefInterrupt
		str			r1, [r0, #0x0004]

		# ensure supervisor mode
		orr			r3, r4, #0x13						@ or the supervisor mode in
		msr			cpsr_c, r3							@ put into the right hand end cpsr
		ldr			sp, =temp_stack

 		#Create the first stack frame
		mov			fp, #0x00
		mov			ip, sp
		push		{fp, ip, lr, pc}
		sub			fp, ip, #4
		
#		bl			ZeroBssMemory

		# go for the c-code now
		bl			start_main
SafetyLoop:
		b				SafetyLoop
		
ZeroBssMemory:
		ldr			r0, =__bss_start__
		ldr			r1, =__bss_end__
		sub			r2, r1, r0
		bl			bzero
		mov			pc,lr

#1:
#		str			r0, [r1]!
#		cmp			r2, r1
#		bne			1b 
#		mov			pc,lr

.global WriteToMemory32
WriteToMemory32:
		str			r0,[r1]
		mov			pc,lr

.global ReadFromMemory32
ReadFromMemory32:
		ldr			r0,[r0]
		mov			pc,lr

.global SmallDelay
SmallDelay:
loop:
		subs		r0,r0,#0x00000001
		bne			loop
		mov			pc,lr

.global VoidCall
VoidCall:
		mov			pc,lr

.global MemoryBarrier
MemoryBarrier:
		mov			r0, #0x0000
		mcr			p15, #0, r0, c7, c10, #5
		mov			pc,lr

.global SynchronisationBarrier
SynchronisationBarrier:
		mov			r0, #0x0000
		mcr			p15, #0, r0, c7, c10, #4
		mov			pc,lr
		
.global DataCacheFlush
DataCacheFlush:
		mov			r0, #0x0000
		mcr			p15, #0, r0, c7, c14, #0
		mov			pc,lr
		
.global DataSynchronisationBarrier
DataSynchronisationBarrier:
		stmfd		sp!,{r0-r8,r12,lr}				@ Store registers
		mcr			p15, 0, ip, c7, c5,  0		@ invalidate I cache
		mcr			p15, 0, ip, c7, c5,  6		@ invalidate BTB
		mcr			p15, 0, ip, c7, c10, 4		@ drain write buffer
		mcr			p15, 0, ip, c7, c10, 4		@ prefetch flush
		ldmfd		sp!,{r0-r8,r12,pc}				@ restore registers	 and return
		
UndefInterrupt:
# allows handling to be added
		bl			undefinedError
		mov			pc, lr

AbortInterrupt:
# allows handling to be added
		bl			abortError
		mov			pc, lr

.space			0x100
temp_stack:
.space			1024
.global exc_stack
exc_stack:

.global supervisor_sp
supervisor_sp:
.space			4

.bss
.p2align 4
.global FramebufferMemory
FramebufferMemory:
.space			0x400 			@ 100 words of 4 bytes

.global EndFrameBuffer
EndFrameBuffer:
.space			4

.global LinuxMachineType
LinuxMachineType:
.word			00000000

.global AtagsAddress
AtagsAddress:
.word			00000000

.end

#
# Copyright (c) 2012 Ischus Limited www.ischus.com
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software
# and associated documentation files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or
# substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
# BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
