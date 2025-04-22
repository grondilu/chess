unit module Chess::Pieces;
use Chess::Colors;

subset Symbol of Str where /^ :i <[Øprnbqk]> $/;
subset UnicodeSymbol of Str where "\x2654" .. "\x265F";
role Piece is export {
    method symbol returns Symbol { 'Ø' }
    method unicode-symbol { ' ' }
}
role Piece[Symbol $symbol, UnicodeSymbol $black, UnicodeSymbol $white, UInt $mask] is export {
  has color $.color is required;
  method WHICH { self.symbol }
  multi method new(color $color) { self.bless: :$color }
  method attacks($index) { 
    (BEGIN blob8.new(
      20, 0, 0, 0, 0, 0, 0, 24, 0, 0, 0, 0, 0, 0, 20, 0, 0, 20, 0, 0,
      0, 0, 0, 24, 0, 0, 0, 0, 0, 20, 0, 0, 0, 0, 20, 0, 0, 0, 0, 24, 0, 0,
      0, 0, 20, 0, 0, 0, 0, 0, 0, 20, 0, 0, 0, 24, 0, 0, 0, 20, 0, 0, 0, 0,
      0, 0, 0, 0, 20, 0, 0, 24, 0, 0, 20, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 20,
      2, 24, 2, 20, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 53, 56, 53, 2, 0, 0,
      0, 0, 0, 0, 24, 24, 24, 24, 24, 24, 56, 0, 56, 24, 24, 24, 24, 24, 24,
      0, 0, 0, 0, 0, 0, 2, 53, 56, 53, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      20, 2, 24, 2, 20, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 20, 0, 0, 24, 0, 0, 20,
      0, 0, 0, 0, 0, 0, 0, 0, 20, 0, 0, 0, 24, 0, 0, 0, 20, 0, 0, 0, 0, 0, 0,
      20, 0, 0, 0, 0, 24, 0, 0, 0, 0, 20, 0, 0, 0, 0, 20, 0, 0, 0, 0, 0, 24,
      0, 0, 0, 0, 0, 20, 0, 0, 20, 0, 0, 0, 0, 0, 0, 24, 0, 0, 0, 0, 0, 0, 20
    ))[$index] +& $mask
  }
  method offsets {...}
  multi method symbol(Piece:D:) { ($!color ~~ white ?? *.uc !! *.lc)($symbol) }
  multi method symbol(Piece:U:) { 'x' }
  multi method unicode-symbol(Piece:D:) { $!color ~~ white ?? $white !! $black }
}

class Pawn does Piece['p', '♟', '♙', 1] is export {
    method offsets { (constant @ = 16, 32, 17, 15).map: * * ($.color == white ?? -1 !! +1) }
}
class Knight does Piece['n', '♞', '♘',  2] is export { method offsets { constant @ = -18, -33, -31, -14, 18, 33, 31, 14 } }
class Bishop does Piece['b', '♝', '♗',  4] is export { method offsets { constant @ = -17, -15, 17, 15 }  }
class Rook   does Piece['r', '♜', '♖',  8] is export { method offsets { constant @ = -16, 1, 16, -1 } }
class Queen  does Piece['q', '♛', '♕', 16] is export { method offsets { constant @ = -17, -16, -15, 1, 17, 16, 15, -1 } }
class King   does Piece['k', '♚', '♔', 32] is export { method offsets { constant @ = -17, -16, -15, 1, 17, 16, 15, -1 } }

# vi: shiftwidth=4 nu
