use Test;
use lib 'lib';
use Chess;

plan 10;

my $p = Chess::Position.new('8/4P3/8/8/8/8/8/4K2k w - - 0 1');
my @promo = $p.legal-moves.grep({ .from == E7 && .to == E8 });
is @promo.elems, 4, 'four promotion choices';
is-deeply @promo.map(*.promotion).sort.List,
    (+Knight, +Bishop, +Rook, +Queen).sort.List,
    'N, B, R, Q promotions';

is $p.san($p.parse-move('e8=Q')), 'e8=Q', 'queen promotion SAN';
is $p.san($p.parse-move('e8=N')), 'e8=N', 'underpromotion SAN';

$p.play('e8=Q');
is $p.piece-at(E8).type, Queen, 'promoted to queen';
is $p.piece-at(E8).color, White, 'promoted piece is white';

my $cap = Chess::Position.new('3r3k/4P3/8/8/8/8/8/4K3 w - - 0 1');
ok $cap.legal-moves.first(*.uci eq 'e7d8q'), 'promotion capture to d8=Q';
is $cap.san($cap.parse-move('exd8=Q')), 'exd8=Q+', 'promotion capture SAN with check';

nok Chess::Position.new('8/4P3/8/8/8/8/8/4K2k w - - 0 1')
        .is-legal(Chess::Move.new(:from(E7), :to(E8))),
    'promotion without a piece is illegal';

my $uci = Chess::Position.new('8/4P3/8/8/8/8/8/4K2k w - - 0 1');
$uci.play('e7e8q');
is $uci.piece-at('e8').symbol, 'Q', 'UCI promotion e7e8q';
