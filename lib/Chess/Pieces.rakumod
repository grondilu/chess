unit module Chess::Pieces;
use Chess::Board;

subset Symbol of Str where /^ :i <[Øprnbqk]> $/;
role Piece is export { method symbol returns Symbol { 'Ø' } }
role Piece[Symbol $symbol, UInt $mask] is export {
  has color $.color;
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
  multi method symbol(Piece:U:) { $symbol }
}

class Pawn does Piece['p',  1] is export {
    method offsets { (constant @ = 16, 32, 17, 15).map: * * ($.color == white ?? -1 !! +1) }
}
class Knight does Piece['n',  2] is export { method offsets { constant @ = -18, -33, -31, -14, 18, 33, 31, 14 } }
class Bishop does Piece['b',  4] is export { method offsets { constant @ = -17, -15, 17, 15 }  }
class Rook   does Piece['r',  8] is export { method offsets { constant @ = -16, 1, 16, -1 } }
class Queen  does Piece['q', 16] is export { method offsets { constant @ = -17, -16, -15, 1, 17, 16, 15, -1 } }
class King   does Piece['k', 32] is export { method offsets { constant @ = -17, -16, -15, 1, 17, 16, 15, -1 } }
