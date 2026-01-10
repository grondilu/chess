use DB::SQLite;
use Chess::PGN;

constant $plylimit = 48;

sub MAIN($pgn-filename where /lichess .* \.pgn$/) {
	print "\e7";

	die "$pgn-filename does not exist" unless $pgn-filename.IO.e;

	my DB::SQLite $db-connection .= new: filename => "%*ENV<HOME>/Documents/chess.sqlite";

	my $db = $db-connection.db;
	my $sth = $db.prepare: q{INSERT INTO lichess (from_hash, to_hash, uci, ply, url_code) values (?, ?, ?, ?, ?)};

	
	given run(|qqww[pgn-extract --plylimit $plylimit --hashcomments --nocomments -Wuci "$pgn-filename"], :out, :err(q{/dev/null}.IO)) {
		my token zobrist-hash { <.xdigit>**1..16 }
		my $url_code;
		LEAVE .out.close;
		gather for .out.lines {
			LAST print "\n";
			when /^$/ { next }
			when /^ '[LichessURL "https://lichess.org/' (<alnum>+) / { $url_code = $/[0].Str; }
			when /^ :s [ <Chess::PGN::move> '{' ~ '}' <zobrist-hash> ]+ <Chess::PGN::game-termination> $/ {
				if $url_code.defined {
					my @moves = $<Chess::PGN::move>».Str;
					my @from-hash = Nil, |$<zobrist-hash>.head(*-1).map: *.Str.parse-base(16).base(36);
					my @to-hash   = $<zobrist-hash>».Str.map: *.parse-base(16).base(36);

					for @moves Z @from-hash Z @to-hash Z 1..* -> ($uci, $from_hash, $to_hash, $ply) {
						print "\e8\e[0J";
						printf "%16s %16s %5s %3d %s\n", ($from_hash // ''), $to_hash, $uci, $ply, $url_code;
						take Array.new: $from_hash, $to_hash, $uci, $ply, $url_code;
						LAST $url_code = Nil;
					}
				}
			}
		}.rotor(100_000, :partial)
		.map:
		{
			print "\e8\e[0JBeginning transaction...";
			$db.begin;
			$sth.execute: .list for .list;
			$db.commit;
			put "done";
			note "sleeping two minutes";
			sleep 120;
		}
	}
	$db.finish;

}
