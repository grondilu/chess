use lib <lib>;
use Chess::PGN;

use Test;

subtest "masters' games", {
  for <Morphy Capablanca Fischer Karpov Kasparov> {
    ok Chess::PGN.parse(qq{resources/$_.pgn}.IO.slurp), $_;
  }
}

done-testing;

# vim: ft=raku nu shiftwidth=2
