unit class Chess::Board;
use Chess::Colors;
use Chess::Pieces;

# https://en.wikipedia.org/wiki/0x88
enum square is export ((([1..8] .reverse) X[R~] 'a'..'h') Z=> ((0, 16 ... *) Z[X+] ^8 xx 8).flat);

has Piece @!board[128];
has square %.kings{color};

method     AT-KEY(square $square              ) { @!board[$square];                               }
method ASSIGN-KEY(square $square, Piece $piece) { @!board[$square] = $piece;                      } 
method EXISTS-KEY(square $square              ) { @!board[$square].defined;                       }
method DELETE-KEY(square $square              ) { LEAVE @!board[$square] = Nil; @!board[$square]; }

# RANK : ─ 
# FILE : │
# SLASH : ╱
# SLOSH : ╲

sub rank (square $sq) is export { $sq +>  4 }
sub file (square $sq) is export { $sq +& 15 }
sub slash(square $sq) is export { $sq  % 15 }
sub slosh(square $sq) is export { $sq  % 17 }

constant %RANK  = square::{*}.sort(&file).classify(&rank );
constant %FILE  = square::{*}.sort(&rank).classify(&file );
constant %SLASH = square::{*}.sort(&file).classify(&slash);
constant %SLOSH = square::{*}.sort(&file).classify(&slosh);

method rank (square $sq) { self{|%RANK{  rank($sq)}} }
method file (square $sq) { self{|%FILE{  file($sq)}} }
method slash(square $sq) { self{|%SLASH{slash($sq)}} }
method slosh(square $sq) { self{|%SLOSH{slosh($sq)}} }

subset en-passant-square of square is export where /<[36]>$/;

our constant %SECOND-RANK    is export = (white) => rank(a2), (black) => rank(a7);
our constant $PROMOTION-RANK is export = rank(a1)|rank(a8);

submethod BUILD(:@!board, :%!kings) {}

method pairs { @!board.pairs.grep: *.value }
method all-pairs { square::{*}.sort(+*).map({ $_ => @!board[$_]}) }

method is-pinned(square $square) returns Bool {
    with self{$square} -> $piece {
	my $king-square = %!kings{$piece.color};
	my &test-block = -> $t, @a, @b {
	    my $a = first *.defined, self{|map {square($_)}, @a};
	    my $b = first *.defined, self{|map {square($_)}, @b};
	    if ($a,$b).one ~~ King {
		($a, $b) = $b, $a if $b ~~ King;
		return True if $a.color ~~ $piece.color && $b ~~ $t and $b.color ~~ ¬$piece.color;
	    }
	}
	if    rank($king-square)  == rank($square)  { test-block Queen|Rook,   ($square, *+ 1 ^...^ * %%  8), ($square, *-1 ^... * %% 16) }
	elsif file($king-square)  == file($square)  { test-block Queen|Rook,   ($square, *+16 ^...^ * > 128), ($square, *-16 ^...^ * < 0) }
	elsif slash($king-square) == slash($square) { test-block Queen|Bishop, ($square, *+15 ^...^ {(($_ % 16) > 7) || $_ > 128}), ($square, *-15 ^...^ { ($_ < 0) || (($_ % 16) > 7) }) }
	elsif slosh($king-square) == slosh($square) { test-block Queen|Bishop, ($square, *+17 ^...^ {(($_ % 16) > 7) || $_ > 128}), ($square, *-17 ^...^ { ($_ < 0) || (($_ % 16) > 7) }) }
	return False;
    }
    else { fail "no piece on $square" }
}

proto method find-attacking-pieces(Piece:D :$piece,  square :$to) {*}
multi method find-attacking-pieces(Piece   :$piece where Pawn, :$to) {
    gather for $piece.offsets[2,3] -> $offset {
	try my $square = square($to - $offset);
	next if $!;
	with self{$square} {
	    take $square if .symbol eq $piece.symbol
	}
    }
}
multi method find-attacking-pieces(Piece   :$piece where King|Knight,       :$to) {
    gather for $piece.offsets -> $offset {
	try my $square = square($to + $offset);
	next if $!;
	with self{$square} {
	    take $square if .symbol eq $piece.symbol
	}
    }
}
multi method find-attacking-pieces(Piece  :$piece where Bishop|Rook|Queen, :$to) {
    gather COLLECT: for $piece.offsets -> $offset {
	my square $square = $to;

	repeat {
	    try $square = square($square + $offset);
	    next COLLECT if $!;
	} until self{$square}.defined;

	my Piece $candidate = self{$square};
	take $square if $candidate.symbol eq $piece.symbol;
    }
}

method is-king-attacked(color :$color) returns Bool {
    my $king-location = %!kings{$color};
    [||] map {
	self.find-attacking-pieces(piece => .new(:color(¬$color)), :to($king-location)).head.defined ;
    }, King, Queen, Rook, Bishop, Knight, Pawn, King;
}

method ascii {
    my $s = "   +------------------------+\n";
    my @squares = square::{(8,7...1) X[R~] 'a'..'h'};
    for @squares.rotor(8) -> @row {
	state $r;
	$s ~= " {8 - $r++} |";
	for @row -> $square {
	    my $piece = self{$square};
	    $s ~= " {$piece ?? $piece.symbol !! '.'} ";
	}
	$s ~= "|\n";
    }
    $s ~= "   +------------------------+\n";
    $s ~= "     a  b  c  d  e  f  g  h";
    return $s;
}

# vi: shiftwidth=4 nu nowrap
