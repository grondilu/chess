unit module Chess::Board;

enum color is export <white black>;

# https://en.wikipedia.org/wiki/0x88
enum square is export ((([1..8] .reverse) X[R~] 'a'..'h') Z=> ((0, 16 ... *) Z[X+] ^8 xx 8).flat);

multi prefix:<¬>(color $color --> color) is export { $color ~~ white ?? black !! white }

sub rank(square $sq) is export { $sq +>  4 }
sub file(square $sq) is export { $sq +& 15 }

our constant %SECOND-RANK   is export = (white) => rank(a2), (black) => rank(a7);
our constant PROMOTION-RANK is export = rank(a1)|rank(a8);

# vi: shiftwidth=4 nu nowrap
