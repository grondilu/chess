unit module Kitty;

# avoid edges of ID true range
constant margin   = 1000;
our constant ID-RANGE = margin..(4294967295 - margin);
our %ID = <
    checkerboard
    green-square move-dest oc.move-dest
    p b n r q k
    P B N R Q K
> Z=> ID-RANGE.pick..*;

our sub transmit-data(UInt :$square-size = 128, Str :$piece-set = 'cburnett') {
    for %ID {
	my $magick;
	my $geometry = join 'x', (.key eq 'checkerboard' ?? 8*$square-size !! $square-size) xx 2;
	$magick = run «magick -density 300 -background none - -resize $geometry png:-», :in, :out;
	$magick.in.say: %?RESOURCES{"images/" ~ (.key ~~ /^:i <[pbnrqk]> $/ ?? "piece/$piece-set/" !! '') ~ "{.key}.svg"}.slurp;
	$magick.in.close;
	print APC
	$magick.out.slurp(:bin, :close),
	a => 't',
	f => 100,
	t => 'd',
	i => .value,
	q => 1
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
    ',m=' ~ (@payload > 1 ?? 1 !! 0) ~ ';' ~
    (
	@payload > 1 ??
	[
	    @payload.head ~ "\e\\",
	    |@payload.tail(*-1).head(*-1).map({"\e_Gm=1;$_\e\\"}),
	    "\e_Gm=0;" ~ @payload.tail
	].join !! @payload.pick
    )
}

# vi: shiftwidth=4
