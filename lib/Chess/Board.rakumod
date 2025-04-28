unit class Chess::Board;
use Chess::FEN;
use Chess::Colors;
use Chess::Pieces;

#| https://en.wikipedia.org/wiki/0x88
subset Square of UInt is export where { not $_ +& 0x88 }
enum square-enum is export ((([1..8] .reverse) X[R~] 'a'..'h') Z=> grep Square, ^Inf);
our constant @squares = square-enum::{*}.sort(*.value);

#| rank: ─, file: │, slash: ╱, slosh: ╲
sub rank (Square $sq) is export { $sq +>      4 }
sub file (Square $sq) is export { $sq +&  0b111 }
sub slash(Square $sq) is export { $sq mod    15 }
sub slosh(Square $sq) is export { $sq mod    17 }
constant %RANK  = @squares.sort(&file).classify(&rank );
constant %FILE  = @squares.sort(&rank).classify(&file );
constant %SLASH = @squares.sort(&file).classify(&slash);
constant %SLOSH = @squares.sort(&file).classify(&slosh);
method rank (Square $sq) { self{|%RANK{  rank($sq)}} }
method file (Square $sq) { self{|%FILE{  file($sq)}} }
method slash(Square $sq) { self{|%SLASH{slash($sq)}} }
method slosh(Square $sq) { self{|%SLOSH{slosh($sq)}} }

multi prefix:<~>(Square $_ --> Str) is export { ('a'..'h')[.&file] ~ (1..8)[7-.&rank] }

# Double(hybrid?) representation
# ==============================

#|(
    Keeping track of which piece is on a given square.
    Here the length of 128 is due to the use of a 0x88 board
)
has piece @.board[128];
#|(
    Keeping track of which squares a given piece is on.
    The first element of this buffer is not used
    due to the structure of the piece enum.
)
has buf64 $.bitboard;

sub index-to-square(int8 $i where ^64 --> Square) { ($i +> 3) +< 4 +| $i +& 0b111 }
sub square-to-index(Square $s --> uint8) { my uint8 $ = rank($s) +< 3 +| file($s) }

multi method AT-KEY(Square $square) { @!board[$square] }
multi method AT-KEY(piece $piece) {
    Set[Square].new:
    gather loop (my (int8 $i, uint64 $bits) = 0, $!bitboard[$piece]; $bits > 0; $i++) {
	take index-to-square($i) if $bits +& 1;
	$bits +>= 1;
    }
}

multi method EXISTS-KEY(Square $square) { @!board[$square].defined }
multi method EXISTS-KEY(  piece $piece) { $!bitboard[$piece] > 0 }

method DELETE-KEY(Square $square) {
    with self{$square} {
	LEAVE @!board[$square] = Nil;
	$!bitboard[$_] +&= +^(1 +< square-to-index $square);
	return @!board[$square];
    }
    else { fail "attempt to remove piece from empty square" }
}
multi method ASSIGN-KEY(Square $square, piece:D $piece) {
    $!bitboard[+$piece] +|= 1 +< square-to-index $square;
    @!board[$square] = $piece;                     
} 
multi method ASSIGN-KEY(Square $square, piece:U $piece) {
    with self{$square} {
	$!bitboard[$_] +&= +^(1 +< square-to-index $square);
    }
    @!board[$square] = Nil;                     
} 

