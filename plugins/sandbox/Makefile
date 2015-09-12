FLAGS= -pthread -lluajit -static-libgcc
LFLAGS= -o luasandbox
WFLAGS= -DWIN32 -o luasandbox.exe

linux: 
	gcc code.c $(FLAGS) $(LFLAGS)
win: 
	gcc code.c $(FLAGS) $(WFLAGS)
travis:
	gcc code.c $(FLAGS) -DLUAJIT_INC  -o luasandbox
.PHONY: clean

clean:
	rm -f code.o
