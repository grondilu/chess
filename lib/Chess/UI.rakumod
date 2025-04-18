use Terminal::LineEditor::RawTerminalInput;
unit class Chess::UI does Terminal::LineEditor::RawTerminalIO does Terminal::LineEditor::RawTerminalUtils;

use Chess::Graphics;
use Chess::Position;
use Chess::Board;

submethod TWEAK { self.start-decoder }

method detect-window-size {
    # see XTWINOPS in https://invisible-island.net/xterm/ctlseqs/ctlseqs.html
    my &response = rx/ ^ \e \[ 4\; (\d+) ** 2 % \; t $ /;
    self.query-terminal("\e[14t", &response).then:
    { ~.result ~~ &response ?? $0».Int !! Empty }
}

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
    use Chess::Moves;

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

    my enum State <IDLE ONE-SQUARE-IS-SELECTED PROMOTION>;
    my State $state = IDLE;
    my square ($selected-square, $promotion-square);

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
	    when 'q' { proceed if $state ~~ PROMOTION; self.set-done; done }
	    when <q b n r>.any {
		if $state ~~ PROMOTION {
		    my $move = Promotion.new: :from($selected-square), :to($promotion-square), :promotion(%( <q b r n> Z=> Queen, Bishop, Rook, Knight ){$_});
		    $position .= new: $position, $move;
		    show-position;
		    $state = IDLE;
		}
	    }
	    when Str { print "\rinput=$_\e[K" }
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
				    } elsif $position.moves(:$selected-square).map(*.LAN.substr(0,4)).any eq "$selected-square$square" {
					if $position{$selected-square} ~~ Pawn && rank($square) == PROMOTION-RANK {
					    print "\rplease type q, b, n or r to pick promotion piece\e[K";
					    $state = PROMOTION;
					    $promotion-square = $square;
					}
					else {
					    say "\rmove is $selected-square$square\e[K";
					    $position.=new: $position, Move.new: "$selected-square$square";
					    show-position;
					    $state = IDLE;
					    $selected-square = Nil;
					}
				    } else {
					$state = IDLE;
					$selected-square = Nil
				    }
				}
			    }
			}
		    }
		    elsif $state ~~ IDLE && ($position{$square}:exists) && $position{$square}.color ~~ $position.turn
			or $state ~~ ONE-SQUARE-IS-SELECTED && $square == $position.moves(:square($selected-square))».to.any 
		    { print "\e]22;hand\e\\" }
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
