unit class Chess::GUI;
use Raylib::Bindings;
use Chess::Board;
use Chess::Position;
use Chess::Pieces;
use Chess::Colors;

# CONSTANTS
# ---------
#
# square size in pixels
constant SS = 100;

# ENUMS
# -----

our enum Events <RESET UNDO NEW-MOVE>;
enum BoardState <IDLE LOCKED PIECE-SELECTED PIECE-DRAGGED>;

# SUBCLASSES
# ----------

# basic 2D linear algebra
# Raylib::Bingings::Vector2 is a bit weird, so I'm creating a simpler class
class Vec2 {
    has Num ($.x, $.y);
    multi infix:<+>(::?CLASS $a, ::?CLASS $b) returns ::?CLASS is export { ::?CLASS.new: :x($a.x + $b.x), :y($a.y + $b.y) }
    multi infix:<->(::?CLASS $a, ::?CLASS $b) returns ::?CLASS is export { ::?CLASS.new: :x($a.x - $b.x), :y($a.y - $b.y) }
    multi infix:<*>(Real     $a, ::?CLASS $b) returns ::?CLASS is export { ::?CLASS.new: :x($a   * $b.x), :y($a   * $b.y ) }
    multi infix:</>(::?CLASS $a, Real     $b) returns ::?CLASS is export { ::?CLASS.new: :x($a.x /   $b), :y($a.y / $b   ) }
    sub norm      (::?CLASS $v) returns Num  is export { sqrt( $v.x**2 + $v.y**2 ) }
    sub normalized(::?CLASS $v) returns ::?CLASS is export { $v / norm($v) }
    sub square-to-vec2(square-enum(Cool) $sq, Bool :$flipped-board = False) returns ::?CLASS is export {
        my Num(Cool) ($x, $y) = (&file, &rank).map: { .($sq) + 1/2 }
        ($x, $y) .= map: 8 - * if $flipped-board;
        ($x, $y) .= map: * * SS;
        return ::?CLASS.new: :$x, :$y;
    }
}

class Arrow {
    use Color;
    has Square ($.origin, $.destination);
    has Instant $!then = now;
    method age { now - $!then }
    has Color $.color .= new: :rgba(128, 128, 128, 255);
    method draw(Bool :$flipped-board = False) {
	import Vec2;
	my Vec2 ($from, $to) = ($!origin, $!destination).map: { square-to-vec2 $_, :$flipped-board }
	my Vec2 $i = normalized($to - $from);
	my Vec2 $j = normalized Vec2.new: :x(-$i.y), :y($i.x);

	#               E+
	#                | \
	#  A+------------+  \
	#   |            D   \
	#   |                 +G
	#   |            C   /
	#  B+------------+  /
	#                | /
	#               F+
	my %points =
	    A => $from + (SS/4)*$j - SS/10*$i,
	    B => $from - (SS/4)*$j - SS/10*$i,
	    C => $from + norm($to - $from)*$i - 4*SS/10*$i + (SS/4)*$j,
	    D => $from + norm($to - $from)*$i - 4*SS/10*$i - (SS/4)*$j,
	    E => $from + norm($to - $from)*$i - 4*SS/10*$i - SS/2*$j,
	    F => $from + norm($to - $from)*$i - 4*SS/10*$i + SS/2*$j,
	    G => $from + norm($to - $from)*$i 
	    ;
	for <A C B>, <B C D>, <E F G> {
	    draw-triangle |%points{@$_}.map({ Vector2.init(.x, .y) }), Raylib::Bindings::Color.init: |$!color.rgba;
	}
    }
}


# ATTRIBUTES
# ----------

has Chess::Position $.position handles <AT-POS DELETE-POS> .= new;
has Promise     $.raylib;
has Supplier    $.new-move .= new;

has Arrow %!arrows;

has @!undo;
has @!history;

has Bool $!mute              = True;
has Bool $!flipped-board;
has Bool $!show-coordinates = False;
has BoardState $!board-state = IDLE;

has %!textures;

package MoveSound {
    enum name <Move Wrong Correct Check Capture>;
}
has %!sounds{MoveSound::name};

sub sigmoid($_) { 8*(1/(1 +exp(-0.51082569 * $_)) - 1/2) }
sub term:<DEBUG> returns Bool { with %*ENV<DEBUG> { return so /:i true/ } else { return False } }

# METHODS
# -------

method lock   { $!board-state = LOCKED }
method unlock { $!board-state = IDLE }

method quiet { $!mute = True }
method quit { close-window }

