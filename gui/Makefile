CC       ?= cc
PKG      := gtk4
CFLAGS   ?= -O2 -Wall -Wextra

PIECES   := wP wN wB wR wQ wK bP bN bB bR bQ bK
SVG_DIR  := pieces/svg
PNG_DIR  := pieces/png
SVG_URL  := https://raw.githubusercontent.com/lichess-org/lila/master/public/piece/cburnett
PNGS     := $(addprefix $(PNG_DIR)/,$(addsuffix .png,$(PIECES)))
SVGS     := $(addprefix $(SVG_DIR)/,$(addsuffix .svg,$(PIECES)))

.PHONY: all clean pieces raku

all: chess-gui

# Do not run pkg-config here: it is only needed to compile the C binary,
# and the host session often has GTK runtime libs without gtk4.pc.
raku: $(PNGS)
	raku chess-gui.raku

chess-gui: chess-gui.c $(PNGS)
	@pkg-config --exists $(PKG) || { \
	  echo 'pkg-config: $(PKG) not found (gtk4-devel). Build the C GUI in the toolbox, or run: make raku'; \
	  exit 1; \
	}
	$(CC) $(CFLAGS) $$(pkg-config --cflags $(PKG)) \
	  -DPIECE_DIR=\"$(abspath $(PNG_DIR))\" -o $@ chess-gui.c \
	  $$(pkg-config --libs $(PKG))

pieces: $(PNGS)

$(PNG_DIR)/%.png: $(SVG_DIR)/%.svg | $(PNG_DIR)
	rsvg-convert -w 256 -h 256 -o $@ $<

$(SVG_DIR)/%.svg: | $(SVG_DIR)
	curl -fsSL $(SVG_URL)/$*.svg -o $@

$(PNG_DIR) $(SVG_DIR):
	mkdir -p $@

clean:
	rm -f chess-gui $(PNGS)
