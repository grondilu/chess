unit module Chess;
use Chess::PGN;
use Chess::FEN;
use Base64;

enum color <black white>;

enum square ('a'..'h' X~ 1..8);
sub row (square $s --> UInt) { +$s.substr(1,1) }
sub file(square $s --> Str)  { ~$s.substr(0,1) }

sub  left(square $s where /<[b..h]>/) { return square::{$s.trans('b'..'h' => 'a'..'g')}; }
sub right(square $s where /<[a..g]>/) { return square::{$s.trans('a'..'g' => 'b'..'h')}; }
sub    up(square $s where /<[1..7]>/) { return square::{$s.trans(1..7     => 2..8    )}; }
sub  down(square $s where /<[2..8]>/) { return square::{$s.trans(2..8     => 1..7    )}; }

class Position {...}
class Move {...}

role Piece[Str $symbol] {
  has color $.color;
  method moves {...}
  method symbol returns Str { $!color eq white ?? $symbol.uc !! $symbol }
}
class Rook   does Piece['r'] { method moves { &up, &left, &down, &right }   }
class Bishop does Piece['b'] { method moves { &up, &down X∘ &left, &right } }
class King   does Piece['k'] { method moves { (Rook, Bishop)».moves().flat } }
class Queen  does Piece['q'] { method moves { King.moves() } }
class Knight does Piece['n'] { method moves { flat do for &left, &right X &up, &down -> (&a, &b) { &a ∘ &b ∘ &b, &a ∘ &a ∘ &b } } }
class Pawn   does Piece['p'] { method moves { $!color == white ?? &up !! &down } }


# watch out : 'Capture' is a rakudo core class
role _Capture { }
role Castle {}
role LongCastle  does Castle { method gist { 'O-O-O' } }
role ShortCastle does Castle { method gist { 'O-O'   } }

my constant %pieces = 
  k => King,
  q => Queen,
  r => Rook,
  b => Bishop,
  n => Knight,
  p => Pawn
;

our subset fen of Str where { Chess::FEN.parse($_) }
our constant startpos is export = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

class Position {
  has Piece %.board{square};
  has color $.turn             is rw;
  has UInt  $.half-move-clock  is rw;
  has UInt  $.full-move-number is rw;
  has square $.en-passant      is rw;
  has Str $.castling-rights    is rw;

