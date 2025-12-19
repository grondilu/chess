unit module Chess::Moves;
use Chess::PGN;
use Chess::Colors;
use Chess::Board;
use Chess::Pieces;

class Move is export {...}
class PawnMove {...}

subset KnightMove of Move is export where { wn attacks 119 + .to - .from }
subset BigPawnMove of PawnMove is export where { abs(rank(.to) - rank(.from)) == 2 }
role capture is export {}

role EnPassant {...}
role Promotion {...}
role Castle {...}
class KingsideCastle {...}
class QueensideCastle {...}

my regex annotation { <[+#]>?<[!?]>** 0..2 }

class Move {
    has Square ($.from, $.to);
    our subset FullyDefined of ::?CLASS where { defined .from & .to : }
    method LAN(FullyDefined:) { ($!from, $!to).map({ square-enum($_) }).fmt("%s", '') }
    method gist { self.LAN }
    multi method piece-type(KnightMove:) { knight }
    multi method move-pieces(FullyDefined: Chess::Board $board) {
	my piece $from = $board{$!from}<>;
	my piece $to = $board{$!to}<>;
	if $from ~~ king && self !~~ Castle {
	    if file($!to) > file($!from) + 1 {
		return KingsideCastle.new(:$!from, :$!to).move-pieces: $board
	    } elsif file($!from) > file($!to) + 1 {
		return QueensideCastle.new(:$!from, :$!to).move-pieces: $board
	    } 
	}
	if self ~~ PawnMove && self ~~ capture && self !~~ EnPassant {
	    return (self but EnPassant).move-pieces: $board without $board{$!to};
	}
	$board{$!to} = $board{$!from}:delete;
	return -> {
	    $board{$!to}:delete;
	    $board{$!from} = $from;
	    $board{$!to}   = $to;
	}
    }
    multi method pseudo-SAN(capture:) {
	self.piece-type.symbol.uc ~ 'x' ~ square-enum($!to)
    }
    method uint(FullyDefined:) {
	# http://hgm.nubati.net/book_format.html
	reduce 8 * * + *,
	7-rank($!from),
	file($!from),
	7-rank($!to),
	file($!to)
    }
    multi method new(
	Str $ where /^(<[a..h]><[1..8]>)**2$/,
	color :$color!,
	Chess::Board :$board!
    ) {
	my ($from, $to) =
	    square-enum::{$/[0][0]},
	    square-enum::{$/[0][1]};
	if $board{$from} ~~ pawn {
	    return PawnMove.new: "$from$to"
	}
	elsif $board{$from} ~~ ($color ~~ white ?? wk !! bk) {
	    if file($from) == 4 {
		if file($to) == 6 {
		    return KingsideCastle.new: :$color
		}
		elsif file($to) == 2 {
		    return QueensideCastle.new: :$color
		}
	    }
	}
	return self.bless:
	from => square-enum::{$/[0][0]},
	to   => square-enum::{$/[0][1]}
    }
    multi method new(Str $ where /^(<[a..h]><[1..8]>)(<[a..h]><[18]>)(<[qbnr]>)$/) {
	my ($from, $to) = $/[^2].map: { square-enum::{$_} }
	my piece $promotion = %(<q b n r> Z=> piece::<♕ ♗ ♘ ♖>){$/[2]};
	$promotion = ¬$promotion if ~$/[1] ~~ /1$/;
	PawnMove.bless( :$from, :$to ) but Promotion[$promotion];
    }
    multi method new(
	Str $ where /^ <Chess::PGN::SAN><[#!]>?<[!?]>** ^2 $/,
	color :$color!,
	Chess::Board :$board!
    ) {
	given $<Chess::PGN::SAN> -> $/ {
	    with $<castle> {
		when 'O-O'   { return  KingsideCastle.new: :$color }
		when 'O-O-O' { return QueensideCastle.new: :$color }
		default      { die "unknown castling type" }
	    }
	    orwith $<pawn-move> -> $/ {
		my Square $to   = square-enum::{$<square>};
		my UInt ($file, $rank) = file($to), rank($to) + ($color ~~ white ?? 1 !! -1);
		with $<file> { $file = %( 'a'..'h' Z=> ^8 ){.Str} }
		elsif $color ~~ white && $to ~~ /4$/ or $color ~~ black && $to ~~ /5$/ {
		    my $direction = $color ~~ white ?? +16 !! -16;
		    my Square $from = $to + $direction;
		    $from = $to + 2*$direction without $board{$from};
		    return PawnMove.new(:$from, :$to);
		}
		my Square $from = $rank +< 4 + $file;
		my PawnMove $move .=new: :$from, :$to;
		with $<promotion> {
		    my $promotion = %( <q b n r> Z=> wq, wb, wn, wr ){.Str.lc};
		    $promotion = ¬$promotion if $color ~~ black;
		    $move does Promotion[$promotion];
		}
		if file($from) !== file($to) {
		    $move does capture;
		    $move does EnPassant without $board{$to};
		}
		return $move;
	    }
	    orwith $<piece-move> -> $/ {
		my $to = square-enum::{$<square>};
		my piece $piece = %(<N B R Q K> Z=> piece::<♘ ♗ ♖ ♕ ♔>){$<piece>};
		$piece = ¬$piece if $color ~~ black;
		my Square @from = $board.findSpecificAttackingPieces: :$piece, :$to;
		my &constructor = $board{$to}:exists ??
		-> *%args { self.new(|%args) but capture } !!
		-> *%args { self.new(|%args) };
		with $<disambiguation> -> $/ {
		    with $<file> -> $/ {
			my $file = %( 'a'..'h' Z=> ^8 ){$/};
			@from.=grep: { file($_) == $file };
		    }
		    with $<rank> -> $/ {
			my $rank = 8 - $/.Int;
			@from.=grep: { rank($_) == $rank };
		    }
		    with $<square> -> $/ {
			@from = (square-enum::{$/},);
		    }
		}
		fail "could not find piece for move $/ ($color to play) in position :\n{$board.ascii}" if @from == 0;
		if @from > 1 {
		    @from.=grep: -> $from {
			my &undo = self.bless(:$from, :$to).move-pieces: $board;
			LEAVE &undo();
			not $board.isKingAttacked($color);
		    }
		}
		fail "ambiguity remains for move $/ ($color to play) in position:\n{$board.ascii}" if @from > 1;
		my Square $from = @from.pick;
		return &constructor(:$from, :$to);
	    }
	    else {...}
	}
    }

    multi method new(UInt $int) {
	my $to-file   =  $int +& 0b0_000_000_000_000_111      ;
	my $to-rank   = ($int +& 0b0_000_000_000_111_000) +> 3;
	my $from-file = ($int +& 0b0_000_000_111_000_000) +> 6;
	my $from-rank = ($int +& 0b0_000_111_000_000_000) +> 9;
	my $promotion = ($int +& 0b0_111_000_000_000_000) +> 12;

	my ($from, $to) = map -> ($f, $r) { square-enum::{['a'..'h'][$f] ~ (1 + $r)} }, ($from-file, $from-rank), ($to-file, $to-rank);
	my $blessing = self.bless: :$from, :$to;
	$blessing does Promotion[(piece, knight, bishop, rook, queen)[$promotion]] if $promotion > 0;
	return $blessing;
    }
}

role Castle[UInt $rook-column] is Move is export {
    method rook-column { $rook-column }
    method piece-type { king }
    method move-pieces(Move::FullyDefined: Chess::Board $board) {
	# move the king
	my &undo1 = self.Move::move-pieces($board);
	# move the rook
	my $rank = rank(self.from);
	my Square $from = $rank +< 4 + $rook-column;
	my Square $to   = (self.from + self.to) div 2;
	my @record = $board{$to, $from};
	$board{$to} = $board{$from}:delete;
	return -> { $board{$to, $from} = @record; &undo1() }
    }
    multi method new(color :$color!) {
	my $rank = $color ~~ white ?? rank(e1) !! rank(e8);
	my Square $from = $rank +< 4 + file(e1);
	if $rook-column > file($from) {
	    my Square $to = $from + 2;
	    return KingsideCastle.bless: :$from, :$to;
	} else {
	    my Square $to = $from - 2;
	    return QueensideCastle.bless: :$from, :$to;
	}
    }
}

class  KingsideCastle does Castle[7] is export { method pseudo-SAN {   'O-O' } }
class QueensideCastle does Castle[0] is export { method pseudo-SAN { 'O-O-O' } }

class PawnMove is Move is export {
    multi method new(Str $ where /^(<[a..h]><[1..8]>)**2(<[qbnr]>)?$/) {
	my Square ($from, $to) = $/[0].map: { square-enum::{$_} }
	my ($delta-rank, $delta-file) = (&rank, &file).map: { abs(.($to) - .($from)) }
	my $blessing = self.bless: :$from, :$to;
	if    $delta-rank == 2 && $delta-file == 0  { return $blessing }
	elsif $delta-rank|$delta-file !== 1         { fail "illegal pawn move" }
	elsif file($to) !== file($from)             { $blessing does capture     }
	with $/[1]                                  { $blessing does Promotion[%(<b n r q> Z=> bishop, knight, rook, queen){$_}] }
	return $blessing;
    }
    method piece-type { pawn }
    method pseudo-SAN(Move::FullyDefined:) {
	file(self.from) == file(self.to) ?? 
	~self.to !!
	"{('a'..'h')[file(self.from)]}x{square-enum(self.to)}"
    }
}

role EnPassant is export {
    method move-pieces(Move::FullyDefined: Chess::Board $board) {
	my &undo1 = self.Move::move-pieces($board);
	my Square $square = rank(self.from) +< 4 + file(self.to);
	my $record = $board{$square}:delete;
	return -> { 
	    $board{$square} = $record;
	    &undo1()
	}
    }
}

role Promotion[piece:D $promotion] is export {
    method LAN {
	self.Move::LAN ~ symbol($promotion).lc
    }
    method pseudo-SAN { self.PawnMove::pseudo-SAN ~ '=' ~ symbol($promotion).uc; }
    method move-pieces(Move::FullyDefined: Chess::Board $board) {
	my $to = $board{self.to};
	my $from = $board{self.from};
	$board{self.to} = $promotion given $board{self.from}:delete;
	return -> {
	    $board{self.to}:delete;
	    $board{self.to} = $to;
	    $board{self.from} = $from;
	}
    }
    method uint(Move::FullyDefined:) {
	self.Move::uint + (%(wn, wb, wr, wq Z=> 1..4){$promotion ≡ white ?? $promotion !! ¬$promotion} +& 7) +< 12;
    }
}

# vi: shiftwidth=4 nu
