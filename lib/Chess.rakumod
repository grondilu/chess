unit module Chess;

use Chess::FEN;

our constant startpos = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

sub show-FEN(Str $fen where Chess::FEN.parse($fen)) is export {
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
