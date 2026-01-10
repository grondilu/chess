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

our sub uci-to-uint(Str $uci) returns uint16 {
    constant a = 'a'.ord;
    my uint16 $uint =
	    ($uci.substr(2, 1).ord - a) + 
	    ($uci.substr(3, 1).Int - 1) +< 3 + 
	    ($uci.substr(0, 1).ord - a) +< 6 + 
	    ($uci.substr(1, 1).Int - 1) +< 9;
    if $uci.chars > 4 {
         given $uci.substr(4, 1) {
	     when 'n' { $uint += 1 +< 12; }
	     when 'b' { $uint += 2 +< 12; }
	     when 'r' { $uint += 3 +< 12; }
	     when 'q' { $uint += 4 +< 12; }
	 }
    }
    return $uint;
}
    
class Move {
    has Square ($.from, $.to);
    our subset FullyDefined of ::?CLASS where { defined .from & .to : }
    method LAN(FullyDefined:) { ($!from, $!to).map({ square-enum($_) }).fmt("%s", '') }
    method Str { self.LAN }
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
    method WHICH { self.uint.base(36) }
    method uint(FullyDefined:) {
	# http://hgm.nubati.net/book_format.html
	reduce 8 * * + *,
	7-rank($!from),
	file($!from),
	7-rank($!to),
	file($!to)
    }
    multi method new(
	Str $move where /^ <Chess::PGN::move> <annotation>? $/,
	color :$color,
	Chess::Board :$board
    ) {
	grammar :: is Chess::PGN {
	    rule TOP { <move> }
	}.parse: $move,
	    actions => class {
		method move:sym<castle>($/) {
		    with $/ {
			when 'O-O'   { make  KingsideCastle.new: :$color }
			when 'O-O-O' { make QueensideCastle.new: :$color }
		    }
		}
		method move:sym<pawn>($/) {
		    my $to = square-enum::{$<to>};
		    my &below = * + ($color ~~ white ?? +1 !! -1)*16;
		    my $from = &below($to);
		    $from = &below($from) without $board{$from};
		    $from = square-enum::{~$from};
		    die "there is no piece on $from" without $board{$from};
		    die "piece on $from is not a pawn" unless $board{$from} ~~ pawn;
		    make PawnMove.new: "$from$to" ~ ($<promotion-piece> // '');
		}
		method move:sym<LAN>($/) {
		    my ($from, $to) = <from to>.map: { square-enum::{$/{$_}} }
		    my Move $default .= new:
			    from => square-enum::{$/<from>},
			    to   => square-enum::{$/<to>}
			    ;
		    with $<promotion-piece> { make PawnMove.new: "$from$to$_" }
		    else {
			if !$board.defined || !$color.defined { make $default; }
			elsif $board{$from} ~~ pawn { make PawnMove.new: "$from$to"; }
			elsif $board{$from} ~~ ($color ~~ white ?? wk !! bk) {
			    if file($from) == 4 {
				if file($to) == 6 {
				    make KingsideCastle.new: :$color
				}
				elsif file($to) == 2 {
				    make QueensideCastle.new: :$color
				}
				else { make $default }
			    } else { make $default }
			}
			else { make $default }
		    }
		}
		method move:sym<piece>($/) {
		    my $to = square-enum::{$<to>};
		    with $<piece> {
			my $type = %(<K Q B N R> Z=> <king queen bishop knight rook pawn>){$<piece>};
			my @attackers = $board
			    .attackers(:$color, :square($to))
			    .grep({ $board{$_} ~~ Chess::Pieces::{$type} });

			if @attackers > 1 {
			    die "disambiguation needed" unless $<disambiguation>:exists;
			    given $<disambiguation> {
				when .<file> { @attackers.=grep: -> $a { file($a) == %('a'..'h' Z=> ^8){.<file>} } }
				when .<rank> { @attackers.=grep: -> $a { rank($a) == .<rank>.Int - 1 } }
				when .<square> { @attackers.=grep: -> $a { $a == .<square>.Int } }
				default {!!!}
			    }
			    die "ambiguity remains" if @attackers > 1;
			}
			if @attackers == 1 {
			    my $attacker = @attackers.pop;
			    given Chess::Pieces::{$type} {
				default {
				    my $from = $attacker;
				    make Move.new: :$from, :$to;
				}
			    }
			} else { # attackers == 0
			    die "no $type found attacking $to";
			}
		    }
		}
	    }
	fail "could not make object" unless $<move>.made ~~ Move;
	return $<move>.made;

    #`{{{
	given $/<Chess::PGN::move> -> $/ {
	    else {...}
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
    }}}
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
    multi method new(Str $ where /^(<[a..h]><[1..8]>)**2(<[QBNR]>)?$/) {
	my Square ($from, $to) = $/[0].map: { square-enum::{$_} }
	my ($delta-rank, $delta-file) = (&rank, &file).map: { abs(.($to) - .($from)) }
	my $blessing = self.bless: :$from, :$to;
	if    $delta-rank == 2 && $delta-file == 0  { return $blessing }
	elsif $delta-rank|$delta-file !== 1         { fail "illegal pawn move from $from to $to" }
	elsif file($to) !== file($from)             { $blessing does capture     }
	with $/[1]                                  { $blessing does Promotion[%(<B N R Q> Z=> bishop, knight, rook, queen){$_}] }
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

role Promotion[piece:U $promotion] is export {
    method LAN { self.Move::LAN ~ self.symbol.uc }
    method symbol { Chess::Pieces::{*}.first($promotion).&symbol.uc }
    method pseudo-SAN { self.PawnMove::pseudo-SAN ~ '=' ~ self.symbol; }
    method move-pieces(Move::FullyDefined: Chess::Board $board) {
	my $to = $board{self.to};
	my $from = $board{self.from};
	my $color = Chess::Pieces::get-color $board{self.from}:delete;
	$board{self.to} = Chess::Pieces::piece::{*}.first({
	    $_ ~~ $promotion && .&Chess::Pieces::get-color ~~ $color
	});
	return -> {
	    $board{self.to}:delete;
	    $board{self.to} = $to;
	    $board{self.from} = $from;
	}
    }
    method uint(Move::FullyDefined:) {
	self.Move::uint + (%(<N B R Q> Z=> 1..4){self.symbol} +& 7) +< 12;
    }
}

# vi: shiftwidth=4 nu
