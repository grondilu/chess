unit module Chess;
# translated from https://github.com/jhlywa/chess.js.git
#`{{{ ORIGINAL LICENSE
Copyright (c) 2025, Jeff Hlywa (jhlywa@gmail.com)
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice,
this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
}}}
use Chess::PGN;
use Chess::FEN;
use Chess::Graphics;

use Kitty;
use Term::termios;
use Terminal::Size;

class Move     {...}
class PawnMove {...}
class BigPawnMove {...}
class EnPassant {...}
class Promotion {...}
class KingsideCastle {...}
class QueensideCastle {...}
class Position {...}

sub term:<startpos> is export { Position.new }

enum color is export <white black>;
sub prefix:<¬>(color $color --> color) { $color ~~ white ?? black !! white }

# https://en.wikipedia.org/wiki/0x88
enum square is export ((([1..8] .reverse) X[R~] 'a'..'h') Z=> ((0, 16 ... *) Z[X+] ^8 xx 8).flat);
our sub rank(square $sq) { $sq +>  4 }
our sub file(square $sq) { $sq +& 15 }

constant %SECOND-RANK = (white) => rank(a2), (black) => rank(a7);
constant PROMOTION-RANK = rank(a1)|rank(a8);

# https://www.w3.org/TR/png/#3PNGsignature
constant PNG-SIGNATURE = Blob.new: 137, 80, 78, 71, 13, 10, 26, 10;

constant $square-size = 60;

subset SAN of Str is export where /^<Chess::PGN::SAN>$/;

multi infix:<*>(Position $position, SAN $move --> Position) is export { Move.new($move, :$position).after }

subset en-passant-square of square where /<[36]>$/;

enum castling-rights <kingside queenside>;

role Piece { method symbol { 'Ø' } }
role Piece[Str $symbol, UInt $mask] {
  has color $.color;
  method attacks($index) { 
    (BEGIN blob8.new(
      20, 0, 0, 0, 0, 0, 0, 24, 0, 0, 0, 0, 0, 0, 20, 0, 0, 20, 0, 0,
      0, 0, 0, 24, 0, 0, 0, 0, 0, 20, 0, 0, 0, 0, 20, 0, 0, 0, 0, 24, 0, 0,
      0, 0, 20, 0, 0, 0, 0, 0, 0, 20, 0, 0, 0, 24, 0, 0, 0, 20, 0, 0, 0, 0,
      0, 0, 0, 0, 20, 0, 0, 24, 0, 0, 20, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 20,
      2, 24, 2, 20, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 53, 56, 53, 2, 0, 0,
      0, 0, 0, 0, 24, 24, 24, 24, 24, 24, 56, 0, 56, 24, 24, 24, 24, 24, 24,
      0, 0, 0, 0, 0, 0, 2, 53, 56, 53, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      20, 2, 24, 2, 20, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 20, 0, 0, 24, 0, 0, 20,
      0, 0, 0, 0, 0, 0, 0, 0, 20, 0, 0, 0, 24, 0, 0, 0, 20, 0, 0, 0, 0, 0, 0,
      20, 0, 0, 0, 0, 24, 0, 0, 0, 0, 20, 0, 0, 0, 0, 20, 0, 0, 0, 0, 0, 24,
      0, 0, 0, 0, 0, 20, 0, 0, 20, 0, 0, 0, 0, 0, 0, 24, 0, 0, 0, 0, 0, 0, 20
    ))[$index] +& $mask
  }
  method offsets {...}
  multi method symbol(Piece:D:) { ($!color ~~ white ?? *.uc !! *.lc)($symbol) }
  multi method symbol(Piece:U:) { $symbol }
  multi method gist(::?CLASS:D:) { $!color ~ " " ~ %(:p<pawn>, :n<knight>, :b<bishop>, :r<rook>, :q<queen>, :k<king>){$symbol} }
  multi method gist(::?CLASS:U:) { %(:p<pawn>, :n<knight>, :b<bishop>, :r<rook>, :q<queen>, :k<king>){$symbol} }
}

class ActualPiece {}
class Pawn   is ActualPiece does Piece['p',  1] {
    method offsets { (constant @ = 16, 32, 17, 15).map: * * ($.color == white ?? -1 !! +1) }
}
class Knight is ActualPiece does Piece['n',  2] { method offsets { constant @ = -18, -33, -31, -14, 18, 33, 31, 14 } }
class Bishop is ActualPiece does Piece['b',  4] { method offsets { constant @ = -17, -15, 17, 15 }  }
class Rook   is ActualPiece does Piece['r',  8] { method offsets { constant @ = -16, 1, 16, -1 } }
class Queen  is ActualPiece does Piece['q', 16] { method offsets { constant @ = -17, -16, -15, 1, 17, 16, 15, -1 } }
class King   is ActualPiece does Piece['k', 32] { method offsets { constant @ = -17, -16, -15, 1, 17, 16, 15, -1 } }

class Position {
    trusts Move;
    has Piece @!board[128];
    method !board { @!board }

    method board {
	do for square::{*}.sort(*.value).rotor(8) -> @row {
	    do for @row -> $i {
		if !@!board[$i].defined {
		    Any
		} else {
		    $i => @!board[$i]
		}
	    }.Array
	}.Array
    }

    has square %.kings{color};
    has color $.turn;
    has Set[castling-rights] %.castling-rights{color};
    has en-passant-square $.en-passant;
    has UInt ($.half-moves-count, $.move-number);

    has Move $.last-move;
    multi method new(*@moves where @moves.all ~~ SAN, Position :from($startpos) = startpos) {
	reduce -> $position, $move { Move.new($move, :$position).after }, $startpos, |@moves;
    }
    multi method new(Str $fen = q{rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1}) {
	use Chess::FEN;
	my square %kings{color};
	my Piece @board[128];
	my color $turn;
	my Set[castling-rights] %castling-rights{color};
	my en-passant-square $en-passant;
	my UInt ($half-moves-count, $move-number);
	my Move $last-move;
	Chess::FEN.parse:
	$fen,
	actions => class {
	    has Int $!r = 0;
	    has Int $!c = 0;
	    has Piece %!pieces{square};
	    method rank($/) { $!r++; $!c=0 }
	    method piece($/) {
		my $square = square::{('a'..'h')[$!c++] ~ (7-$!r)+1};
		@board[$square] = %(<p n b r q k> Z=> Pawn, Knight, Bishop, Rook, Queen, King){~$/.lc}.new(:color(~$/ ~~ /<upper>/ ?? white !! black));
		if $/ eq 'k'|'K' { %kings{%( k => black, K => white ){$/}} = $square; }
	    }
	    method empty-squares($/)    { $!c+=$/ }
	    method active-color($/)     { $turn = $/ eq 'w' ?? white !! black }
	    method half-move-clock($/)  { $half-moves-count = +$/ }
	    method en-passant($/)       { $en-passant = square::{$/} unless $/ eq '-' }
	    method castling($/)         {
		return if $/ eq '-';
		for (white) => rx/<[KQ]>/, (black) => rx/<[kq]>/ {
		    %castling-rights{.key} = Set[castling-rights].new:
		    %(<k q> Z=> kingside, queenside){$/.Str.comb(.value)».lc};
		}
	    }
	    method full-move-number($/) { $move-number = +$/ }
	}.new
	;
	self.bless: :%kings, :@board, :$turn, :%castling-rights, :$en-passant, :$half-moves-count, :$move-number, :$last-move;
    }

    submethod BUILD(:%!kings, :@!board, :$!turn, :%!castling-rights, :$!en-passant, :$!half-moves-count, :$!move-number, :$!last-move) {}

