@ gofish.s
.syntax unified

// TO DO: print outputs to text logfile
// TO DO: separate functions to separate files
.data
pr

.text
.global main
.type   main, %function
main:
// Prologue
	sub sp, sp, #8       // Move sp for fp, lr
	str fp, [sp, #0]     // Save fp
	str lr, [sp, #4]     // Save lr

	add fp, sp, #4       // Set frame pointer

done:
// Epilogue
	mov r0, #0
	ldr fp, [sp, #0]

	ldr fp, [sp, #0]     // Restore caller fp
	ldr lr, [sp, #4]     // Restore caller lr
	add sp, sp, #8       // Move sp back in place
	bx lr                // Return to caller

/*

You will write a program that simulates the card game “Go Fish”. The main driver, written in
assembler, will call the individual functions to shuffle the deck of cards, deal the cards, ask for a
card, and lay down the cards. For this implementation, we will use the variation where players
give just one card when asked, and lay down pairs. Basically, the players take turns asking the
other player for a card of a certain rank, which the other player must hand over if they have such
a card. The players’ goal is to collect matching pairs of cards (of the same rank), placing them
on the table. Make sure to keep score of how many pairs each player has. Because the number
of cards each player may hold at any moment in time can be anything (less than 47 of course),
you will need to treat the players’ hands carefully. Possible approaches are: 1. Allocate 47
element array for each player and keep track of the cards in hand; 2. Use the stack to store the
players’ hand; or 3. Dynamically resize the players’ hands each time the number of cards
changes. Obviously approach 1 is easiest and approach 3 is hardest.

The program will simulate the playing of the game, with two players (player 1 is the user, player
2 is the computer).

Output: For the output of the main program, you should print each play to a text log file and
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