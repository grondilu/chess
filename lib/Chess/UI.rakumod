use Terminal::LineEditor::RawTerminalInput;
unit class Chess::UI does Terminal::LineEditor::RawTerminalIO does Terminal::LineEditor::RawTerminalUtils;

use Chess::Graphics;
use Chess::Position;
use Chess::Board;

submethod TWEAK { self.start-decoder }

sub play-sound(Str $sound) {
    given try run <play -q ->, :in {
	.in.write: "resources/sounds/$sound.ogg".IO.slurp(:bin);
	.in.close;
    }
}
    
method input-moves(Chess::Position $from) is export {

    use Kitty;
    use Chess::Board;
    use Chess::Pieces;

    use Terminal::ANSI;

    my Chess::Position $position .= new: $from.fen;

    my $*square-size = 64;

    self.enter-raw-mode;
    LEAVE self.leave-raw-mode;

    my ($*rows, $*cols) = %*ENV<LINES COLUMNS>;
    without $*rows|$*cols { ($*rows, $*cols) = await self.detect-terminal-size; }
    my ($*window-height, $*window-width) = await self.detect-window-size;

    # save cursor position
    my @cursor = await self.detect-cursor-pos;

    hide-cursor;
    LEAVE { show-cursor; print "\e]22;\e\\" }

    my Int $z = 0;
    my UInt $placement-id = Kitty::ID-RANGE.pick;

    print "\e]22;>wait\e\\";
    # save cursor position (in terminal)
    print "\e7";
    sub show-position { 
	print "\e8";
	show $position, :$placement-id, :$z, :no-screen-measure;
	$z += 3; # supper impose next placement with some margin
    }();
    print "\e]22;<\e\\";

    my @upper-left = (@cursor[1]-1) * ($*window-width div $*cols), (@cursor[0]-1) * ($*window-height div $*rows);

    self.set-mouse-event-mode: MouseAnyEvents;
    LEAVE self.set-mouse-event-mode: MouseNoEvents;

    # SGR reporting
    print "\e[?1016h";
    LEAVE print "\e[?1016l";

    my enum State <IDLE ONE-SQUARE-IS-SELECTED>;
    my State $state = IDLE;
    my square $selected-square;

    sub select-square($square) {
	if $position{$square}:exists {
	    print Kitty::APC
	    a => 'p',
	    p => $placement-id + 70,
	    i => %Kitty::ID<green-square>,
	    P => %Kitty::ID<checkerboard>,
	    Q => $placement-id,
	    |Chess::Graphics::get-placement-parameters($square),
	    z => $z + ($position{$square} ?? 1 !! 0),
	    q => 1
	    ;
	    if $position{$square}.color ~~ $position.turn {
		my @moves = $position.moves(:$square);
		print "\r{@moves».LAN}\e[K";
		for @moves {
		    print Kitty::APC
		    a => 'p',
		    p => $placement-id + 71 + $++,
		    i => %Kitty::ID<green-circle>,
		    P => %Kitty::ID<checkerboard>,
		    Q => $placement-id,
		    |Chess::Graphics::get-placement-parameters(.to),
		    z => $z + ($position{.to} ?? 1 !! 0),
		    q => 1
		    ;
		}
	    }
	}
    }
    sub unselect-square($square) {
	print Kitty::APC a => 'd', d => 'i', p => $placement-id + 70, i => %Kitty::ID<green-square>, q => 1;
	for $position.moves(:$selected-square) {
	    print Kitty::APC a => 'd', d => 'i', q => 1,
	    i => %Kitty::ID<green-circle>,
	    p => $placement-id + 71 + $++
	    ;
	}
    }

    react {
	whenever self.decoded {
	    when 'q' { self.set-done; done }
	    when Str { print "\r$_\e[K" }
	    when MouseTrackingEvent {
		my ($x, $y) = .x, .y;
		my ($dx, $dy) = ($x, $y) Z- @upper-left;
		my ($c, $r) = ($dx, $dy) »div» $*square-size;
		if $c&$r ~~ ^8 {
		    my $square = square($r +< 4 + $c);
		    if .button.defined {
			if .button == 1 && .pressed {
			    given $state {
				when IDLE {
				    select-square $square;
				    $state = ONE-SQUARE-IS-SELECTED;
				    $selected-square = $square;
				}
				when ONE-SQUARE-IS-SELECTED {
				    use Chess::Moves;
				    unselect-square($square);
				    if $square == $selected-square {
					$state = IDLE;
					$selected-square = Nil;
				    } elsif $position.moves(:$selected-square).map(*.LAN).any eq "$selected-square$square" {
					say "\rmove is $selected-square$square\e[K";
					$position.=new: $position, Move.new: "$selected-square$square";
					show-position;
					$state = IDLE;
					$selected-square = Nil;
				    } else {
					$state = IDLE;
					$selected-square = Nil
				    }
				}
			    }
			}
		    }
		    elsif $position{$square}:exists && $position{$square}.color ~~ $position.turn { print "\e]22;hand\e\\" }
		    else { print "\e]22;not-allowed\e\\\r{.raku}\e[K" }
		} else { print "\e]22;not-allowed\e\\" }
	    }
	    default {
		print "\r{.raku}\e[K";
	    }
	}
    }

}

# vi: shiftwidth=4 nu nowrap
