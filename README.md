# Chess

Chess-related stuff in Raku

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
show startpos;
```

On most terminals, the code above would produce an ascii diagram :

```
   +------------------------+
 8 | r  n  b  q  k  b  n  r |
 7 | p  p  p  p  p  p  p  p |
 6 | .  .  .  .  .  .  .  . |
 5 | .  .  .  .  .  .  .  . |
 4 | .  .  .  .  .  .  .  . |
 3 | .  .  .  .  .  .  .  . |
 2 | P  P  P  P  P  P  P  P |
 1 | R  N  B  Q  K  B  N  R |
   +------------------------+
     a  b  c  d  e  f  g  h
 ```

On kitty, it will show a nice picture inside the terminal:

![Hopefully the code above should produce a nice representation of the starting position](https://i.imgur.com/6CIyr3G.png)

This requires :

  - ~~an internet connection (to access the lichess API);~~
  - [Kitty](https://sw.kovidgoyal.net/kitty/), or any terminal supporting its [graphics protocol](https://sw.kovidgoyal.net/kitty/graphics-protocol/)
  - ~~`wget`~~
  - [ImageMagick](https://imagemagick.org/script/command-line-tools.php)
  - GNU's *coreutils* (for `basenc`)

## TODO

 - [ ] implement rules of the game
 - [ ] interface Stockfish
 - [x] make Board image internally, not relying on lichess
 - [ ] opening and tactics trainer
 - [ ] game database management
 - [ ] translate [Chess.js](https://github.com/jhlywa/chess.js/tree/master)
 - [ ] read and write [Polyglot books](https://www.chessprogramming.org/PolyGlot)
