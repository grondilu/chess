unit class Chess::Moves;
use Chess::PGN;
use Chess::Colors;
use Chess::Board;
use Chess::Pieces;

class Move is export {...}

subset KnightMove of Move is export where { grey-knight.attacks(119 + .to - .from) };
role capture is export {}

class PawnMove {...}
role EnPassant {...}
role BigPawnMove {...}
role Promotion {...}
class KingsideCastle {...}
class QueensideCastle {...}

my regex annotation { <[+#]>?<[!?]>** 0..2 }

class Move {
    has square ($.from, $.to);
    our subset FullyDefined of ::?CLASS where { defined .from & .to : }
    method LAN(FullyDefined:) { "$!from$!to" }
    method gist { self.LAN }
    multi method piece-type(KnightMove:) { knight }
    multi method move-pieces(FullyDefined: Chess::Board $board) {
	my ($from, $to) = $board{$!from, $!to};
	$board{$!to} = $board{$!from}:delete;
	return -> {
	    $board{$!from, $!to} = $from, $to;
	}
    }
    multi method pseudo-SAN(capture:) {
	self.piece-type.symbol.uc ~ 'x' ~ $!to
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
		my square $to   = square::{$<square>};
		my UInt ($file, $rank) = file($to), rank($to) + ($color ~~ white ?? 1 !! -1);
		with $<file> { $file = %( 'a'..'h' Z=> ^8 ){.Str} }
		elsif $color ~~ white && $to ~~ /4$/ or $color ~~ black && $to ~~ /5$/ {
		    my $direction = $color ~~ white ?? +16 !! -16;
		    my $from = square($to + $direction);
		    with $board{$from} { return PawnMove.new: :$from, :$to; }
		    else {
			$from = square($to + 2*$direction);
			return PawnMove.new(:$from, :$to) but BigPawnMove;
		    }
		}
		my square $from = square($rank +< 4 + $file);
		my $move = PawnMove.new(:$from, :$to);
		with $<promotion> {
		    my $promotion = %( <q b n r> Z=> queen, bishop, knight, rook ){.Str.lc};
		    $move does Promotion[$promotion];
		}
		if file($from) !== file($to) {
		    $move does capture;
		    $move does EnPassant without $board{$to};
		}
		return $move;
	    }
	    orwith $<piece-move> -> $/ {
		my $to = square::{$<square>};
		my piece-type $type = %( <N B R Q K> Z=> knight, bishop, rook, queen, king ){$<piece>};
		my square @from = $board.findSpecificAttackingPieces: :piece(Piece.new(:$type, :$color)), :$to;
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
			@from = (square::{$/.Str},);
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
		my square $from = @from.pick;
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

	my ($from, $to) = map -> ($f, $r) { square::{['a'..'h'][$f] ~ (1 + $r)} }, ($from-file, $from-rank), ($to-file, $to-rank);
	my $blessing = self.bless: :$from, :$to;
	$blessing does Promotion[(piece-type, knight, bishop, rook, queen)[$promotion]] if $promotion > 0;
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
	my $from = square($rank +< 4 + $rook-column);
	my $to   = square((self.from + self.to) div 2);
	my @record = $board{$to, $from};
	$board{$to} = $board{$from}:delete;
	return -> { $board{$to, $from} = @record; &undo1() }
    }
    multi method new(color :$color!) {
	my $rank = $color ~~ white ?? rank(e1) !! rank(e8);
	my $from = square($rank +< 4 + file(e1));
	if $rook-column > file($from) {
	    my $to = square($from + 2);
	    return KingsideCastle.bless: :$from, :$to;
	} else {
	    my $to = square($from - 2);
	    return QueensideCastle.bless: :$from, :$to;
	}
    }
}

class  KingsideCastle does Castle[7] is export { method pseudo-SAN {   'O-O' } }
class QueensideCastle does Castle[0] is export { method pseudo-SAN { 'O-O-O' } }

class PawnMove is Move is export {
    method piece-type { pawn }
    method pseudo-SAN(Move::FullyDefined:) {
	file(self.from) == file(self.to) ?? 
	~self.to !!
	"{('a'..'h')[file(self.from)]}x{self.to}"
    }
}

role EnPassant is export {
    method move-pieces(Move::FullyDefined: Chess::Board $board) {
	my &undo1 = self.Move::move-pieces($board);
	my $square = square(rank(self.from) +< 4 + file(self.to));
	my $record = $board{$square}:delete;
	return -> { $board{$square} = $record; &undo1() }
    }
}

role Promotion[piece-type $promotion] is export {
    method LAN { self.Move::LAN ~ symbol($promotion).lc }
    method pseudo-SAN { self.PawnMove::pseudo-SAN ~ '=' ~ $promotion.symbol.uc; }
    method move-pieces(Move::FullyDefined: Chess::Board $board) {
	$board{self.to} = Piece.new(:type($promotion),:color(.color)) given $board{self.from}:delete;
    }
    method uint(Move::FullyDefined:) {
	self.Move::uint + %(
	    knight, bishop, rook, queen Z=> 1..4
	){$promotion} +< 12;
    }
}

role BigPawnMove is export {}



# vi: shiftwidth=4 nu
