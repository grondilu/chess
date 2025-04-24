unit class Chess::Board;
use Chess::FEN;
use Chess::Colors;
use Chess::Pieces;

# https://en.wikipedia.org/wiki/0x88
enum square is export ((([1..8] .reverse) X[R~] 'a'..'h') Z=> ((0, 16 ... *) Z[X+] ^8 xx 8).flat);

class BitBoard {
    constant @squares = square::{*}.sort: *.value;
    constant %squares = @squares.antipairs.map: { .key => 1 +< .value };

    has uint64 $.bits;
    multi method new(UInt $bits) { self.bless: :$bits }

    submethod BUILD(:$!bits = 0) {}

    method elems { $!bits.polymod(2 xx *).sum }
    multi method keys { gather loop (my (uint64 $i, int $k) = $!bits, 0; $i > 0; $k++, $i +>= 1) { take @squares[$k] if $i +& 1 } }
    multi method Bool { $!bits > 0 }

    method EXISTS-KEY(square $square) { so $!bits +& %squares{$square} }

    method add   (square $square) { $!bits +|= %squares{$square} }
    method remove(square $square) { $!bits +^= %squares{$square} }
}

# hybrid representation:
# - keeping track on which piece is on which square
# - keeping track on which squares are pieces on
has Piece @!board[128];
has Hash[BitBoard,color] %!pieces{piece-type};

multi method AT-KEY    (square $square) { @!board[$square] }
multi method AT-KEY    (Piece:D $piece) { %!pieces{$piece.type}{$piece.color} }
multi method AT-KEY    (Piece:U $     ) { %!pieces{piece-type}{color} }

multi method EXISTS-KEY(square $square) { @!board[$square].defined }
multi method EXISTS-KEY(  Piece $piece) { %!pieces{$piece.type}{$piece.color}:exists }

method DELETE-KEY(square $square) {
    with self{$square} -> $piece {
	LEAVE @!board[$square] = Nil;
	self{$piece}.remove: $square;
	return @!board[$square];
    }
    else { fail "attempt to remove piece from empty square" }
}
method ASSIGN-KEY(square $square, Piece $piece) {
    self{$piece}.add: $square;
    @!board[$square] = $piece;                     
} 

proto method find(Piece $piece) returns Set[square] {*}
multi method find(Piece $piece) { Set[square].new: %!pieces{$piece.type}{$piece.color}.keys }
multi method find(King $king) {
    given self{$king} {
	fail "too many {$king.color} kings" if .elems > 1;
	return Set[square].new: .keys;
    }
}

multi method new(Str $board) { self.bless: :$board }

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

submethod BUILD(Str :$board) {
    for piece-type::{*} -> $type {
	%!pieces{$type}.=new;
	for black, white -> $color { %!pieces{$type}{$color}.=new }
    }
    .=new without %!pieces{piece-type};
    .=new without %!pieces{piece-type}{color};
    constant %PIECES = <p r n b q k> Z=> pawn, rook, knight, bishop, queen, king;
    with $board {
	my $self = self;
	my @board := @!board;
	my %pieces := %!pieces;
	Chess::FEN.parse:
	$board,
	actions => class {
	    has UInt $!s = 0;
	    method rank($/) { $!s += 8 }
	    method empty-squares($/) { $!s += +$/ }
	    method piece($/) { $!s++ }
	    method black-piece($/) {
		my square $square = square($!s);
		@board[$square] = my $piece = Piece.new: :type(%PIECES{$/.Str   }), :color(black);
		%pieces{$piece.type}{$piece.color}.add: $square;
	    }
	    method white-piece($/) {
		my square $square = square($!s);
		@board[$square] = my $piece = Piece.new: :type(%PIECES{$/.Str.lc}), :color(white);
		%pieces{$piece.type}{$piece.color}.add: $square;
	    }
	}.new;
    }
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

method pairs { @!board.pairs.grep: *.value }
method all-pairs { square::{*}.sort(+*).map({ $_ => @!board[$_]}) }

proto method findSpecificAttackingPieces(Piece:D :$piece,  square :$to) {*}
multi method findSpecificAttackingPieces(Piece   :$piece where Pawn, :$to) {
    gather for $piece.offsets[2,3] -> $offset {
	my $diff = $to - $offset;
	next unless $diff ~~ a8..h1 && $diff % 16 < 8;
	my $square = square($diff);
	with self{$square} {
	    take $square if .symbol eq $piece.symbol
	}
    }
}
multi method findSpecificAttackingPieces(Piece   :$piece where King|Knight,       :$to) {
    gather for $piece.offsets -> $offset {
	my $sum = $to + $offset;
	next unless $sum ~~ a8..h1 && $sum % 16 < 8;
	my $square = square($sum);
	with self{$square} {
	    take $square if .symbol eq $piece.symbol
	}
    }
}
multi method findSpecificAttackingPieces(Piece  :$piece where Bishop|Rook|Queen, :$to) {
    gather COLLECT: for $piece.offsets -> $offset {
	my square $square = $to;

	repeat {
	    my $sum = $square + $offset;
	    next COLLECT unless $sum ~~ a8..h1 && $sum % 16 < 8;
	    $square = square($sum);
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

method attacked(color :$color, square :$square) returns Bool {
    self.attackers(:$color, :$square).head.defined
}

method isKingAttacked(color $color --> Bool) {
    with self.find(Piece.new(:type(king), :$color)).pick -> $square {
	return self.attacked(:color(¬$color), :$square)
    }
    else { return False }
}

method attackers(color :$color, square :$square) {
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
