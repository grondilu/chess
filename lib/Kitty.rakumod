unit module Kitty;
use Term::termios;

our constant %ID = <checkerboard green p P b B n N r R q Q k K> Z=> 100..*;

our sub pick-placement-id returns UInt {
    # https://sw.kovidgoyal.net/kitty/graphics-protocol/#display-images-on-screen
    (1..4294967295).pick
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
