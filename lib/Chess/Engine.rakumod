unit class Chess::Engine is Proc::Async;
use Chess::Moves;
use Chess::Position;

has Supply $!lines;

has Str $.command;
has Str $.name;
has UInt ($.major-version, $.minor-version);

multi method new(Str $command = 'stockfish') { self.Proc::Async::new: $command, :w }

submethod BUILD { $!lines = self.stdout.lines; }
submethod TWEAK {
    self.start;
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
		if /^ 'id name ' $<name> = [ <ident>+ ] \s $<major-version> = [ <[1..9]>\d* ] [ \. $<minor-version> = \d+ ]? / {
		    $!name = $<name>.Str;
		    $!major-version = $<major-version>.UInt;
		    $!minor-version = $<minor-version>.UInt;
		}
		elsif /^ 'id name ' $<name> = [ <ident>+ ] / { $!name = $<name>.Str; }
		elsif /^ uciok $/ {
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

method best-move(Chess::Position :$position, :@moves, UInt :$movetime = 500 --> Promise) {
    my Promise $best-move .= new;
    with $position {
	if $position.isCheckmate {
	    LEAVE $best-move.keep(Nil);
	    return $best-move;
	}
    }
    use Chess::UCI;
    start {
	my $command = "position";
	with $position { $command ~= " fen {$position.fen}"; }
	else           { $command ~= " startpos" }
	$command ~= " moves {@moves.join: q[ ]}" with @moves;
	$command ~= "\ngo movetime $movetime";
	self.say: $command;
    }
    start react {
	whenever $!lines {
	    if /^<Chess::UCI::best-move>/ {
		$best-move.keep: Move.new(~$<Chess::UCI::best-move>) / $position;
		done;
	    } elsif /'score mate ' \-?\d+/ {
		# this is forced checkmate so there's no best move
		$best-move.break("forced mate");
		done
	    }
	}
    }
    return $best-move;
}

method quit { 
    react {
	whenever self.say("stop") {
	    # give stockfish one second to give it a chance to
	    # finish any calculation
	    sleep 1;
	    whenever self.say("quit") {
		note "$!name quitting.";
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
