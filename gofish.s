@ gofish.s
.syntax unified

.equ CARDS,         52
.equ SPACE,         32   // ASCII for ' '
.equ INPUT_SPACE,   48   // Space for holding input (high in case user enters too many chars)
                         // Should be divisible by 4

// TO DO: print outputs to text logfile
// TO DO: separate functions to separate files
// TO DO: double check documentation
.data
input:       .space INPUT_SPACE
inputErr:    .asciz "\033[91mFatal error: you entered too many characters and corrupted memory >:|\033[0m\n"

// Decks, which are closed with a space and NUL character, and are filled with spaces when empty
mainDeck:    .asciz "                                                     "
sortedDeck:  .asciz "222233334444555566667777888899990000JJJJQQQQKKKKAAAA " // 0 refers to the 10 card
p1Hand:      .asciz "                                                "
p2Hand:      .asciz "                                                "

printDeck:   .asciz "\033[2mDECK: \033[0m%s\n"
printP1Deck: .asciz " \033[93mYOU: \033[0m%s\n"
printP2Deck: .asciz " \033[95mCPU: \033[0m%s\n"

promptRank:  .asciz " \033[93;3mYou \033[0;3mask if the other player has a <2-10/J/Q/K/A>: \033[0m"
pcts:        .asciz " %s"

newline:     .asciz "\n"

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
	ldr r0, =printDeck   // And print it
	ldr r1, =mainDeck
	bl printf

	bl deal
// Print player's hand
	ldr r0, =printP1Deck
	ldr r1, =p1Hand
	bl printf
// Print CPU's hand
	ldr r0, =printP2Deck
	ldr r1, =p2Hand
	bl printf
// Print main deck
	ldr r0, =printDeck
	ldr r1, =mainDeck
	bl printf

// Print \n
	ldr r0, =newline
	bl printf

// Prompt player to ask CPU for a rank
	bl getRank

done:
// Epilogue
	mov r0, #0

	ldr fp, [sp, #0]     // Restore caller fp
	ldr lr, [sp, #4]     // Restore caller lr
	add sp, sp, #8       // Move sp back in place
	bx lr                // Return to caller



// Initializes the deck in a random order
// PARAMETERS None
// RETURNS    None
initDeck:
// Accomplishes this by selecting a random card from the 'sorted' deck
// and writing it to the next spot in the deck
	mov r10, lr          // 'Mini' prologue

	mov r4, #52          // r4 = # cards in sortedDeck
	ldr r5, =mainDeck    // r5 points to main deck
	ldr r6, =sortedDeck  // r6 points to sortedDeck

// Initialize random generator with srand(time(0))
	mov r0, #0
	bl time
	bl srand

idLoop:
	mov r0, #0           // min = 0
	mov r1, r4           // max = # of remaining cards in sortedDeck - 1
	sub r1, r1, #1
	bl randNum

	mov r1, r6           // Pass r1 = pointer to sortedDeck
	bl popCard           // Pass r0 = random number to popCard
	strb r0, [r5]        // Load popped card to deck

	sub r4, r4, #1
	add r5, r5, #1

	cmp r4, #0           // Break loop when 0 cards remain in sortedDeck
	beq idLoopEnd
	b idLoop

idLoopEnd:
	mov lr, r10          // 'Mini' epilogue
	bx lr



// Deals 5 cards to each hand from mainDeck, alternating between hands
// PARAMETERS None
// RETURNS    None
deal:
	mov r10, lr          // 'Mini' prologue
	ldr r4, =p1Hand      // r4 points to player's hand
	ldr r5, =p2Hand      // r5 points to CPU's hand
	ldr r6, =mainDeck    // r6 points to main deck

	mov r8, #0           // Counter

dealLoop:
// Take card from deck and deal to player
	mov r0, #0           // r0 = take first (0th) card
	mov r1, r6           // r1 = from mainDeck
	bl popCard
	strb r0, [r4]        // Write card to p1Hand
	add r4, r4, #1       // Increment p1Hand pointer
	add r8, r8, #1       // Increment counter

// Take card from deck and deal to CPU
	mov r0, #0           // r0 = take first (0th) card
	mov r1, r6           // r1 = from mainDeck
	bl popCard
	strb r0, [r5]        // Write card to p2Hand
	add r5, r5, #1       // Increment p2Hand pointer
	add r8, r8, #1       // Increment counter

	cmp r8, #10          // Break when 10 cards have been dealt in total
	beq dealLoopEnd
	b dealLoop

dealLoopEnd:
	mov lr, r10          // 'Mini' epilogue
	bx lr



// Prompts the player to ask for a rank.
// PARAMETERS None
// RETURNS    r0: rank
getRank:
	mov r10, lr          // 'Mini' prologue

	ldr r4, =input       // r4 points to temporary input storage
	bl clearInput

	ldr r0, =promptRank
	bl printf

	ldr r0, =pcts
	mov r1, r4
	bl scanf

// Check that user has not entered too many chars, corrupting data
	add r4, r4, INPUT_SPACE-1 // Move pointer to last char
	ldrb r5, [r4]
	cmp r5, #0                // Check that last char is NUL
	bne throwInputErr
	sub r4, r4, INPUT_SPACE-1 // Move pointer back

// Check that input is valid
	// TO DO: implement
	// START ON THIS!

	mov lr, r10          // 'Mini' epilogue
	bx lr


// Clears all data in the 'input' variable
// TO DO: test if this works correctly
// PARAMETERS None
// RETURNS    None
clearInput:
	ldr r0, =input       // r0 = pointer to end of 'input'
	add r0, r0, INPUT_SPACE-1
	ldr r1, =input       // r1 = pointer to 'input'
	mov r2, #0           // r1 = NUL

ciLoop:
	strb r2, [r1]
	add r1, r1, #4
	cmp r1, r0
	blt ciLoop

ciLoopEnd:
	bx lr



// Throws input error and exits program
// PARAMETERS None
// RETURNS    None
throwInputErr:
	ldr r0, =inputErr
	bl printf
	b done



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



// Pops Nth card from a deck, and shifts all later cards to the left, to close the gap
// PARAMETERS r0: card index (starting with 0), r1: pointer to the deck
// RETURNS    r0: character representing card
popCard:
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
	mov r5, r1           // r5 points to the deck in question
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