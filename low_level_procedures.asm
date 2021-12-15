TITLE Designing Low-Level I/O Procedures     (low_level_procedures.asm)

; Author: Kai-Hsiang Chang
; Last Modified: 12/14/2021
; Description: This program implements two common low-level I/O procedures, one to read numeric input from the user
;			   and another to print a number to the output. The implemented procedures are called ReadVal and WriteVal
;			   respectively. ReadVal reads the string representation of numeric input from the user and converts
;			   it to a numeric representation and returns the value as output. WriteVal takes a number as input,
;			   converts it to string representation, and then prints it to the output. These procedures are showcased by
;			   asking the user to input ten numbers, from which summary calculations are performed and printed to the output.
;
;			   The primary purpose of this program is to demonstrate a working implementation for the above described I/O
;			   procedures using macros and procedures. As such, the main procedure is somewhat crowded with code that
;			   demonstrates their use.

INCLUDE Irvine32.inc

; ---------------------------------------------------------------------------------
; Name: mGetString

; Prompt the user to input a number. The String representation of the user input
;	and the length of the string is returned as output.

; Preconditions: do not use EAX, ECX, or EDX as arguments

; Postconditions: none

; Receives:	
;	prompt		=	prompt message reference
;	inString	=	string reference to store user input
;	maxStrLen	=	the maximum length string allowed
;	inStrLen	=	reference to the number of bytes read

; Returns:
;	inString	=	string representation of user input
;	inStrLen	=	number of bytes read
; ---------------------------------------------------------------------------------
mGetString		MACRO	prompt, inString, maxStrLen, inStrLen
	PUSH	EAX
	PUSH	ECX
	PUSH	EDX

	MOV		EDX, prompt
	CALL	WriteString
	MOV		EDX, inString
	MOV		ECX, maxStrLen
	CALL	ReadString
	MOV		inStrLen, EAX

	POP		EDX
	POP		ECX
	POP		EAX
ENDM

; ---------------------------------------------------------------------------------
; Name: mDisplayString

; Print the provided string

; Preconditions: do not use EDX as an argument

; Postconditions: printOut is printed to the output

; Receives:	
;	printOut	=	address of the string to print

; Returns: none
; ---------------------------------------------------------------------------------
mDisplayString	MACRO	printOut
	PUSH	EDX

	MOV		EDX, printOut
	CALL	WriteString

	POP		EDX
ENDM

ARRAYSIZE		=		10

.data

intro1			BYTE	"Designing Low-Level I/O Procedures",13,10
				BYTE	"Written by: Kai-Hsiang Chang",13,10,13, 10, 0
intro2			BYTE	"Please provide 10 signed decimal integers.",13,10
				BYTE	"Each number must be small enough to fit inside a 32 bit register. The "
				BYTE	"sum and average of all numbers must also fit within a 32 bit register. "
				BYTE	"After you have finished inputting the raw numbers, I will display a list of the "
				BYTE	"integers, their sum, and their average value.",13,10,13,10,0
numPrompt		BYTE	"Please enter a signed number: ",0
errorPrompt		BYTE	32,32,32,"ERROR: You did not enter a signed number or your number was too big.",13,10,32,32,32,"Please try again: ",0
numsMsg			BYTE	13,10,"You entered the following numbers:",13,10,0
sumMsg			BYTE	13,10,13,10,"The sum of these numbers is: ",0
avgMsg			BYTE	13,10,13,10,"The truncated average is: ",0
goodbye			BYTE	13,10,13,10,"Thanks for playing!",0
delimStr1		BYTE	") ",0
delimStr2		BYTE	", ",0
userNumStr		BYTE	15 DUP(0)			; The number inputted by the user (string form)
userNumLen		DWORD	?					; Length of user input
userNum			SDWORD	?					; numeric user input (calculated from the string input)
numStr			BYTE	15 DUP(0)			; Used in WriteVal to keep track of conversion from number -> string
arr				SDWORD	ARRAYSIZE DUP(?)

.code
main PROC
	mDisplayString	OFFSET intro1
	mDisplayString	OFFSET intro2

	; -----------------------------------------------------------
	; Get user input ten times and append each input to our array
	; -----------------------------------------------------------
	MOV				EDI, OFFSET arr
	MOV				ECX, 1
	CLD
_getInputLoop:
	;	Print the line number
	PUSH			ECX
	PUSH			OFFSET numStr
	CALL			WriteVal
	mDisplayString	OFFSET delimStr1

	;	Get user input
	PUSH			OFFSET numPrompt
	PUSH			OFFSET errorPrompt
	PUSH			OFFSET userNumStr
	PUSH			OFFSET userNumLen
	PUSH			OFFSET userNum
	CALL			ReadVal
	;	Store input in arr
	MOV				EAX, userNum
	STOSD
	
	INC				ECX
	CMP				ECX, 10
	JLE				_getInputLoop

	; ------------------------------
	; Print the array of user inputs
	; ------------------------------
	mDisplayString	OFFSET numsMsg
	MOV				ESI, OFFSET arr
	MOV				ECX, 10
	CLD
