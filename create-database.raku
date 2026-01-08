use DB::SQLite;
use Chess;
use Chess::PGN;

sub MAIN($pgn-filename where /'.pgn'$/) {
	print "\e7";

	my $sqlite-filename = $pgn-filename.subst(/'.pgn'$/, '.sqlite');
	fail "$sqlite-filename already exists" if $sqlite-filename.IO.e;

	my DB::SQLite $db-connection .= new: filename => $sqlite-filename;

	$db-connection.execute: q:to/END_SQL/;
		CREATE TEMP TABLE temp_moves (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			from_hash  TEXT,
			to_hash    TEXT NOT NULL,
			uci        TEXT NOT NULL
		);
		END_SQL

	die "$pgn-filename does not exist" unless $pgn-filename.IO.e;

	my $db = $db-connection.db;
	my $sth = $db.prepare: q{INSERT INTO temp_moves (from_hash, to_hash, uci) values (?, ?, ?)};

	my $pgn-extract = run(|qqww[pgn-extract --notags --hashcomments -Wuci "$pgn-filename"], :out, :err(q{/dev/null}.IO));
	gather for $pgn-extract.out.lines -> $line {
		next if $line ~~ /^$/;

		print "\e8";
			die "oops: could not parse '$line' " unless parse grammar :: is Chess::PGN {
				rule TOP { [ <move> <zobrist-hash> ]* <game-termination> }
				token zobrist-hash { <.xdigit>**1..16 }
			}: $line.subst(/<[{}]>/, '', :g), actions => class {

				method TOP($/) {
					print join ' ', $<move>;
					print "\e[0J";
					my @moves = $<move>».Str;
					my @from-hash = Nil, |$<zobrist-hash>.head(*-1)».Str.map: *.parse-base(16).base(36);
					my @to-hash   = $<zobrist-hash>».Str.map: *.parse-base(16).base(36);
					for @from-hash Z @to-hash Z @moves -> ($from, $to, $move) {
						take $($from, $to, $move);
					}
				}

			};
		LAST print "\n";
	}.rotor(100_000, :partial)
	.map:
		{
			print "\e8\e[0JBeginning transaction...";
			$db.begin;
			$sth.execute: .list for .list;
			$db.commit;
			put " done";
		}
	
		$db.finish;
	$pgn-extract.out.close;

	$db-connection.execute: q:to/END_SQL/;
		CREATE TABLE moves AS
		SELECT from_hash, to_hash, uci, count(*) as count
		FROM temp_moves
		GROUP BY from_hash, to_hash, uci
		END_SQL

	#.say for $db-connection.query(q{select from_hash, to_hash from temp_moves group by from_hash, to_hash having count(distinct uci) > 1}).arrays;

}