  method clone { nextwith :board(%!board.clone), |%_ }
  method zobrist-hash returns uint64 {
    # http://hgm.nubati.net/book_format.html
    use Chess::Polyglot;
    my uint64 ($piece, $castle, $en-passant, $turn);

    for %!board.sort(:by(*.key)) {
      my ($row, $file) = -> $s { [ (row($s) - 1) , %( 'a'..'h' Z=> ^8 ){file($s)} ] }(square::{.key});
      my $kind-of-piece = 2*%( <p n b r q k > Z=> ^6 ){.value.symbol.lc} + %( black, white Z=> ^2 ){.value.color};
      my $offset-piece = 64 * $kind-of-piece + 8 * $row + $file;
      $piece +^= Chess::Polyglot::RandomPiece[$offset-piece];
    }

    if $!castling-rights ~~ /K/ { $castle +^= Chess::Polyglot::RandomCastle[0] }
    if $!castling-rights ~~ /Q/ { $castle +^= Chess::Polyglot::RandomCastle[1] }
    if $!castling-rights ~~ /k/ { $castle +^= Chess::Polyglot::RandomCastle[2] }
    if $!castling-rights ~~ /q/ { $castle +^= Chess::Polyglot::RandomCastle[3] }

    if $!en-passant {
      my &up-or-down = $!turn == white ?? &down !! &up;
      my @left-or-right;
      given file($!en-passant) {
	when 'a' { @left-or-right = &right }
	when 'h' { @left-or-right = &left }
	default  { @left-or-right = &left, &right }
      }
      for @left-or-right X∘ &up-or-down -> &direction {
	if my $left-or-right = %!board{&direction($!en-passant)} {
	  if $left-or-right ~~ Pawn and $left-or-right.color == $!turn {
	    $en-passant +^= Chess::Polyglot::RandomEnPassant[%( 'a'..'h' Z=> ^8 ){file($!en-passant)}];
	    last;
	  }
	}
      }
    }

    if $!turn == white { $turn +^= Chess::Polyglot::RandomTurn[0] }

    return my uint64 $ = $piece +^ $castle +^ $en-passant +^ $turn;

  }
  submethod BUILD(fen :$fen = startpos) {
    my $pos = self;
    my Int ($r, $c) = 0, 0;
    Chess::FEN.parse:
      $fen,
      actions => class {
	method rank($/) { $r++; $c=0 }
	method piece($/) {
	  $pos.board{
	    Chess::square::{('a'..'h')[$c++] ~ (7-$r)+1}
	  } = %pieces{$/.lc}.new(:color($/ eq $/.uc ?? white !! black));
	}
	method empty-squares($/)    { $c+=$/ }
	method active-color($/)     { $pos.turn = $/ eq 'w' ?? white !! black }
	method half-move-clock($/)  { $pos.half-move-clock = +$/ }
	method en-passant($/)       { $pos.en-passant = $/ eq '-' ?? square !! square::{$/} }
	method castling($/)         { $pos.castling-rights = ~$/ }
	method full-move-number($/) { $pos.full-move-number = +$/ }
      }
  }
  method forward   { self.turn == white ?? &up !! &down }
  method backwards { self.turn == black ?? &up !! &down }
  method fen {
    [
      do for 8,7...1 -> $r {
	do do for 'a'..'h' -> $c {
	  my $piece = self.board{square::{"$c$r"}};
	  $piece ?? $piece.symbol !! '1'
	}.join
	.subst(/1+/, { .chars }, :g)
      }.join("/"),
      $!turn eq white ?? 'w' !! 'b',
      $!castling-rights,
      $!en-passant.defined ?? $!en-passant !! '-',
      $!half-move-clock,
      $!full-move-number
    ].join(' ')
  }
  method ray(square $from, &direction) {
    if self.board{$from} {
      my $s = $from;
      gather loop {
	try $s = &direction($s);
	last if $!;
	if self.board{$s} {
	  take $s if self.board{$s}.color ne self.board{$from}.color;
	  last
	} else { take $s }
      }
    } else { () }
  }
  method pass returns ::?CLASS {
    self.new: fen => self.fen.subst: /<<<[wb]>>>/, { $_ eq 'w' ?? 'b' !! 'w' }
  }
  method pseudo-legal-moves {
    (state %){self.fen} //= Array.new:
    gather {
      for self.board {
	my ($from, $moving-piece) = .kv;
	next if $moving-piece.color !== self.turn;
	given $moving-piece {
	  when King|Knight {
	    for .moves {
	      try {
		my $to = .($from);
		my $move = Move.new(:$from, :$to, :$moving-piece);
		if !self.board{$to} {
		  take $move;
		} elsif self.board{$to}.color ne self.turn {
		  take $move but _Capture;
		}
	      }
	    }
	    proceed;
	  }
	  when King {
	    # Castling
	    succeed unless file($from) eq 'e' and (
	      self.turn == white && self.castling-rights ~~ /<[KQ]>/ or
	      self.turn == black && self.castling-rights ~~ /<[kq]>/
	    );
	    for &left, &right Z LongCastle, ShortCastle -> (&direction, ::castle) {
	      my $to = direction($from);
	      next if self.board{$to};
	      $to = direction($to);
	      next if self.board{$to};
	      take Move.new(:$from, :$to, :$moving-piece) but castle;
	    }
	  }
	  when Queen|Bishop|Rook {
	    for .moves -> &dir {
	      for self.ray($from, &dir) -> $to {
		my $move = Move.new: :$from, :$to, :$moving-piece;
		$move does _Capture if self.board{$to};
		take $move;
	      }
	    }
	  }
	  when Pawn {
	    my (&forward, $start-rank, $sub-promotion-rank);
	    if .color == white {
	      &forward = &up;
	      $start-rank = 2;
	      $sub-promotion-rank = 7;
	    } else {
	      &forward = &down;
	      $start-rank = 7;
	      $sub-promotion-rank = 2;
	    }
	    try {
	      # moving forward one square
	      my $to = &forward($from);
	      unless self.board{$to} {
		if $from ~~ /$sub-promotion-rank/ {
		  for Queen, Rook, Bishop, Knight {
		    take Move.new: :$from, :$to, :promotion(.new(:color(self.turn))), :$moving-piece;
		  }
		} else { take Move.new: :$from, :$to, :$moving-piece }
	      }
	    }
	    if $from ~~ /$start-rank$/ {
	      # moving forward two squares (special move)
	      # this can never be a promotion
	      # and this can never go off-board (so no need to catch errors)
	      my $on = &forward($from);
	      my $to = &forward($on);
	      my $en-passant;
	      unless ?self.board{$on} or ?self.board{$to} {
		for &left, &right -> &dir {
		  try {
		    my $piece = self.board{&dir($to)};
		    if ?$piece and $piece ~~ Pawn and $piece.color !== .color {
		      $en-passant = $on;
		    } 
		  }
		}
		if ?$en-passant {
		  take Move.new: :$from, :$to, :$moving-piece, :$en-passant;
		} else {
		  take Move.new: :$from, :$to, :$moving-piece;
		}
	      }
	    } 
	    # capturing
	    for &left, &right -> &direction {
	      try {
		my $to = &forward(&direction($from));
		my $move;
		if self.board{$to} && self.board{$to}.color ne self.turn {
		  if $from ~~ /$sub-promotion-rank$/ {
		    for Queen, Rook, Bishop, Knight {
		      $move = Move.new: :$from, :$to, :$moving-piece, :promotion(.new(:color(self.turn)));
		      take $move but _Capture;
		    }
		  } else {
		    $move = Move.new: :$from, :$to, :$moving-piece;
		    take $move but _Capture;
		  }
		} elsif $to == self.en-passant {
		  $move = Move.new: :$from, :$to, :$moving-piece;
		  take $move but _Capture
		}
	      }
	    }
	  }
	}
      }
    }
  }
  method attacks(square $s) {
    given self.clone {
      .board{$s} = Pawn.new: color => .pass.turn;
      .pseudo-legal-moves.grep({ .to == $s })
    }
  }
  method legal-moves {
    (state %){self.fen} //= Array.new:
      self.pseudo-legal-moves

      # checks must be parried
      .grep({!.(self).pass.check})
      # cannot castle out of a check
      .grep({ not $_ ~~ Castle && self.check })
  }
  method check returns Bool {
    so self.pass.attacks:
      square.pick(*).first: { $_ ~~ King and .color == self.turn given self.board{$_} }
  }
  method checkmate returns Bool { self.check and self.legal-moves == 0 }
}

