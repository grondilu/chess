use Test;
use lib 'lib';
use Chess;

plan 16;

my $p = Chess::Position.new;
my $e4 = $p.parse-move('e4');
is $e4.uci, 'e2e4', 'parse SAN e4';
is $p.san($e4), 'e4', 'emit SAN e4';
is $p.parse-move('e2e4').uci, 'e2e4', 'parse UCI e2e4';

$p.play($_) for <e4 e5 Nf3 Nc6 Bb5>;
is $p.parse-move('a6').uci, 'a7a6', 'Ruy Lopez a6';
$p.play('a6');
is $p.san($p.parse-move('Nxe5')), 'Nxe5', 'knight capture SAN';

# Disambiguate two knights that both go to d2.
my $n = Chess::Position.new('7k/8/8/8/8/8/8/1N2KN2 w - - 0 1');
is $n.san($n.parse-move('Nbd2')), 'Nbd2', 'file disambiguation Nbd2';
is $n.san($n.parse-move('Nfd2')), 'Nfd2', 'file disambiguation Nfd2';
dies-ok { $n.parse-move('Nd2') }, 'ambiguous Nd2 throws';

# Disambiguate two rooks on the same file by rank.
my $r = Chess::Position.new('k7/8/8/8/8/R7/8/R3K3 w - - 0 1');
is $r.san($r.parse-move('R1a2')), 'R1a2+', 'rank disambiguation R1a2';
is $r.san($r.parse-move('R3a2')), 'R3a2+', 'rank disambiguation R3a2';

# Two rooks on the same rank.
my $rr = Chess::Position.new('k7/8/8/8/R6R/8/8/4K3 w - - 0 1');
is $rr.san($rr.parse-move('Rae4')), 'Rae4', 'Rae4';
is $rr.san($rr.parse-move('Rhe4')), 'Rhe4+', 'Rhe4+ (a-rook still checks)';

# Castling tokens.
my $c = Chess::Position.new('r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1');
is $c.parse-move('O-O').uci, 'e1g1', 'O-O';
is $c.parse-move('0-0-0').uci, 'e1c1', '0-0-0 accepted';

dies-ok { Chess::Position.new.play('e5') }, 'illegal SAN throws';
dies-ok { Chess::Position.new.parse-move('zzzz') }, 'garbage move throws';
