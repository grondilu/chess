use Test;
use lib <lib>;
use Chess;

plan 1;

constant $output = q:to/EOF/.trim-trailing;
	   +------------------------+
	 8 | r  .  .  .  .  r  k  . |
	 7 | .  .  .  .  n  q  p  p |
	 6 | .  p  .  p  .  .  .  . |
	 5 | .  .  p  P  p  p  .  . |
	 4 | b  P  P  .  P  .  .  . |
	 3 | R  .  B  .  N  Q  .  . |
	 2 | P  .  .  .  .  P  P  P |
	 1 | .  R  .  .  .  .  K  . |
	   +------------------------+
	     a  b  c  d  e  f  g  h
	EOF

my Chess::Position $position .= new: 
      'r4rk1/4nqpp/1p1p4/2pPpp2/bPP1P3/R1B1NQ2/P4PPP/1R4K1 w - - 0 28';

is $position.ascii, $output, "ASCII board";


done-testing;

#vi: ft=raku nu
