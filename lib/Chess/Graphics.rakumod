unit module Chess::Graphics;
use Base64;

=for SYSTEM-REQUIREMENTS
  - L<ImageMagick|https://imagemagick.org/>
  - wget

our constant $square-size = 60;
our constant $board-size = 8*$square-size;

constant $dark  = "195 158 128";
constant $light = "243 225 197";

our constant checkerboard = encode-base64 do given run <magick - png:->, :in, :out {
  .in.say: gather {
    take 'P3';
    take "$board-size $board-size";
    take 255;
    for ^$board-size -> $x {
      my $c = $x div $square-size;
      for ^$board-size .map({$_ div $square-size}) -> $r {
	take ($r + $c) %% 2 ?? $dark !! $light;
      }
      take "\n";
    }
  }.join("\n");
  .in.close;
  .out.slurp(:bin);
}, :str;

our constant %pieces = do for 
  # https://commons.wikimedia.org/wiki/Category:PNG_chess_pieces/Standard_transparent
  'https://upload.wikimedia.org/wikipedia/commons/' X~ <
    3/3b/Chess_klt60.png
    4/49/Chess_qlt60.png
    5/5c/Chess_rlt60.png
    9/9b/Chess_blt60.png
    2/28/Chess_nlt60.png
    0/04/Chess_plt60.png
    e/e3/Chess_kdt60.png
    a/af/Chess_qdt60.png
    a/a0/Chess_rdt60.png
    8/81/Chess_bdt60.png
    f/f1/Chess_ndt60.png
    c/cd/Chess_pdt60.png
  > {
  /_(<[kqrbnp]>)(<[ld]>)/;
  my $name = ($/[1] eq 'l' ?? *.uc !! ~*)($/[0]);
  given run «wget $_ -q -O -», :out {
    $name => encode-base64 .out.slurp(:bin), :str;
  }
}

# vim: nowrap shiftwidth=2
