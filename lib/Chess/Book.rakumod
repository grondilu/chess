unit class Chess::Book;
use Chess::Position;
use Chess::Moves;

has blob8 $.data;

multi method new(IO::Path $path) { self.bless: data => $path.slurp: :bin, :close }

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