    method pass { 
	self.bless:
	:kings(%!kings<>),
	:board(@!board<>),
	:turn(¬$!turn),
	:castling-rights(%!castling-rights<>),
	:$!en-passant,
	:$!half-moves-count,
	:$!move-number,
	:last-move(Move)
    }

    method gist { self.fen }
    method fen returns Str {
	join ' ',
	do for 8,7...1 -> $r {
	    do for 'a'..'h' -> $c {
		my $piece = @!board[square::{"$c$r"}];
		$piece ?? $piece.symbol !! '1'
	    }.join
	    .subst(/1+/, { .chars }, :g)
	}.join("/"),
	$!turn eq white ?? 'w' !! 'b',
	(
	    %!castling-rights{white} ?? %(kingside, queenside Z=> <K Q>){%!castling-rights{white}.keys} !! '',
	    %!castling-rights{black} ?? %(kingside, queenside Z=> <k q>){%!castling-rights{black}.keys} !! ''
	).flat.sort.join.subst(/^$/, '-'),
	$!en-passant.defined ?? $!en-passant !! '-',
	$!half-moves-count,
	$!move-number
    }

    method png returns Blob {

	(state %){self.uint.base(36)} //= .out.slurp given shell gather {
	    sub encode(Distribution::Resource $resource --> Str) {
		use Base64;
		encode-base64($resource.slurp(:bin, :close)).join
	    }
	    my Bool $flip-board = self.turn ~~ black;
	    # default checkerboard has 60x60 squares
	    my $checkboard = encode %?RESOURCES<images/checkerboard.png>;
	    my %pieces = <K Q R B N P k q r b n p>.map: { $_ => encode(%?RESOURCES{"images/$_.png"}) };

	    take qq[magick <(basenc -d --base64 <<<"$checkboard") png:-];
	    my ($r, $c) = 0, 0;
	    for self.board -> @rank {
		for @rank {
		    if .defined {
			my ($R, $C) = ($r, $c).map: { 60 * ($flip-board ?? 7 - $_ !! $_) }
			$C--; # It just looks better with this. Don't ask me why!
			take qq[composite -geometry +$C+$R <(basenc -d --base64 <<<"%pieces{.value.symbol}") - png:-];
		    }
		    $c++;
		}
		$c = 0;
		$r++;
	    }
	    take qq[magick - -resize {join 'x', (8*$square-size) xx 2} png:-];
	}.join(" |\n"),
	:out, :bin
	;

    }

    method test {

    }

    method input-moves {
	ENTER my $saved-termios := Term::termios.new(fd => 1).getattr;
	LEAVE $saved-termios.setattr: :DRAIN;

	ENTER {
	    my $termios := Term::termios.new(fd => 1).getattr;
	    $termios.makeraw;
	    $termios.setattr: :DRAIN;
	}

	# In addition to console_codes (4) :
	# =item L<ANSI Escape Codes|https://gist.github.com/fnky/458719343aabd01cfb17a3a4f7296797>
	# =item L<XTerm control sequences|https://invisible-island.net/xterm/ctlseqs/ctlseqs.html>
	ENTER {
	    print join '',
	    # save state
	    "\e7",
	    # save the screen and erase it
	    "\e[?47h\e[2J",
	    # make cursor invisible
	    "\e[?25l"
	}
	LEAVE {
	    print join '',
	    # make cursor visible
	    "\e[?25h",
	    # restore the screen
	    "\e[?47l",
	    # restore state
	    "\e8"
	    ;
	}

	ENTER {
	    print "\e[?1016h"; # Enable SGR mode for better precision
	    print "\e[?1002h"; # Enable button-event tracking (press/release)
	    print "\e[?1003h";
	}
	LEAVE {
	    print "\e[?1003l";
	    print "\e[?1002l";
	    print "\e[?1016l";
	}

	show self;

	class Mouse {
	    class Button { has Bool $.is-pressed; }
	    has Button ($.left, $.right);
	    class Event {
		has UInt(Cool) ($.x, $.y); 
		method isInsideChessboard returns Bool { $!x&$!y ~~ 0..(8*$square-size) }
	    }
	    class Click   is Event { }
	    class Release is Event { }
	    class Move    is Event { }
	}
	my $mouse-reporting = supply {
	    loop {
		my Buf $buf .= new;
		repeat {
		    given $*IN.read(1) {
			if .head == qq[\e].ord {
			    my Buf $csi .= new;
			    loop {
				my $r = $*IN.read(1);
				$csi.push: $r;
				last if $r.head == <M m>».ord.any;
			    }
			    if $csi.decode ~~ / \[ <[<>]> [$<private-code> =\d+]\; [$<x> = \d+] \; [$<y> = \d+] <m=[mM]>/ {
				given $<private-code> {
				    when 35 { emit Mouse::Move.new:  :$<x>, :$<y> }
				    when  0 { emit ($<m> eq 'M' ?? Mouse::Click !! Mouse::Release).new: :$<x>, :$<y> }
				    default { emit ~$_; }
				}
			    } else { emit "unreckognized csi {$csi.decode}" }
			} else { $buf.push($_) }
		    }
		} until try my $c = $buf.decode;
		emit $c;
		last if $c eq 'q';
	    }
	};

	constant $time-out = 5;
	# display the position
	react {
	    whenever $mouse-reporting {
		when Mouse::Event {
		    my ($x, $y) = (.x, .y).map: * div $square-size;
		    my ($r, $c) = 7 - $y, $x;
		    if $r & $c ~~ ^8 {
			# hand-shaped pointer
			printf "\e]22;hand\a";
			my $square = square::{ ('a'..'h')[$c] ~ ($r + 1) };
			if @!board[$square].defined {
			    when Mouse::Click   { print "\e]22;grabbing\a" }
			    print "\r$square {@!board[$square]}";
			} else { print  "\e]22;not-allowed\a\e[2K"; }
		    } else { printf "\e]22;default\a"; }
		}
		when Mouse::Release { print "\e]22;hand\a"; }
		when Str {
		    print "\rgot message `$_`\e[K";
		}
	    }
	    # can't make the line below work for some reason
	    #whenever Promise.in($time-out) { done }
	}
    }

    method moves(Bool :$legal = True, Piece:U :$piece, square :$square) {
	my ($us, $them) = $!turn, ¬$!turn;
	my @squares = $square ?? ($square,) !! square::{*};
	my $before = self;

	slip (state %){self.uint.base(36)}{$legal}{$piece.symbol}{$square // 'all'} //=
	gather {
	    for @squares -> $from {
		if !@!board[$from].defined || @!board[$from].color ~~ $them {
		    next;
		}
		my square $to;
		if @!board[$from] ~~ Pawn {
		    my $pawn = @!board[$from];
		    next if $piece ~~ ActualPiece && $piece !~~ Pawn;
		    $to = square($from + $pawn.offsets[0]);
		    if !@!board[$to] {
			if rank($to) == PROMOTION-RANK {
			    for Queen, Knight, Bishop, Rook -> $promotion {
				take Promotion.bless: :$before, :$from, :$to, :$promotion
			    }
			} else { take PawnMove.bless: :$before, :$from, :$to; }
			try $to = square($from + $pawn.offsets[1]);
			unless $! {
			    if rank($from) == %SECOND-RANK{$us} && !@!board[$to] {
				take BigPawnMove.bless: :$before, :$from, :$to;
			    }
			}
		    }
		    for 2..^4 -> $j {
			try $to = square($from + $pawn.offsets[$j]);
			next if $!;
			if @!board[$to].defined && @!board[$to].color ~~ $them {
			    if rank($to) == PROMOTION-RANK {
				for Queen, Knight, Bishop, Rook -> $promotion {
				    take Promotion.bless: :$before, :$from, :$to, :$promotion, :is-capture;
				}
			    } else { take PawnMove.bless: :$before, :$from, :$to, :is-capture; }
			} elsif $!en-passant && $to ~~ $!en-passant {
			    take EnPassant.bless: :$before, :$from, :$to;
			}
		    }
		} else {
		    next if $piece ~~ ActualPiece && @!board[$from] !~~ $piece;
		    for @!board[$from].offsets -> $offset {
			$to = $from;
			loop {
			    try $to = square($to + $offset);
			    last if $!;
			    if !@!board[$to] {
				take Move.bless: :$before, :$from, :$to;
			    } else {
				last if @!board[$to].color ~~ $us;
				take Move.bless: :$before, :$from, :$to, :is-capture;
				last;
			    }
			    last if @!board[$from] ~~ King|Knight;
			}
		    }
		}
	    }
	    if $piece !~~ ActualPiece || $piece ~~ King {
		if $piece ~~ King || $square.defined && $square == %!kings{$us} {
		    if kingside ∈ %!castling-rights{$us} {
			my square $castling-from = %!kings{$us};
			my square $castling-to   = square($castling-from + 2);
			if 
			    !@!board[square($castling-from + 1)] &&
			    !@!board[$castling-to] &&
			    !self!attacked($them, %!kings{$us}) &&
			    !self!attacked($them, square($castling-from + 1)) &&
			    !self!attacked($them, $castling-to)
			{
			    take KingsideCastle.new: :$before, :from(%!kings{$us}), :to($castling-to)
			}
		    }
		    if queenside ∈ %!castling-rights{$us} {
			my square $castling-from = %!kings{$us};
			my square $castling-to   = square($castling-from - 2);
			if 
			    !@!board[square($castling-from - 1)] &&
			    !@!board[$castling-to] &&
			    !self!attacked($them, %!kings{$us}) &&
			    !self!attacked($them, square($castling-from - 1)) &&
			    !self!attacked($them, $castling-to)
			{
			    take QueensideCastle.new: :$before, :from(%!kings{$us}), :to($castling-to)
			}
		    }
		}
	    }
	}.grep:
	    !$legal || (%!kings{$us}:!exists) ?? * !! { ! .after.pass.isCheck }
    }

    method !attacked(color $color, square $square, Bool :$verbose) {
	constant $RAYS = Blob[int8].new:
	17, 0, 0, 0, 0, 0, 0, 16, 0, 0, 0, 0, 0, 0, 15, 0, 0, 17, 0, 0, 0,
	0, 0, 16, 0, 0, 0, 0, 0, 15, 0, 0, 0, 0, 17, 0, 0, 0, 0, 16, 0, 0, 0,
	0, 15, 0, 0, 0, 0, 0, 0, 17, 0, 0, 0, 16, 0, 0, 0, 15, 0, 0, 0, 0, 0,
	0, 0, 0, 17, 0, 0, 16, 0, 0, 15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 17, 0,
	16, 0, 15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 17, 16, 15, 0, 0, 0, 0,
	0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, -1, -1, -1, -1, -1, -1, -1, 0, 0, 0,
	0, 0, 0, 0, -15, -16, -17, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -15, 0,
	-16, 0, -17, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -15, 0, 0, -16, 0, 0, -17,
	0, 0, 0, 0, 0, 0, 0, 0, -15, 0, 0, 0, -16, 0, 0, 0, -17, 0, 0, 0, 0, 0,
	0, -15, 0, 0, 0, 0, -16, 0, 0, 0, 0, -17, 0, 0, 0, 0, -15, 0, 0, 0, 0,
	0, -16, 0, 0, 0, 0, 0, -17, 0, 0, -15, 0, 0, 0, 0, 0, 0, -16, 0, 0, 0,
	0, 0, 0, -17;
	my @attackers;
	for square::{*} -> $i {
	    my $piece = @!board[$i];
	    if !$piece || $piece.color !~~ $color {
		next;
	    }
	    my $difference = $i - $square;
	    next if $difference == 0;
	    my $index = $difference + 119;
	    if $piece.attacks($index) {
		if $piece ~~ Pawn {
		    if
		    $difference > 0 && $piece.color ~~ white ||
		    $difference ≤ 0 && $piece.color ~~ black {
			if !$verbose {
			    return True;
			} else {
			    @attackers.push: $i;
			}
		    }
		    next;
		}
		if $piece ~~ Knight|King {
		    if !$verbose {
			return True;
		    } else {
			@attackers.push: $i;
			next;
		    }
		}
		my $offset = $RAYS[$index];
		my $j = $i + $offset;
		my Bool $blocked = False;
		while $j !== $square {
		    if @!board[$j] {
			$blocked = True;
			last;
		    }
		    $j += $offset;
		}
		if !$blocked {
		    if !$verbose {
			return True;
		    } else {
			@attackers.push: $i;
		    }
		}
	    }
	}
	$verbose ?? @attackers !! False;
    }
    method attackers(square $square, color $attackedBy?) {
	self!attacked:
	$attackedBy.defined ?? $attackedBy !! $!turn,
	$square,
	:verbose
	;
    }

    method !isKingAttacked(color $color --> Bool) {
	%!kings{$color}:exists ?? self!attacked(¬$color, %!kings{$color}) !! False
    }
    method isCheck     returns Bool {  self!isKingAttacked($!turn) }
    method inCheck     returns Bool {  self.isCheck }
    method isCheckmate returns Bool {  self.isCheck && self.moves.elems == 0 }
    method isStalemate returns Bool { !self.isCheck && self.moves.elems == 0 }

    proto method pick-move(|) {*}
    multi method pick-move(Bool :$best! where !*) { samewith :engine<stockfish>, :time-out(3), :number-of-threads(1), :skill-level(10) }
    multi method pick-move(Bool :$best! where ?*) { samewith :engine<stockfish>, :time-out(15), :number-of-threads(8), :skill-level(20) }
    multi method pick-move(
	Str :$engine!,
	Real :$time-out!,
	UInt :$number-of-threads!,
	UInt :$skill-level! where 0..20
    ) {
	my Str $init-string;
	$init-string ~= "setoption name Threads value $number-of-threads\n"  if $number-of-threads.defined;
	$init-string ~= "setoption name Skill Level value $skill-level\n"    if $skill-level      .defined;
	$init-string ~= [
	    "position fen {self.fen}",
	    "go infinite"
	].join("\n");
	my $best-move;
	my $process = Proc::Async.new: :w, $engine;
	react {
	    whenever $process.stdout.lines {
		use Chess::UCI;
		if /^<Chess::UCI::best-move>/ {
		    $best-move = Chess::Move.new: ~$<Chess::UCI::best-move>, :position(self);
		    await $process.say: "quit";
		}
	    }
	    whenever $process.start { done }
	    whenever $process.say: $init-string {
		whenever Promise.in($time-out) {
		    await $process.say: "stop";
		}
	    }
	}
	return $best-move;
    }

    method isInsufficientMaterial returns Bool {
	my UInt %pieces{Piece} = (Pawn, Bishop, Knight, Rook, Queen, King) X=> 0;
	my @bishops;
	my UInt ($numPieces, $squareColor) = 0, 0;
	for square::{*}.sort(*.value) -> $square {
	    $squareColor = (&rank, &file)».($square).sum % 2;
	    if @!board[$square]:exists {
		my $piece = @!board[$square];
		%pieces{$piece.WHAT}++;
		if $piece ~~ Bishop {
		    @bishops.push: $squareColor;
		}
		$numPieces++
	    }
	}
	if $numPieces == 2 {
	    return True;
	} elsif $numPieces == 3 && (%pieces{Bishop} == 1 || %pieces{Knight} == 1) {
	    return True;
	} elsif $numPieces == %pieces{Bishop} + 2 {
	    my UInt $sum = 0;
	    $sum += $_ for @bishops;
	    if $sum == 0|@bishops.elems {
		return True
	    }
	}
	return False;
    }
    method ascii {
	my $s = "   +------------------------+\n";
	my @squares = square::{(8,7...1) X[R~] 'a'..'h'};
	for @squares.rotor(8) -> @row {
	    state $r;
	    $s ~= " {8 - $r++} |";
	    for @row -> $square {
		my $piece = @!board[$square];
		$s ~= " {$piece ?? $piece.symbol !! '.'} ";
	    }
	    $s ~= "|\n";
	}
	$s ~= "   +------------------------+\n";
	$s ~= "     a  b  c  d  e  f  g  h";
	return $s;

    }
    # http://hgm.nubati.net/book_format.html
    method uint returns uint64 {
	constant $Random64 = Blob[uint64].new: map *.parse-base(16), <
	    9D39247E33776D41 2AF7398005AAA5C7 44DB015024623547 9C15F73E62A76AE2
	    75834465489C0C89 3290AC3A203001BF 0FBBAD1F61042279 E83A908FF2FB60CA
	    0D7E765D58755C10 1A083822CEAFE02D 9605D5F0E25EC3B0 D021FF5CD13A2ED5
	    40BDF15D4A672E32 011355146FD56395 5DB4832046F3D9E5 239F8B2D7FF719CC
	    05D1A1AE85B49AA1 679F848F6E8FC971 7449BBFF801FED0B 7D11CDB1C3B7ADF0
	    82C7709E781EB7CC F3218F1C9510786C 331478F3AF51BBE6 4BB38DE5E7219443
	    AA649C6EBCFD50FC 8DBD98A352AFD40B 87D2074B81D79217 19F3C751D3E92AE1
	    B4AB30F062B19ABF 7B0500AC42047AC4 C9452CA81A09D85D 24AA6C514DA27500
	    4C9F34427501B447 14A68FD73C910841 A71B9B83461CBD93 03488B95B0F1850F
	    637B2B34FF93C040 09D1BC9A3DD90A94 3575668334A1DD3B 735E2B97A4C45A23
	    18727070F1BD400B 1FCBACD259BF02E7 D310A7C2CE9B6555 BF983FE0FE5D8244
	    9F74D14F7454A824 51EBDC4AB9BA3035 5C82C505DB9AB0FA FCF7FE8A3430B241
	    3253A729B9BA3DDE 8C74C368081B3075 B9BC6C87167C33E7 7EF48F2B83024E20
	    11D505D4C351BD7F 6568FCA92C76A243 4DE0B0F40F32A7B8 96D693460CC37E5D
	    42E240CB63689F2F 6D2BDCDAE2919661 42880B0236E4D951 5F0F4A5898171BB6
	    39F890F579F92F88 93C5B5F47356388B 63DC359D8D231B78 EC16CA8AEA98AD76
	    5355F900C2A82DC7 07FB9F855A997142 5093417AA8A7ED5E 7BCBC38DA25A7F3C
	    19FC8A768CF4B6D4 637A7780DECFC0D9 8249A47AEE0E41F7 79AD695501E7D1E8
	    14ACBAF4777D5776 F145B6BECCDEA195 DABF2AC8201752FC 24C3C94DF9C8D3F6
	    BB6E2924F03912EA 0CE26C0B95C980D9 A49CD132BFBF7CC4 E99D662AF4243939
	    27E6AD7891165C3F 8535F040B9744FF1 54B3F4FA5F40D873 72B12C32127FED2B
	    EE954D3C7B411F47 9A85AC909A24EAA1 70AC4CD9F04F21F5 F9B89D3E99A075C2
	    87B3E2B2B5C907B1 A366E5B8C54F48B8 AE4A9346CC3F7CF2 1920C04D47267BBD
	    87BF02C6B49E2AE9 092237AC237F3859 FF07F64EF8ED14D0 8DE8DCA9F03CC54E
	    9C1633264DB49C89 B3F22C3D0B0B38ED 390E5FB44D01144B 5BFEA5B4712768E9
	    1E1032911FA78984 9A74ACB964E78CB3 4F80F7A035DAFB04 6304D09A0B3738C4
	    2171E64683023A08 5B9B63EB9CEFF80C 506AACF489889342 1881AFC9A3A701D6
	    6503080440750644 DFD395339CDBF4A7 EF927DBCF00C20F2 7B32F7D1E03680EC
	    B9FD7620E7316243 05A7E8A57DB91B77 B5889C6E15630A75 4A750A09CE9573F7
	    CF464CEC899A2F8A F538639CE705B824 3C79A0FF5580EF7F EDE6C87F8477609D
	    799E81F05BC93F31 86536B8CF3428A8C 97D7374C60087B73 A246637CFF328532
	    043FCAE60CC0EBA0 920E449535DD359E 70EB093B15B290CC 73A1921916591CBD
	    56436C9FE1A1AA8D EFAC4B70633B8F81 BB215798D45DF7AF 45F20042F24F1768
	    930F80F4E8EB7462 FF6712FFCFD75EA1 AE623FD67468AA70 DD2C5BC84BC8D8FC
	    7EED120D54CF2DD9 22FE545401165F1C C91800E98FB99929 808BD68E6AC10365
	    DEC468145B7605F6 1BEDE3A3AEF53302 43539603D6C55602 AA969B5C691CCB7A
	    A87832D392EFEE56 65942C7B3C7E11AE DED2D633CAD004F6 21F08570F420E565
	    B415938D7DA94E3C 91B859E59ECB6350 10CFF333E0ED804A 28AED140BE0BB7DD
	    C5CC1D89724FA456 5648F680F11A2741 2D255069F0B7DAB3 9BC5A38EF729ABD4
	    EF2F054308F6A2BC AF2042F5CC5C2858 480412BAB7F5BE2A AEF3AF4A563DFE43
	    19AFE59AE451497F 52593803DFF1E840 F4F076E65F2CE6F0 11379625747D5AF3
	    BCE5D2248682C115 9DA4243DE836994F 066F70B33FE09017 4DC4DE189B671A1C
	    51039AB7712457C3 C07A3F80C31FB4B4 B46EE9C5E64A6E7C B3819A42ABE61C87
	    21A007933A522A20 2DF16F761598AA4F 763C4A1371B368FD F793C46702E086A0
	    D7288E012AEB8D31 DE336A2A4BC1C44B 0BF692B38D079F23 2C604A7A177326B3
	    4850E73E03EB6064 CFC447F1E53C8E1B B05CA3F564268D99 9AE182C8BC9474E8
	    A4FC4BD4FC5558CA E755178D58FC4E76 69B97DB1A4C03DFE F9B5B7C4ACC67C96
	    FC6A82D64B8655FB 9C684CB6C4D24417 8EC97D2917456ED0 6703DF9D2924E97E
	    C547F57E42A7444E 78E37644E7CAD29E FE9A44E9362F05FA 08BD35CC38336615
	    9315E5EB3A129ACE 94061B871E04DF75 DF1D9F9D784BA010 3BBA57B68871B59D
	    D2B7ADEEDED1F73F F7A255D83BC373F8 D7F4F2448C0CEB81 D95BE88CD210FFA7
	    336F52F8FF4728E7 A74049DAC312AC71 A2F61BB6E437FDB5 4F2A5CB07F6A35B3
	    87D380BDA5BF7859 16B9F7E06C453A21 7BA2484C8A0FD54E F3A678CAD9A2E38C
	    39B0BF7DDE437BA2 FCAF55C1BF8A4424 18FCF680573FA594 4C0563B89F495AC3
	    40E087931A00930D 8CFFA9412EB642C1 68CA39053261169F 7A1EE967D27579E2
	    9D1D60E5076F5B6F 3810E399B6F65BA2 32095B6D4AB5F9B1 35CAB62109DD038A
	    A90B24499FCFAFB1 77A225A07CC2C6BD 513E5E634C70E331 4361C0CA3F692F12
	    D941ACA44B20A45B 528F7C8602C5807B 52AB92BEB9613989 9D1DFA2EFC557F73
	    722FF175F572C348 1D1260A51107FE97 7A249A57EC0C9BA2 04208FE9E8F7F2D6
	    5A110C6058B920A0 0CD9A497658A5698 56FD23C8F9715A4C 284C847B9D887AAE
	    04FEABFBBDB619CB 742E1E651C60BA83 9A9632E65904AD3C 881B82A13B51B9E2
	    506E6744CD974924 B0183DB56FFC6A79 0ED9B915C66ED37E 5E11E86D5873D484
	    F678647E3519AC6E 1B85D488D0F20CC5 DAB9FE6525D89021 0D151D86ADB73615
	    A865A54EDCC0F019 93C42566AEF98FFB 99E7AFEABE000731 48CBFF086DDF285A
	    7F9B6AF1EBF78BAF 58627E1A149BBA21 2CD16E2ABD791E33 D363EFF5F0977996
	    0CE2A38C344A6EED 1A804AADB9CFA741 907F30421D78C5DE 501F65EDB3034D07
	    37624AE5A48FA6E9 957BAF61700CFF4E 3A6C27934E31188A D49503536ABCA345
	    088E049589C432E0 F943AEE7FEBF21B8 6C3B8E3E336139D3 364F6FFA464EE52E
	    D60F6DCEDC314222 56963B0DCA418FC0 16F50EDF91E513AF EF1955914B609F93
	    565601C0364E3228 ECB53939887E8175 BAC7A9A18531294B B344C470397BBA52
	    65D34954DAF3CEBD B4B81B3FA97511E2 B422061193D6F6A7 071582401C38434D
	    7A13F18BBEDC4FF5 BC4097B116C524D2 59B97885E2F2EA28 99170A5DC3115544
	    6F423357E7C6A9F9 325928EE6E6F8794 D0E4366228B03343 565C31F7DE89EA27
	    30F5611484119414 D873DB391292ED4F 7BD94E1D8E17DEBC C7D9F16864A76E94
	    947AE053EE56E63C C8C93882F9475F5F 3A9BF55BA91F81CA D9A11FBB3D9808E4
	    0FD22063EDC29FCA B3F256D8ACA0B0B9 B03031A8B4516E84 35DD37D5871448AF
	    E9F6082B05542E4E EBFAFA33D7254B59 9255ABB50D532280 B9AB4CE57F2D34F3
	    693501D628297551 C62C58F97DD949BF CD454F8F19C5126A BBE83F4ECC2BDECB
	    DC842B7E2819E230 BA89142E007503B8 A3BC941D0A5061CB E9F6760E32CD8021
	    09C7E552BC76492F 852F54934DA55CC9 8107FCCF064FCF56 098954D51FFF6580
	    23B70EDB1955C4BF C330DE426430F69D 4715ED43E8A45C0A A8D7E4DAB780A08D
	    0572B974F03CE0BB B57D2E985E1419C7 E8D9ECBE2CF3D73F 2FE4B17170E59750
	    11317BA87905E790 7FBF21EC8A1F45EC 1725CABFCB045B00 964E915CD5E2B207
	    3E2B8BCBF016D66D BE7444E39328A0AC F85B2B4FBCDE44B7 49353FEA39BA63B1
	    1DD01AAFCD53486A 1FCA8A92FD719F85 FC7C95D827357AFA 18A6A990C8B35EBD
	    CCCB7005C6B9C28D 3BDBB92C43B17F26 AA70B5B4F89695A2 E94C39A54A98307F
	    B7A0B174CFF6F36E D4DBA84729AF48AD 2E18BC1AD9704A68 2DE0966DAF2F8B1C
	    B9C11D5B1E43A07E 64972D68DEE33360 94628D38D0C20584 DBC0D2B6AB90A559
	    D2733C4335C6A72F 7E75D99D94A70F4D 6CED1983376FA72B 97FCAACBF030BC24
	    7B77497B32503B12 8547EDDFB81CCB94 79999CDFF70902CB CFFE1939438E9B24
	    829626E3892D95D7 92FAE24291F2B3F1 63E22C147B9C3403 C678B6D860284A1C
	    5873888850659AE7 0981DCD296A8736D 9F65789A6509A440 9FF38FED72E9052F
	    E479EE5B9930578C E7F28ECD2D49EECD 56C074A581EA17FE 5544F7D774B14AEF
	    7B3F0195FC6F290F 12153635B2C0CF57 7F5126DBBA5E0CA7 7A76956C3EAFB413
	    3D5774A11D31AB39 8A1B083821F40CB4 7B4A38E32537DF62 950113646D1D6E03
	    4DA8979A0041E8A9 3BC36E078F7515D7 5D0A12F27AD310D1 7F9D1A2E1EBE1327
	    DA3A361B1C5157B1 DCDD7D20903D0C25 36833336D068F707 CE68341F79893389
	    AB9090168DD05F34 43954B3252DC25E5 B438C2B67F98E5E9 10DCD78E3851A492
	    DBC27AB5447822BF 9B3CDB65F82CA382 B67B7896167B4C84 BFCED1B0048EAC50
	    A9119B60369FFEBD 1FFF7AC80904BF45 AC12FB171817EEE7 AF08DA9177DDA93D
	    1B0CAB936E65C744 B559EB1D04E5E932 C37B45B3F8D6F2BA C3A9DC228CAAC9E9
	    F3B8B6675A6507FF 9FC477DE4ED681DA 67378D8ECCEF96CB 6DD856D94D259236
	    A319CE15B0B4DB31 073973751F12DD5E 8A8E849EB32781A5 E1925C71285279F5
	    74C04BF1790C0EFE 4DDA48153C94938A 9D266D6A1CC0542C 7440FB816508C4FE
	    13328503DF48229F D6BF7BAEE43CAC40 4838D65F6EF6748F 1E152328F3318DEA
	    8F8419A348F296BF 72C8834A5957B511 D7A023A73260B45C 94EBC8ABCFB56DAE
	    9FC10D0F989993E0 DE68A2355B93CAE6 A44CFE79AE538BBE 9D1D84FCCE371425
	    51D2B1AB2DDFB636 2FD7E4B9E72CD38C 65CA5B96B7552210 DD69A0D8AB3B546D
	    604D51B25FBF70E2 73AA8A564FB7AC9E 1A8C1E992B941148 AAC40A2703D9BEA0
	    764DBEAE7FA4F3A6 1E99B96E70A9BE8B 2C5E9DEB57EF4743 3A938FEE32D29981
	    26E6DB8FFDF5ADFE 469356C504EC9F9D C8763C5B08D1908C 3F6C6AF859D80055
	    7F7CC39420A3A545 9BFB227EBDF4C5CE 89039D79D6FC5C5C 8FE88B57305E2AB6
	    A09E8C8C35AB96DE FA7E393983325753 D6B6D0ECC617C699 DFEA21EA9E7557E3
	    B67C1FA481680AF8 CA1E3785A9E724E5 1CFC8BED0D681639 D18D8549D140CAEA
	    4ED0FE7E9DC91335 E4DBF0634473F5D2 1761F93A44D5AEFE 53898E4C3910DA55
	    734DE8181F6EC39A 2680B122BAA28D97 298AF231C85BAFAB 7983EED3740847D5
	    66C1A2A1A60CD889 9E17E49642A3E4C1 EDB454E7BADC0805 50B704CAB602C329
	    4CC317FB9CDDD023 66B4835D9EAFEA22 219B97E26FFC81BD 261E4E4C0A333A9D
	    1FE2CCA76517DB90 D7504DFA8816EDBB B9571FA04DC089C8 1DDC0325259B27DE
	    CF3F4688801EB9AA F4F5D05C10CAB243 38B6525C21A42B0E 36F60E2BA4FA6800
	    EB3593803173E0CE 9C4CD6257C5A3603 AF0C317D32ADAA8A 258E5A80C7204C4B
	    8B889D624D44885D F4D14597E660F855 D4347F66EC8941C3 E699ED85B0DFB40D
	    2472F6207C2D0484 C2A1E7B5B459AEB5 AB4F6451CC1D45EC 63767572AE3D6174
	    A59E0BD101731A28 116D0016CB948F09 2CF9C8CA052F6E9F 0B090A7560A968E3
	    ABEEDDB2DDE06FF1 58EFC10B06A2068D C6E57A78FBD986E0 2EAB8CA63CE802D7
	    14A195640116F336 7C0828DD624EC390 D74BBE77E6116AC7 804456AF10F5FB53
	    EBE9EA2ADF4321C7 03219A39EE587A30 49787FEF17AF9924 A1E9300CD8520548
	    5B45E522E4B1B4EF B49C3B3995091A36 D4490AD526F14431 12A8F216AF9418C2
	    001F837CC7350524 1877B51E57A764D5 A2853B80F17F58EE 993E1DE72D36D310
	    B3598080CE64A656 252F59CF0D9F04BB D23C8E176D113600 1BDA0492E7E4586E
	    21E0BD5026C619BF 3B097ADAF088F94E 8D14DEDB30BE846E F95CFFA23AF5F6F4
	    3871700761B3F743 CA672B91E9E4FA16 64C8E531BFF53B55 241260ED4AD1E87D
	    106C09B972D2E822 7FBA195410E5CA30 7884D9BC6CB569D8 0647DFEDCD894A29
	    63573FF03E224774 4FC8E9560F91B123 1DB956E450275779 B8D91274B9E9D4FB
	    A2EBEE47E2FBFCE1 D9F1F30CCD97FB09 EFED53D75FD64E6B 2E6D02C36017F67F
	    A9AA4D20DB084E9B B64BE8D8B25396C1 70CB6AF7C2D5BCF0 98F076A4F7A2322E
	    BF84470805E69B5F 94C3251F06F90CF3 3E003E616A6591E9 B925A6CD0421AFF3
	    61BDD1307C66E300 BF8D5108E27E0D48 240AB57A8B888B20 FC87614BAF287E07
	    EF02CDD06FFDB432 A1082C0466DF6C0A 8215E577001332C8 D39BB9C3A48DB6CF
	    2738259634305C14 61CF4F94C97DF93D 1B6BACA2AE4E125B 758F450C88572E0B
	    959F587D507A8359 B063E962E045F54D 60E8ED72C0DFF5D1 7B64978555326F9F
	    FD080D236DA814BA 8C90FD9B083F4558 106F72FE81E2C590 7976033A39F7D952
	    A4EC0132764CA04B 733EA705FAE4FA77 B4D8F77BC3E56167 9E21F4F903B33FD9
	    9D765E419FB69F6D D30C088BA61EA5EF 5D94337FBFAF7F5B 1A4E4822EB4D7A59
	    6FFE73E81B637FB3 DDF957BC36D8B9CA 64D0E29EEA8838B3 08DD9BDFD96B9F63
	    087E79E5A57D1D13 E328E230E3E2B3FB 1C2559E30F0946BE 720BF5F26F4D2EAA
	    B0774D261CC609DB 443F64EC5A371195 4112CF68649A260E D813F2FAB7F5C5CA
	    660D3257380841EE 59AC2C7873F910A3 E846963877671A17 93B633ABFA3469F8
	    C0C0F5A60EF4CDCF CAF21ECD4377B28C 57277707199B8175 506C11B9D90E8B1D
	    D83CC2687A19255F 4A29C6465A314CD1 ED2DF21216235097 B5635C95FF7296E2
	    22AF003AB672E811 52E762596BF68235 9AEBA33AC6ECC6B0 944F6DE09134DFB6
	    6C47BEC883A7DE39 6AD047C430A12104 A5B1CFDBA0AB4067 7C45D833AFF07862
	    5092EF950A16DA0B 9338E69C052B8E7B 455A4B4CFE30E3F5 6B02E63195AD0CF8
	    6B17B224BAD6BF27 D1E0CCD25BB9C169 DE0C89A556B9AE70 50065E535A213CF6
	    9C1169FA2777B874 78EDEFD694AF1EED 6DC93D9526A50E68 EE97F453F06791ED
	    32AB0EDB696703D3 3A6853C7E70757A7 31865CED6120F37D 67FEF95D92607890
	    1F2B1D1F15F6DC9C B69E38A8965C6B65 AA9119FF184CCCF4 F43C732873F24C13
	    FB4A3D794A9A80D2 3550C2321FD6109C 371F77E76BB8417E 6BFA9AAE5EC05779
	    CD04F3FF001A4778 E3273522064480CA 9F91508BFFCFC14A 049A7F41061A9E60
	    FCB6BE43A9F2FE9B 08DE8A1C7797DA9B 8F9887E6078735A1 B5B4071DBFC73A66
	    230E343DFBA08D33 43ED7F5A0FAE657D 3A88A0FBBCB05C63 21874B8B4D2DBC4F
	    1BDEA12E35F6A8C9 53C065C6C8E63528 E34A1D250E7A8D6B D6B04D3B7651DD7E
	    5E90277E7CB39E2D 2C046F22062DC67D B10BB459132D0A26 3FA9DDFB67E2F199
	    0E09B88E1914F7AF 10E8B35AF3EEAB37 9EEDECA8E272B933 D4C718BC4AE8AE5F
	    81536D601170FC20 91B534F885818A06 EC8177F83F900978 190E714FADA5156E
	    B592BF39B0364963 89C350C893AE7DC1 AC042E70F8B383F2 B49B52E587A1EE60
	    FB152FE3FF26DA89 3E666E6F69AE2C15 3B544EBE544C19F9 E805A1E290CF2456
	    24B33C9D7ED25117 E74733427B72F0C1 0A804D18B7097475 57E3306D881EDB4F
	    4AE7D6A36EB5DBCB 2D8D5432157064C8 D1E649DE1E7F268B 8A328A1CEDFE552C
	    07A3AEC79624C7DA 84547DDC3E203C94 990A98FD5071D263 1A4FF12616EEFC89
	    F6F7FD1431714200 30C05B1BA332F41C 8D2636B81555A786 46C9FEB55D120902
	    CCEC0A73B49C9921 4E9D2827355FC492 19EBB029435DCB0F 4659D2B743848A2C
	    963EF2C96B33BE31 74F85198B05A2E7D 5A0F544DD2B1FB18 03727073C2E134B1
	    C7F6AA2DE59AEA61 352787BAA0D7C22F 9853EAB63B5E0B35 ABBDCDD7ED5C0860
	    CF05DAF5AC8D77B0 49CAD48CEBF4A71E 7A4C10EC2158C4A6 D9E92AA246BF719E
	    13AE978D09FE5557 730499AF921549FF 4E4B705B92903BA4 FF577222C14F0A3A
	    55B6344CF97AAFAE B862225B055B6960 CAC09AFBDDD2CDB4 DAF8E9829FE96B5F
	    B5FDFC5D3132C498 310CB380DB6F7503 E87FBB46217A360E 2102AE466EBB1148
	    F8549E1A3AA5E00D 07A69AFDCC42261A C4C118BFE78FEAAE F9F4892ED96BD438
	    1AF3DBE25D8F45DA F5B4B0B0D2DEEEB4 962ACEEFA82E1C84 046E3ECAAF453CE9
	    F05D129681949A4C 964781CE734B3C84 9C2ED44081CE5FBD 522E23F3925E319E
	    177E00F9FC32F791 2BC60A63A6F3B3F2 222BBFAE61725606 486289DDCC3D6780
	    7DC7785B8EFDFC80 8AF38731C02BA980 1FAB64EA29A2DDF7 E4D9429322CD065A
	    9DA058C67844F20C 24C0E332B70019B0 233003B5A6CFE6AD D586BD01C5C217F6
	    5E5637885F29BC2B 7EBA726D8C94094B 0A56A5F0BFE39272 D79476A84EE20D06
	    9E4C1269BAA4BF37 17EFEE45B0DEE640 1D95B0A5FCF90BC6 93CBE0B699C2585D
	    65FA4F227A2B6D79 D5F9E858292504D5 C2B5A03F71471A6F 59300222B4561E00
	    CE2F8642CA0712DC 7CA9723FBB2E8988 2785338347F2BA08 C61BB3A141E50E8C
	    150F361DAB9DEC26 9F6A419D382595F4 64A53DC924FE7AC9 142DE49FFF7A7C3D
	    0C335248857FA9E7 0A9C32D5EAE45305 E6C42178C4BBB92E 71F1CE2490D20B07
	    F1BCC3D275AFE51A E728E8C83C334074 96FBF83A12884624 81A1549FD6573DA5
	    5FA7867CAF35E149 56986E2EF3ED091B 917F1DD5F8886C61 D20D8C88C8FFE65F
	    31D71DCE64B2C310 F165B587DF898190 A57E6339DD2CF3A0 1EF6E6DBB1961EC9
	    70CC73D90BC26E24 E21A6B35DF0C3AD7 003A93D8B2806962 1C99DED33CB890A1
	    CF3145DE0ADD4289 D0E4427A5514FB72 77C621CC9FB3A483 67A34DAC4356550B
	    F8D626AAAF278509
	>;

	sub RandomPiece     { $Random64.subbuf: 0, 768 }
	sub RandomCastle    { $Random64.subbuf: 768, 4 }
	sub RandomEnPassant { $Random64.subbuf: 772, 8 }
	sub RandomTurn      { $Random64.subbuf: 780, 1 }

	my uint64 ($piece, $castle, $en-passant, $turn);

	for @!board.pairs {
	    next unless .value.defined;
	    my ($rank, $file) = { 7 - rank($^k), file($^k) }(square(.key));
	    my $kind-of-piece = 2*%( <p n b r q k > Z=> ^6 ){.value.symbol.lc} + %( black, white Z=> ^2 ){.value.color};
	    my $offset-piece = 64 * $kind-of-piece + 8 * $rank + $file;
	    $piece +^= RandomPiece[$offset-piece];
	}

	if kingside  ∈ %!castling-rights{white} { $castle +^= RandomCastle[0] }
	if queenside ∈ %!castling-rights{white} { $castle +^= RandomCastle[1] }
	if kingside  ∈ %!castling-rights{black} { $castle +^= RandomCastle[2] }
	if queenside ∈ %!castling-rights{black} { $castle +^= RandomCastle[3] }

	if $!en-passant.defined {
	    my &up-or-down = $!turn == white ?? *+16 !! *-16;
	    my @left-or-right;
	    given file($!en-passant) {
		when 'a' { @left-or-right = *+1 }
		when 'h' { @left-or-right = *-1 }
		default  { @left-or-right = *-1, *+1 }
	    }
	    for @left-or-right X∘ &up-or-down -> &direction {
		if my $left-or-right = @!board[&direction($!en-passant)] {
		    if $left-or-right ~~ Pawn and $left-or-right.color == $!turn {
			$en-passant +^= RandomEnPassant[file($!en-passant)];
			last;
		    }
		}
	    }
	}

	if $!turn == white { $turn +^= RandomTurn[0] }

	return my uint64 $ = $piece +^ $castle +^ $en-passant +^ $turn;
    }
    method show returns UInt {
	Kitty::transmit-data;

	my $checkerboard-placement-id = Kitty::ID-RANGE.pick;

	my ($rows, $columns) = .rows, .cols given terminal-size;
	my ($window-height, $window-width) = Chess::Graphics::get-window-size;
	my ($cell-width, $cell-height) = $window-width div $columns, $window-height div $rows;

	say Kitty::APC
	a => 'p',
	i => %Kitty::ID<checkerboard>,
	p => $checkerboard-placement-id,
	q => 1;

	for square::{*} -> $square {
	    with @!board[$square] -> $piece {
		my ($rank, $file) = rank($square), file($square);
		print Kitty::APC
		a => 'p',
		i => %Kitty::ID{$piece.symbol},
		p => $checkerboard-placement-id + 1 + $square,
		P => %Kitty::ID<checkerboard>,
		Q => $checkerboard-placement-id,
		H => ($file*$square-size) div $cell-width,
		X => ($file*$square-size) mod $cell-width,
		V => ($rank*$square-size) div $cell-height,
		Y => ($rank*$square-size) mod $cell-height,
		z => 10,
		q => 1
		;
	    }
	}

	return $checkerboard-placement-id;
    }
}

class Move {
    #| A move really makes sense only with
    #| a given chess position
    has Position $.before;

    has square ($.from, $.to);
    has Bool $.is-capture;

    method gist { self.SAN }
    method uint {
	# http://hgm.nubati.net/book_format.html
	reduce 8 * * + *,
	7-rank($!from),
	file($!from),
	7-rank($!to),
	file($!to)
    }
    multi method new(UInt $int, Position :position($before) = startpos) {
	my $to-file   =  $int +& 0b0_000_000_000_000_111      ;
	my $to-rank   = ($int +& 0b0_000_000_000_111_000) +> 3;
	my $from-file = ($int +& 0b0_000_000_111_000_000) +> 6;
	my $from-rank = ($int +& 0b0_000_111_000_000_000) +> 9;
	my $promotion = ($int +& 0b0_111_000_000_000_000) +> 12;

	$promotion = ['', 'n', 'b', 'r', 'q'][$promotion];

	my ($from, $to) = map -> ($f, $r) { square::{['a'..'h'][$f] ~ (1 + $r)} }, ($from-file, $from-rank), ($to-file, $to-rank);
	$before.moves(:square($from)).first: { .LAN eq "$from$to$promotion" }
    }
    multi method new(Str $move where /^[<[a..h]><[1..8]>]**2<[qnbr]>?$/, Position :position($before) = startpos --> Move) {
	$before.moves.first({ .LAN eq $move }) or fail "illegal move $move";
    }
    multi method new(SAN $move, Position:D :position($before)) {
	$before
	    .moves(:piece(inferPieceType($move)))
	    .first({ my $san = .SAN; $san|strippedSan($san) eq $move })
		or fail "move $move is not legal";
    }
    method color returns color   { $!before.turn }
    method piece returns Piece:U { $!before!Position::board[$!from].WHAT }
    method pseudo-SAN returns Str {
	join '',
	self.piece.symbol.uc,
	getDisambiguator(self, self.before.moves),
	self.is-capture ?? 'x' !! '',
	$!to
    }
    method SAN {
	given self.after {
	    self.pseudo-SAN ~ (.isCheckmate ?? '#' !! .isCheck ?? '+' !! '')
	}
    }
    method LAN returns Str { "$!from$!to" }
    method move-pieces(@board) { @board[$!to] = @board[$!from]:delete }

    method after returns Position {
	my square %kings{color} = $!before.Position::kings<>;
	my Piece @board[128] =  $!before!Position::board<>;
	my color $turn       = ¬$!before.turn;
	my Set[castling-rights] %castling-rights{color} = $!before.castling-rights<>;
	my en-passant-square $en-passant;
	my UInt $half-moves-count = $!before.half-moves-count + 1;
	my UInt $move-number = $!before.move-number;
	$move-number++ if $!before.turn ~~ black;

	given my $moving-piece = @board[$!from] {
	    when King {
		if %castling-rights{$moving-piece.color} {
		    %castling-rights{$moving-piece.color} (-)= (kingside, queenside);
		}
		%kings{$!before.turn} = $!to;
	    }
	    when Rook {
		if %castling-rights{$moving-piece.color} {
		    if $!from == h1|h8 {
			%castling-rights{$moving-piece.color} (-)= kingside;
		    } elsif $!from == a1|a8 {
			%castling-rights{$moving-piece.color} (-)= queenside;
		    }
		}
	    }
	    when Pawn {
		$half-moves-count = 0;
		$en-passant = square($!to - $moving-piece.offsets[0]) if self ~~ BigPawnMove;
	    }
	    when !* {
		fail "there is no piece on square $!from";
	    }
	}
	given @board[$!to] {
	    when .defined && .color ~~ self.color {
		fail "can't capture a piece of the same color";
	    }
	    when .defined {
		$half-moves-count = 0;
	    }
	}
	self.move-pieces(@board);
	Position.bless:
	    :%kings,
	    :@board,
	    :$turn,
	    :%castling-rights,
	    :$en-passant,
	    :$half-moves-count,
	    :$move-number,
	    :last-move(self);
    }


    sub inferPieceType(SAN $san --> Piece:U) {
	given $san {
	    when /^<[a..h]>/ {
		when /<[a..h]>\d.*<[a..h]>\d/ { fail "could not parse '$san'" }
		return Pawn;
	    }
	    when /^<[oO]>/ { return King; }
	    when /^<[NBRQK]>/ {
		return %(<n b r q k> Z=> Knight, Bishop, Rook, Queen, King){.substr(0, 1).lc};
	    }
	    default { fail "could not parse '$san'" }
	}
    }
    sub strippedSan(Str $move) {
	$move.subst(/[<[+#]><[?!]>*]/, "");
    }
    sub getDisambiguator(Move $move, *@moves) {
	my square ($from, $to) = $move.from, $move.to;
	my Piece $piece = $move.piece;
	my UInt ($ambiguities, $sameRank, $sameFile) = 0 xx 3;
	for @moves {
	    my $ambigFrom  = .from;
	    my $ambigTo    = .to;
	    my $ambigPiece = .piece;
	    if $piece ~~ $ambigPiece && $from !~~ $ambigFrom && $to ~~ $ambigTo {
		$ambiguities++;
		if rank($from) == rank($ambigFrom) {
		    $sameRank++
		}
		if file($from) == file($ambigFrom) {
		    $sameFile++
		}
	    }
	}
	if $ambiguities > 0 {
	    if $sameRank & $sameFile > 0 {
		return ~$from;
	    } elsif $sameFile > 0 {
		return $from.Str.substr(1, 1);
	    } else {
		return $from.Str.substr(0, 1);
	    }
	}
	return '';
    }

}

class PawnMove is Move {
    method piece { Pawn }
    method pseudo-SAN {
	if self.is-capture {
	    return "{self.from.Str.substr(0, 1)}x{self.to}";
	} else {
	    return self.to.Str;
	}
    }
}

class Promotion is PawnMove {
  has Piece $.promotion;
  method uint { self.Move::uint + 8**3 * %(Knight, Bishop, Rook, Queen Z=> 1..4){$!promotion} }
  method LAN { self.Move::LAN ~ $!promotion.symbol }
  method pseudo-SAN {
      self.PawnMove::pseudo-SAN ~ '=' ~ $!promotion.symbol.uc
  }
  method move-pieces(@board) {
    @board[$.from]:delete;
    @board[$.to] = $!promotion.new: :color(self.before.turn);
  }
}

class BigPawnMove is PawnMove {
  method pseudo-SAN { ~$.to }
}

class EnPassant is PawnMove {
    has Bool $.is-capture = True;
    method pseudo-SAN { $.from.substr(0, 1) ~ 'x' ~ $.before.en-passant }
    method move-pieces(@board) {
	self.Move::move-pieces(@board);
	@board[square(self.before.en-passant - @board[self.to].offsets[0])]:delete;
    }
}

# Castling here will work only for standard chess,
# not Fischer random.
role Castle is Move {
    method piece { King }
    method from { self.color ~~ white ?? e1 !! e8 }
    method king-step returns Int {...}
    method king-rook-distance returns UInt {...}
    method pseudo-SAN {...}
    method move-pieces(@board) {
	self.Move::move-pieces(@board);
	@board[self.from + self.king-step] =
	@board[self.from + self.king-step * self.king-rook-distance]:delete;
    }
}
class KingsideCastle does Castle {
    method to   { self.color ~~ white ?? g1 !! g8 }
    method king-step { +1 }
    method king-rook-distance { 3 }
    method pseudo-SAN { 'O-O' }
}
class QueensideCastle does Castle {
    method to   { self.color ~~ white ?? c1 !! c8 }
    method king-step { -1 }
    method king-rook-distance { 4 }
    method pseudo-SAN { 'O-O-O' }
}

multi legal-moves(Position $pos) { samewith $pos.fen }
multi legal-moves(Str $fen where { Chess::FEN.parse: $_ }) is export {
    Chess::Position.new($fen).moves
}

proto show($) is export {*}
multi show(Position $pos) {
    if %*ENV<TERM> eq 'xterm-kitty' { samewith $pos.png }
    else { say $pos }
}
multi show(Blob $blob where $blob.subbuf(0, 8) ~~ PNG-SIGNATURE) {
    use Kitty;
    say Kitty::APC
    $blob,
    a => 'T',
    f => 100,
    t => 'd'
}

class Game {
    has Pair @.tag-pair;
    has Position $.last-position;
    has Str  $.termination;
    method moves { { .last-move ?? (.last-move, |&?BLOCK(.last-move.before)) !! Empty }($!last-position).reverse; }
    method pgn {
	join "\n",
	@!tag-pair.map({ qq《[{.key} {.value}] 》}),
	Q{},
	join Q{ },
	|(self.moves».SAN.rotor(2, :partial).map(*.join(' ')) Z[R~] (1..* X~ Q{. })),
	"$!termination\n"
	;
    }
}

our proto load-games($) returns Array[Game] {*}
multi load-games(Match $/) {
    # for some reason using an hyper here fails
    #hyper for $<game> -> $/ {
    #   Game.new:
    Array[Game].new: gather for $<game> -> $/ {
	take Game.new:
	:tag-pair($<tag-pair-section><tag-pair>.map(-> $/ { ~$<name> => ~$<value> })),
	:last-position([*] startpos, |$<movetext-section><move>»<SAN>».Str),
	:termination(~$<game-termination>);
    }
}
multi load-games(IO::Path $pgn) { samewith $pgn.slurp }
multi load-games(Str $pgn) { samewith Chess::PGN.parse: $pgn }

our proto make-book($) returns Blob {*}
multi make-book($data) {
    [~] gather for load-games($data) {
	take .before.uint => .uint for .moves
    }.sort(*.key)
    .map: {
	my Buf $buf .= new;
	$buf.write-uint64( 0,   .key, BigEndian);
	$buf.write-uint16( 8, .value, BigEndian);
	$buf.write-uint16(10,      1, BigEndian);  # default weight of 1
	$buf.write-uint32(12,      0, BigEndian);  # default learn value of 0
	$buf;
    }
}


sub perft(UInt $depth, Position :$position = startpos) returns UInt is export {
  my $nodes = 0;
  for $position.moves -> $move {
      if $depth > 1 { $nodes += samewith $depth - 1, position => $move.after; }
      else { $nodes++ }
  }
  return $nodes;
}

# vi: ft=raku nowrap nu shiftwidth=4
