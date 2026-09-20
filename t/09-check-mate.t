use Test;
use lib 'lib';
use Chess;

plan 13;

# Fool's mate.
my $fools = Chess::Position.new;
$fools.play($_) for <f3 e5 g4 Qh4>;
ok $fools.is-checkmate, "fool's mate is checkmate";
ok $fools.in-check, "mated side is in check";
is $fools.legal-moves.elems, 0, 'no legal moves in mate';
is $fools.result, '0-1', "fool's mate result is 0-1";

# SAN of the mating move is generated from the position before it is played.
$fools = Chess::Position.new;
$fools.play($_) for <f3 e5 g4>;
is $fools.san($fools.parse-move('Qh4')), 'Qh4#', "fool's mate SAN uses #";

# Scholar's mate.
my $scholar = Chess::Position.new;
$scholar.play($_) for <e4 e5 Qh5 Nc6 Bc4 Nf6 Qxf7>;
ok $scholar.is-checkmate, "scholar's mate";
is $scholar.result, '1-0', 'white delivered mate so 1-0';

# Stalemate: black king a8, white queen b6, white king a1.
my $stale = Chess::Position.new('k7/8/1Q6/8/8/8/8/K7 b - - 0 1');
ok $stale.is-stalemate, 'stalemate detected';
nok $stale.in-check, 'stalemated side is not in check';
is $stale.result, '1/2-1/2', 'stalemate is a draw';
ok $stale.is-game-over, 'stalemate ends the game';

# Pinned knight cannot leave the king file.
my $pin = Chess::Position.new('4r2k/8/8/8/8/8/4N3/4K3 w - - 0 1');
nok $pin.legal-moves.first({ .from == E2 }), 'pinned knight has no legal moves';
ok $pin.legal-moves.first({ .from == E1 }), 'king can still step out';
