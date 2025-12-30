use Chess::Board;
unit class Chess::GUI is Chess::Board;
use Raylib::Bindings;
use Chess::Position;
use Chess::Pieces;
use Chess::Colors;

# ATTRIBUTES
# ----------
has Promise $.main-loop;
has Proc::Async $.engine;
has @!undo;

multi sub await(::?CLASS $gui) is export { await $gui.main-loop; }

# CONSTANTS
# ---------
#
# square size in pixels
constant SS = 100;

# basic 2D linear algebra
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

sub draw-arrow(Square $origin, Square $destination, Bool :$flipped-board, Color :$color = init-red) {
    import Vec2;

    my Vec2 ($from, $to) = ($origin, $destination).map: { square-to-vec2 $_, :$flipped-board }
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
    draw-triangle |%points<A C B>.map({ Vector2.init(.x, .y) }), $color;
    draw-triangle |%points<B C D>.map({ Vector2.init(.x, .y) }), $color;
    draw-triangle |%points<E F G>.map({ Vector2.init(.x, .y) }), $color;
}

sub sigmoid($_) { 8*(1/(1 +exp(-0.51082569 * $_)) - 1/2) }
sub term:<DEBUG> returns Bool { with %*ENV<DEBUG> { return so /:i true/ } else { return False } }

sub draw-eval-bar(Int $evaluation, color :$turn) {
    my $height-delta = round(SS*($turn ~~ black ?? -1 !! +1)*&sigmoid($evaluation / 100));
    draw-rectangle 8*SS - 10, 0, 10, 4*SS - $height-delta, Color.init(0, 0, 0, 128);
    draw-rectangle 8*SS - 10, 4*SS - $height-delta + 1, 10, 4*SS + $height-delta, Color.init(255, 255, 255, 128);
}

# CONSTRUCTION
# ------------
#
submethod BUILD(:$engine = 'stockfish') {
    sub init-light { Color.init($_, $_, $_, 255) given 256*4 div 5 }
    sub init-dark  { Color.init($_, $_, $_, 255) given 256*3 div 5 }

    # ENGINE start
    $!engine .= new: :w, |$engine.words;
    my $engine-termination = $!engine.start.then: { note "stockfish has terminated" }
    await $!engine.ready;

    $!main-loop = start {
	LEAVE await Promise.allof: start { $!engine.say: "quit" }, $engine-termination;

	set-trace-log-level LOG_ERROR;
	if DEBUG { set-trace-log-level LOG_ALL }
	#set-config-flags FLAG_WINDOW_RESIZABLE;
	init-window(8*SS, 8*SS, "raylib chessboard");
	set-target-fps(60);
	LEAVE close-window;

	my %textures;
	constant @piece-symbols = map &Chess::Pieces::symbol, piece::{*};
	for @piece-symbols {
	    my $image = load-image("resources/images/piece/cburnett/$_.png");
	    %textures{$_} = load-texture-from-image $image;
	    unload-image $image;
	}
	LEAVE for @piece-symbols { unload-texture %textures{$_}; }

	until window-should-close {
	    ENTER begin-drawing;
	    LEAVE end-drawing;

	    state Bool $show-coordinates = False;
	    state Bool $flipped-board    = False;
	    state %grabbed-piece;

	    state Square $selected-square;

	    sub get-square(Vector2 $pos) returns Square {
		my ($x, $y) = $pos.x, $pos.y;
		return Square unless 0 ≤ $x & $y < 8*SS;
		my ($f, $r) = $x, $y Xdiv SS;
		($f, $r) .= map(7 - *) if $flipped-board;

		return square-enum::{("a".."h")[$f] ~ (1..8).reverse[$r]};
	    }

	    # draw chessboard
	    ENTER {
		#= draw chessboard
		for ^8 X ^8 -> ($i, $j) { draw-rectangle $i * SS, $j * SS, SS, SS, (($i + $j) mod 2 ?? init-dark() !! init-light); }
		if $show-coordinates {
		    for ^8 {
			draw-text
			{ $flipped-board ?? .reverse !! $_ }("a".."h")[$_],
			SS*$_ + SS div 20,
			7*SS + (SS * 3 div 4),
			SS div 5,
			(($_ mod 2) ?? init-dark() !! init-light);
			draw-text
			{ $flipped-board ?? 9 - $_ !! $_ }(8 - $_).Str,
			7*SS + (SS * 5 div 6),
			SS*$_ + SS div 20,
			SS div 5,
			(($_ mod 2) ?? init-dark() !! init-light)
			;
		    }
		}
	    }
	    # draw pieces
	    LEAVE {
		for @Chess::Board::squares -> $s {
		    my $x = file($s) * SS;
		    my $y = rank($s) * SS;
		    if $flipped-board {
			$x = 7*SS - $x;
			$y = 7*SS - $y;
		    }
		    if %grabbed-piece and $s ~~ %grabbed-piece<from><square> {
			given get-mouse-position {
			    $x += (.x - %grabbed-piece<from><mouse-position>.x).Int;
			    $y += (.y - %grabbed-piece<from><mouse-position>.y).Int;
			}
		    }
		    with self[$s] {
			draw-texture %textures{symbol $_}, $x, $y, init-white;
		    }
		}
	    }

	    with chr get-char-pressed {
		when 'f' { $flipped-board     ?^= True;                 }
		when 'c' { $show-coordinates    = !$show-coordinates    }
	    }

	    if is-cursor-on-screen {
		my $mouse-position = get-mouse-position;
		if my $square = get-square($mouse-position) {
		    set-mouse-cursor self.board[$square] ?? MOUSE_CURSOR_POINTING_HAND !! MOUSE_CURSOR_DEFAULT;

		    if is-mouse-button-up(MOUSE_BUTTON_LEFT) {
			if %grabbed-piece {
			    self.board[get-square $mouse-position] =
			    self.board[%grabbed-piece<from><square>]:delete;
			    %grabbed-piece = ();
			}
		    } elsif !%grabbed-piece and is-mouse-button-down(MOUSE_BUTTON_LEFT) {
			with self[$square] {
			    %grabbed-piece = from => %( :$mouse-position, :$square ), type => self[$square];
			}
		    }
		}
	    }
	}
    }


}


# vim: shiftwidth=4
