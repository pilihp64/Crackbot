FLAGS= -pthread -static-libgcc
LFLAGS= -o luasandbox -lluajit-5.1
WFLAGS= -DWIN32 -o luasandbox.exe -llibluajit

linux: 
	gcc code.c $(FLAGS) $(LFLAGS)
win: 
	gcc code.c $(FLAGS) $(WFLAGS)
travis:
	gcc code.c $(FLAGS) -DLUAJIT_INC $(LFLAGS)
.PHONY: clean

clean:
	rm -f code.o
