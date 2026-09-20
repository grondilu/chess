CC      ?= cc
CFLAGS  ?= -O2 -fPIC -std=c11
LDFLAGS ?= -shared
LIBDIR  := resources/libraries
LIB     := $(LIBDIR)/libzobrist.so
SRC     := src/zobrist.c

.PHONY: all clean test

all: $(LIB)

$(LIB): $(SRC)
	mkdir -p $(LIBDIR)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $<

clean:
	rm -f $(LIB)

test: all
	prove -e 'raku -Ilib' t
