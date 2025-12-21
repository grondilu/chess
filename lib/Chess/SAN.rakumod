unit module Chess::SAN;
use Chess::Position;
use Chess::Moves;
use Chess::PGN;

subset SAN of Str is export where /^<Chess::PGN::SAN><[+#]>?$/;

sub stripSAN(SAN $move) { $move.subst(/<[+#]>?<[!?]>*$/, '') }
our sub getDisambiguator(Move $move, Chess::Position $position) {
    use Chess::Board;
    use Chess::Pieces;
    my Square ($from, $to) = $move.from, $move.to;
    my piece $piece = $position{$move.from};
    my UInt ($ambiguities, $sameRank, $sameFile) = 0 xx 3;
    for $position.moves {
	my $ambigFrom  = .from;
	my $ambigTo    = .to;
	my $ambigPiece = $position{.from};
	if ($piece +& 7) == ($ambigPiece +& 7) && $from !~~ $ambigFrom && $to ~~ $ambigTo {
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

proto move-to-SAN(Move $, Chess::Position $, :$without-annotations) returns SAN is export {*}
multi move-to-SAN($move, $position, :$without-annotations!) {
    my $from = $move.from;
    fail "no piece on square {$from}" without $position{$from};
    my @moves = $position.moves(:piece($position{$from}));
    fail "could not find moves in position {$position.fen}" if @moves == 0;
    do given @moves.first({ .LAN eq $move.LAN }) {
	fail "could not find move `{$move.LAN}` in position \n{$position.fen}\n{$position.ascii}"
	    unless .defined;
	when PawnMove|Castle {
	    .pseudo-SAN;
	}
	default {
	    use Chess::Pieces;  # for symbol
	    use Chess::Board;   # for square-enum
	    fail "pawn move not reckognized" if $position{$move.from} ~~ pawn and $move !~~ PawnMove;
	    symbol($position{$move.from}).uc ~
	    getDisambiguator($move, $position) ~
	    ($position{$move.to}:exists ?? 'x' !! '') ~
	    square-enum($move.to);
	}
    }
}
multi move-to-SAN($move, $position) {
    samewith($move, $position, :without-annotations) ~
    do given $position.new($move) {
	when    Checkmate { '#' }
	when    Check     { '+' }
	default              {  '' }
    }
}

sub move-from-SAN(SAN $move, $position) returns Move is export {
    $position
	.moves
	.first({ stripSAN(move-to-SAN($_, $position)) eq stripSAN($move) })
	    or fail "$move is not legal in pos {$position.fen}";
}


# vi: shiftwidth=4 nu
