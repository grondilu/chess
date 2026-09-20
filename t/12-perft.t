use Test;
use lib 'lib';
use Chess;

# Perft counts from https://www.chessprogramming.org/Perft_Results
# Depths are kept modest so the suite stays practical in pure Raku.

plan 17;

sub perft-is($name, $fen, $depth, $want) {
    my $got = Chess::Position.new($fen).perft($depth);
    is $got, $want, "$name perft($depth)";
}

perft-is 'start', START-FEN, 1, 20;
perft-is 'start', START-FEN, 2, 400;
perft-is 'start', START-FEN, 3, 8902;

my $kiwipete = 'r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1';
perft-is 'kiwipete', $kiwipete, 1, 48;
perft-is 'kiwipete', $kiwipete, 2, 2039;

my $pos3 = '8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1';
perft-is 'position 3', $pos3, 1, 14;
perft-is 'position 3', $pos3, 2, 191;
perft-is 'position 3', $pos3, 3, 2812;

my $pos4 = 'r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1';
perft-is 'position 4', $pos4, 1, 6;
perft-is 'position 4', $pos4, 2, 264;
perft-is 'position 4', $pos4, 3, 9467;

my $pos5 = 'rnbq1k1r/pp1Pbppp/2p5/8/2B5/8/PPP1NnPP/RNBQK2R w KQ - 1 8';
perft-is 'position 5', $pos5, 1, 44;
perft-is 'position 5', $pos5, 2, 1486;

my $pos6 = 'r4rk1/1pp1qppp/p1np1n2/2b1p1B1/2B1P1b1/P1NP1N2/1PP1QPPP/R4RK1 w - - 0 10';
perft-is 'position 6', $pos6, 1, 46;
perft-is 'position 6', $pos6, 2, 2079;

# Divide of the start position at depth 2: every first move has 20 replies.
my %div = Chess::Position.new.perft-divide(2);
is %div.values.sum, 400, 'start perft-divide(2) sums to 400';
is %div.elems, 20, 'start perft-divide(2) has 20 root moves';
