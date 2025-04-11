unit module Chess::Graphics;
use Chess::Board;


our constant $square-size = 60;

our sub get-window-size {
    use Term::termios;
    ENTER my $saved_termios := Term::termios.new(fd => 1).getattr;
    LEAVE $saved_termios.setattr: :DRAIN;
    my $termios := Term::termios.new(fd => 1).getattr;
    $termios.makeraw;

    $termios.setattr(:DRAIN);

    print "\e[14t";

    if $*IN.read(4) ~~ Blob.new: "\e[4;".comb(/./)».ord {
	my Buf $buf .= new;
	loop {
	    my $c = $*IN.read(1);
	    $buf ~= $c;
	    last if $c[0] ~~ 't'.ord;
	}
	if $buf.decode ~~ / (\d+) ** 2 % \; / {
	    return $0».Int;
	} else { fail "unexpected response from stdin" }
    } else { fail "could not read stdin" }
}

our sub get-placement-parameters(square $square, :$terminal-size, :@window-size ($window-height, $window-width)) {
    my ($rank, $file) = rank($square), file($square);
    my ($rows, $columns) = .rows, .cols given $terminal-size;
    my ($cell-width, $cell-height) = $window-width div $columns, $window-height div $rows;
    %(
	H => ($file*$square-size) div $cell-width,
	X => ($file*$square-size) mod $cell-width,
	V => ($rank*$square-size) div $cell-height,
	Y => ($rank*$square-size) mod $cell-height,
    )
}
# vi: nu nowrap shiftwidth=4
