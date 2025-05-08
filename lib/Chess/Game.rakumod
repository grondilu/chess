unit class Chess::Game;

enum Termination <white-wins black-wins draw unfinished>;

enum seven-tag-roster <Event Site Date Round White Black Result>;

subset str-tag of Str where seven-tag-roster::{*}».Str.any;

subset LAN of Str where /^ [<[a..h]><[1..8]>]**2 <[qbnr]>? $/;

proto tag-sort(Str $a, Str $b) returns Order {*}
multi tag-sort(str-tag $, $) { Less }
multi tag-sort($, str-tag $) { More }
multi tag-sort(str-tag $a, str-tag $b) { seven-tag-roster::{$a} <=> seven-tag-roster::{$b} }
multi tag-sort(Str $a, Str $b) { Order.pick }

has %.tag-pair;
has LAN @.moves;
has Termination $.termination = unfinished;

multi method new(@moves where { .all ~~ LAN }) {
    self.new: moves => my LAN @ = @moves
}

sub square-to-coord($square) {
    # Convert algebraic square (e.g., 'e2') to (row, col).
    my ($file, $rank) = $square.comb(/./);
    my $col = ord($file) - ord('a');  # 0 to 7
    my $row = 8 - $rank;              # rank 1 → row 7, rank 8 → row 0
    return $row, $col
}

sub coord-to-square($row, $col) {
    # Convert (row, col) to algebraic square (e.g., (6, 4) → 'e2').
    my $file = chr(ord('a') + $col);
    my $rank = (8 - $row).Str;
    return $file ~ $rank;
}

sub long-to-standard(*@moves) {
    # Initial chess board
    constant @initial-board = 
	< r n b q k b n r >,
	< p p p p p p p p >,
	< . . . . . . . . >,
	< . . . . . . . . >,
	< . . . . . . . . >,
	< . . . . . . . . >,
	< P P P P P P P P >,
	< R N B Q K B N R >
    ;
    # Convert list of moves from long algebraic to standard algebraic notation.
    my @board[8;8] = (.<> for @initial-board<>);
    my $en-passant-square;
    gather for @moves -> $move {
	my ($from-square, $to-square, $promotion);
	given $move.chars {
	    when 4 { ($from-square, $to-square, $promotion) = $move.substr(0,2), $move.substr(2,2), Nil; }
	    when 5 { ($from-square, $to-square, $promotion) = $move.substr(0,2), $move.substr(2,2), $move.substr(4,1).uc; }
	    default { fail "Invalid move length: $_" }
	}
	my ($from-row, $from-col) = square-to-coord $from-square;
	my (  $to-row,   $to-col) = square-to-coord   $to-square;
	my $piece = @board[$from-row;$from-col];
	fail "no piece on $from-square for move $move" if $piece eq '.';
        # Determine standard notation and update board
	if $piece.uc eq 'K' and abs($to-col - $from-col) == 2 {
	    # Castling
	    take $to-col == 6 ?? 'O-O' !! 'O-O-O';
	    if $piece eq 'K' { # White
		@board[7;4] = '.';
		@board[7;$to-col] = 'K';
		if $to-col == 6 { # Kingside
		    (@board[7;7], @board[7;5]) = < . R >;
		}
		else { # Queenside
		    (@board[7;0], @board[7;3]) = < . R >;
		}
	    }
	    else { # Black
		@board[0;4] = '.';
		@board[0;$to-col] = 'k';
		if $to-col == 6 {
		    (@board[0;7], @board[0;5]) = < . r >;
		}
		else { # Queenside
		    (@board[0;0], @board[0;3]) = < . r >;
		}
	    }
	    $en-passant-square = Nil;
	}
	elsif $piece.uc eq 'P' { # Pawn
	    my $from-file = $from-square.substr(0, 1);
	    my $to-file   =   $to-square.substr(0, 1);
	    if $from-file eq $to-file {
		# Non-capture
		take $to-square ~ ($promotion.defined ?? "=$promotion" !! '');
	    }
	    else {
		# Capture (normal or en-passant)
		if @board[$to-row;$to-col] ne '.' or $to-square eq $en-passant-square {
		    take
			($from-file ~ 'x' ~ $to-square) ~
			($promotion.defined ?? "=$promotion" !! '');
		    # Handle en passant
		    with $en-passant-square {
			when $to-square { @board[$from-row;$to-col] = '.' }
		    }
		}
		else { fail "Invalid pawn capture: $move" }
	    }
	    @board[$from-row;$from-col] = '.';
	    @board[$to-row;$to-col] = $piece without $promotion;
	    @board[$to-row;$to-col] = $piece eq 'P' ?? .uc !! .lc with $promotion;
            # Update en passant square
	    if $piece eq 'P' and $from-row == 6 and $to-row == 4 {
		$en-passant-square = coord-to-square 5, $from-col;
	    }
	    elsif $piece eq 'p' and $from-row == 1 and $to-row == 3 {
		$en-passant-square = coord-to-square 2, $from-col;
	    }
	    else { $en-passant-square = Nil }
	}
	else {
	    my $piece-letter = $piece.uc;
	    take (
		$piece-letter,
		@board[$to-row;$to-col] ne '.' ?? 'x' !! '',
		$to-square
	    ).join;
	    @board[$from-row;$from-col] = '.';
	    @board[$to-row;$to-col] = $piece;
	    $en-passant-square = Nil;
	}
    }
}

method pgn {

    join "\n",
    %!tag-pair
    .sort({ tag-sort($^a.key, $^b.key) })
    .map({ qq《[{.key} {.value}] 》}),
    '',
    join ' ',
    |(long-to-standard(|@!moves).rotor(2, :partial).map(*.join(' ')) Z[R~] (1..* X~ Q[. ])),
    %(
	(white-wins) => '1-0',
	(black-wins) => '0-1',
	(draw)       => '½-½',
	(unfinished) => '*'
    ){$!termination},
    "\n"
    ;
}

our proto load($) {*}
multi load(Match $/) {
    use Chess::Position;
    use Chess::Moves;
    # for some reason using an hyper here fails
    #hyper for $<game> -> $/ {
    #   Game.new:
    gather for $<game> -> $/ {
	my Chess::Position $position .= new;
	my Move @moves;
	for $<movetext-section><move> -> $/ {
	    my Move $move .= new: ~$<SAN>, :color($position.turn), :board($position);
	    @moves.push: $move;
	    $position.make: $move;
	}
	my Termination $termination =
	    %(
		'1-0' => white-wins,
		'0-1' => black-wins,
		'1/2-1/2' => draw,
		'*' => unfinished
	    ){~$<game-termination>}
	    ;
	my %tag-pair = $<tag-pair-section><tag-pair>.map(-> $/ { Pair.new: ~$<name>, ~$<value> } );
	take ::?CLASS.new: :%tag-pair, :@moves, :$termination;
    }
}
multi load(IO::Path $pgn) { samewith $pgn.slurp }
multi load(Str $pgn) { samewith Chess::PGN.parse: $pgn }

# vi: ft=raku shiftwidth=4 nu nowrap
