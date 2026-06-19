CC ?= cc
CFLAGS ?= -std=c99 -Wall -Wextra -pedantic
BISON ?= bison
FLEX ?= flex

.PHONY: all test clean

all: cauto

src/parser.c: src/parser.y
	$(BISON) -d -o $@ $<

src/parser.h: src/parser.c
	@true

src/lexer.c: src/lexer.l src/parser.h
	$(FLEX) -o $@ $<

cauto: src/parser.c src/lexer.c
	$(CC) $(CFLAGS) -o $@ src/parser.c src/lexer.c

test: cauto
	sh tests/run.sh

clean:
	rm -f cauto src/parser.c src/parser.h src/lexer.c tests/*.out tests/*.out.c tests/*.out.o tests/*.err
