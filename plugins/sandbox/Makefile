FLAGS= -pthread -llua5.1
LFLAGS= -o luasandbox
WFLAGS= -o luasandbox.exe

linux: 
	gcc code.c $(FLAGS) $(LFLAGS)
win: 
	gcc code.c $(FLAGS) $(WFLAGS)
travis:
	gcc code.c $(FLAGS) -I/usr/include/lua5.1  -o luasandbox
.PHONY: clean

clean:
	rm -f code.o
