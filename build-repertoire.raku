#!/usr/bin/env -S raku -Ilib
use DB::SQLite;
use Chess;
use Chess::GUI;
use Chess::Moves;
use Chess::Position;

constant $MOVETIME = 30_000;

sub MAIN {

    my DB::SQLite $db .= new: filename => "%*ENV<HOME>/Documents/chess.sqlite";
    my Chess::GUI $gui .= new: :terse;

    constant $random-flip-chance = .5;

    $gui.lock;

    sub find-book-move(Bool :$from-start = False) {
	with $db.query(
	    qq:to/END_SQL/
	    SELECT uci 
	    FROM lichess
	    WHERE from_hash {$from-start ?? 'is null' !! qq{= '$gui.position.uint.base(36)'}}
	    GROUP BY uci
	    ORDER BY RANDOM()*count(*)
	    DESC LIMIT 1
	    END_SQL
	).value {
	    return Move.new: $_, :color($gui.position.turn), :board($gui.position);
	}
    }
    sub opening-preference {
	with $db.query(qq[select uci from opening_preferences where from_hash = '$gui.position.uint.base(36)']).value {
	    return Move.new: $_, :color($gui.position.turn), :board($gui.position);
	}
    }

    sub reset {
        $gui.reset;
        if rand < $random-flip-chance {
            $gui.flip;
            with find-book-move :from-start {
                $gui.make-move: $_;
            }
            else { die "could not find first move!" }
        }
    }

    sleep .1 until $gui.ready;
    reset;

    my $number-of-lines = 0;
    while $gui.ready {
	last if $number-of-lines > 10;

	with opening-preference() {
	    note "An opening preference exists";
	    $gui.make-move: $_;
	} else {
	    $gui.make-move:
	    do with $db.query(qq[select bestmove from engine_results where position = '$gui.position.uint.base(36)' order by timestamp desc limit 1]).value {
		Move.new: $_;
	    } else { $gui.position.run-engine: :hostname<aldebaran>, :threads(4), :movetime(5000); }
	}

	with find-book-move() {
	    $gui.make-move: $_ 
	} else {
	    note "no book move";
	    $number-of-lines++;
	    reset;
	}

    }
    note "we're done";

}

# vi: shiftwidth=4
