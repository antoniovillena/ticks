all: ticks

clean:
	rm -f ticks ticks.exe *.o

ticks.o : ticks.c
	gcc -c -o $@ $<

ifeq ($(shell uname -m),armv6l)
execute.o : execute.s
	as -o $@ $<
else
execute.o : execute.c
	gcc -c -o $@ $<
endif

ticks : ticks.o execute.o
	gcc -o ticks $^
