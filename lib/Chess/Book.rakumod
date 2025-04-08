unit class Chess::Book;
use Chess;

constant $entry-size = 16; # bytes

has IO::Handle $!io-handle;

multi method new(IO::Handle $io-handle) { self.bless: :$io-handle }
multi method new(IO::Path   $path     ) { self.bless: :io-handle($path.open: :r) }

submethod BUILD(:$!io-handle) {}
submethod TWEAK { fail "unexpected file size" unless self!size %% $entry-size }

method !size {
	$!io-handle.seek: 0, SeekFromEnd;
	return $!io-handle.tell
}
multi method get(Chess::Position $position) {
	my UInt $num-entries = self!size div $entry-size;
	my uint64 $key = $position.uint;
	my UInt ($left, $right) = 0, $num-entries - 1;
	my UInt $first-match;
	while $left ≤ $right {
		my UInt $middle = ($left + $right) div 2;
		my UInt $offset = $entry-size * $middle;
		$!io-handle.seek: $offset, SeekFromBeginning;
		given $!io-handle.read(8).read-uint64(0, BigEndian) {
			when $key {
				$first-match = $middle;
				last;
			}
			when * < $key { $left = $middle + 1; }
			default { $right = $middle - 1; }
		}
	}
	$!io-handle.seek: -8, SeekFromCurrent;
	loop {
		try $!io-handle.seek: -$entry-size, SeekFromCurrent;
		last if $!;
		if $!io-handle.read(8).read-uint64(0, BigEndian) !== $key {
			$!io-handle.seek(8, SeekFromCurrent);
			last;
		}
		$!io-handle.seek: -8, SeekFromCurrent;
	}
	gather until $!io-handle.eof {
		given $!io-handle.read(8).read-uint64(0, BigEndian) {
			when $key.none { last }
			default {
				take {
					%(
						move   => Chess::Move.new(.read-uint16(0, BigEndian), :$position),
						weight => .read-uint16(2, BigEndian),
						learn  => .read-uint32(4, BigEndian)
					)
				}($!io-handle.read(8));
			}
		}
	}
}


