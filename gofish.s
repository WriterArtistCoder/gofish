@ gofish.s
.syntax unified

.equ CARDS,         52
.equ SPACE,         32   // ASCII for ' '
.equ INPUT_SPACE,   48   // Space for holding input (high in case user enters too many chars)
                         // Should be divisible by 4
.equ UPPERCASE,     223  // Constant to convert to uppercase

// TO DO: print outputs to text logfile
// TO DO: separate functions to separate files
// TO DO: double check documentation
.data
input:           .space INPUT_SPACE
fatalInputErr:   .asciz "\033[91mFatal error: you entered too many characters and corrupted memory >:|\033[0m\n"
inputErr:        .asciz "\033[91mWhat?\033[0m\n"

// Decks, which are closed with a space and NUL character, and are filled with spaces when empty
mainDeck:        .asciz "                                                     "
sortedDeck:      .asciz "222233334444555566667777888899990000JJJJQQQQKKKKAAAA " // 0 refers to the 10 card
p1Hand:          .asciz "                                                "
p2Hand:          .asciz "                                                "
p1Pairs:         .space 1  // Number of pairs held by player
p2Pairs:         .space 1  // Number of pairs held by CPU

printDeck:       .asciz "\033[2mDECK: \033[0m%s\n"
printP1Deck:     .asciz " \033[93mYOU: \033[0m%s\n"
printP2Deck:     .asciz " \033[95mCPU: \033[0m%s\n"
printScore:      .asciz " \033[93m%d \033[0m- \033[95m%d \033[0m\n"
printGoFish:     .asciz " \033[95mCPU: Go fish.\n \033[93mYOU draw a %c.\033[0m\n\n"
printGoFishTen:  .asciz " \033[95mCPU: Go fish.\n \033[93mYOU draw a 10.\033[0m\n\n"
printCGoFish:    .asciz " \033[93mYOU: Go fish.\n \033[95mCPU draws a %c.\033[0m\n\n"
printCGoFishTen: .asciz " \033[93mYOU: Go fish.\n \033[95mCPU draws a 10.\033[0m\n\n"
printBookP2s:    .asciz " \033[95mCPU: Yes, I have that card T_T.\033[0m\n"
printBookP1s:    .asciz " \033[93mYOU: Yes, I have that card T_T.\033[0m\n"
printPairP1:     .asciz " \033[93mYOU booked a pair of %cs! They are laid on the 'table'.\033[0m\n"
printPairP1Ten:  .asciz " \033[93mYOU booked a pair of 10s! They are laid on the 'table'.\033[0m\n"
printPairP2:     .asciz " \033[95mCPU booked a pair of %cs! They are laid on the 'table'.\033[0m\n"
printPairP2Ten:  .asciz " \033[95mCPU booked a pair of 10s! They are laid on the 'table'.\033[0m\n"
ten:             .asciz "10"

promptRank:      .asciz " \033[93;3mYou \033[0;3mask if the other player has a <2-10/J/Q/K/A>: \033[0m"
printCPUAsk:     .asciz " \033[95;3mCPU \033[0;3masks if you have a %c.\033[0m\n"
printCPUAskTen:  .asciz " \033[95;3mCPU \033[0;3masks if you have a 10.\033[0m\n"
pcts:            .asciz " %s"

newline:         .asciz "\n"

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
	bl dispDecks         // Print hands and deck
	bl dispScore         // Print number of pairs held by each player

	bl initPairing       // Any duplicate cards in hands are booked
	mov r10, r0          // If cards were booked, r10 = 1. Otherwise, r10 = 0

mainLoop:
	cmp r10, #0          // If it's the start of the game and no cards were paired,
	beq mainLoop2        // skip printing hands, deck, and score

	bl dispDecks         // Print hands and deck
	bl dispScore         // Print number of pairs held by each player

mainLoop2:
	mov r10, #1          // Set flag to always print hands, deck, and score

// Print \n
	ldr r0, =newline
	bl printf

// Prompt player to ask CPU for a rank
	bl getRank
	ldr r1, =p2Hand      // Pass result of getRank as r0, pointer to CPU's hand as r1
	bl checkDeck         // Check deck for matching card

	cmp r0, #-1          // If no matches, "go fish"
	bleq goFish
	blne bookP2s         // If match found, CPU gives card to player
	                     // pass pointer to card to bookP2s

	bl dispDecks         // Print hands and deck
	bl dispScore         // Print number of pairs held by each player

	bl checkGG           // Check if game is over - if either hand or the deck are out