{
    use Color;

    method add-arrow(Str :$name = (^2**32).pick.base(36), square-enum :$from, square-enum :$to, Color :$color) {
	note "adding arrow";
	my ($origin, $destination) = $from, $to;
	%!arrows{$name} = $color ?? Arrow.new(:$origin, :$destination, :$color) !! Arrow.new(:$origin, :$destination);
    }
}
method draw-eval-bar(Int $evaluation) {
    my $height-delta = round(SS*($!position.turn ~~ black ?? -1 !! +1)*&sigmoid($evaluation / 100));
    draw-rectangle 8*SS - 10, 0, 10, 4*SS - $height-delta, Color.init(0, 0, 0, 128);
    draw-rectangle 8*SS - 10, 4*SS - $height-delta + 1, 10, 4*SS + $height-delta, Color.init(255, 255, 255, 128);
}

multi method play-sound(MoveSound::name $key) {
    with %!sounds{$key} {
	play-sound $_ if is-sound-valid $_
    }
}
multi method play-sound(:$correct!) { self.play-sound: MoveSound::Correct; }
multi method play-sound(:$wrong!  ) { self.play-sound: MoveSound::Wrong;   }

use Chess::Moves;
method make-move(Move $move) {
    my $position = $!position.uint;
    @!undo.push: $!position.make: $move;
    @!history.push: $move;
    unless $!mute {
	if $move ~~ Chess::Moves::capture {
	    self.play-sound: MoveSound::Capture;
	} else { self.play-sound: MoveSound::Move }
	self.play-sound: MoveSound::Check if $!position ~~ Check;
    }
}

method ready { is-window-ready }
method undo {
    @!undo.pop.() if @!undo;
    @!history.pop if @!history;
}
method flip { $!flipped-board ?^= True }
method reset {
    @!undo = ();
    @!history = ();
    $!position .= new;
    %!arrows = ();
    $!flipped-board = False;
    $!mute = False;
}

