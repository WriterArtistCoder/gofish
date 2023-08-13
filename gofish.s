@ gofish.s
.syntax unified

.equ CARDS, 52

// TO DO: print outputs to text logfile
// TO DO: separate functions to separate files
.data

.text
.global main
.type   main, %function
main:
// Prologue
	sub sp, sp, #8       // Move sp for fp, lr
	str fp, [sp, #0]     // Save fp
	str lr, [sp, #4]     // Save lr

	add fp, sp, #4       // Set frame pointer

	mov r0, #50
	mov r1, #60
	bl randnum

	bl shuffle
	bl deal

done:
// Epilogue
	mov r0, #0

	ldr fp, [sp, #0]     // Restore caller fp
	ldr lr, [sp, #4]     // Restore caller lr
	add sp, sp, #8       // Move sp back in place
	bx lr                // Return to caller

shuffle:
	mov r10, lr
	mov r4, #0           // i = 0

// Initialize random generator with srand(time(0))
	mov r0, #0
	bl time
	bl srand

shLoop:
	cmp r4, CARDS-2      // break if i > n-2
	bgt shEnd

	

	add r4, r4, #1       // i++
	b shLoop

shEnd:
	mov lr, r10
	bx lr

// Random number generator (srand(time(0)) must be called first)
// PARAMETERS r0: min, r1: max (both inclusive)
// RETURNS    r0: random number
randnum:
// Prologue
	sub sp, sp, #20      // Allocate space for registers
	str r4, [sp, #0]     // Load registers into stack
	str r5, [sp, #4]
	str r6, [sp, #8]
	str fp, [sp, #12]
	str lr, [sp, #16]
	add fp,  sp, #16     // Set fp

	mov  r6, r0          // r6 = min
	sub  r4, r1, r6      // r1 = max - min
	add  r4, r4, #1      // r1 = max - min + 1
	bl rand              // r0 = rand()

	udiv r5, r0, r4      // r2 = rand() / (max-min+1)
	mls  r0, r5, r4, r0  // r0 = rand() % (max-min+1)
	add  r0, r0, r6      // r0 = (rand() % (max-min+1)) + min

// Epilogue
	ldr r4, [sp, #0]     // Restore registers from stack
	ldr r5, [sp, #4]
	ldr r6, [sp, #8]
	ldr fp, [sp, #12]
	ldr lr, [sp, #16]
	add sp, sp, #20      // Move sp back in place
	bx lr

//for i from 0 to n−2 do
//     j ← random integer such that i ≤ j < n
//     exchange a[i] and a[j]

deal:
	mov r10, lr
	// TO DO: implement
	mov lr, r10
	bx lr

/*
FUNCTIONS:
1. shuffle deck
2. deal
3. ask for card
4. lay down the cards

* players take turns asking the other player for a card of a certain rank,
  the other player must hand over if they have it
* players give just one card when asked
* players’ goal is to collect matching pairs of cards (of the same rank), placing them
  on the table. Make sure to keep score of how many pairs each player has

For the output of the main program, you should print each play to a text log file and
indicate the eventual winner.

You ask: Do you have a J?

Computer says: Go Fish

You draw a 4

Computer asks: Do you have a 4?

You say: Yes. I have a 4

Computer books the 4 and lays down one pair of 4

Etc...

I recommend writing each assembler function in a separate .s file. If you’re running from the Pi
command line, definitely write a makefile to perform the compilation. */