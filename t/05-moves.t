use Test;
use lib 'lib';
use Chess;

plan 14;

my $p = Chess::Position.new;
is $p.legal-moves.elems, 20, 'start position has 20 legal moves';

my @uci = $p.legal-moves.map(*.uci).sort;
is @uci.List, <
    a2a3 a2a4 b1a3 b1c3 b2b3 b2b4 c2c3 c2c4
    d2d3 d2d4 e2e3 e2e4 f2f3 f2f4 g1f3 g1h3
    g2g3 g2g4 h2h3 h2h4
>.List, 'start move list in UCI';

ok $p.is-legal(Chess::Move.new(:from(E2), :to(E4))), 'e2e4 is legal';
ok $p.is-legal(Chess::Move.from-uci('g1f3')), 'g1f3 is legal';
nok $p.is-legal(Chess::Move.new(:from(E2), :to(E5))), 'e2e5 is not legal';
nok $p.is-legal(Chess::Move.new(:from(E7), :to(E5))), 'black pawn cannot move on white turn';
nok $p.is-legal(Chess::Move.new(:from(E1), :to(E2))), 'king cannot capture own pawn';

$p.play('e4');
is $p.side-to-move, Black, 'side flips after a move';
is $p.legal-moves.elems, 20, 'black also has 20 replies to e4';

my $fen = $p.fen;
$p.play('e5');
$p.unmake-move;
is $p.fen, $fen, 'unmake restores FEN';

my $clone = $p.clone;
$clone.play('d5');
is $p.fen, $fen, 'clone is independent of the original';
isnt $clone.fen, $fen, 'clone actually moved';

# Double pawn push is blocked if the intermediate square is occupied.
my $blocked = Chess::Position.new('4k3/8/8/8/4n3/8/4P3/4K3 w - - 0 1');
nok $blocked.legal-moves.first(*.uci eq 'e2e4'), 'double push blocked by a piece on e4';
ok $blocked.legal-moves.first(*.uci eq 'e2e3'), 'single push still allowed';
