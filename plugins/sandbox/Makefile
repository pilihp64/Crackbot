CC :=gcc
SOURCE := code.c

FLAGS := -pthread -llua5.1
LFLAGS := -o luasandbox
WFLAGS := -o luasandbox.exe

LINUX := $(CC) $(SOURCE) $(FLAGS) $(LFLAGS)
WIN := $(CC) $(SOURCE) $(FLAGS) $(WFLAGS)

.PHONY: clean

clean:
	rm -f obj/*.o
