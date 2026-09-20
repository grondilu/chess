use Test;
use lib 'lib';
use Chess;

plan 10;

my $p = Chess::Position.new;
$p.play($_) for <e4 a6 e5 d5>;
is $p.en-passant-square, D6, 'double push sets EP square d6';
ok $p.is-legal(Chess::Move.from-uci('e5d6')), 'exd6 en passant is legal';
is $p.san($p.parse-move('exd6')), 'exd6', 'EP SAN is a pawn capture';

$p.play('exd6');
ok $p.piece-at(D5) === Nil, 'captured pawn is removed from d5';
is $p.piece-at(D6).symbol, 'P', 'capturing pawn lands on d6';
ok $p.en-passant-square === Nil, 'EP square cleared after the capture';

# EP that would leave the king in check is illegal (rank pin).
# White Ka5, pawn e5; black pawn d5, rook h5; EP d6.
my $pin = Chess::Position.new('8/8/8/K2pP2r/8/8/8/7k w - d6 0 1');
nok $pin.legal-moves.first(*.uci eq 'e5d6'), 'pinned EP capture is illegal';
ok $pin.legal-moves.first(*.uci eq 'e5e6'), 'the same pawn may still push';

# EP from FEN.
my $from-fen = Chess::Position.new('rnbqkbnr/pppp1ppp/8/4P3/8/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1');
$from-fen.play('d5');
ok $from-fen.is-legal($from-fen.parse-move('exd6')), 'EP available after d7-d5 vs pawn on e5';

# Skipping EP loses the right.
my $skip = Chess::Position.new;
$skip.play($_) for <e4 a6 e5 d5 Nf3>;
ok $skip.en-passant-square === Nil, 'EP expires if not used immediately';
