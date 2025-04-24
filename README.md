# Chess

Chess-related stuff in Raku

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

### PGN Grammar

```raku
use Chess::PGN;
say Chess::PGN.parse: "1. f3 e5 2. g4?? Qh4#";
```

### FEN Grammar

```raku
use Chess::FEN;
say Chess::FEN.parse('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1');
```

See [the wikipedia article about FEN](http://en.wikipedia.org/wiki/Forsyth%E2%80%93Edwards_Notation) for more information.

## General utilities

### Graphical display

#### With unicode and escape codes

An alternative to ascii is unicode with escape codes.  It looks better on a dark background.

![unicode and escape codes display](https://i.imgur.com/a/axFRvcu.png)

### Graphical display in the terminal with Kitty's graphics protocol

![showing the start position in kitty](https://i.imgur.com/aNAXmJS.png)

[ImageMagick](https://imagemagick.org/script/command-line-tools.php) is also required to produce the PNG files as the images of the pieces are stored in SVG.

Zooming in or out in Kitty will not scale the image of the chessboard up or down.  You can however set the dynamic variable `$*square-size` to
pick a different board size.  This only works if you set this variable before the first execution of `show` though, as the image data is transmitted to kitty only once.


![showing the start position in kitty, with a custom square size](https://i.imgur.com/KaqfJKu.png)


### Polyglot books

WIP

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
