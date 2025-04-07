unit class Chess::Stockfish is Proc::Async;
use Chess;

has Supply $!lines;

multi method new { samewith 'stockfish', :w }

submethod BUILD {
	$!lines = self.stdout.lines;
}
submethod TWEAK {
	start react {
		whenever $!lines { .note if /^info/; }
		whenever signal(SIGINT) {
			note "caught SIGINT, quitting...";
			self.quit;
			done
		}
	}
}

method set-threads(UInt $n where 1..8 --> Promise) {
	self.say: "setoption name Threads value $n";
}
method set-skill-level(UInt $skill-level where 0..20 --> Promise) {
	self.say: "setoption name Skill Level value $skill-level"
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
	
method best-move(Chess::Position :$position, UInt :$movetime = 5000 --> Promise) {
	use Chess::UCI;
	start self.say: "position fen {$position.fen}\ngo movetime $movetime";
	my Promise $best-move .= new;
	start react {
		whenever $!lines {
			if /^<Chess::UCI::best-move>/ {
				$best-move.keep: Chess::Move.new: ~$<Chess::UCI::best-move>, :$position;
				done;
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
				note "stockfish quitting.";
				done
			}
		}
		# ten second time-out before suicide
		whenever Promise.in(10) {
			self.kill
		}
	}
}

# vi: nowrap nu
