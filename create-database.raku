use DB::SQLite;
use Chess;
use Chess::PGN;

sub MAIN($pgn-filename where /'.pgn'$/) {

	my $sqlite-filename = $pgn-filename.subst(/'.pgn'$/, '.sqlite');
	fail "$sqlite-filename already exists" if $sqlite-filename.IO.e;

	my DB::SQLite $db-connection .= new; #: filename => $sqlite-filename;

	$db-connection.execute: q:to/END_SQL/;
		CREATE TEMP TABLE temp_moves (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			from_hash  TEXT,
			to_hash    TEXT NOT NULL,
			xolalg     TEXT NOT NULL
		);
		END_SQL

	die "$pgn-filename does not exist" unless $pgn-filename.IO.e;

	die "could not parse normal PGN" unless Chess::PGN.parse: run(|qqww[pgn-extract "$pgn-filename"], :out, :err(q{/dev/null}.IO)).out.slurp(:close);
	die "could not parse lalg   PGN" unless Chess::PGN.parse: run(|qqww[pgn-extract -Wlalg   "$pgn-filename"], :out, :err(q{/dev/null}.IO)).out.slurp(:close);
	die "could not parse xolalg PGN" unless Chess::PGN.parse: run(|qqww[pgn-extract -Wxolalg "$pgn-filename"], :out, :err(q{/dev/null}.IO)).out.slurp(:close);


	my $db = $db-connection.db;
	my $sth = $db.prepare: q{INSERT INTO temp_moves (from_hash, to_hash, xolalg) values (?, ?, ?)};

	print "\e7";
	my $games = 0;
	gather {
	unless grammar :: is Chess::PGN {
		rule comment { '{' ~ '}' <zobrist-hash> }
		token zobrist-hash { <xdigit>**1..16 }
	}.parse:
		run(|qqww[pgn-extract --hashcomments -Wxolalg "$pgn-filename"], :out, :err(q[/dev/null])).out.slurp(:close),
		actions => class {
			has @!zobrist-hash = constant null = Nil but role { method Str { '' } };
			method game($/) {
				print "\e8\e[0J$<tag-pair-section>";
				my @moves = $<movetext-section><annotated-move>»<move>.map: *.Str;
				my @from-hash = @!zobrist-hash.head(*-1);
				my @to-hash   = @!zobrist-hash.tail(*-1);
				for @from-hash Z @to-hash Z @moves -> ($from, $to, $move) {
					take $($from, $to, $move);
					#put "$move: $from → $to";
				}
				@!zobrist-hash = null;
			}
			method zobrist-hash($/) { @!zobrist-hash.push: $/.Str.parse-base(16).base(36) }
			#method move:sym<LAN>   ($/) { put "LAN: $/" }
			#method move:sym<SAN>   ($/) { put "SAN: $/" }
			#method move:sym<XOLALG>($/) { put "XOLALG: $/" }
		}.new
		{ fail "Could not parse $pgn-filename, only $games games were parsed" }
	}.rotor(1_000, :partial)
	.map:
		{
			$db.begin;
			$sth.execute: .list for .list;
			$db.commit;
		}
	
	$db.finish;

	print "\e8\e[0J";

	$db-connection.execute: q:to/END_SQL/;
		CREATE TABLE moves AS
		SELECT from_hash, to_hash, xolalg, count(*) as count
		FROM temp_moves
		GROUP BY from_hash, to_hash, xolalg
		END_SQL

	.say for $db-connection.query(q{select * from moves order by count desc limit 100}).arrays;
	
}


