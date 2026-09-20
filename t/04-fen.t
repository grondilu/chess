use Test;
use lib 'lib';
use Chess;

plan 15;

my $start = Chess::Position.new;
is $start.fen, START-FEN, 'start FEN round-trip';
is $start.side-to-move, White, 'white to move';
is $start.castling-rights, WK +| WQ +| BK +| BQ, 'all castling rights';
ok $start.en-passant-square === Nil, 'no EP square';
is $start.halfmove-clock, 0, 'halfmove 0';
is $start.fullmove-number, 1, 'fullmove 1';
is $start.piece-at('e2').symbol, 'P', 'piece-at e2';
ok $start.piece-at('e4') === Nil, 'empty e4';
is $start.king-square(White), E1, 'white king on e1';
is $start.king-square(Black), E8, 'black king on e8';

$start.play('e4');
is $start.fen,
    'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1',
    'FEN after 1.e4';

my $kiwipete = 'r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1';
is Chess::Position.new($kiwipete).fen, $kiwipete, 'kiwipete FEN round-trip';

dies-ok { Chess::Position.new('8/8/8/8/8/8/8/8 w - - 0 1') }, 'FEN without kings';
dies-ok { Chess::Position.new('4P3/8/8/8/8/8/8/4K2k w - - 0 1') }, 'pawn on rank 8';
dies-ok { Chess::Position.new('not a fen') }, 'garbage FEN';
