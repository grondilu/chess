# Chess

Chess-related stuff in Raku

## SYNOPSIS

```
$ raku -MChess
> use Chess;

> say startpos;                       
rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1
> show startpos;  # see further for kitty terminal
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
> show q{r1bqkbnr/pppp1ppp/2n5/1B2p3/4P3/5N2/PPPP1PPP/RNBQK2R b KQkq - 3 3}
   +------------------------+
 8 | r  .  b  q  k  b  n  r |
 7 | p  p  p  p  .  p  p  p |
 6 | .  .  n  .  .  .  .  . |
 5 | .  B  .  .  p  .  .  . |
 4 | .  .  .  .  P  .  .  . |
 3 | .  .  .  .  .  N  .  . |
 2 | P  P  P  P  .  P  P  P |
 1 | R  N  B  Q  K  .  .  R |
   +------------------------+
     a  b  c  d  e  f  g  h
> say Chess::Position.new: <f4 e5 g4>;   # building a position from a list of moves
rnbqkbnr/pppp1ppp/8/4p3/5PP1/8/PPPPP2P/RNBQKBNR b KQkq - 0 2
> say legal-moves startpos;
[d3 d4 e3 e4 c3 c4 f3 f4 Nf3 Nh3 h3 h4 a3 a4 g3 g4 Na3 Nc3 b3 b4]
 ```


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

On most terminals, the code above would produce an ascii diagram, as seen in the synopsis.

On kitty(see below), it will show a nice diagram inside the terminal:

![Hopefully the code above should produce a nice representation of the starting position](https://i.imgur.com/6CIyr3G.png)

This requires :

  - ~~an internet connection (to access the lichess API);~~
  - [Kitty](https://sw.kovidgoyal.net/kitty/), or any terminal supporting its [graphics protocol](https://sw.kovidgoyal.net/kitty/graphics-protocol/)
  - ~~`wget`~~
  - [ImageMagick](https://imagemagick.org/script/command-line-tools.php)
  - GNU's *coreutils* (for `basenc`)

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
