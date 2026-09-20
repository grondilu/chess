use Test;
use lib 'lib';
use Chess;

plan 18;

ok A1 == 0, 'a1 = 0';
ok H1 == 7, 'h1 = 7';
ok A8 == 56, 'a8 = 56';
ok H8 == 63, 'h8 = 63';
ok E4 == 28, 'e4 = 28';

is sq('a1'), A1, 'sq a1';
is sq('h8'), H8, 'sq h8';
is sq('E4'), E4, 'sq is case-insensitive';
is sq-name(E2), 'e2', 'sq-name e2';
is sq-name(0), 'a1', 'sq-name a1';

is file-of(H1), 7, 'file of h1';
is rank-of(A8), 7, 'rank of a8';
is square(4, 3), E4, 'square(file, rank)';

is-deeply knight-dest(B1).sort.List, (A3, C3, D2).sort.List, 'knight from b1';
is-deeply king-dest(A1).sort.List, (A2, B1, B2).sort.List, 'king from a1';

dies-ok { sq('i9') }, 'invalid square i9';
dies-ok { sq('e') }, 'incomplete square';
dies-ok { sq-name(64) }, 'square 64 is off the board';
