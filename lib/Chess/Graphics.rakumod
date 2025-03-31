unit module Chess::Graphics;
use Base64;

our constant $square-size = 60;

our constant checkerboard = encode-base64 %?RESOURCES<images/checkerboard.png>.IO.slurp(:bin), :str;

# https://commons.wikimedia.org/wiki/Category:PNG_chess_pieces/Standard_transparent
our constant %pieces = gather for <k q r b n p> {
    take $_ => encode-base64 %?RESOURCES{"images/$_.png"}.IO.slurp(:bin), :str for .lc, .uc
}

# vim: nowrap shiftwidth=2
