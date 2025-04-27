use Terminal::LineEditor::RawTerminalInput;
unit class Chess::UI does Terminal::LineEditor::RawTerminalIO does Terminal::LineEditor::RawTerminalUtils;

use Chess::Graphics;
use Chess::Position;
use Chess::Board;

=begin rakudoc

=head THE STATE MACHINE

Dealing with mouse and keyboard events to allow the user to enter chess moves
on a graphical board can be tricky.  It requires a rigorous state machine
implementations.

=head2 GROUND STATE

Nothing is selected, and nothing is highlighted. The user is
expected to move the mouse and click on a piece of the side whose turn it is.

=head2 A-PIECE-IS-SELECTED

One piece is selected, thus its square is highlighted. The destination
squares of all possible moves are also highlighted, albeit differently.

=head2 A-MOVE-WAS-PLAYED

similar to the ground state, except the origin and destination squares for
the previouly played move are highlighted.

=head2

=end rakudoc

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
    show $position, :$placement-id, :$z, :no-screen-measure;
    print "\e]22;<\e\\";

    my @upper-left = (@cursor[1]-1) * ($*window-width div $*cols), (@cursor[0]-1) * ($*window-height div $*rows);

    self.set-mouse-event-mode: MouseAnyEvents;
    LEAVE self.set-mouse-event-mode: MouseNoEvents;

    # SGR reporting
    print "\e[?1016h";
    LEAVE print "\e[?1016l";

    my enum State <IDLE ONE-SQUARE-IS-SELECTED PROMOTION>;
    my State $state = IDLE;
    my Square ($selected-square, $promotion-square);
    my Square $square;

    my @undo-stack;
    sub select-square($square) {
	if $position{$square}:exists {
	    @undo-stack.push:
	    Chess::Graphics::highlight-square $square, :$placement-id,
	    z => $z + ($position{$square}:exists ?? 1 !! 0);
	    if $position{$square} ≡ $position.turn {
		my @moves = $position.moves(:$square);
		@undo-stack.push:
		Chess::Graphics::highlight-moves-destinations(@moves, :$placement-id, z => $z + 1, :$position);
	    }
	}
    }
    sub unselect-square($square) { @undo-stack.pop()() while @undo-stack; }

    react {
	whenever self.decoded {
	    when 'q' { proceed if $state ~~ PROMOTION; self.set-done; done }
	    when <q b n r>.any {
		if $state ~~ PROMOTION {
		    my $move = Promotion.new: :from($selected-square), :to($promotion-square), :promotion(%( <q b r n> Z=> queen, bishop, rook, knight ){$_});
		    Chess::Graphics::make-move $move, :$position, :$placement-id, :$z;
		    $position.make: $move;
		    $state = IDLE;
		}
	    }
	    when Str { print "\rinput=$_\e[K" }
	    when MouseTrackingEvent {
		my ($x, $y) = .x, .y;
		my ($dx, $dy) = ($x, $y) Z- @upper-left;
		my ($c, $r) = ($dx, $dy) »div» $*square-size;
		if $c&$r ~~ ^8 {
		    my Square $hovered-square = $r +< 4 + $c;
		    $square //= $hovered-square;
		    if $square !== $hovered-square {
			print "\r{square-enum($square)} -> {square-enum($hovered-square)}\e[K";
			$square = $hovered-square;
		    }
		    if .button.defined {
			if .button == 1 && .pressed && !.motion {
			    given $state {
				when IDLE {
				    if $position{$square}:exists && $position{$square} ≡ $position.turn {
					select-square $square;
					$state = ONE-SQUARE-IS-SELECTED;
					$selected-square = $square;
				    }
				}
				when ONE-SQUARE-IS-SELECTED {
				    use Chess::Moves;
				    unselect-square($square);
				    my $lan = ($selected-square, $square).map({square-enum($_)}).fmt("%s", '');
				    if $square == $selected-square {
					$state = IDLE;
					$selected-square = Nil;
				    }
				    elsif $position.moves(:$selected-square).map(*.LAN.substr(0,4)).any eq $lan {
					if $position{$selected-square} ~~ pawn && rank($square) == $PROMOTION-RANK {
					    print "\rplease type q, b, n or r to pick promotion piece\e[K";
					    $state = PROMOTION;
					    $promotion-square = $square;
					}
					else {
					    print "\rmove is $lan\e[K";
					    my $move = Move.new("$lan")/$position;
					    Chess::Graphics::make-move $move, :$position, :$placement-id, :$z;
					    $position.make: $move;
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
		    elsif $state ~~ IDLE && ($position{$square}:exists) && $position{$square} ≡ $position.turn
			or $state ~~ ONE-SQUARE-IS-SELECTED && $square == $position.moves(:square($selected-square))».to.any 
		    { print "\e]22;hand\e\\" }
		    else { print "\e]22;not-allowed\e\\" }
		} else { print "\e]22;not-allowed\e\\" }
	    }
	    default {
		;
	    }
	}
    }

}

# vi: shiftwidth=4 nu nowrap
