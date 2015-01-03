FLAGS= -pthread -llua5.1
LFLAGS= -o luasandbox -m32
WFLAGS= -o luasandbox.exe -m32

LINUX= gcc code.c $(FLAGS) $(LFLAGS)
WIN= gcc code.c $(FLAGS) $(WFLAGS)
linux: 
	$(LINUX)
win: 
	$(WIN)
travis:
	gcc code.c $(FLAGS) -o luasandbox -m64
.PHONY: clean

clean:
	rm -f obj/*.o
