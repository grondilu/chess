# Chess

Chess-related stuff in Raku

**DISCLAIMER: recent changes make most of the documentation
below inexact.  Corrections will come.**


## SYNOPSIS

```
$ raku -MChess
> say startpos;                       
rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1
> say startpos * 'e4'; # position after 1.e4
rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1
> (startpos * 'd4').ascii;  # see further for kitty terminal
   +------------------------+
 8 | r  n  b  q  k  b  n  r |
 7 | p  p  p  p  p  p  p  p |
 6 | .  .  .  .  .  .  .  . |
 5 | .  .  .  .  .  .  .  . |
 4 | .  .  .  P  .  .  .  . |
 3 | .  .  .  .  .  .  .  . |
 2 | P  P  P  .  P  P  P  P |
 1 | R  N  B  Q  K  B  N  R |
   +------------------------+
> say legal-moves startpos;
[d3 d4 e3 e4 c3 c4 f3 f4 Nf3 Nh3 h3 h4 a3 a4 g3 g4 Na3 Nc3 b3 b4]
 ```
## Description


### Exported symbols

The library exports a black/white enumeration for colors,
either for squares or for pieces:

```raku
say white;
say black;
```

An enumeration for all the squares of the chessboard is also exported :

```raku
.say for e4, e5, g8
```

There is a term called `startpos` which returns an instance of the `Chess::Position` class representing
the starting position.  See synopsis above.

The multiplication operator is overloaded to apply a move to a position. The position must be on the left
side, and the move on the right side, as show on the synopsis.  For this to work the move must be a string
in SAN notation.  Hopefully this is quite intuitive.

The crux of any chess library or engine is to generate all possible moves from any given position.  This is done
in this library either with an exported subroutine `legal-moves`, as seen in the synopsis, or with the `moves` method
of the `Chess::Position` class.

## PGN Grammar

```raku
use Chess::PGN;
say Chess::PGN.parse: "1. f3 e5 2. g4?? Qh4#";
```

## FEN Grammar

```raku
use Chess::FEN;
say Chess::FEN.parse('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1');
```

See [the wikipedia article about FEN](http://en.wikipedia.org/wiki/Forsyth%E2%80%93Edwards_Notation) for more information.

## General utilities

### Displaying a chess position

```raku
use Chess;
show [*] startpos, <e4 e5 Nf3 Nc6>;
```

On most terminals, the code above would produce an ascii diagram, as seen in the synopsis.

On kitty(see below), it will show a nice diagram inside the terminal (notice
that it flips the board when it's Black's turn) :

![Ruy Lopez position](https://i.imgur.com/KBXgO7U.png)

This requires :

  - ~~an internet connection (to access the lichess API);~~
  - [Kitty](https://sw.kovidgoyal.net/kitty/), or any terminal supporting its [graphics protocol](https://sw.kovidgoyal.net/kitty/graphics-protocol/)
  - ~~`wget`~~
  - ~~[ImageMagick](https://imagemagick.org/script/command-line-tools.php)~~
  - ~~GNU's *coreutils* (for `basenc`)~~

### Polyglot books

The subroutine `Chess::make-book` takes PGN data, either as a string or an `IO::Path` object,
and produces a Blob that can then be spurt into a [polyglot book](https://www.chessprogramming.org/PolyGlot).

The class `Chess::Book` can be used to read such books.

## LINKS

 - [Human.bin](https://digilander.libero.it/taioscacchi/programmi/saros-page.html)

## TODO

 - [x] implement rules of the game
 - [ ] interface Stockfish
 - [x] make Board image internally, not relying on lichess
 - [ ] opening and tactics trainer
 - [ ] game database management
 - [ ] translate [Chess.js](https://github.com/jhlywa/chess.js/tree/master)
 - [ ] read and write [Polyglot books](https://www.chessprogramming.org/PolyGlot)
 - [ ] make the board square as tall as the cursor by default
 - [ ] clean-up and update README
