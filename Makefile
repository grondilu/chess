.PHONY: all clean test gui gui-raku

all:

clean:
	$(MAKE) -C gui clean

gui:
	$(MAKE) -C gui

gui-raku:
	$(MAKE) -C gui raku

test:
	prove -e 'raku -Ilib' t