// Print \n
	ldr r0, =newline
	bl printf

// CPU asks player for a rank
	bl cgetRank
	ldr r1, =p1Hand      // Pass result of cgetRank as r0, pointer to player's hand as r1
	bl checkDeck         // Check deck for matching card

	cmp r0, #-1          // If no matches, "go fish"
	bleq cgoFish
	blne bookP1s         // If match found, CPU gives card to player
	                     // pass pointer to card to bookP1s

	bl checkGG           // Check if game is over - if either hand or the deck are out

	b mainLoop

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
	beq idEnd
	b idLoop

idEnd:
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
	beq dealEnd
	b dealLoop

dealEnd:
	mov lr, r10          // 'Mini' epilogue
	bx lr



// Pairs and lays on table any duplicate cards in P1 and P2 hands, when the cards are dealt at the start.
// PARAMETERS None
// RETURNS    r0: 1 if pair was found (NEEDS TESTING)
initPairing:
// Prologue
	sub sp, sp, #16       // Allocate space for registers (sp rounded up to nearest 8)
	str r4, [sp, #0]     // Load registers into stack
	str r5, [sp, #4]     // Load registers into stack
	str fp, [sp, #8]
	str lr, [sp, #12]
	add fp,  sp, #16     // Set fp

	ldr r4, =p1Hand      // r4 points to start of player's hand
	mov r5, #0           // r5 is flag for whether pair(s) was found

ipLoop1:
	ldrb r0, [r4]        // r0 = char representing card
	cmp r0, SPACE        // Check if reached end
	beq ip2              // if so, go to CPU's hand
	mov r1, #1           // r1 = 1 represents player, not CPU
	bl pairIfPossible

	cmp r0, #1           // If a pair was found and laid on table,
	subeq r4, r4, #1     // decrement r4 pointer
	moveq r5, #1         // And set r5 flag to 1

	add r4, r4, #1       // Increment r4 pointer & loop again! :D
	b ipLoop1

ip2:
	ldr r4, =p2Hand      // r4 points to start of CPU's hand

ipLoop2:
	ldrb r0, [r4]        // r0 = char representing card
	cmp r0, SPACE        // Check if reached end
	beq ipEnd            // if so, exit
	mov r1, #2           // r1 = 2 represents CPU, not player
	bl pairIfPossible

	cmp r0, #1           // If a pair was found and laid on table,
	subeq r4, r4, #1     // decrement r4 pointer
	moveq r5, #1         // And set r5 flag to 1

	add r4, r4, #1       // Increment r4 pointer & loop again! :D
	b ipLoop2

ipEnd:
	mov r0, r5           // Return r5

// Epilogue
	ldr r4, [sp, #0]     // Restore registers from stack
	ldr r5, [sp, #4]
	ldr fp, [sp, #8]
	ldr lr, [sp, #12]
	add sp, sp, #16      // Move sp back in place
	bx lr



// Prompts the player to ask for a rank.
// PARAMETERS None
// RETURNS    r0: char representing rank
getRank:
	mov r10, lr          // 'Mini' prologue

grStart:
	ldr r4, =input       // r4 points to temporary input storage
	bl clearInput        // TO DO: remove if unnecessary?

	ldr r0, =promptRank
	bl printf

	ldr r0, =pcts
	mov r1, r4
	bl scanf

// Check that user has not entered way too many chars, corrupting data
	add r4, r4, INPUT_SPACE-1 // Move pointer to last char
	ldrb r5, [r4]
	cmp r5, #0                // Check that last char is NUL
	bne throwFatalInputErr
	sub r4, r4, INPUT_SPACE-1 // Move pointer back

// Check that input is valid
 // Read first char
	ldrb r5, [r4]

 // Is it a non-numeral card?
	cmp r5, 'J
	beq grValid
	cmp r5, 'j
	beq grUpper
	cmp r5, 'Q
	beq grValid
	cmp r5, 'q
	beq grUpper
	cmp r5, 'K
	beq grValid
	cmp r5, 'k
	beq grUpper
	cmp r5, 'A
	beq grValid
	cmp r5, 'a
	beq grUpper

 // Else, is it a numeral card?
	cmp r5, '1           // Throw error if first char is below '1' in ASCII
	blt grInvalid
	cmp r5, '9           // Or above '9'
	bgt grInvalid

grValid:
	mov r0, r5
	cmp r0, '1           // Check if first char = '1'
	bne grEnd            // If not, return char
	mov r0, '0           // If so, return '0', since the only rank that begins with 1 is 10,
	b grEnd              // which is represented by a 0

grUpper:                 // Convert char to uppercase, then go to grValid
	and r5, r5, UPPERCASE
	b grValid

grInvalid:               // If input invalid,
	bl throwInputErr     // throw error and re-prompt
	b grStart

grEnd:
	mov lr, r10          // 'Mini' epilogue
	bx lr



// CPU says "Go fish", player draws a card
// PARAMETERS None
// RETURNS    None
goFish:
	mov r10, lr          // 'Mini' prologue
	ldr r4, =p1Hand      // r4 points to start of player's hand

gfLoop: // Move r4 to END of player's hand
	add r4, r4, #1       // Increment pointer
	ldrb r5, [r4]
	cmp r5, SPACE        // Check if char is a space
	bne gfLoop           // If not, continue

// Take card from deck and deal to player
	mov r0, #0           // r0 = take first (0th) card
	ldr r1, =mainDeck    // r1 = from mainDeck
	bl popCard
	strb r0, [r4]        // Write card to p1Hand

// Print 'go fish' and drawn card
	mov r1, r0           // r1 = drawn card
	ldr r0, =printGoFish
	cmp r1, '0           // Replace '0' with '10' if needed
	ldreq r0, =printGoFishTen
	bl printf

// If possible, pair the cards and lay on the table
	ldrb r0, [r4]        // r0 = char representing card
	mov r1, #1           // r1 = 1 represents player, not CPU
	bl pairIfPossible

// Return to caller
	mov lr, r10          // 'Mini' epilogue
	bx lr



// Takes card from CPU's hand and moves to player's
// PARAMETERS r0: Index of card to take
// RETURNS    None
bookP2s:
	mov r10, lr          // 'Mini' prologue

	mov r8, r0           // r8 = index of desired card in CPU's hand
	ldr r4, =p1Hand      // r4 = pointer to player's hand
	mov r9, #0           // r9 = number of cards in player's hand

bpLoop: // Move r4 to END of player's hand
	add r4, r4, #1       // Increment pointer
	add r9, r9, #1       // Increment counter
	ldrb r5, [r4]
	cmp r5, SPACE        // Check if char is a space
	bne bpLoop           // If not, continue

	ldr r5, =p2Hand      // r5 = pointer to CPU's hand

// Take card from CPU's hand and move to player's
	mov r0, r8           // r0 = index of card in CPU's hand
	ldr r1, =p2Hand      // r1 = pointer to CPU's hand
	bl popCard
	strb r0, [r4]        // Write card to p1Hand

// CPU says they have the card
	ldr r0, =printBookP2s
	bl printf

// If possible, pair the cards and lay on the table
	ldrb r0, [r4]        // r0 = char representing card
	mov r1, #1           // r1 = 1 represents player, not CPU
	bl pairIfPossible

bpEnd: // Return to caller
	mov lr, r10          // 'Mini' epilogue
	bx lr



// CPU asks player for a rank.
// PARAMETERS None
// RETURNS    r0: char representing rank
cgetRank:
	mov r10, lr          // 'Mini' prologue

	ldr r4, =p2Hand      // r4 = pointer to CPU's hand
	mov r9, #0           // r9 = number of cards in CPU's hand

cgrLoop: // Move r4 to END of CPU's hand
	add r4, r4, #1       // Increment pointer
	add r9, r9, #1       // Increment counter
	ldrb r5, [r4]
	cmp r5, SPACE        // Check if char is a space
	bne cgrLoop           // If not, continue

// Get random index
 // This will end up biased (intentionally) towards cards the CPU has more of
	mov r0, #0           // r0 stores lowest index:  zero
	sub r9, r9, #1       // r9 stores highest index: number of cards - 1
	mov r1, r9
	bl randNum

// Move r4 to the correct index
	ldr r4, =p2Hand      // r4 = pointer to CPU's hand
	mov r9, #0           // r9 = counter

cgrLoopB:
	add r4, r4, #1       // Increment pointer
	add r9, r9, #1       // Increment counter
	cmp r9, r0           // Check if counter has reached index
	bne cgrLoopB         // If not, continue

// Get card char at that index (load into r5) and ask for it
	ldrb r5, [r4]

	mov r1, r5
	ldr r0, =printCPUAsk
	cmp r1, '0           // Replace '0' with '10' if needed
	ldreq r0, =printCPUAskTen
	bl printf

// Return to caller
	mov r0, r5
	mov lr, r10          // 'Mini' epilogue
	bx lr



// Player says "Go fish", CPU draws a card
// PARAMETERS None
// RETURNS    None
cgoFish:
	mov r10, lr          // 'Mini' prologue
	ldr r4, =p2Hand      // r4 points to start of CPU's hand

cgfLoop: // Move r4 to END of CPU's hand
	add r4, r4, #1       // Increment pointer
	ldrb r5, [r4]
	cmp r5, SPACE        // Check if char is a space
	bne cgfLoop          // If not, continue

// Take card from deck and deal to CPU
	mov r0, #0           // r0 = take first (0th) card
	ldr r1, =mainDeck    // r1 = from mainDeck
	bl popCard
	strb r0, [r4]        // Write card to p2Hand

// Print 'go fish' and drawn card
	mov r1, r0           // r1 = drawn card
	ldr r0, =printCGoFish
	cmp r1, '0           // Replace '0' with '10' if needed
	ldreq r0, =printCGoFishTen
	bl printf

// If possible, pair the cards and lay on the table
	ldrb r0, [r4]        // r0 = char representing card
	mov r1, #2           // r1 = 2 represents CPU, not player
	bl pairIfPossible

// Return to caller
	mov lr, r10          // 'Mini' epilogue
	bx lr



// Takes card from player's hand and moves to CPU's
// PARAMETERS r0: Index of card to take
// RETURNS    None
bookP1s:
	mov r10, lr          // 'Mini' prologue

	mov r8, r0           // r8 = index of desired card in player's hand
	ldr r4, =p2Hand      // r4 = pointer to CPU's hand
	mov r9, #0           // r9 = number of cards in CPU's hand

cbpLoop: // Move r4 to END of CPU's hand
	add r4, r4, #1       // Increment pointer
	add r9, r9, #1       // Increment counter
	ldrb r5, [r4]
	cmp r5, SPACE        // Check if char is a space
	bne cbpLoop           // If not, continue

	ldr r5, =p1Hand      // r5 = pointer to player's hand

// Take card from player's hand and move to CPU's
	mov r0, r8           // r0 = index of card in player's hand
	ldr r1, =p1Hand      // r1 = pointer to player's hand
	bl popCard
	strb r0, [r4]        // Write card to p2Hand

// Player says they have the card
	ldr r0, =printBookP1s
	bl printf

// If possible, pair the cards and lay on the table
	ldrb r0, [r4]        // r0 = char representing card
	mov r1, #2           // r1 = 2 represents player, not CPU
	bl pairIfPossible

cbpEnd: // Return to caller
	mov lr, r10          // 'Mini' epilogue
	bx lr



// Prints player's hand, CPU's hand, and deck in that order.
// PARAMETERS None
// RETURNS    None
dispDecks:
	mov r10, lr          // 'Mini' prologue

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

	mov lr, r10          // 'Mini' epilogue
	bx lr



// Prints number of pairs held by player and CPU.
// PARAMETERS None
// RETURNS    None
dispScore:
	mov r10, lr          // 'Mini' prologue

// Print player's hand
	ldr  r0, =printScore
	ldr  r1, =p1Pairs
	ldrb r1, [r1]
	ldr  r2, =p2Pairs
	ldrb r2, [r2]
	bl printf

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

ciEnd:
	bx lr



// Throws fatal input error and exits program
// PARAMETERS None
// RETURNS    None
throwFatalInputErr:
	ldr r0, =fatalInputErr
	bl printf
	b done



// Throws mild input error and exits program
// PARAMETERS None
// RETURNS    None
throwInputErr:
// Prologue
	sub sp, sp, #8       // Allocate space for registers (sp rounded up to nearest 8)
	str fp, [sp, #0]
	str lr, [sp, #4]
	add fp,  sp, #4      // Set fp

	ldr r0, =inputErr
	bl printf

// Epilogue
	ldr fp, [sp, #0]    // Restore registers from stack
	ldr lr, [sp, #4]
	add sp, sp, #8      // Move sp back in place
	bx lr



// Looks for the first 2 cards of a certain rank, and if found pairs and lays them on the table.
// PARAMETERS r0: char representing card, r1: 1 if player holds card, 2 if CPU holds card
// RETURNS    r0: 0 if no pair found, 1 if pair found
pairIfPossible:
// Prologue
	sub sp, sp, #32      // Allocate space for registers (sp rounded up to nearest 8)
	str r4, [sp, #0]     // Load registers into stack
	str r5, [sp, #4]
	str r6, [sp, #8]
	str r8, [sp, #12]
	str r9, [sp, #16]
	str fp, [sp, #20]
	str lr, [sp, #24]
	add fp,  sp, #32     // Set fp

	mov r4, r0           // r4 = char representing card
	mov r5, r1           // r5 = flag representing which player

	cmp r5, #1           // If player, set deck pointer to p1Hand
	ldreq r6, =p1Hand    // Else (if CPU), set deck pointer to p2Hand
	ldrne r6, =p2Hand

// Find 2 cards matching rank
 // Find 1st instance of rank
	mov r0, r4           // r0 = char representing card
	mov r1, r6           // r1 = deck pointer
	bl checkDeck

	mov r8, r0           // r8 = index of first instance
	cmp r8, #-1          // If not found, return
	beq piFailure

 // Find 2nd instance of rank
	mov r0, r4           // r0 = char representing card
	mov r1, r6           // r1 = deck pointer
	add r1, r1, r8       // (points to REST of deck past first instance)
	add r1, r1, #1
	bl checkDeck

	mov r9, r0           // r9 = index of second instance
	cmp r9, #-1          // If not found, return
	beq piFailure

	add r9, r9, r8       // Fixes r9: index is counted from deck pointer
	add r9, r9, #1       // Deck pointer points to REST of deck not START, so must be accounted for

// Delete both cards
 // Pop first instance
	mov r0, r8
	mov r1, r6
	bl popCard
 // Pop second instance
	sub r9, r9, #1       // Since a card has been deleted, correct index
	mov r0, r9
	mov r1, r6
	bl popCard

	cmp r5, #1           // Check if is player and not CPU
	bne piCPU

// Increment pairs, if is player (overwrites r8, r9)
	ldr r8, =p1Pairs
	ldrb r9, [r8]
	add r9, r9, #1
	strb r9, [r8]

// Print that pair was created, if is player
	ldr r0, =printPairP1
	mov r1, r4
	cmp r4, '0           // Replace '0' with '10' if needed
	ldreq r0, =printPairP1Ten
	bl printf

// Flag that pair was created (return 1)
	mov r0, #1

	b piEnd

piCPU:
// Increment pairs, if is CPU (overwrites r8, r9)
	ldr r8, =p2Pairs
	ldrb r9, [r8]
	add r9, r9, #1
	strb r9, [r8]

// Print that pair was created, if is CPU
	ldr r0, =printPairP2
	mov r1, r4
	cmp r4, '0           // Replace '0' with '10' if needed
	ldreq r0, =printPairP2Ten
	bl printf

// Flag that pair was created (return 1)
	mov r0, #1
	b piEnd

piFailure:
// Flag that pair was not created (return 0)
	mov r0, #0
	b piEnd

piEnd:
// Epilogue
	ldr r4, [sp, #0]     // Restore registers from stack
	ldr r5, [sp, #4]
	ldr r6, [sp, #8]
	ldr r8, [sp, #12]
	ldr r9, [sp, #16]
	ldr fp, [sp, #20]
	ldr lr, [sp, #24]
	add sp, sp, #32      // Move sp back in place
	bx lr



// Random number generator (srand(time(0)) must be called first)
// PARAMETERS r0: min, r1: max (both inclusive)
// RETURNS    r0: random number
randNum:
// Prologue
	sub sp, sp, #24      // Allocate space for registers (sp rounded up to nearest 8)
	str r4, [sp, #0]     // Load registers into stack
	str r5, [sp, #4]
	str r6, [sp, #8]
	str fp, [sp, #12]
	str lr, [sp, #16]
	add fp,  sp, #16     // Set fp

	mov  r6, r0          // r6 = min
	sub  r4, r1, r6      // r1 = max - min
	add  r4, r4, #1      // r1 = max - min + 1
	bl   rand            // r0 = rand()

	udiv r5, r0, r4      // r5 = rand() / (max-min+1)
	mls  r0, r5, r4, r0  // r0 = rand() % (max-min+1)
	add  r0, r0, r6      // r0 = (rand() % (max-min+1)) + min

// Epilogue
	ldr r4, [sp, #0]     // Restore registers from stack
	ldr r5, [sp, #4]
	ldr r6, [sp, #8]
	ldr fp, [sp, #12]
	ldr lr, [sp, #16]
	add sp, sp, #24      // Move sp back in place
	bx lr



// Pops Nth card from a deck, and shifts all later cards to the left, to close the gap
// PARAMETERS r0: card index (starting with 0), r1: pointer to the deck
// RETURNS    r0: character representing card
popCard:
// Prologue
	sub sp, sp, #24      // Allocate space for registers (sp rounded up to nearest 8)
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
	blt pcIncr           // If less than index, continue loop

	ldrbeq r6, [r5]      // If EQUAL to index, hold card's character
	ldrb r8, [r5,+1]     // Replace current char with the next
	strb  r8, [r5]
	cmp r8, SPACE        // If that next char is a SPACE
	beq pcEnd            // Break loop

pcIncr:
	add r4, r4, #1       // Increment counter
	add r5, r5, #1       // Increment pointer
	b pcLoop

pcEnd:
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



// Check if a deck/hand contains a specific rank.
// PARAMETERS r0: char representing rank, r1: pointer to the deck
// RETURNS    r0: index of first card with matching rank, or -1 if not found
checkDeck:
// Prologue
	sub sp, sp, #24      // Allocate space for registers (sp rounded up to nearest 8)
	str r4, [sp, #0]     // Load registers into stack
	str r5, [sp, #4]
	str r6, [sp, #8]
	str fp, [sp, #12]
	str lr, [sp, #16]
	add fp,  sp, #24     // Set fp

	mov r4, #0           // r4 is counter
	mov r5, r1           // r5 points to the deck in question
	mov r6, SPACE        // r6 will hold char representing the card

cdLoop:
	ldrb r6, [r5]        // Load card's char into r6
	cmp r6, r0           // Check if equal to rank
	beq cdEnd            // If so, return counter

	cmp r6, SPACE        // Check if end of deck
	moveq r4, #-1        // If so, return -1
	beq cdEnd

	add r4, r4, #1       // Increment counter
	add r5, r5, #1       // Increment pointer
	b cdLoop

cdEnd:
	mov r0, r4           // Return counter

// Epilogue
	ldr r4, [sp, #0]     // Restore registers from stack
	ldr r5, [sp, #4]
	ldr r6, [sp, #8]
	ldr fp, [sp, #12]
	ldr lr, [sp, #16]
	add sp, sp, #24      // Move sp back in place
	bx lr



// Check if the game is over - if either hand or the deck is empty.
// PARAMETERS None
// RETURNS    r0: 0 if game not over, 1 if game over
checkGG:
// Prologue
	sub sp, sp, #16       // Allocate space for registers (sp rounded up to nearest 8)
	str r4, [sp, #0]     // Load registers into stack
	str fp, [sp, #4]
	str lr, [sp, #8]
	add fp,  sp, #16     // Set fp
	
	ldrb r4, =p1Hand
	cmp r4, SPACE
	beq cgOver

	ldrb r4, =p2Hand
	cmp r4, SPACE
	beq cgOver

	ldrb r4, =mainDeck
	cmp r4, SPACE
	beq cgOver

// No decks are empty, return 0
	mov r0, #0
	b cgEnd

cgOver:
	mov r0, #1

cgEnd:
// Epilogue
	ldr r4, [sp, #0]     // Restore registers from stack
	ldr fp, [sp, #4]
	ldr lr, [sp, #8]
	add sp, sp, #16      // Move sp back in place
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