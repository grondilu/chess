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
show Chess::startpos;
```

![Hopefully the code above should produce a nice colored representation of the starting position](https://i.imgur.com/oY9xqNe.png)

This requires :

  - an internet connection (to access the lichess API);
  - [Kitty](https://sw.kovidgoyal.net/kitty/), or any terminal supporting its [graphics protocol](https://sw.kovidgoyal.net/kitty/graphics-protocol/)
  - `wget`
  - [ImageMagick](https://imagemagick.org/script/command-line-tools.php)
  - GNU's *coreutils* (for `basenc`)

