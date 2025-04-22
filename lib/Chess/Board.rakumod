unit class Chess::Board;
use Chess::FEN;
use Chess::Colors;
use Chess::Pieces;

# https://en.wikipedia.org/wiki/0x88
enum square is export ((([1..8] .reverse) X[R~] 'a'..'h') Z=> ((0, 16 ... *) Z[X+] ^8 xx 8).flat);

# hybrid representation:
# - keeping track on which piece is an which square
# - keeping track on which squares are pieces on
has Piece @!board[128];
has Set[square] %!pieces{Piece};

has square %.kings{color};

method     AT-KEY(square $square) { @!board[$square] }
method EXISTS-KEY(square $square) { @!board[$square].defined }

method DELETE-KEY(square $square) {
    with self{$square} -> $piece {
	LEAVE @!board[$square] = Nil;
	.=new without %!pieces{$piece};
	%!pieces{$piece} (-)= Set[square].new: $square;
	return @!board[$square];
    }
    else { fail "attempt to remove piece from empty square" }
}
method ASSIGN-KEY(square $square, Piece $piece) {
    %!pieces{$piece} (|)= Set[square].new: $square;
    @!board[$square] = $piece;                     
} 

method find(Piece $piece) { %!pieces{$piece} }

method set(Str $board) {
    constant %pieces = <p n b r q k> Z=> Pawn, Knight, Bishop, Rook, Queen, King;
    my $self = self;
    Chess::FEN.parse:
    $board,
    actions => class {
	has UInt $!s = 0;
	method rank($/) { $!s += 8 }
	method empty-squares($/) { $!s += +$/ }
	method piece($/) { $!s++ }
	method black-piece($/) { $self{square($!s)} = %pieces{$/.Str.lc}.new: black }
	method white-piece($/) { $self{square($!s)} = %pieces{$/.Str.lc}.new: white }
    }.new;
}


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

submethod BUILD(:@!board, :%!pieces, :%!kings) {}

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

proto method findSpecificAttackingPieces(Piece:D :$piece,  square :$to) {*}
multi method findSpecificAttackingPieces(Piece   :$piece where Pawn, :$to) {
    gather for $piece.offsets[2,3] -> $offset {
	try my $square = square($to - $offset);
	next if $!;
	with self{$square} {
	    take $square if .symbol eq $piece.symbol
	}
    }
}
multi method findSpecificAttackingPieces(Piece   :$piece where King|Knight,       :$to) {
    gather for $piece.offsets -> $offset {
	try my $square = square($to + $offset);
	next if $!;
	with self{$square} {
	    take $square if .symbol eq $piece.symbol
	}
    }
}
multi method findSpecificAttackingPieces(Piece  :$piece where Bishop|Rook|Queen, :$to) {
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

method unicode {
    constant $ls = qq{\e[48;5;244m};
    constant $ds = qq{\e[48;5;28m};
    my $s = "   ┌────────────────────────┐\n";
    my @squares = square::{(8,7...1) X[R~] 'a'..'h'};
    for @squares.rotor(8) -> @row {
	state $r;
	$s ~= "\e[0m {8 - $r++} │";
	for @row -> $square {
	    state $c = 0;
	    $s ~= ($c + $r) %% 2 ?? $ds !! $ls;
	    with self{$square} {
		$s ~= .color ~~ white ?? "\e[97m" !! "\e[30m";
		$s ~= " {.unicode-symbol} ";
	    }
	    else { $s ~= "   "; }
	    $c++;
	}
	$s ~= "\e[0m│\n";
    }
    $s ~= "   └────────────────────────┘\n";
    $s ~= "     a  b  c  d  e  f  g  h";
    $s ~= "\e[0m";
    return $s;
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

method attacked(color :$color, square :$square) returns Bool {
    self!attackers(:$color, :$square).head.defined
}

method isKingAttacked(color $color --> Bool) {
    self.kings{$color}:exists ?? self.attacked(:color(¬$color), :square(self.kings{$color})) !! False
}

method !attackers(color :$color, square :$square) {
    constant $RAYS = Blob[int8].new: <
	17 0 0 0 0 0 0 16 0 0 0 0 0 0 15 0 0 17 0 0 0
	0 0 16 0 0 0 0 0 15 0 0 0 0 17 0 0 0 0 16 0 0 0
	0 15 0 0 0 0 0 0 17 0 0 0 16 0 0 0 15 0 0 0 0 0
	0 0 0 17 0 0 16 0 0 15 0 0 0 0 0 0 0 0 0 0 17 0
	16 0 15 0 0 0 0 0 0 0 0 0 0 0 0 17 16 15 0 0 0 0
	0 0 0 1 1 1 1 1 1 1 0 -1 -1 -1 -1 -1 -1 -1 0 0 0
	0 0 0 0 -15 -16 -17 0 0 0 0 0 0 0 0 0 0 0 0 -15 0
	-16 0 -17 0 0 0 0 0 0 0 0 0 0 -15 0 0 -16 0 0 -17
	0 0 0 0 0 0 0 0 -15 0 0 0 -16 0 0 0 -17 0 0 0 0 0
	0 -15 0 0 0 0 -16 0 0 0 0 -17 0 0 0 0 -15 0 0 0 0
	0 -16 0 0 0 0 0 -17 0 0 -15 0 0 0 0 0 0 -16 0 0 0
	0 0 0 -17
    >;
    gather for square::{*} -> $i {
	next without my $piece = self{$i};
	next unless $piece.color ~~ $color;
	next if $i ~~ $square;
	my $difference = $i - $square;
	my $index = $difference + 119;
	if $piece.attacks($index) {
	    if $piece ~~ Pawn {
		if
		$difference > 0 && $piece.color ~~ white ||
		$difference ≤ 0 && $piece.color ~~ black {
		    take $i;
		}
		next;
	    }
	    elsif $piece ~~ Knight|King { take $i; }
	    else {
		my $offset = $RAYS[$index];
		my $j = $i + $offset;
		my Bool $blocked = False;
		while $j !== $square {
		    with self{square($j)} {
			$blocked = True;
			last;
		    }
		    $j += $offset;
		}
		take $i unless $blocked;
	    }
	}
    }
}

# vi: shiftwidth=4 nu nowrap