# CONSTRUCTION
# ------------
#
submethod BUILD {
    sub init-light { Color.init($_, $_, $_, 255) given 256*4 div 5 }
    sub init-dark  { Color.init($_, $_, $_, 255) given 256*3 div 5 }

    # arrow test
    #@!arrows.push: Arrow.new: :origin(e2), :destination(f5);
    #self.add-arrow: :from(e2), :to(e4);

    $!raylib = start {

	set-trace-log-level LOG_ERROR;
	if DEBUG { set-trace-log-level LOG_ALL }
	#set-config-flags FLAG_WINDOW_RESIZABLE;
	init-window(8*SS, 8*SS, "raylib chessboard");
	set-target-fps(60);
	LEAVE { note "closing raylib window"; close-window; }

	constant @piece-symbols = map &Chess::Pieces::symbol, piece::{*};
	for @piece-symbols {
	    my $image = load-image("resources/images/piece/cburnett/$_.png");
	    %!textures{$_} = load-texture-from-image $image;
	    unload-image $image;
	}
	LEAVE for @piece-symbols { unload-texture %!textures{$_}; }

	init-audio-device;
	given "resources/sounds" {
	    %!sounds{MoveSound::Move}    = load-sound "$_/Move.ogg";
	    %!sounds{MoveSound::Capture} = load-sound "$_/Capture.ogg";
	    %!sounds{MoveSound::Check}   = load-sound "$_/Check.mp3";
	    %!sounds{MoveSound::Correct} = load-sound "$_/correct-156911.mp3";
	    %!sounds{MoveSound::Wrong}   = load-sound "$_/wronganswer-37702.mp3";
	}
	LEAVE close-audio-device;
	LEAVE unload-sound $_ for %!sounds.values;

	until window-should-close {
	    ENTER begin-drawing;
	    LEAVE end-drawing;

	    state Bool $on-board         = False;
	    state %grabbed-piece;

	    state Vec2 $drag-offset;
	    state Square $selected-square;

	    sub get-square(Vec2 $pos) returns Square {
		my ($x, $y) = $pos.x, $pos.y;
		return Square unless 0 ≤ $x & $y < 8*SS;
		my ($f, $r) = $x, $y Xdiv SS;
		($f, $r) .= map(7 - *) if $!flipped-board;

		return square-enum::{("a".."h")[$f] ~ (1..8).reverse[$r]};
	    }
	    sub get-square-center(Square $s) returns Vec2 {
		my Num(Cool) ($x, $y) = file($s)*SS + (SS div 2), rank($s)*SS + (SS div 2);
		($x, $y) .= map: 8*SS - * if $!flipped-board;
		return Vec2.new: :$x, :$y;
	    }

	    #LEAVE draw-text $!board-state.Str, 10, 10, 100, init-red;
	    #LEAVE draw-text now.Str, 10, 111, 10, init-blue;

	    # draw chessboard
	    ENTER {
		#= draw chessboard
		for ^8 X ^8 -> ($i, $j) { draw-rectangle $i * SS, $j * SS, SS, SS, (($i + $j) mod 2 ?? init-dark() !! init-light); }
		if $!show-coordinates {
		    for ^8 {
			draw-text
			{ $!flipped-board ?? .reverse !! $_ }("a".."h")[$_],
			SS*$_ + SS div 20,
			7*SS + (SS * 3 div 4),
			SS div 5,
			(($_ mod 2) ?? init-dark() !! init-light);
			draw-text
			{ $!flipped-board ?? 9 - $_ !! $_ }(8 - $_).Str,
			7*SS + (SS * 5 div 6),
			SS*$_ + SS div 20,
			SS div 5,
			(($_ mod 2) ?? init-dark() !! init-light)
			;
		    }
		}
	    }
	    # draw arrows
	    LEAVE {
		.draw: :$!flipped-board for %!arrows.values;
		%!arrows .= grep: { .value.age < 10 }
	    }
	    # draw pieces
	    LEAVE {
		for @Chess::Board::squares -> $s {
		    my $x = file($s) * SS;
		    my $y = rank($s) * SS;
		    if $!flipped-board {
			$x = 7*SS - $x;
			$y = 7*SS - $y;
		    }
		    if $!board-state ~~ PIECE-DRAGGED && $s ~~ $selected-square {
			given get-mouse-position {
			    my $square-center = get-square-center $s;
			    $x += (.x - $drag-offset.x - $square-center.x).Int;
			    $y += (.y - $drag-offset.y - $square-center.y).Int;
			}
		    }
		    with self[$s] {
			draw-texture %!textures{symbol $_}, $x, $y, init-white;
		    }
		}
	    }

	    with $selected-square {
		my @legal-moves = $!position.moves: :square($_);
		if @legal-moves > 0 {
		    my $center = get-square-center $_;
		    draw-rectangle $center.x.UInt - (SS div 2), $center.y.UInt - (SS div 2), SS, SS, Color.init(0, 255, 0, 128);
		    for @legal-moves {
			$center = get-square-center .to;
			draw-circle $center.x.Int, $center.y.Int, SS/5e0, Color.init(0, 128, 0, 128);
		    }
		}
	    }
	    with chr get-char-pressed {
		when 'f' { self.flip }
		when 'c' { $!show-coordinates    = !$!show-coordinates    }
		when 'u' { self.undo }
		when 'r' { self.reset }
	    }

	    if is-cursor-on-screen {

		my $mouse-position = Vec2.new: :x(.x), :y(.y) given get-mouse-position;
		$on-board = so 0 ≤ ($mouse-position.x & $mouse-position.y) < 8*SS;
		my $square = get-square $mouse-position;

		# shaping cursor appropriately
		with self[$square] {
		    set-mouse-cursor Chess::Pieces::get-color($_) ~~ $!position.turn ?? MOUSE_CURSOR_POINTING_HAND !! MOUSE_CURSOR_DEFAULT;
		} else { set-mouse-cursor MOUSE_CURSOR_DEFAULT }


		my %mouse =
		    pressed      => is-mouse-button-pressed(MOUSE_BUTTON_LEFT),
		    down         => is-mouse-button-down(MOUSE_BUTTON_LEFT),
		    released     => is-mouse-button-released(MOUSE_BUTTON_LEFT);

		given $!board-state {
		    import Vec2;
		    when IDLE {
			if %mouse<pressed> && $on-board {
			    if self[$square] and Chess::Pieces::get-color(self[$square]) ~~ $!position.turn {
				$selected-square = $square;
				$!board-state = PIECE-SELECTED;
				$drag-offset = $mouse-position - get-square-center($square);
			    }
			}
		    }
		    when PIECE-SELECTED {
			if %mouse<down> && $square ~~ $selected-square && norm($mouse-position - get-square-center($square) - $drag-offset) > 20 {
			    $!board-state = PIECE-DRAGGED;
			}
			proceed;
		    }
		    default {
			if (%mouse<released> && $!board-state ~~ PIECE-DRAGGED) || (%mouse<pressed> && $!board-state ~~ PIECE-SELECTED) {
			    my @legal-moves = $!position.moves: :square($selected-square);
			    if $square ~~ @legal-moves».to.any {
				use Chess::Moves;
				my Move $move .= new: :from($selected-square), :to($square);
				my Chess::Position $position .= new: $!position.fen;
				self.make-move: $move;
				$!board-state = IDLE;
				$selected-square = Square;
				$!new-move.emit: %( :$move, :$position );
			    } else {
				note "going back to IDLE state";
				$!board-state = IDLE;
				$selected-square = Square;
			    }
			}
		    }
		}
	    }
	}
    }
}


# vim: shiftwidth=4 nu
