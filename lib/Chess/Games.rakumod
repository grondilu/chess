unit module Chess::Games;
use Chess::Position;
use Chess::Moves;
use Chess::SAN;

enum Termination <white-wins black-wins draw unfinished>;

class Game {
    has Pair @.tag-pair;
    has Move @.moves;
    has Termination $.termination;

    has Chess::Position $.initial-position;

    method pgn {
	my Chess::Position @position = produce { Chess::Position.new: $^a, $^b }, Chess::Position.new, |@!moves;
	my @SAN = (@!moves Z, @position).map: -> ($a, $b) { move-to-SAN $a, $b }
	join "\n",
	@!tag-pair.map({ qq《[{.key} {.value}] 》}),
	Q{},
	join Q{ },
	|(@SAN.rotor(2, :partial).map(*.join(' ')) Z[R~] (1..* X~ Q{. })),
	%(
	    (white-wins) => '1-0',
	    (black-wins) => '0-1',
	    (draw)       => '½-½',
	    (unfinished) => '*'
	){$!termination},
	"\n"
	;
    }
}

our proto load($) returns Array[Game] {*}
multi load(Match $/) {
    # for some reason using an hyper here fails
    #hyper for $<game> -> $/ {
    #   Game.new:
    gather for $<game> -> $/ {
	my Chess::Position $position .= new;
	my Move @moves;
	for $<movetext-section><move>»<SAN> {
	    @moves.push:
		my Move $move = move-from-SAN(.Str.subst(/<[+#]>$/,'',:g), $position);
	    $position = Chess::Position.new: $position, $move;
	}
	my Termination $termination =
	    %(
		'1-0' => white-wins,
		'0-1' => black-wins,
		'1/2-1/2' => draw,
		'*' => unfinished
	    ){~$<game-termination>}
	    ;
	take Game.new:
	:tag-pair($<tag-pair-section><tag-pair>.map(-> $/ { ~$<name> => ~$<value> })),
	:@moves,
	:$termination;
    }
}
multi load(IO::Path $pgn) { samewith $pgn.slurp }
multi load(Str $pgn) { samewith Chess::PGN.parse: $pgn }

# vi: ft=raku shiftwidth=4 nu
