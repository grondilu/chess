use Test;
use lib 'lib';
use Chess;

plan 12;

my $kk = Chess::Position.new('k7/8/8/8/8/8/8/K7 w - - 0 1');
ok $kk.is-insufficient-material, 'king vs king';
is $kk.result, '1/2-1/2', 'K vs K is drawn';

ok Chess::Position.new('k7/8/8/8/8/8/8/K2B4 w - - 0 1')
    .is-insufficient-material, 'king and bishop vs king';
ok Chess::Position.new('k7/8/8/8/8/8/8/K2N4 w - - 0 1')
    .is-insufficient-material, 'king and knight vs king';
ok Chess::Position.new('k1b5/8/8/8/8/8/8/KB6 w - - 0 1')
    .is-insufficient-material, 'same-color bishops';
nok Chess::Position.new('kb6/8/8/8/8/8/8/KB6 w - - 0 1')
    .is-insufficient-material, 'opposite-color bishops can still mate';
nok Chess::Position.new('k7/8/8/8/8/8/8/KBN5 w - - 0 1')
    .is-insufficient-material, 'bishop and knight vs king is not insufficient';
nok Chess::Position.new('k7/8/8/8/8/8/4P3/K7 w - - 0 1')
    .is-insufficient-material, 'a pawn is always sufficient';

# Fifty-move rule: the draw is claimable at 100 half-moves.
my $fifty = Chess::Position.new('7k/8/8/8/8/8/8/K7 w - - 99 50');
nok $fifty.is-fifty-move, '99 half-moves is not yet fifty';
$fifty.play('Kb1');
ok $fifty.is-fifty-move, '100 half-moves is fifty-move';

# Threefold: knights out and back twice.
my $rep = Chess::Position.new;
$rep.play($_) for <Nf3 Nf6 Ng1 Ng8 Nf3 Nf6 Ng1 Ng8>;
ok $rep.is-threefold, 'threefold repetition of the start position';
ok $rep.is-draw, 'threefold counts as a draw';
