use Test;
use lib 'lib';
use Chess;

plan 12;

my $wp = Chess::Piece.new(:color(White), :type(Pawn));
is $wp.symbol, 'P', 'white pawn symbol';
is $wp.color, White, 'white pawn color';
is $wp.type, Pawn, 'white pawn type';

my $bn = Chess::Piece.from-symbol('n');
is $bn.symbol, 'n', 'black knight from symbol';
is $bn.color, Black, 'black knight color';
is $bn.type, Knight, 'black knight type';

is Chess::Piece.from-packed(pack-piece(+White, +King)).symbol, 'K', 'from-packed king';
is piece-type(pack-piece(+Black, +Queen)), +Queen, 'piece-type of black queen';
is piece-color(pack-piece(+Black, +Queen)), Black, 'piece-color of black queen';
is opponent-color(+White), +Black, 'opponent of white';

ok $wp.unicode, 'unicode glyph is non-empty';
dies-ok { Chess::Piece.from-symbol('x') }, 'unknown symbol dies';
