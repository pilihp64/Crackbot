FLAGS= -pthread -llua5.1
LFLAGS= -o luasandbox
WFLAGS= -o luasandbox.exe

LINUX= gcc code.c $(FLAGS) $(LFLAGS)
WIN= gcc code.c $(FLAGS) $(WFLAGS) -m32
linux: 
	$(LINUX)
win: 
	$(WIN)
.PHONY: clean

clean:
	rm -f obj/*.o
