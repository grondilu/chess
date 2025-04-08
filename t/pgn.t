#!/usr/bin/env raku
# https://www.saremba.de/chessgml/standards/pgn/pgn-complete.htm

use lib <lib>;
use Chess::PGN;

use Test;

subtest "masters' games", {
  for <Morphy Capablanca Fischer Petrosian Karpov Kasparov> {
    ok Chess::PGN.parse(qq{resources/masters/$_.pgn}.IO.slurp), $_;
  }
}

subtest "2013 World Championship", {
  ok Chess::PGN.parse(qq{resources/WorldChamp2013.pgn}.IO.slurp),           "non-annotated version";
  ok Chess::PGN.parse(qq{resources/WorldChamp2013-annotated.pgn}.IO.slurp),     "annotated version";
}

done-testing;


# vim: ft=raku nu shiftwidth=2