_printArr:
	LODSD
	;	Print each value in arr
	PUSH			EAX
	PUSH			OFFSET numStr
	CALL			WriteVal
	;	Handle case where last element does not need a delimiter afterwards
	CMP				ECX, 1
	JE				_skipDelim
	mDisplayString	OFFSET delimStr2
_skipDelim:
	LOOP			_printArr
	
	; ------------------------------------------
	; Calculate and print the sum of user inputs
	; ------------------------------------------
	mDisplayString	OFFSET sumMsg
	MOV				ESI, OFFSET arr
	MOV				EBX, 0			; Sum in EBX
	MOV				ECX, 10
	CLD
_sumArr:
	;	Loop through arr and update the sum in EBX
	LODSD
	ADD				EBX, EAX
	LOOP			_sumArr

	;	Print the sum
	PUSH			EBX
	PUSH			OFFSET numStr
	CALL			WriteVal
	
	; -----------------------------------------
	; Calculate and print the truncated average
	; -----------------------------------------
	mDisplayString	OFFSET avgMsg
	MOV				EAX, EBX		; Sum in EAX
	;	Check if sum is negative
	ADD				EAX, 0
	JS				_negSum
	PUSH			0				; Indicates a positive sum
	JMP				_avgArr

_negSum:
	;	If sum is negative, we negate it prior to calculations
	PUSH			1				; Indicates a negative sum
	NEG				EAX

_avgArr:
	;	Calculate the truncated average
	MOV				EBX, 10
	MOV				EDX, 0
	DIV				EBX

	;	Evaluate sign
	POP				EBX				; Indicates sign (1 for negative, 0 for positive)
	CMP				EBX, 0
	JE				_printAvg
	NEG				EAX				; If sum was negative, we undo the negation

_printAvg:
	;	Print the truncated average
	PUSH			EAX
	PUSH			OFFSET numStr
	CALL			WriteVal			

	mDisplayString	OFFSET goodbye

	Invoke ExitProcess,0			; Exit to operating system
main ENDP

; ---------------------------------------------------------------------------------
; Name: ReadVal

; Get the user input as a string of digits using mGetString, then convert the string
;	to numeric form while validating the input. The input must contain only digits,
;	or a sign at the start of the string. The input must also fit within a 32-bit
;	register. If any of these conditions fail, the user is asked for another input.
;	The validated numeric value is then returned as output.

; Preconditions: none

; Postconditions: none

; Receives:	
;	[EBP+24]	=	numPrompt reference
;	[EBP+20]	=	errorPrompt reference
;	[EBP+16]	=	userNumStr reference
;	[EBP+12]	=	userNumLen reference
;	[EBP+8]		=	userNum reference

; Returns: userNum = numeric representation of user input
; ---------------------------------------------------------------------------------
ReadVal PROC
	PUSH		EBP
	MOV			EBP, ESP
	PUSH		EAX
	PUSH		EBX
	PUSH		ECX
	PUSH		EDX
	PUSH		ESI

	; Get user input as string
	MOV			ESI, [EBP+16]		; userNumStr reference in ESI
	MOV			EBX, [EBP+12]		; userNumLen reference in EBX
	mGetString	[EBP+24], ESI, 15, [EBX]

_eval:
	MOV			ECX, [EBX]			; Counter in ECX, based on length of user input
	MOV			EBX, 0				; EBX used to calculate and store numeric form of user input
	CLD
	; Evaluate possible sign (+ or -)
	LODSB
	CMP			AL, 43
	JE			_evalPositive
	CMP			AL, 45
	JE			_evalNegative
	;	At this point, we know the number is unsigned and represents a positive number
	PUSH		0					; This will be popped later to represent a positive number in a conditional

_numLoop:
	; Evaluate each character one at a time and convert to numeric form. The running calculation is stored in EBX
	;	If the character is less than 48 or greater than 57, then it is not a numeric character
	CMP			AL, 48
	JL			_errorPop
	CMP			AL, 57
	JG			_errorPop

	;	 num = 10 * num + (numChar - 48), where num is the numeric form of user input we are calculating
	;	 and numChar is the character we are currently evaluating. num is stored in EBX
	PUSH		EAX
	MOV			EAX, EBX
	MOV			EBX, 10
	MUL			EBX
	MOV			EBX, EAX
	POP			EAX
	JO			_errorPop				; If the number is too large, ask for another one
	MOVZX		EAX, AL
	ADD			EBX, EAX
	SUB			EBX, 48

	LODSB
	LOOP		_numLoop
	JMP			_zeroCheck

