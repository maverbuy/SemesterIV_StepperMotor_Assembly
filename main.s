;******************** (C) Yifeng ZHU *******************************************
; @file    main.s
; @author  Yifeng Zhu
; @date    May-17-2015
; @note
;           This code is for the book "Embedded Systems with ARM Cortex-M 
;           Microcontrollers in Assembly Language and C, Yifeng Zhu, 
;           ISBN-13: 978-0982692639, ISBN-10: 0982692633
; @attension
;           This code is provided for education purpose. The author shall not be 
;           held liable for any direct, indirect or consequential damages, for any 
;           reason whatever. More information can be found from book website: 
;           http:;www.eece.maine.edu/~zhu/book
;*******************************************************************************



;*******************************************************************************
;main.s
;
;Embedded Systems Software - Lab #4b
;Modified by: Mitch Verbuyst
;			  Feb 26, 2018
;
;This lab is a continuation of Lab #4 for the Stepper motor, but instead of C
;code, it will be written using assembly.  For this lab, the stepper motor will
;only be rotated for one full rotation using full stepping mode.
;
;
;Configure GPIO pins for stepper motor 
;PB2 - A
;PB3 - A not
;PB6 - B
;PB7 - B not
;
;********************************************************************************

	INCLUDE core_cm4_constants.s		; Load Constant Definitions
	INCLUDE stm32l476xx_constants.s      

	AREA    main, CODE, READONLY
	EXPORT	__main				; make __main visible to linker
	ENTRY			
				
__main	PROC
	

;******************************************************************************	
    ; Enable the clock to GPIO Port B	
	LDR r2, =RCC_BASE
	LDR r1, [r2, #RCC_AHB2ENR]
	ORR r1, r1, #RCC_AHB2ENR_GPIOBEN
	STR r1, [r2, #RCC_AHB2ENR]
	
	;use r3 for GPIO B
	LDR r3, =GPIOB_BASE ; stepper motor
	

;************************GPIO B******************************

	LDR r4, =B_MODER_VAL
	;set up GPIOB pin #2 MODER to output (01)
	LDR r1, [r3, #GPIO_MODER]
	LDR r0, =B_MODER_MASK
	AND r1,r1,r0
	ORR r1,r4
	STR r1, [r3, #GPIO_MODER]
	
	;set up GPIOB OTYPER to push pull (0)
	LDR r1, [r3, #GPIO_OTYPER]
	LDR r0, =B_TYPER_MASK
	AND r1,r1,r0
	ORR r1,r1, #B_TYPER_VAL
	STR r1, [r3, #GPIO_OTYPER]
	
	;set up GPIOB PUPDR to no pull up no pull down (00)
	LDR r1, [r3, #GPIO_PUPDR]
	LDR r0, =B_PUPDR_MASK
	AND r1,r1,r0
	ORR r1,r1, #B_PUPDR_VAL
	STR r1, [r3, #GPIO_PUPDR]
	
;*********************************End of Configuration***************************

	
;//////////////////////////////////////FUNCTIONAL CODE//////////////////////////////////////////////////
;CANNOT TOUCH R3
	
	MOV r0, #0 ; counter for first for loop "j"
	MOV r1, #0 ; counter for second for loop "i"
	MOV r2, #0 ; counter delay for loop "k"
	
;CANNOT TOUCH R0, R1, R2 AFTER HERE
	
	
outerloop
	MOV r1, #0 ; reset i = 0
	CMP r0, #512 ; j < 512
	BGE end_loop_1
	ADD r0, r0, #1 ;j++
	
innerloop
	CMP r1, #4 ; i < 4
	BGE end_loop_2
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;for loop (delay)
	MOV r4, #1
delay	
	ADD r4, #1
	LDR r10, =0x1F40
	CMP r4, r10
	BLE delay
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	;find out what iteration of "i" we are on
	CMP r1, #0
	BEQ first
	CMP r1, #1
	BEQ second
	CMP r1, #2
	BEQ third
	CMP r1, #3
	BEQ fourth
	
;==========================================================;	
; first "step" for full wave	
first
	MOV r5, #0x9 ; A
	MOV r6, #0x9 ; A not
	MOV r7, #0x9 ; B
	MOV r8, #0x9 ;;B not
	B winding

; second "step" for full wave
second
	MOV r5, #0xA ; A
	MOV r6, #0xA ; A not
	MOV r7, #0xA ; B
	MOV r8, #0xA ;;B not
	B winding

; third "step" for full wave
third
	MOV r5, #0x6 ; A
	MOV r6, #0x6 ; A not
	MOV r7, #0x6 ; B
	MOV r8, #0x6 ;;B not
	B winding

; fourth "step" for full wave
fourth
	MOV r5, #0x5 ; A
	MOV r6, #0x5 ; A not
	MOV r7, #0x5 ; B
	MOV r8, #0x5 ;;B not
	B winding
;==========================================================;	
	
;==========set the proper windings=========================;
winding
	AND r5, r5, 0x8
	LSR r5, #3
	
	AND r6,r6,0x4
	LSR r6, #2
	
	AND r7,r7,0x2
	LSR r7,#1
	
	AND r8,r8,0x1
	
;======================================================;


;==================shift windings to output registers==================;

	;clear the output register
	LDR r4, [r3, #GPIO_ODR]
	LDR r10, =B_ODR_CLEAR
	AND r4,r4,r10
	STR r4, [r3, #GPIO_ODR]
	
	;set ODR 2 (A)
	LDR r4, [r3, #GPIO_ODR]
	LSL r5, #2
	ORR r4, r4, r5
	STR r4, [r3, #GPIO_ODR]
	
	;set ODR 3 (A not)
	LDR r4, [r3, #GPIO_ODR]
	LSL r6, #3
	ORR r4, r4, r6
	STR r4, [r3, #GPIO_ODR]
	
	;set ODR 6 (B)
	LDR r4, [r3, #GPIO_ODR]
	LSL r7, #6
	ORR r4, r4, r7
	STR r4, [r3, #GPIO_ODR]
	
	;set ODR 7 (B not)
	LDR r4, [r3, #GPIO_ODR]
	LSL r8, #7
	ORR r4, r4, r8
	STR r4, [r3, #GPIO_ODR]

;=======================================================================;

	
	ADD r1,r1, #1 ;j++
	B innerloop
	
	
end_loop_2
	B outerloop
	
end_loop_1
	
	
	


	
	
	
  
stop 	B 		stop     		; dead loop & program hangs here

;MASKS for GPIO configuration
B_MODER_MASK 	EQU 0xFFFF0F0F
B_MODER_VAL		EQU 0x00005050
B_TYPER_MASK 	EQU 0xFF33
B_TYPER_VAL 	EQU 0x0000
B_PUPDR_MASK 	EQU	0xFFFF0F0F
B_PUPDR_VAL		EQU 0x00000000
B_ODR_CLEAR 	EQU 0xFF33




	ENDP
					
	ALIGN			

	AREA    myData, DATA, READWRITE
	ALIGN
	END
