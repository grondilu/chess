unit module Chess::UI;
use Chess::Graphics;
use Chess::Position;
use Chess::Board;
use Term::termios;

use Terminal::Size;
use CSI;

our sub input-moves(Chess::Position $from) is export {
    use Kitty;
    my $saved-termios := Term::termios.new(fd => 1).getattr;
    LEAVE $saved-termios.setattr: :DRAIN;

    my $termios := Term::termios.new(fd => 1).getattr;
    $termios.makeraw;
    $termios.setattr: :DRAIN;

    # See :
    # =item `man 4 consoles_codes`
    # =item L<ANSI Escape Codes|https://gist.github.com/fnky/458719343aabd01cfb17a3a4f7296797>
    # =item L<XTerm control sequences|https://invisible-island.net/xterm/ctlseqs/ctlseqs.html>
    print join '',
    "\e7",                   # save state
    "\e[?47h\e[2J",          # save the screen and erase it
    "\e[?25l";               # make cursor invisible
    LEAVE {
	print join '',
	"\e[?25h",           # make cursor visible
	"\e[?47l",           # restore the screen
	"\e8"                # restore state
	;
    }

    # display the position
    my $placement = show $from;
    say "\rmake your moves with the mouse";
    say "\rany key to quit";

    print "\e[?1016h"; # Enable SGR mode for better precision
    print "\e[?1002h"; # Enable button-event tracking (press/release)
    print "\e[?1003h"; # Enable all mouse events (motion)
    LEAVE {
	print "\e[?1003l";
	print "\e[?1002l";
	print "\e[?1016l";
    }

    class Mouse {
	class Button {
	    has Bool $.is-pressed handles <Bool>;
	    method press   { $!is-pressed = True }
	    method release { $!is-pressed = False }
	}
	has Button ($.left, $.right);
	submethod BUILD { $!left.=new; $!right.=new }
	class Event {
	    has UInt(Cool) ($.x, $.y); 
	    method isInsideChessboard returns Bool { $!x&$!y ~~ 0..(8*$Chess::Graphics::square-size) }
	}
	class Click   is Event { }
	class Release is Event { }
	class Move    is Event { }
    }

    enum State <
	IDLE
	ONE-SQUARE-IS-SELECTED
    >;

    my $*terminal-size = terminal-size;
    my ($*window-height, $*window-width) = CSI::get-window-size;

    my Mouse $mouse .= new;
    my State $board-state = IDLE;

    my square $selected-square;

    my Supplier $mouse-and-keyboard-reporting .= new;

    start {
	use CSI;

	loop {
	    try my $csi = get-csi;
	    if $! {
		$mouse-and-keyboard-reporting.emit: CSI::Error;
		last;
	    }
	    elsif $csi ~~ / \[ <[<>]> [$<private-code> =\d+]\; [$<x> = \d+] \; [$<y> = \d+] <m=[mM]>/ {
		given $<private-code> {
		    when 35 { $mouse-and-keyboard-reporting.emit: Mouse::Move.new:  :$<x>, :$<y> }
		    when  0 {
			if $<m> eq 'M' {
			    $mouse.left.press;
			    $mouse-and-keyboard-reporting.emit: Mouse::Click.new: :$<x>, :$<y>;
			} else {
			    $mouse.left.release;
			    $mouse-and-keyboard-reporting.emit: Mouse::Release.new: :$<x>, :$<y>;
			}
		    }
		    default { $mouse-and-keyboard-reporting.emit: ~$/; }
		}
	    }
	    else { $mouse-and-keyboard-reporting.emit: "unreckognized csi {$csi.raku}" }
	}
    }

    react {
	whenever $mouse-and-keyboard-reporting {
	    when CSI::Error {
		print "non-CSI input: quitting";
		sleep .5;
		done
	    }
	    when Mouse::Event {
		my ($x, $y) = (.x, .y).map: * div $Chess::Graphics::square-size;
		my ($r, $c) = 7 - $y, $x;
		if $r & $c ~~ ^8 {
		    my $square = square::{ ('a'..'h')[$c] ~ ($r + 1) };
		    if $from{$square}.defined && $from{$square}.color == $from.turn {
			print "\r$board-state: $square -> {$from.moves(:$square)».LAN}\e[K";
			when Mouse::Click {
			    if $board-state == IDLE {
				my @moves = $from.moves(:$square);
				$board-state = ONE-SQUARE-IS-SELECTED;
				$selected-square = $square;
				print Kitty::APC
				a => 'p',
				p => $placement + 70,
				i => %Kitty::ID<green-square>,
				P => %Kitty::ID<checkerboard>,
				Q => $placement,
				|Chess::Graphics::get-placement-parameters($square),
				z => $from{$square} ?? 1 !! 0,
				q => 1
				;
				for @moves {
				    print Kitty::APC
				    a => 'p',
				    p => $placement + 71 + $++,
				    i => %Kitty::ID<green-circle>,
				    P => %Kitty::ID<checkerboard>,
				    Q => $placement,
				    |Chess::Graphics::get-placement-parameters(.to),
				    z => $from{$square} ?? 1 !! 0,
				    q => 1
				    ;
				}
			    }
			    elsif $board-state == ONE-SQUARE-IS-SELECTED {
				print Kitty::APC
				a => 'd',
				d => 'i',
				p => $placement + 70,
				i => %Kitty::ID<green-square>,
				q => 1;
				for $from.moves(:square($selected-square)) {
				    print Kitty::APC
				    a => 'd',
				    d => 'i',
				    p => $placement + 71 + $++,
				    i => %Kitty::ID<green-circle>,
				    q => 1;
				}
				if $square == $selected-square {
				    $board-state = IDLE;
				    $selected-square = square;
				} else {
				    $selected-square = $square;
				    print Kitty::APC
				    a => 'p',
				    p => $placement + 70,
				    i => %Kitty::ID<green-square>,
				    P => %Kitty::ID<checkerboard>,
				    Q => $placement,
				    |Chess::Graphics::get-placement-parameters($square),
				    z => 10,
				    q => 1
				    ;
				    for $from.moves(:$square) {
					print Kitty::APC
					a => 'p',
					p => $placement + 71 + $++,
					i => %Kitty::ID<green-circle>,
					P => %Kitty::ID<checkerboard>,
					Q => $placement,
					|Chess::Graphics::get-placement-parameters(.to),
					z => 11,
					q => 1
					;
				    }
				}
			    }
			    print "\e]22;grabbing\a";
			}
			when Mouse::Release { print "\e]22;grab\a";  }
			default { print "\e]22;hand\a"; }
		    } else { print  "\e]22;not-allowed\a\e[2K"; }
		} else { printf "\e]22;default\a"; }
	    }
	    #when Mouse::Release { print "\e]22;hand\a"; }
	    when Str {
		print "\rgot message `$_`\e[K";
	    }
	}
	# can't make the line below work for some reason
	#whenever Promise.in($time-out) { done }
    }
}


# vi: shiftwidth=4 nu nowrap
