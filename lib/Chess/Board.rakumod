unit class Chess::Board;
use Chess::Colors;
use Chess::Pieces;

# https://en.wikipedia.org/wiki/0x88
enum square is export ((([1..8] .reverse) X[R~] 'a'..'h') Z=> ((0, 16 ... *) Z[X+] ^8 xx 8).flat);

multi prefix:<¬>(color $color --> color) is export { $color ~~ white ?? black !! white }

sub rank(square $sq) is export { $sq +>  4 }
sub file(square $sq) is export { $sq +& 15 }

subset en-passant-square of square is export where /<[36]>$/;

our constant %SECOND-RANK   is export = (white) => rank(a2), (black) => rank(a7);
our constant PROMOTION-RANK is export = rank(a1)|rank(a8);

has Piece @!board[128];
submethod BUILD(:@!board) {}

method pairs { @!board.pairs.grep: *.value }
method all-pairs { square::{*}.sort(+*).map({ $_ => @!board[$_]}) }

method AT-KEY(square $square) { @!board[$square] }
method ASSIGN-KEY(square $square, Piece $piece) { @!board[$square] = $piece }
method EXISTS-KEY(square $square) { @!board[$square].defined }
method DELETE-KEY(square $square) { LEAVE @!board[$square] = Nil; @!board[$square] }

# vi: shiftwidth=4 nu nowrap
