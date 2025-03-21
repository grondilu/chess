#!/usr/bin/env raku
use lib <lib>;
use Chess;
use Test;

# http://hgm.nubati.net/book_format.html

constant data = q:to/EOF/;
starting position
FEN=rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1
key=463b96181691fc9c

position after e2e4
FEN=rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1
key=823c9b50fd114196

position after e2e4 d75
FEN=rnbqkbnr/ppp1pppp/8/3p4/4P3/8/PPPP1PPP/RNBQKBNR w KQkq d6 0 2
key=0756b94461c50fb0

position after e2e4 d7d5 e4e5
FEN=rnbqkbnr/ppp1pppp/8/3pP3/8/8/PPPP1PPP/RNBQKBNR b KQkq - 0 2
key=662fafb965db29d4

position after e2e4 d7d5 e4e5 f7f5
FEN=rnbqkbnr/ppp1p1pp/8/3pPp2/8/8/PPPP1PPP/RNBQKBNR w KQkq f6 0 3
key=22a48b5a8e47ff78

position after e2e4 d7d5 e4e5 f7f5 e1e2
FEN=rnbqkbnr/ppp1p1pp/8/3pPp2/8/8/PPPPKPPP/RNBQ1BNR b kq - 0 3
key=652a607ca3f242c1

position after e2e4 d7d5 e4e5 f7f5 e1e2 e8f7
FEN=rnbq1bnr/ppp1pkpp/8/3pPp2/8/8/PPPPKPPP/RNBQ1BNR w - - 0 4
key=00fdd303c946bdd9

position after a2a4 b7b5 h2h4 b5b4 c2c4
FEN=rnbqkbnr/p1pppppp/8/8/PpP4P/8/1P1PPPP1/RNBQKBNR b KQkq c3 0 3
key=3c8123ea7b067637

position after a2a4 b7b5 h2h4 b5b4 c2c4 b4c3 a1a3
FEN=rnbqkbnr/p1pppppp/8/8/P6P/R1p5/1P1PPPP1/1NBQKBNR b Kkq - 0 4
key=5c3f9b829b279560
EOF

my $fen;
for data.lines {
	if /^'FEN='/ {
		$fen = $/.postmatch;
	} elsif /^'key='/ {
		my Chess::Position $pos .=new: :$fen;
		is $pos.zobrist-hash, $/.postmatch.parse-base(16);
	}
}

done-testing;

# vi: ft=raku