_evalPositive:
	; Evaluate the "+" sign
	LODSB
	PUSH		0					; This will be popped later to represent a positive number in a conditional
	LOOP		_numLoop

_evalNegative:
	; Evaluate the "-" sign
	LODSB
	PUSH		1					; This will be popped later to represent a negative number in a conditional
	LOOP		_numLoop

_zeroCheck:
	; Check if the number is 0, which is neither positive nor negative
	CMP			EBX, 0
	JNE			_signAndBitEval
	POP			EAX					; Discard the most recently pushed value (that determines the sign)
	JMP			_finish

_signAndBitEval:
	; Handle sign and check if the number is able to fit in a 32-bit register
	POP			EAX					; This value represents the number's sign: 0 for positive, 1 for negative
	CMP			EAX, 1
	JE			_negative

	;	The number is positive
	CMP			EBX, 2147483647
	JO			_error				; If the number is too large, ask for another one
	JMP			_finish
_negative:
	;	The number is negative
	NEG			EBX
	CMP			EBX, -2147483648
	JO			_error				; If the number is too large, ask for another one
	JMP			_finish

_errorPop:
	; Error handling where we need to discard the top value on the stack
	POP			EBX					; Discard the most recently pushed value (that determines the sign) in cases of errors where it hasn't already been popped/evaluated

_error:
	; User entered an invalid input and is asked for another input
	MOV			ESI, [EBP+16]		; userNumStr reference in ESI
	MOV			EBX, [EBP+12]		; userNumLen reference in EBX
	mGetString	[EBP+20], ESI, 15, [EBX]
	JMP			_eval

_finish:
	; Move the numeric form of user input to the output
	MOV			EAX, [EBP+8]
	MOV			[EAX], EBX

	POP			ESI
	POP			EDX
	POP			ECX
	POP			EBX
	POP			EAX
	POP			EBP
	RET			20
ReadVal	ENDP

; ---------------------------------------------------------------------------------
; Name: WriteVal

; Convert a numeric value to ascii string representation. Invoke mDisplayString to
;	print the string representation.

; Preconditions: numStr array must be populated with only 0 values

; Postconditions: prints out the string representation of the number
;				  numStr is modified to contain only 0 values (cleared for future use)

; Receives:	
;	[EBP+12]	=	numToPrint
;	[EBP+8]		=	numStr reference (used to keep track of conversion from number -> string)

; Returns: none
; ---------------------------------------------------------------------------------
WriteVal PROC
	PUSH			EBP
	MOV				EBP, ESP
	PUSH			EAX
	PUSH			EBX
	PUSH			ECX
	PUSH			EDX
	PUSH			ESI
	PUSH			EDI

	; Count the number of digits in the number
	MOV				EAX, [EBP+12]		; numToPrint in EAX
	MOV				ECX, 0				; digit counter
	;	If numToPrint is negative, we negate it prior to counting the number of digits
	ADD				EAX, 0
	JNS				_digitCounterLoop
	NEG				EAX
_digitCounterLoop:
	;	Repeatedly divide the number by 10 until the quotient is zero. The digit count is equal to the number of iterations this takes
	INC				ECX
	MOV				EDX, 0
	MOV				EBX, 10
	DIV				EBX
	CMP				EAX, 0
	JNE				_digitCounterLoop

	; Convert the number to a string, stored in numStr
	MOV				EDI, [EBP+8]		; numStr reference in EDI
	MOV				EAX, [EBP+12]		; numToPrint in EAX
	;	If numToPrint is negative, we negate it and add a "-" sign at the front
	ADD				EAX, 0
	JNS				_continue
	NEG				EAX
	CLD
	PUSH			EAX
	MOV				AL, 45
	STOSB
	POP				EAX

_continue:
	ADD				EDI, ECX
	DEC				EDI
	STD
_insertNumToArrLoop:
	;	Loop through the number and insert it into numStr
	;		Repeatedly divide the number by 10 to get the remainder, which we then convert to ascii and append to numStr
	;		in reverse order (since we are starting with the last digits). We stop this process when the quotient is zero.
	MOV				EDX, 0
	MOV				EBX, 10
	DIV				EBX
	PUSH			EAX
	MOV				EAX, EDX
	ADD				AL, 48
	STOSB	
	POP				EAX
	CMP				EAX, 0
	JNE				_insertNumToArrLoop
	CLD

	;At this point we have finished adding all digit characters to numStr in the correct order and print the string
	mDisplayString	[EBP+8]

	; Clear numStr for future use by changing all elements to 0
	MOV				EDI, [EBP+8]
	MOV				AL, 0
	MOV				ECX, 15
_clearNumStr:
	REP				STOSB

	POP				EDI
	POP				ESI
	POP				EDX
	POP				ECX
	POP				EBX
	POP				EAX
	POP				EBP
	RET				8
WriteVal ENDP

END main
