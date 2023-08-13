@ gofish.s
.syntax unified

.equ CARDS, 52
.equ SPACE, 32           // ASCII for ' '

// TO DO: print outputs to text logfile
// TO DO: separate functions to separate files
.data
deck: .space 53          // Last char is unfilled, is a NUL character
sortedDeck: .asciz "222233334444555566667777888899990000JJJJQQQQKKKKAAAA " // 0 refers to the 10 card

.text
.global main
.type   main, %function
main:
// Prologue
	sub sp, sp, #8       // Move sp for fp, lr
	str fp, [sp, #0]     // Save fp
	str lr, [sp, #4]     // Save lr

	add fp, sp, #4       // Set frame pointer

	bl initDeck          // Initialize the deck
	bl deal

done:
// Epilogue
	mov r0, #0

	ldr fp, [sp, #0]     // Restore caller fp
	ldr lr, [sp, #4]     // Restore caller lr
	add sp, sp, #8       // Move sp back in place
	bx lr                // Return to caller



// Initializes the deck in a random order
initDeck:
// Accomplishes this by selecting a random card from the 'sorted' deck
// and writing it to the next spot in the deck
	mov r10, lr

	mov r4, #52          // r4 = # cards in sortedDeck
	ldr r5, =deck        // r5 points to start of actual deck

// Initialize random generator with srand(time(0))
	mov r0, #0
	bl time
	bl srand

idLoop:
	mov r0, #0           // min = 0
	mov r1, r4           // max = # of remaining cards in sortedDeck - 1
	sub r1, r1, #1
	bl randNum
	bl popCard           // Pass random number to popCard
	strb r0, [r5]        // Load popped card to deck
	                     // TO DO: Fix bug where " " has been loaded into deck

	sub r4, r4, #1
	add r5, r5, #1

	cmp r4, #0           // Break loop when 0 cards remain in sortedDeck
	beq idEnd
	b idLoop

idEnd:
	mov lr, r10
	bx lr



// Random number generator (srand(time(0)) must be called first)
// PARAMETERS r0: min, r1: max (both inclusive)
// RETURNS    r0: random number
randNum:
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

	udiv r5, r0, r4      // r5 = rand() / (max-min+1)
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



// Pops Nth card from the deck, and shifts all later cards to the left, to close the gap
// PARAMETERS r0: card index (starting with 0)
// RETURNS    r0: character representing card
popCard: // TO DO: test what happens if card at N is " "
// Prologue
	sub sp, sp, #24      // Allocate space for registers
	str r4, [sp, #0]     // Load registers into stack
	str r5, [sp, #4]
	str r6, [sp, #8]
	str r8, [sp, #12]
	str fp, [sp, #16]
	str lr, [sp, #20]
	add fp,  sp, #20     // Set fp

	mov r4, #0           // r4 = current card #
	ldr r5, =sortedDeck  // r5 points to start of sortedDeck
	mov r6, SPACE        // r6 will hold char representing the card

pcLoop:
	cmp r4, r0           // Check if reached correct index
	blt pcLoopIncr       // If less than index, continue loop

	ldrbeq r6, [r5]      // If EQUAL to index, hold card's character
	ldrb r8, [r5,+1]     // Replace current char with the next
	strb  r8, [r5]
	cmp r8, SPACE        // If that next char is a SPACE
	beq   pcLoopEnd      // Break loop

pcLoopIncr:
	add r4, r4, #1       // Increment counter
	add r5, r5, #1       // Increment pointer
	b pcLoop

pcLoopEnd:
	mov r0, r6

// Epilogue
	ldr r4, [sp, #0]     // Restore registers from stack
	ldr r5, [sp, #4]
	ldr r6, [sp, #8]
	ldr r8, [sp, #12]
	ldr fp, [sp, #16]
	ldr lr, [sp, #20]
	add sp, sp, #24      // Move sp back in place
	bx lr



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