unit class Chess::Moves;
use Chess::Board;
use Chess::Pieces;

class Move is export {...}
subset KnightMove of Move is export where { Knight.attacks(119 + .to - .from) };
role capture is export {}

class Promotion {...}

class Move {
    has square ($.from, $.to);
    method LAN { "$!from$!to" }
    method gist { self.LAN }
    multi method piece-type(KnightMove:) { Knight }
    method move-pieces(@board) { @board[$!to] = @board[$!from]:delete }
    multi method pseudo-SAN(capture:) {
	self.piece-type.symbol.uc ~ 'x' ~ $!to
    }
    method uint {
	# http://hgm.nubati.net/book_format.html
	reduce 8 * * + *,
	7-rank($!from),
	file($!from),
	7-rank($!to),
	file($!to)
    }
    multi method new(Str $ where /^(<[a..h]><[1..8]>)**2 <promotion=[nrbq]>? $/) {
	my square ($from, $to) = $/[0].map: { square::{.Str} };
	with $<promotion> {
	    Promotion.new: :$from, :$to, :promotion(%(<n r b q> Z=> Knight, Rook, Bishop, Queen){$<promotion>});
	} else { self.bless: :$from, :$to }
    }
    multi method new(UInt $int) {
	my $to-file   =  $int +& 0b0_000_000_000_000_111      ;
	my $to-rank   = ($int +& 0b0_000_000_000_111_000) +> 3;
	my $from-file = ($int +& 0b0_000_000_111_000_000) +> 6;
	my $from-rank = ($int +& 0b0_000_111_000_000_000) +> 9;
	my $promotion = ($int +& 0b0_111_000_000_000_000) +> 12;

	$promotion = ['', 'n', 'b', 'r', 'q'][$promotion];

	my ($from, $to) = map -> ($f, $r) { square::{['a'..'h'][$f] ~ (1 + $r)} }, ($from-file, $from-rank), ($to-file, $to-rank);
	if $promotion == 0 { return self.bless: :$from, :$to; }
	else               { return self.bless: :$from, :$to, promotion => (Piece, Knight, Bishop, Rook, Queen)[$promotion] }
    }
}

role Castle[UInt $rook-column] is Move is export {
    method piece-type { King }
    method move-pieces(@board) {
	# move the king
	self.Move::move-pieces(@board);
	# move the rook
	my $rank = rank(self.from);
	my $from = square($rank +< 4 + $rook-column);
	my $to   = square((self.from + self.to) div 2);
	@board[$to] = @board[$from]:delete
    }
}

class  KingsideCastle does Castle[7] is export { method pseudo-SAN {   'O-O' } }
class QueensideCastle does Castle[0] is export { method pseudo-SAN { 'O-O-O' } }

class PawnMove is Move is export {
    method piece-type { Pawn }
    method pseudo-SAN {
	file(self.from) == file(self.to) ?? 
	~self.to !!
	"{('a'..'h')[file(self.from)]}x{self.to}"
    }
}

class EnPassant is PawnMove is export {
    method move-pieces(@board) {
	self.Move::move-pieces(@board);
	@board[rank(self.from) +< 4 + file(self.to)]:delete;
    }
}

class Promotion is PawnMove is export {
    has Piece:U $.promotion;
    method LAN { self.Move::LAN ~ $!promotion.symbol.lc }
    method pseudo-SAN { self.PawnMove::pseudo-SAN ~ '=' ~ $!promotion.symbol.uc; }
    method move-pieces(@board) {
	@board[self.to] = $.promotion.new: :color(.color) given
	@board[self.from]:delete;
    }
}

class BigPawnMove is PawnMove is export {
    method pseudo-SAN { ~self.to }
}



# vi: shiftwidth=4 nu
