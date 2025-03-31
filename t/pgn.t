use lib <lib>;
use Chess::PGN;

use Test;

skip 'NYI';
{
  constant pgn = q:to/EOF/;
  [White "Paul Morphy"]
  [Black "Duke Karl / Count Isouard"]
  [fEn "1n2kb1r/p4ppp/4q3/4p1B1/4P3/8/PPP2PPP/2KR4 w k - 0 17"]

  17.Rd8# 1-0
  EOF

  say Chess::PGN.parse: pgn;

}

done-testing;

# vim: ft=raku nu shiftwidth=2
