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

# https://commons.wikimedia.org/wiki/Category:PNG_chess_pieces/Standard_transparent
our constant %pieces = gather for <k q r b n p> {
    take $_ => encode-base64 qq{images/$_.png}.IO.slurp(:bin), :str for .lc, .uc
}

# vim: nowrap shiftwidth=2
