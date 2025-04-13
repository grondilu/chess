unit module CSI;

our sub get-csi(Str $csi?) {
    use Term::termios;

    my $saved_termios := Term::termios.new(fd => 1).getattr;
    LEAVE $saved_termios.setattr: :DRAIN;
    my $termios := Term::termios.new(fd => 1).getattr;
    $termios.makeraw;

    $termios.setattr: :DRAIN;

    .print with $csi;

    # Loop on characters from STDIN
    #
    # Read first two bytes
    my Buf $buf .= new: $*IN.read(2);
    fail "failed to read CSI" unless $buf ~~ "\e[".encode;

    # Read single bytes until we reach termination byte which,
    # according to ECMA-48, ranges from 04/00 to 07/14 
    repeat { $buf ~= $*IN.read(1) } until $buf.tail ~~ 4*16 .. 7*16 + 14;
    return $buf.decode;
}

our sub cursor-position-report {
    given get-csi "\e[6n" {
	when / \e \[ $<y> = [\d+] \; $<x> = [\d+] R / { return $<x y>».Int; }
	default { fail "could not parse CSI response {.raku}" }
    }
}

our sub get-window-size {
    given get-csi "\e[14t" {
	when / \e \[ 4\; (\d+) ** 2 % \; t / { return $0».Int; }
	default { fail "could not parse CSI response: {.raku}" }
    }
}


# vi: shiftwidth=4 nu nowrap
