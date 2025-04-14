unit module Chess::Book;
use Chess::Position;
use Chess::Moves;

our sub search-from-disk(Chess::Position $position, IO::Path :$path) {

	constant $entry-size = 16; # bytes

	my IO::Handle $handle = $path.open: :r, :bin;
	$handle.seek: 0, SeekFromEnd;
	my $size = $handle.tell;
	fail "unexpected file size" unless $size %% $entry-size;

	my UInt $num-entries = $size div $entry-size;
	my uint64 $key = $position.uint;
	my UInt ($left, $right) = 0, $num-entries - 1;
	my UInt $first-match;
	while $left ≤ $right {
		my UInt $middle = ($left + $right) div 2;
		my UInt $offset = $entry-size * $middle;
		$handle.seek: $offset, SeekFromBeginning;
		given $handle.read(8).read-uint64(0, BigEndian) {
			when $key {
				$first-match = $middle;
				last;
			}
			when * < $key { $left = $middle + 1; }
			default { $right = $middle - 1; }
		}
	}
	$handle.seek: -8, SeekFromCurrent;
	loop {
		try $handle.seek: -$entry-size, SeekFromCurrent;
		last if $!;
		if $handle.read(8).read-uint64(0, BigEndian) !== $key {
			$handle.seek(8, SeekFromCurrent);
			last;
		}
		$handle.seek: -8, SeekFromCurrent;
	}
	gather until $handle.eof {
		given $handle.read(8).read-uint64(0, BigEndian) {
			when $key.none { last }
			default {
				take {
					%(
						move   => Move.new(.read-uint16(0, BigEndian), :$position),
						weight => .read-uint16(2, BigEndian),
						learn  => .read-uint32(4, BigEndian)
					)
				}($handle.read(8));
			}
		}
	}
}


