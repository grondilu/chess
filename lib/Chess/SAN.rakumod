unit module Chess::SAN;
use Chess::Position;
use Chess::Moves;
use Chess::PGN;

subset SAN of Str is export where /^<Chess::PGN::SAN><[+#]>?$/;

sub stripSAN(SAN $move) { $move.subst(/<[+#]>?<[!?]>*$/, '') }
our sub getDisambiguator(Move $move, Chess::Position $position) {
    use Chess::Board;
    use Chess::Pieces;
    my square ($from, $to) = $move.from, $move.to;
    my Piece $piece = $position{$move.from};
    my UInt ($ambiguities, $sameRank, $sameFile) = 0 xx 3;
    for $position.moves {
	my $ambigFrom  = .from;
	my $ambigTo    = .to;
	my $ambigPiece = $position{.from};
	if $piece.WHAT ~~ $ambigPiece.WHAT && $from !~~ $ambigFrom && $to ~~ $ambigTo {
	    $ambiguities++;
	    $sameRank++ if rank($from) == rank($ambigFrom);
	    $sameFile++ if file($from) == file($ambigFrom);
	}
    }
    if $ambiguities > 0 {
	if $sameRank & $sameFile > 0 { return ~$from; }
	elsif $sameFile > 0          { return $from.substr(1, 1); }
	else                         { return $from.substr(0, 1); }
    } else { return ''; }
}

sub move-to-SAN(Move $move, Chess::Position $position) returns SAN is export {
    do given $position.moves.first({ .LAN eq $move.LAN }) {
	when PawnMove|Castle { .pseudo-SAN }
	default {
	    $position{$move.from}.symbol.uc ~
	    getDisambiguator($move, $position) ~
	    ($position{$move.to}:exists ?? 'x' !! '') ~
	    $move.to;
	}
    } ~ do given $position.new($move) {
	when    Check     { '+' }
	when    Checkmate { '#' }
	default              {  '' }
    }
}

sub move-from-SAN(SAN $move, $position) returns Move is export {
    $position
	.moves
	.first({ stripSAN(move-to-SAN($_, $position)) eq stripSAN($move) })
	    or fail "$move is not legal in pos {$position.fen}";
}


# vi: set shiftwidth=4 nu
