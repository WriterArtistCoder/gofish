CFLAGS = -Wno-implicit-function-declaration

all: final

final: gofish.o
	@echo "\n\033[0;94;1mLinking and producing final application\033[22;2m"
	gcc $(CFLAGS) gofish.o -g -o final
	@echo "\033[0m---"

gofish.o: gofish.s
	@echo "\n\033[0;92;1mCompiling gofish.s\033[22;2m"
	as --gstabs -o gofish.o gofish.s
	@echo "\033[0m---"

clean:
	@echo "\n\033[0;31;1mRemoving everything but source files\033[22;2m"
	rm -f gofish.o final
	@echo "\033[0m---"
