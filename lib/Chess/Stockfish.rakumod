unit class Chess::Stockfish is Proc::Async;
use Chess::Moves;
use Chess::Position;

has Supply $!lines;

multi method new { samewith 'stockfish', :w }

submethod BUILD { $!lines = self.stdout.lines; }
submethod TWEAK {
    start react {
	#whenever $!lines { .note if /^info/; }
	whenever signal(SIGINT) {
	    note "caught SIGINT, quitting...";
	    self.quit;
	    done
	}
    }
}

method set-threads(UInt $n where 1..8) {
    await self.say: "setoption name Threads value $n";
}
method set-skill-level(UInt $skill-level where 0..20) {
    await self.say: "setoption name Skill Level value $skill-level"
}
method start {
    my $start = self.Proc::Async::start;
    start react {
	whenever self.say: "uci" {
	    note "waiting for `uciok` from stockfish";
	    whenever $!lines { 
		if /^uciok$/ {
		    note "`uciok` received";
		    done
		}
	    }
	}
	whenever Promise.in(5) {
	    note "WARNING: quitting because `uciok` message has still not been received five seconds after command `uci`";
	    self.quit;
	    done;
	}
    }
    return $start;
}

method best-move(Chess::Position :$position, :@moves, UInt :$movetime = 10_000, :$cache? --> Promise) {
    state %cache;
    my Promise $best-move .= new;
    with $position {
	if $position.isCheckmate {
	    LEAVE $best-move.keep(Nil);
	    return $best-move;
	}
    }
    with $cache {
	with %cache{$position} { $best-move.keep($_); return $best-move }
    }
    use Chess::UCI;
    start {
	my $command = "position";
	with $position { $command ~= " fen {$position.fen}"; }
	else           { $command ~= " startpos" }
	$command ~= " moves {@moves.join: q[ ]}" if @moves;
	$command ~= "\ngo movetime $movetime";
	self.say: $command;
    }
    start react {
	whenever $!lines {
	    if /^<Chess::UCI::best-move>/ {
		$best-move.keep: my $move = Move.new: ~$<Chess::UCI::best-move>;
		%cache{$position} = $move with $cache;
		done;
	    } elsif /'score mate 0'/ {
		$best-move.keep: Nil;
		done
	    }
	}
    }
    return $best-move;
}

method self-play(UInt :$n = 10) {
    use Chess::SAN;
    my @moves = 'e2e4';

    sub white-setup {
	self.set-threads: 4;
	self.set-skill-level: 20;
    }
    sub black-setup {
	self.set-threads: 1;
	self.set-skill-level: 10;
    }
    for ^$n {
	for &black-setup, &white-setup {
	    .();
	    @moves.push: .LAN given await self.best-move: :@moves;
	}
    }

    join q{ }, (
	(1..* X~ '. ') Z~
	gather for @moves {
	    state Chess::Position $position .= new;
	    my $move = Move.new($_);
	    note $move.LAN;
	    take move-to-SAN $move, $position;
	    $position .= new: $position, $move;
	}.rotor(2, :partial)
	.map: *.join(q{ })
    )
}

method quit { 
    react {
	whenever self.say("stop") {
	    # give stockfish one second to give it a chance to
	    # finish any calculation
	    sleep 1;
	    whenever self.say("quit") {
		note "stockfish quitting.";
		done;
	    }
	}
	# ten second time-out before suicide
	whenever Promise.in(10) {
	    note "time-out!";
	    self.kill;
	    done;
	}
    }
}

# vi: nowrap nu shiftwidth=4
