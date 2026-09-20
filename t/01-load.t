use Test;
use lib 'lib';
use Chess;

plan 8;

ok START-FEN, 'START-FEN is exported';
ok White.defined, 'White is exported';
ok Black.defined, 'Black is exported';
ok Pawn.defined && Knight.defined && Bishop.defined
    && Rook.defined && Queen.defined && King.defined, 'piece types exported';

my $pos = Chess::Position.new;
ok $pos, 'default position constructs';
isa-ok $pos, Chess::Position;
is $pos.fen, START-FEN, 'default position is the standard start FEN';

my $from-helper = chess-position();
is $from-helper.fen, START-FEN, 'chess-position() helper';
