FLAGS= -pthread -llua5.1
LFLAGS= -o luasandbox
WFLAGS= -o luasandbox.exe

LINUX= gcc code.c $(FLAGS) $(LFLAGS)
WIN= gcc code.c $(FLAGS) $(WFLAGS)
linux: 
	$(LINUX)
win: 
	$(WIN)
travis:
	gcc code.c $(FLAGS) -o luasandbox
.PHONY: clean

clean:
	rm -f code.o
