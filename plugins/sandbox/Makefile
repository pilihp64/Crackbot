SOURCE := code.c
FLAGS := -pthread -llua5.1
LFLAGS := -o luasandbox
WFLAGS := -o luasandbox.exe

LINUX := gcc $(SOURCE) $(FLAGS) $(LFLAGS)
WIN := gcc $(SOURCE) $(FLAGS) $(WFLAGS)
linux: 
	$(LINUX)
win: 
	$(WIN)
.PHONY: clean

clean:
	rm -f obj/*.o
