unit module Chess::Graphics;

our constant $square-size = 60;

our constant checkerboard = %?RESOURCES<images/checkerboard.png>.absolute;

# https://commons.wikimedia.org/wiki/Category:PNG_chess_pieces/Standard_transparent
our constant %pieces = 
  K => %?RESOURCES<images/K.png>.absolute,
  Q => %?RESOURCES<images/Q.png>.absolute,
  B => %?RESOURCES<images/B.png>.absolute,
  N => %?RESOURCES<images/N.png>.absolute,
  R => %?RESOURCES<images/R.png>.absolute,
  P => %?RESOURCES<images/P.png>.absolute,
  k => %?RESOURCES<images/k.png>.absolute,
  q => %?RESOURCES<images/q.png>.absolute,
  b => %?RESOURCES<images/b.png>.absolute,
  n => %?RESOURCES<images/n.png>.absolute,
  r => %?RESOURCES<images/r.png>.absolute,
  p => %?RESOURCES<images/p.png>.absolute
;

# vim: nowrap shiftwidth=2
