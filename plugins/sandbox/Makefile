FLAGS= -pthread -llua5.1 -m32
LFLAGS= -o luasandbox
WFLAGS= -o luasandbox.exe

LINUX= gcc code.c $(FLAGS) $(LFLAGS)
WIN= gcc code.c $(FLAGS) $(WFLAGS)
linux: 
	$(LINUX)
win: 
	$(WIN)
.PHONY: clean

clean:
	rm -f obj/*.o
