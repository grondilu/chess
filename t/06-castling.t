use Test;
use lib 'lib';
use Chess;

plan 14;

my $both = Chess::Position.new('r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1');
my @sans = $both.legal-moves.map({ $both.san($_) });
ok @sans.grep('O-O'), 'white kingside castle is legal';
ok @sans.grep('O-O-O'), 'white queenside castle is legal';

$both.play('O-O');
is $both.piece-at(G1).type, King, 'king landed on g1';
is $both.piece-at(F1).type, Rook, 'rook landed on f1';
ok $both.piece-at(E1) === Nil, 'e1 vacated';
ok $both.piece-at(H1) === Nil, 'h1 vacated';
is $both.fen, 'r3k2r/8/8/8/8/8/8/R4RK1 b kq - 1 1', 'castling rights and placement after O-O';

my $q = Chess::Position.new('r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1');
$q.play('O-O-O');
is $q.piece-at(C1).type, King, 'queen-side king on c1';
is $q.piece-at(D1).type, Rook, 'queen-side rook on d1';

# Path must be empty.
my $blocked = Chess::Position.new('r3k2r/8/8/8/8/8/8/RN2K2R w KQkq - 0 1');
nok $blocked.legal-moves.first({ $_.uci eq 'e1c1' }), 'cannot castle queenside through a knight';

# Cannot castle out of check.
my $in-check = Chess::Position.new('4k3/8/8/8/8/8/4r3/R3K2R w KQ - 0 1');
nok $in-check.legal-moves.first({ $_.from == E1 && abs(file-of($_.to) - 4) == 2 }),
    'cannot castle out of check';

# Cannot castle through check (rook attacks f1).
my $through = Chess::Position.new('4k3/8/8/8/8/8/5r2/R3K2R w KQ - 0 1');
nok $through.legal-moves.first(*.uci eq 'e1g1'), 'cannot castle through check on f1';
ok $through.legal-moves.first(*.uci eq 'e1c1'), 'queenside still legal when only f1 is attacked';

# Capturing a rook strips that side's right.
my $cap = Chess::Position.new('r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1');
$cap.play('Rxh8');
nok $cap.can-castle(BK), 'capturing the h8 rook drops black kingside rights';
