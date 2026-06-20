CC ?= cc
CFLAGS ?= -std=c99 -Wall -Wextra -pedantic
BISON ?= bison
FLEX ?= flex
PREFIX ?= /usr/local

.PHONY: all test install clean

all: c- cpm

src/parser.c: src/parser.y
	$(BISON) -d -o $@ $<

src/parser.h: src/parser.c
	@true

src/lexer.c: src/lexer.l src/parser.h
	$(FLEX) -o $@ $<

c-: src/parser.c src/lexer.c
	$(CC) $(CFLAGS) -o $@ src/parser.c src/lexer.c

cpm: src/cpm.c
	$(CC) $(CFLAGS) -o $@ src/cpm.c

test: c- cpm
	sh tests/run.sh

install: c- cpm
	install -d $(DESTDIR)$(PREFIX)/bin
	install -m 755 c- $(DESTDIR)$(PREFIX)/bin/c-
	install -m 755 cpm $(DESTDIR)$(PREFIX)/bin/cpm

clean:
	rm -f c- cpm src/parser.c src/parser.h src/lexer.c tests/*.out tests/*.out.c tests/*.out.o tests/*.err
