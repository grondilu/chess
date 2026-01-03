#!/usr/bin/env -S raku -Ilib
use DB::SQLite;
use Chess;
use Chess::GUI;
use Chess::Moves;
use Chess::Position;
use Chess::Book;

constant $MOVETIME = 30_000;

sub MAIN($filename = q{repertoire.db}, :$polyglot-book = q{opening-book.polyglot}) {

	my Chess::GUI $gui .= new;
	die "$polyglot-book does not exist"  unless $polyglot-book.IO.e;
	die "$polyglot-book is not readable" unless $polyglot-book.IO.r;
	my Chess::Book $book .= new: $polyglot-book.IO;

	my DB::SQLite $db  .= new: :$filename;

	unless $filename.IO.e {

		$db.execute: q:to/END_SQL/;
		CREATE TABLE chosen_moves(
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			position STRING UNIQUE,
			move     INTEGER
		);
		END_SQL

		# Opening preferences
		# ===================

		# 1.e4
		$db.query: 'insert into chosen_moves (position, move) values (?, ?)',
		startpos.uint.base(36),
		Move.new("e2e4").uint
		;

		# Ruy Lopez and open sicilian
		for
		([*] startpos, |<e4 e5>) => "g1f3",
		([*] startpos, |<e4 e5 Nf3 Nc6>) => "f1b5",
		([*] startpos, |<e4 c5 Nf3 Nc6>) => "d2d4"
		{
			$db.query: 'insert into chosen_moves (position, move) values (?, ?)',
			.key.uint.base(36),
			Move.new(.value).uint
			;
		}


	}

	my $stockfish = run 'stockfish', :in, :out;
	$stockfish.in.say: "setoption name Threads value 8";

	sub term:<best-move> returns Move {
		with $db.query('select move from chosen_moves where position = ?', $gui.position.uint.base(36)).value {
			my Move $move .= new: $_;
			note "found move {$move.LAN} in database";
			return $move;
		} else {
			given $stockfish {
				.in.say: "position fen {$gui.position.fen}";
				.in.say: "go movetime $MOVETIME";
				for .out.lines {
					when /:sigspace ^bestmove ([<[a..h]><[1..8]>]**2<[QBNR]>?)/ {
						say "FOUND BEST MOVE! {$/[0]}";
						my Move $move .= new: $/[0].Str;
						$db.query: 'insert into chosen_moves (position, move) values (?, ?)',
						$gui.position.uint.base(36),
						$move.uint;
						return $move;
					}
					when /^'bestmove (none)'/ {
						return Move
					}
					default { .note }
				}
			}
		}
	}

	sub term:<search-book> returns Bag {
		with $book{$gui.position} {
			return .map({ .<move> => .<weight> }).Bag
		} else { return Bag.new }
	}

	sub reset {
		$gui.reset;
		$gui.quiet;
		if rand < .5 {
			$gui.flip;
			$gui.make-move: search-book.pick;
		}
	}

	sleep 1 unless $gui.ready;
	reset;
	start loop {
		unless $gui.ready {
			note "GUI is not ready for some reason";
			last;
		}
		my $move = best-move;
		$gui.make-move: $move;
		my $book-search = search-book;
		if $book-search.elems == 0 {
			note "no book move at all!";
			reset;
		} elsif $book-search.values.all == 0 {
			note "all weights are zero!";
			reset;
		} else { $gui.make-move: $book-search.pick; }
	}

	await Promise.anyof(
		$gui.raylib,
		signal(SIGINT).Promise
	)
	.then({ $stockfish.in.say("stop") })
	.then({ $stockfish.in.say("quit") })
	.then({ $stockfish.out.slurp: :close })
	.then({ $stockfish.in.close })
	.then({ say "stockfish closed" })
	;

}
