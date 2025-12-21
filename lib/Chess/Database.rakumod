use DB::SQLite;
unit class Chess::Database is DB::SQLite;

constant %name-disambiguation = 
	Adams          => rx/ Adams\,\s?Mi /,
	Carlsen        => rx/ Carlsen\,\s?M[agnus]? /,
	Lasker         => rx/ Lasker\,\s?Em /,
	Morphy         => rx/ "Morphy, Paul" /,
	So             => rx/ [ '"So,' ] | Westley /,
	Short          => rx/ Short\,\s?N /,
	Sokolov        => rx/ Sokolov\,\s?I /,
	Korchnoi       => rx/ Kortschnoj | Korchnoi /,
	VachierLagrave => rx/ Vachier<[\-\s]>Lagrave /,
	VallejoPons    => rx/ "Vallejo Pons" /
;

submethod TWEAK {

	my %PGN;

	self.execute: q:to/END_SQL/;
	CREATE TABLE IF NOT EXISTS pgn_sources (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		sha1_sum TEXT NOT NULL UNIQUE,
		filename TEXT
	);
	END_SQL

        self.execute: q:to/END_SQL/;
        CREATE TABLE IF NOT EXISTS games (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                source_id INTEGER NOT NULL,
                start_offset      INTEGER,            -- offset in the source PGN file for the beginning of the game
                end_offset        INTEGER,            -- offset in the source PGN file for the end of the game
                event TEXT,
                site  TEXT,
                date  TEXT,
                round TEXT,
                white TEXT,
                black TEXT,
                result TEXT,
                moves  TEXT,
                FOREIGN KEY(source_id) REFERENCES pgn_sources(id) ON DELETE CASCADE
        );
        END_SQL

	my $pgn_sources_insert = self.db.prepare: q:to/END_SQL/;
	INSERT OR IGNORE INTO pgn_sources (sha1_sum, filename) VALUES (?, ?);
	END_SQL
	for <
		Abdusattorov Adams Akobian Alekhine Anand Bacrot Bird Blackburne
		Bogoljubow Botvinnik Bronstein Capablanca Carlsen Caruana Chigorin
		Evans Finegold Firouzja Fischer Giri Ivanchuk Karjakin Karpov Kasparov
		Korchnoi Kramnik Lasker Maroczy Marshall Mikenas Morozevich Morphy
		Najdorf Nakamura Navara Nepomniachtchi Nimzowitsch Nunn Petrosian
		Philidor Rapport Reti Rubinstein Saemisch Seirawan Shirov Short Smyslov
		Sokolov So Spassky Spielmann Steinitz Svidler Tal Tarrasch Tartakower
		Tomashevsky Topalov VachierLagrave VallejoPons Winawer
	> -> $master {
		use Digest::SHA1::Native;
		my $pgn = (%?RESOURCES{"masters/$master.pgn"} // qq{resources/masters/$master.pgn}.IO).slurp(:bin);
		my $sha1 = sha1-hex $pgn;
		%PGN{$sha1} = $pgn.decode;
		$pgn_sources_insert.execute: $sha1, "$master.pgn";
	}
	$pgn_sources_insert.finish;

	class Parser is Channel {
		use Chess::Position;
		use Chess::Colors;
		has Str $.filename;
		has color $!master-color;
		has Chess::Position $!position .= new;

		method tag-pair($/) {
			my $master = $!filename.subst: /'.pgn'/, '';
			if $<name> eq 'White'|'Black' && $<value> ~~ (%name-disambiguation{$master} // /$master/) {
				unless $master & $<value> ~~ /Karpov/ {
					die "ambiguous name" if $!master-color.defined;
				}
				$!master-color = $<name> eq 'White' ?? white !! black;
			}
			make ~$<name> => $<value>.Str.subst: /[^\"]|[\"$]/, '', :g;
		}
		method tag-pair-section($/) { make %( $<tag-pair>».made.grep: { .value ne '' } ) }
		method game-termination($/) { $!position .= new; $!master-color = color; }
		method game($/) {
			$/.make: %(
				tags => $<tag-pair-section>.made,
				moves => $<movetext-section>.Str.lines.join(' '),
			);
			self.send: $/;
		}
		method move($/) { make $<SAN>.made }
		method SAN($/) {
			use Chess::Moves;
			my Move $move .=new: $/.Str, :color($!position.turn), :board($!position);
			LEAVE $!position.make: $move;
			make %( :$move, :$!position, :$!master-color );
		}
		method TOP($/) { self.close }
	}
        my @sources = self.query(q{select filename, sha1_sum, id from pgn_sources}).arrays;


	my $game-insert = self.db.prepare: q:to/END_SQL/;
	INSERT OR IGNORE INTO games (source_id, start_offset, end_offset, event, site, date, round, white, black, result, moves)
                             VALUES (        ?,            ?,          ?,     ?,    ?,    ?,     ?,     ?,     ?,      ?,     ?);
	END_SQL
	for @sources {
                self.db.begin;

		use Chess::PGN;

		my ($filename, $sha1_sum, $id) = .list;

		my Parser $parser .= new: :$filename;
		my $parsing = start Chess::PGN.parse: %PGN{$sha1_sum}, actions => $parser;

		for $parser.list {
			print "\e7\e[0J";
			put "source_id $id";
			put "start_offset {.from}";
			put "end_offset {.to}";
			put .made<tags><Event Site Date Round White Black Result>.map({qq{"$_"}});
			put .made<moves>;
			print "\e8";
                        my @args = $id, .from, .to, |.made<tags><Event Site Date Round White Black Result>, .made<moves>;
                        $game-insert.execute: @args;
		}

                await $parsing;
                self.db.commit;

	}
        $game-insert.finish;

}

CHECK {
	my ::?CLASS $db .= new: filename => ':memory';
}
