use lib <.>;
use Chess::PGN;

use Test;

subtest {
  ok Chess::PGN.parse('1. e4'), "simple first move";
  ok Chess::PGN.parse('1. e4 d5 2. exd5'), "scandinavian";
  ok Chess::PGN.parse('1. e4 d5 2. e5 f5 3. exf5ep'), "en passant";
  ok Chess::PGN.parse('1. e4 e5 2. f4 Qh4+'), "simple check";
  ok Chess::PGN.parse('1. e4 g5 2. d4 f5 3. Qh5#'), "dumb mate";
  ok Chess::PGN.parse('1. e4 g5?! 2. d4 f5?? 3. Qh5#'), "dumb mate with comments";
  ok Chess::PGN.parse('1. e4 g5?! 2. d4 f5?? 3. Qh5# 1-0'), "dumb mate with adjudication";
  ok Chess::PGN.parse('1.a4 a6 2.h4 b6 3.Ra3 c6 4.Rh3 d6 5.Rad3'), "disambiguation";
}, 'valid PGN';

subtest {
  for <Morphy Capablanca Fischer Karpov Kasparov> {
    ok Chess::PGN.parse("resources/$_.pgn".IO.slurp), "$_\'s games";
  }
}, "various players' games from PGNMentor";

done-testing;

# vim: ft=raku nu shiftwidth=2
