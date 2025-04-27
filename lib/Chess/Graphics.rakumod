unit module Chess::Graphics;
use Chess::Board;
use Chess::Position;
use Chess::Pieces;
use Chess::Moves;

use Kitty;

constant $default-square-size = 32;

# using dynamic variables for
# terminal and window sizes
#

our sub get-placement-parameters(Square $square) {
    my $square-size = $*square-size // $default-square-size;
    my ($rank, $file) = rank($square), file($square);
    my ($cell-width, $cell-height) = $*window-width div $*cols, $*window-height div $*rows;
    %(
	H => ($file*$square-size) div $cell-width,
	X => ($file*$square-size) mod $cell-width,
	V => ($rank*$square-size) div $cell-height,
	Y => ($rank*$square-size) mod $cell-height,
    )
}

our proto show(Chess::Position $, UInt :$placement-id, UInt :$z, Bool :$no-screen-measure) returns UInt is export {*}
multi show($position, :$placement-id, :$z, :$no-screen-measure!) returns UInt is export {
    once Kitty::transmit-data :square-size($*square-size // $default-square-size);

    say Kitty::APC
    a => 'p',
    i => %Kitty::ID<checkerboard>,
    p => $placement-id,
    :$z,
    q => 1;

    for @Chess::Board::squares -> $square {
	with $position{$square} -> $piece {
	    print Kitty::APC
	    a => 'p',
	    i => %Kitty::ID{symbol($piece)},
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
    use Terminal::LineEditor::RawTerminalInput;

    my Terminal::LineEditor::CLIInput $input .= new;
    LEAVE $input.set-done;

    $input.enter-raw-mode;
    LEAVE $input.leave-raw-mode;
    my ($*rows, $*cols) = %*ENV<LINES COLUMNS>;
    without $*rows|$*cols { ($*rows, $*cols) = await $input.detect-terminal-size; }
    my ($*window-height, $*window-width) = await $input.detect-window-size;

    samewith $position, :$placement-id, :$z, :no-screen-measure;
}
our sub highlight-square(Square $square, UInt :$placement-id, Int :$z = 0) {
    print Kitty::APC
    a => 'p',
    p => $placement-id + 65 + $square,
    i => %Kitty::ID<green-square>,
    P => %Kitty::ID<checkerboard>,
    Q => $placement-id,
    |Chess::Graphics::get-placement-parameters($square),
    z => $z,
    q => 1
    ;
    return { print Kitty::APC :a<d>, :d<i>, p => $placement-id + 65 + $square, i => %Kitty::ID<green-square> }
}
our sub highlight-moves-destinations(@moves, UInt :$placement-id, Int :$z = 0, Chess::Position :$position) {
    my @destinations = @moves».to.unique;
    my @ids = @destinations.map: { %Kitty::ID{$position{$_}:exists ?? "oc.move-dest" !! "move-dest"} }
    for @destinations Z=> @ids {
	print Kitty::APC
	a => 'p',
	p => $placement-id + 2*65 + $++,
	i => .value,
	P => %Kitty::ID<checkerboard>,
	Q => $placement-id,
	|Chess::Graphics::get-placement-parameters(.key),
	z => $z,
	q => 1
	;
    }
    return {
	for @ids -> $i {
	    print Kitty::APC a => 'd', d => 'i', q => 1,
	    :$i,
	    p => $placement-id + 2*65 + $++
	    ;
	}
    }
}

sub remove-piece(Square :$square, Chess::Position :$position, UInt :$placement-id) {
    fail "no piece on $square" unless $position{$square}:exists;
    print Kitty::APC :a<d>, :d<i>, :i(%Kitty::ID{symbol($position{$square})}), p => $placement-id + 1 + $square, q => 1;
}

sub place-piece(piece :$piece, Square :$to, Chess::Position :$position, UInt :$placement-id, Int :$z) {
    if $position{$to}:exists { remove-piece :square($to), :$position, :$placement-id }
    print Kitty::APC
    :a<p>,
    :i(%Kitty::ID{symbol($piece)}),
    p => $placement-id + 1 + $to,
    P => %Kitty::ID<checkerboard>,
    Q => $placement-id,
    |Chess::Graphics::get-placement-parameters($to),
    z => $z + 1,
    q => 1
    ;
}

our proto make-move(Move $move, Chess::Position :$position, UInt :$placement-id, Int :$z) {*}
multi make-move($move, :$position, :$placement-id, Int :$z) {
    my $piece = $position{$move.from};
    remove-piece         square => $move.from, :$position, :$placement-id;
    place-piece :$piece,     to => $move.to  , :$position, :$placement-id, :$z;
}
multi make-move(Castle $move, :$position, :$placement-id, :$z) {
    callsame;
    my $rank  = rank($move.from);
    my Square $from  = $rank +< 4 + $move.rook-column;
    my piece  $piece = $position{$from};
    my Square $to    = ($move.from + $move.to) div 2;
    remove-piece         square => $from, :$position, :$placement-id;
    place-piece  :$piece,            :$to, :$position, :$placement-id, :$z;
}
multi make-move(EnPassant $move, :$position, :$placement-id, :$z) {
    callsame;
    remove-piece square => rank($move.from) +< 4 + file($move.to), :$position, :$placement-id;
}
multi make-move(Promotion $move, :$position, :$placement-id, :$z) {
    with $position{$move.to} { remove-piece square => $move.to, :$position, :$placement-id; }
    remove-piece square => $move.from, :$position, :$placement-id;
    place-piece piece => $move.promotion.new(color => $position.turn), to => $move.to, :$position, :$placement-id, :$z;
}


# vi: nu nowrap shiftwidth=4
