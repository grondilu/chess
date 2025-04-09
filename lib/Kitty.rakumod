unit module Kitty;
use Term::termios;

our constant %ID = <checkerboard green p P b B n N r R q Q k K> Z=> 100..*;

our sub get-window-size {
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

our sub transmit-data {
    once for %ID {
	print APC
	%?RESOURCES{"images/{.key}.png"}.slurp(:bin),
	a => 't',
	f => 100,
	t => 'd',
	i => .value,
	q => 1
	;
    }
}

our proto APC(|) { "\e_G" ~ {*} ~ "\e\\" }
multi APC(*%control-data) {
    %control-data.map({"{.key}={.value}"}).join(',')
}

multi APC($payload, *%control-data) {
    use Base64;

    my @payload = encode-base64($payload)
	.rotor(4096, :partial)
	.map(*.join);
    %control-data.map({"{.key}={.value}"}).join(',') ~
    ',m=' ~ (@payload > 1 ?? 1 !! 0) ~
    ';' ~
    (
	@payload > 1 ??
	[
	    @payload.head ~ "\e\\",
	    |@payload.tail(*-1).head(*-1).map({"\e_Gm=1;$_\e\\"}),
	    "\e_Gm=0;" ~ @payload.tail ~ "\e\\"
	].join !! @payload.pick
    )
}

# vi: shiftwidth=4