class Move {
  has square ($.from, $.to, $.en-passant);
  has Piece ($.promotion, $.moving-piece);
  method CALL-ME(Position $pos) {
    given $pos.clone {
      fail if !.board{$!from} or .board{$!from}.color ne .turn;
      fail if .board{$!to} and .board{$!to}.color eq .turn;
      .board{$!to} = .board{$!from};
      .board{$!from}:delete;
      if self ~~ Castle {
	my $row = .turn eq 'white' ?? 1 !! 8;
	if (self ~~ ShortCastle) {
	  .board{square::{"f$row"}} = .board{square::{"h$row"}}:delete;
	} elsif (self ~~ LongCastle) {
	  .board{square::{"d$row"}} = .board{square::{"a$row"}}:delete;
	} else { die "unexpected castling type" }
      }	elsif .en-passant && .en-passant == $!to {
	.board{.backwards.(.en-passant)}:delete;
      }
      if $!moving-piece ~~ King {
	if .turn eq 'white' {
	  .castling-rights.=subst(/<[KQ]>/, '', :g);
	} else {
	  .castling-rights.=subst(/<[kq]>/, '', :g);
	}
	.castling-rights = '-' if .castling-rights eq '';
      } elsif $!moving-piece ~~ Rook and $!from eq <a1 a8 h1 h8>.any {
	  .castling-rights.=subst:
	    %(
	      a1 => /Q/,
	      a8 => /q/,
	      h1 => /K/,
	      h8 => /k/
	    ){$!from}, ''
	  ;
	.castling-rights = '-' if .castling-rights eq '';
      }
      if $!moving-piece ~~ Pawn or self ~~ _Capture {
	.half-move-clock = 0;
      } else { .half-move-clock++ }
      if $!promotion.defined {
	.board{$!to} = $!promotion;
      }
      if $!en-passant {
	.en-passant = $!en-passant;
      }
      .full-move-number++ if .turn == black;
      .turn = .turn == white ?? black !! white;
      .return
    }
  }
  multi method new(Str $lan where /[<[a..h]><[1..8]>]**2(<[qrbn]>?)/) {
    if $/[1] {
      samewith
	from => square::{$lan.substr: 0, 2},
	to   => square::{$lan.substr: 2, 2},
	promotion => %pieces{$/[1]} if $/[1];
    } else {
      samewith
	from => square::{$lan.substr: 0, 2},
	to   => square::{$lan.substr: 2, 2};
    }
  }
  multi method new(Str $san where /^^<Chess::PGN::half-move>$$/, Position :$pos) {
    ...
  }
  multi method new(UInt $move) {
    my $to-file   =  $move +&                 0b111;
    my $to-row    = ($move +&             0b111_000) +>  3;
    my $from-file = ($move +&         0b111_000_000) +>  6;
    my $from-row  = ($move +&     0b111_000_000_000) +>  9;
    my $promotion = ($move +& 0b111_000_000_000_000) +> 12;

    my ($from, $to) = map -> ($r, $f) { square::{('a'..'h')[$f] ~ ($r + 1)} }, ($from-row, $from-file), ($to-row, $to-file);

    samewith :$from, :$to, promotion => (Piece, Knight, Bishop, Rook, Queen)[$promotion];
  }
  method uint returns uint16 {
    my ($to, $from) = $!to, $!from;
    if self ~~ Castle { ($to, $from) .= map: { square::{.gist.trans("bg" => "ah")} } }
    my uint16 $ = reduce 8* * + *,
      $!promotion ?? %( <k b r q> Z=> 1..4 ){$!promotion.symbol.lc} !! 0,
      row($from) - 1,
      ord(file($from)) - ord('a'),
      row($to) - 1,
      ord(file($to)) - ord('a')
      ;
  }
  method gist { "$!from$!to" ~ ($!promotion ?? $!promotion.symbol.lc !! '') }
}

