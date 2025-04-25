unit class Chess::Book;
use Chess::Colors;
use Chess::Position;
use Chess::Moves;

use Chess::PGN;

has blob8 $.data;

multi method new(IO::Path $path where /'.bin'$/) { self.bless: data => $path.slurp: :bin, :close }
multi method new(IO::Path $path where /'.pgn'$/) { self.new: $path.slurp: :close }

multi method new(Str $pgn) { self.new: Chess::PGN.parse: $pgn }
multi method new(Match $/) {

    gather for $<game> -> $/ {
	my Chess::Position $position .= new;

	for $<movetext-section><move>»<SAN> {
	    my Move $move .= new: .Str, :color($position.turn), :board($position);

	    my Int $weight = do given $<game-termination> {
		when '1/2-1/2'|'½-½' { 1 }
		when '1-0' { $position.turn ~~ white ?? 2 !! 0; }
		when '0-1' { $position.turn ~~ black ?? 2 !! 0; }
		default { 1 }
	    }
	    take $position.fen => %( :move(.Str), :$weight );
	    $position.make: $move;
	}
    }.classify(*.key, :as(*.value))
    .map({ .key => .value.classify({.<move>}, :as({.<weight>})) })
    .map({ .key => .value.map({ .key => .value.sum }) })
    
}


method AT-KEY(Chess::Position $position) {
    constant $entry-size = 16; # bytes

    fail "unexpected file size" unless $!data.elems %% $entry-size;

    my UInt $num-entries = $!data.elems div $entry-size;
    my uint64 $key = $position.uint;
    my UInt ($left, $right) = 0, $num-entries - 1;
    my UInt $first-match;
    while $left ≤ $right {
	my UInt $middle = ($left + $right) div 2;
	my UInt $offset = $entry-size * $middle;
	given $!data.subbuf($offset, $entry-size).read-uint64(0, BigEndian) {
	    when $key {
		$first-match = $middle;
		last;
	    }
	    when * < $key { $left = $middle + 1; }
	    default { $right = $middle - 1; }
	}
    }
    gather {
	given sub ($i) {
		my $entry = $!data.subbuf($i*$entry-size, $entry-size);
		last unless $key == $entry.read-uint64(0, BigEndian);
		take %(
		    move   => Move.new($entry.read-uint16(8, BigEndian)),
		    weight =>          $entry.read-uint16(10, BigEndian),
		    learn  =>          $entry.read-uint32(12, BigEndian)
		);
	} {
	    for $first-match     ^..  * -> $i { .($i) }
	    for $first-match, *-1 ... * -> $i { .($i) }
	}
    }
}

# vi: shiftwidth=4 nu
