unit module Chess;
# translated from https://github.com/jhlywa/chess.js.git
#`{{{ ORIGINAL LICENSE
Copyright (c) 2025, Jeff Hlywa (jhlywa@gmail.com)
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice,
this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
}}}
use Chess::PGN;
use Chess::FEN;

use Chess::Position;
use Chess::SAN;

sub term:<startpos> is export { Chess::Position.new }

multi infix:<*>(Chess::Position $position, SAN $move --> Chess::Position) is export {
    use Chess::Moves;
    try my Move $move-object .= new: $move, :color($position.turn), :board($position);
    fail "cannot make move `$move` in position `{$position.fen}`" if $!;
    $position.new: $move-object;
}

proto legal-moves($) is export {*}
multi legal-moves(Chess::Position $position) { $position.moves }
multi legal-moves(Str $fen where { Chess::FEN.parse: $_ }) { samewith Chess::Position.new($fen) }

our sub perft(UInt $depth, Chess::Position :$position = startpos) returns UInt {
  my $nodes = 0;
  for $position.moves -> $move {
      if $depth > 1 { $nodes += samewith $depth - 1, position => $position.new($move); }
      else { $nodes++ }
  }
  return $nodes;
}

#`{{{
our proto make-book($) returns Blob {*}
multi make-book($data) {
    [~] gather for load-games($data) {
	take .before.uint => .uint for .moves
    }.sort(*.key)
    .map: {
	my Buf $buf .= new;
	$buf.write-uint64( 0,   .key, BigEndian);
	$buf.write-uint16( 8, .value, BigEndian);
	$buf.write-uint16(10,      1, BigEndian);  # default weight of 1
	$buf.write-uint32(12,      0, BigEndian);  # default learn value of 0
	$buf;
    }
}
}}}

# vi: ft=raku nowrap nu shiftwidth=4