sub show(fen $fen) is export {
  Chess::FEN.parse: $fen;
  if %*ENV<TERM> eq 'xterm-kitty' {
    use Chess::Graphics;
    
    my $shell-command = gather {
      my Bool $flip-board = $<active-color> eq 'b';
      take "magick <(basenc --base64 -d <<<{Chess::Graphics::checkerboard}) png:-";
      my ($r, $c) = 0, 0;
      for $<board><rank> {
	for .<symbol> {
	  if .<empty-squares> {
	    $c += $_;
	  } else {
	    my ($R, $C) = ($r, $c).map: { $Chess::Graphics::square-size * ($flip-board ?? 7 - $_ !! $_) }
	    take "composite -geometry +$C+$R <(basenc --base64 -d <<<{%Chess::Graphics::pieces{$_}}) - png:-";
	    $c++;
	  }
	}
	$c = 0;
	$r++;
      }
      take "basenc --base64 -w4096"
    }.join(" |\n");
    my @payload = qqx[$shell-command].lines;
    say @payload > 1 ??
    [
      "\e_Ga=T,f=100,t=d,m=1;" ~ @payload.head ~ "\e\\",
      |@payload.tail(*-1).head(*-1).map({"\e_Gm=1;$_\e\\"}),
      "\e_Gm=0;" ~ @payload.tail ~ "\e\\"
    ].join !! "\e_a=T,f=100,t=d;" ~ @payload.pick ~ "\e\\"
  } else {
    # set black foreground
    print "\e[30m";
    my %pieces = <k q b n r p K Q B N R P> Z=> <♚ ♛ ♝ ♞ ♜ ♟ ♔ ♕ ♗ ♘ ♖ ♙>;
    for $/<board>.split('/') {
      my $r = $++;
      my @pieces = flat map { /\d/ ?? ' ' xx +$/ !! %pieces{$_} // "?" }, .comb;
      for ^8 -> $c {
	print ($r + $c) % 2 ?? "\e[100m" !! "\e[47m";
	print @pieces[$c] // '?';
      }
      print "\e[0m\n";
    }
  }
}

our proto SAN(Position $pos, Move $move --> Str) {
  (state %){$pos.fen ~ '|' ~ $move.gist} //= do {
    my $next-pos = $move.($pos);
    if    $next-pos.checkmate { {*} ~ '#' }
    elsif $next-pos.check     { {*} ~ '+' }
    else                      { {*} }
  }
}
multi SAN($, ShortCastle $) { 'O-O'   }
multi SAN($,  LongCastle $) { 'O-O-O' }
multi SAN($pos, $move) {
  my Str $san = $move.moving-piece.symbol.uc;
  if $move.moving-piece !~~ Pawn {
    my @similar-moves = $pos.legal-moves.grep({ .moving-piece.symbol ~~ $move.moving-piece.symbol && .to == $move.to  && .from !== $move.from });
    if @similar-moves > 0 {
      if @similar-moves.grep({ file(.from) eq file($move.from) }) == 0 {
	$san ~= file($move.from);
      } elsif @similar-moves.grep({ row(.from) eq row($move.from) }) == 0 {
	$san ~= row($move.from);
      } else {
	$san ~= $move.from;
      }
    }
  }
  if $move ~~ _Capture {
    $san ~= 'x';
    $san.=subst: /^P/, file($move.from);
  }
  $san ~= $move.to;
  $san.=subst: /^P/, '';

  if $move.moving-piece ~~ Pawn && row($move.to) == 8|1 {
    $san ~= '=' ~ $move.promotion.symbol.uc;
  }
  return $san;
}

multi infix:<*>(Position $position, Str $move where /^^<Chess::PGN::half-move>$$/) is export {
  fail "illegal move `$move` in position `{$position.fen}`" unless my $actual-move = $position.legal-moves.first: { SAN($position, $_) eq $move };
  $actual-move($position);
}

sub legal-moves(fen $fen) is export { Position.new(:$fen).legal-moves }

# vi: shiftwidth=2 nowrap nu
