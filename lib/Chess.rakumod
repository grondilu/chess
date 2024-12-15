unit module Chess;
use Chess::FEN;
use Base64;

enum color is export <black white>;

enum square ('a'..'h' X~ 1..8);

sub  left(square $s where /<[b..h]>/) is export { return square::{$s.trans('b'..'h' => 'a'..'g')}; }
sub right(square $s where /<[a..g]>/) is export { return square::{$s.trans('a'..'g' => 'b'..'h')}; }
sub    up(square $s where /<[1..7]>/) is export { return square::{$s.trans(1..7     => 2..8    )}; }
sub  down(square $s where /<[2..8]>/) is export { return square::{$s.trans(2..8     => 1..7    )}; }

role Piece { method pseudo-moves(square $from) returns square {...} }

class King does Piece {
  method pseudo-moves(square $from) {
    gather for &left, &right, &up, &down, |((&left, &right) X∘ (&up, &down)) {
      try take .($from);
    }
  }
}
class Rook does Piece {
  method pseudo-moves(square $from) {
    gather for &left, &right, &up, &down {
      try loop (my $to = $from; $to = .($to); take $to) {}
    }
  }
}
class Bishop does Piece {
  method pseudo-moves(square $from) {
    gather for &left, &right X∘ &up, &down {
      try loop (my $to = $from; $to = .($to); take $to) {}
    }
  }
}
class Queen does Piece {
  method pseudo-moves(square $from) {
    gather for Bishop, Rook {
      .take for .new.pseudo-moves($from);
    }
  }
}
class Knight does Piece {
  method pseudo-moves(square $from) {
    gather for
	&left ∘ &left ∘ &up,
	&left ∘ &left ∘ &down,
	&right ∘ &right ∘ &down,
	&right ∘ &right ∘ &up,
	&up ∘ &up ∘ &left,
	&up ∘ &up ∘ &right,
	&down ∘ &down ∘ &left,
	&down ∘ &down ∘ &right {
      try take .($from)
    }
  }
}

our constant startpos = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

our subset fen of Str where { Chess::FEN.parse($_) }

sub show(Str $fen where Chess::FEN.parse($fen)) is export {
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
    my @payload = qqx{$shell-command}.lines;
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

# vi: shiftwidth=2 nowrap
