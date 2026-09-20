use Test;
use lib 'lib';
use Chess;

plan 8;

# A short Ruy Lopez, checking FEN after a well-known sequence.
my $p = Chess::Position.new;
$p.play($_) for <e4 e5 Nf3 Nc6 Bb5 a6 Ba4 Nf6 O-O>;
is $p.fen,
    'r1bqkb1r/1ppp1ppp/p1n2n2/4p3/B3P3/5N2/PPPP1PPP/RNBQ1RK1 b kq - 3 5',
    'Ruy Lopez after 5.O-O';
ok $p.can-castle(BK) && $p.can-castle(BQ), 'black still has both castling rights';
nok $p.can-castle(WK) || $p.can-castle(WQ), 'white has used the king';
is $p.fullmove-number, 5, 'fullmove is 5 with black to play';
is $p.move-stack.elems, 9, 'nine half-moves on the stack';

# Ascii board contains ranks and files.
like $p.ascii, /^^ 8 /, 'ascii shows rank 8';
like $p.ascii, / a \s b \s c \s d \s e \s f \s g \s h /, 'ascii shows files';

# Giving check.
my $g = Chess::Position.new('4k3/8/8/8/8/8/8/4K2R w - - 0 1');
ok $g.gives-check($g.parse-move('Rh8')), 'Rh8 gives check';
