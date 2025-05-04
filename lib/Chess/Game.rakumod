unit class Chess::Game;
use Chess::Position;
use Chess::Moves;

enum Termination <white-wins black-wins draw unfinished>;

enum seven-tag-roster <Event Site Date Round White Black Result>;

subset str-tag of Str where seven-tag-roster::{*}».Str.any;

proto tag-sort(Str $a, Str $b) returns Order {*}
multi tag-sort(str-tag $, $) { Less }
multi tag-sort($, str-tag $) { More }
multi tag-sort(str-tag $a, str-tag $b) { seven-tag-roster::{$a} <=> seven-tag-roster::{$b} }
multi tag-sort(Str $a, Str $b) { Order.pick }

has %.tag-pair;
has Move @.moves;
has Termination $.termination = unfinished;

multi method new(@moves where { .all ~~ /^[<[a..h]><[1..8]>]**2$/ }) {
    my Chess::Position $position .= new;
    self.new: moves =>
	my Move @ = @moves
	    .map: {
		Move.new: $_, :color($position.turn), :board($position)
	    }
}

method pgn {
    join "\n",
    %!tag-pair
    .sort({ tag-sort($^a.key, $^b.key) })
    .map({ qq《[{.key} {.value}] 》}),
    '',
    join ' ',
    |(@!moves.map(
	{
	    my Chess::Position $position .= new;
	    sub ($move) {
		use Chess::Pieces;
		use Chess::SAN;
		LEAVE $position.make: $move;
		return move-to-SAN $move, $position;
	    }
	}()
    ).rotor(2, :partial).map(*.join(' ')) Z[R~] (1..* X~ Q[. ])),
    %(
	(white-wins) => '1-0',
	(black-wins) => '0-1',
	(draw)       => '½-½',
	(unfinished) => '*'
    ){$!termination},
    "\n"
    ;
}
method positions {
    gather for @!moves -> $move {
	state Chess::Position $position .=new;
	LEAVE $position.make: $move;
	take $position.fen
    }
}

our proto load($) {*}
multi load(Match $/) {
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
