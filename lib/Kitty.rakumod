unit module Kitty;

our constant %ID = <checkerboard green p P b B n N r R q Q k K> Z=> 100..*;

our sub transmit-data {
    return unless (state $)++;
    for %ID {
	print APC
	%?RESOURCES{"images/{.key}.png"}.slurp(:bin),
	a => 't',
	f => 100,
	t => 'd',
	i => .value
	;
    }
}

our sub APC($payload, *%control-data) {
    use Base64;

    my @payload = encode-base64($payload)
	.rotor(4096, :partial)
	.map(*.join);
    "\e_G" ~
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
    ) ~ "\e\\"
}

# vi: shiftwidth=4
