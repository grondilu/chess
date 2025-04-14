unit module Chess::Graphics;
use Chess;
use Chess::Board;

use Kitty;

our constant $square-size = 100;

# using dynamic variables for
# terminal and window sizes

our sub get-window-size {
    use CSI;
    print "\e[14t";

    if get-csi("\e[14t") ~~ / \e '[4;' (\d+) ** 2 % \; / { return $0».Int; }
    else { fail "unexpected response from stdin" }
}

our sub get-placement-parameters(square $square) {
    my ($rank, $file) = rank($square), file($square);
    my ($rows, $columns) = .rows, .cols given $*terminal-size;
    my ($cell-width, $cell-height) = $*window-width div $columns, $*window-height div $rows;
    %(
	H => ($file*$square-size) div $cell-width,
	X => ($file*$square-size) mod $cell-width,
	V => ($rank*$square-size) div $cell-height,
	Y => ($rank*$square-size) mod $cell-height,
    )
}

our proto show(Chess::Position $, UInt :$placement-id, UInt :$z, Bool :$no-screen-measure) returns UInt is export {*}
multi show($position, :$placement-id, :$z, :$no-screen-measure!) returns UInt is export {
    once Kitty::transmit-data :$square-size;

    say Kitty::APC
    a => 'p',
    i => %Kitty::ID<checkerboard>,
    p => $placement-id,
    :$z,
    q => 1;

    for square::{*} -> $square {
	with $position{$square} -> $piece {
	    print Kitty::APC
	    a => 'p',
	    i => %Kitty::ID{$piece.symbol},
	    p => $placement-id + 1 + $square,
	    P => %Kitty::ID<checkerboard>,
	    Q => $placement-id,
	    |Chess::Graphics::get-placement-parameters($square),
	    z => $z + 1,
	    q => 1
	    ;
	}
    }

    return $placement-id;
}

multi show($position, :$placement-id = Kitty::ID-RANGE.pick, :$z = 0) returns UInt is export {
    use Terminal::Size;

    my $*terminal-size = terminal-size;
    my ($*window-height, $*window-width) = get-window-size;

    samewith $position, :$placement-id, :$z, :no-screen-measure;
}

# vi: nu nowrap shiftwidth=4