method ascii {
    my $s = "   +------------------------+\n";
    for @squares.rotor(8) -> @row {
	state $r;
	$s ~= " {8 - $r++} |";
	for @row -> $square {
	    my $piece = self{$square};
	    $s ~= " {$piece.defined ?? symbol($piece) !! '.'} ";
	}
	$s ~= "|\n";
    }
    $s ~= "   +------------------------+\n";
    $s ~= "     a  b  c  d  e  f  g  h";
    return $s;
}
method unicode {
    constant $ls = "\e[48;5;244m";
    constant $ds = "\e[48;5;28m";
    my $s = "   ┌────────────────────────┐\n";
    for @squares.rotor(8) -> @row {
	state $r;
	$s ~= "\e[0m {8 - $r++} │";
	for @row -> $square {
	    state $c = 0;
	    $s ~= ($c + $r) %% 2 ?? $ds !! $ls;
	    with self{$square} {
		$s ~= $_ ≡ white ?? "\e[97m" !! "\e[30m";
		$s ~= " $_ ";
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
method kitty(Bool :$flip) {
    use Kitty;
    use Terminal::Size;
    
    my winsize $ws = terminal-size;
    my ($rows, $cols) = $ws.rows, $ws.cols;
    my ($window-height, $window-width) = $ws.ypixel, $ws.xpixel;
    my ($cell-width, $cell-height) = $window-width div $cols, $window-height div $rows;

    my $square-size = $cell-height;
    once Kitty::transmit-data :$square-size;

    my $placement-id = Kitty::ID-RANGE.pick;
    my Str $kitty = Kitty::APC
    a => 'p',
    i => %Kitty::ID<checkerboard>,
    p => $placement-id,
    z => 0,
    q => 1;

    for @Chess::Board::squares -> $square {
	with self{$square} -> $piece {
	    my ($rank, $file) = rank($square), file($square);
	    ($rank, $file).=map(7-*) if $flip;
	    $kitty ~= Kitty::APC
	    a => 'p',
	    i => %Kitty::ID{symbol($piece)},
	    p => $placement-id + 1 + $square,
	    P => %Kitty::ID<checkerboard>,
	    Q => $placement-id,
	    H => ($file*$square-size) div $cell-width,
	    X => ($file*$square-size) mod $cell-width,
	    V => ($rank*$square-size) div $cell-height,
	    Y => ($rank*$square-size) mod $cell-height,
	    z => 1,
	    q => 1
	    ;
	}
    }

    return $kitty;
}

multi method new(Str $board = q{rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1}) {
    self.bless: :$board
}

submethod BUILD(Str :$board) {
    my piece @board[128];
    my buf64 $bitboard .= new: 0 xx 13;
    Chess::FEN.parse:
    $board,
    actions => class {
	has UInt $!s = 0;
	method empty-squares($/) { $!s += +$/ }
	method piece($/) {
	    my piece $piece = ($<black-piece> // $<white-piece>).made;
	    @board[index-to-square $!s] = $piece;
	    $bitboard[$piece] +|= 1 +< $!s++;
	}
	method black-piece($/) { make piece(9 + "pnbrqk".index($/.Str)); }
	method white-piece($/) { make piece(1 + "PNBRQK".index($/.Str)); }
    }.new;
    @!board    = @board;
    $!bitboard := $bitboard;
}

subset en-passant-square of Square is export where { .&rank == 2|5 };

our constant %SECOND-RANK    is export = (white) => rank(a2), (black) => rank(a7);
our constant $PROMOTION-RANK is export = rank(a1)|rank(a8);

proto method findSpecificAttackingPieces(piece :$piece!,  Square :$to!) { map { square-enum::{~$_} }, {*} }
multi method findSpecificAttackingPieces(pawn :$piece, :$to) {
    gather for get-offsets($piece)[2,3] -> $offset {
	my $square = $to - $offset;
	next unless $square ~~ Square;
	with self{$square} {
	    take $square if $_ ~~ $piece;
	}
    }
}
multi method findSpecificAttackingPieces(piece :$piece where king|knight, :$to) {
    gather for get-offsets($piece) -> $offset {
	my $square = $to + $offset;
	next unless $square ~~ Square;
	with self{$square} {
	    take $square if $_ ~~ $piece;
	}
    }
}
multi method findSpecificAttackingPieces(piece  :$piece where bishop|rook|queen, :$to) {
    gather COLLECT: for get-offsets($piece) -> $offset {
	my $square = $to;
	repeat {
	    $square += $offset;
	    next COLLECT unless $square ~~ Square;
	} until self{$square}.defined;
	my piece $candidate = self{$square};
	take $square if $candidate ~~ $piece;
    }
}

method pairs { @!board.pairs.grep: *.value.defined }
method all-pairs { @!board.pairs.grep: { .key ~~ Square } }

method attacked(color :$color, Square :$square) returns Bool {
    self.attackers(:$color, :$square).head.defined
}

method isKingAttacked(color $color --> Bool) {
    with self{$color ~~ white ?? wk !! bk}.pick -> $square {
	return self.attacked(:color(¬$color), :$square)
    }
    else { return False }
}

method attackers(color :$color, Square :$square) {
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
    gather for @squares -> Square $i {
	next without my $piece = self{$i};
	next unless $piece ≡ $color;
	next if $i == $square;
	my $difference = $i - $square;
	my $index = $difference + 119;
	if $piece attacks $index {
	    if $piece ~~ pawn {
		if
		$difference > 0 && $piece ≡ white ||
		$difference ≤ 0 && $piece ≡ black {
		    take $i;
		}
		next;
	    }
	    elsif $piece ~~ knight|king { take $i; }
	    else {
		my $offset = $RAYS[$index];
		my $j = $i + $offset;
		my Bool $blocked = False;
		while $j !== $square {
		    with self{$j} {
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
