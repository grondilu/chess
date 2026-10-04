use v6.d;

unit module Chess::Zobrist;

# Deterministic 64-bit keys for repetition detection. SplitMix64 is a
# local generator: these tables are not Polyglot or Stockfish keys.
constant @BUNDLE = do {
    my $state = 0xA5A5A5A512345678;
    sub splitmix64(--> UInt) {
        $state = ($state + 0x9E3779B97F4A7C15) +& 0xFFFFFFFFFFFFFFFF;
        my $z = $state;
        $z = (($z +^ ($z +> 30)) * 0xBF58476D1CE4E5B9) +& 0xFFFFFFFFFFFFFFFF;
        $z = (($z +^ ($z +> 27)) * 0x94D049BB133111EB) +& 0xFFFFFFFFFFFFFFFF;
        $z +^ ($z +> 31)
    }
    my @psq = Nil xx 16;
    for flat(1..6, 9..14) -> $p {
        # Eager: a lazy map would call splitmix64 after $state is gone.
        @psq[$p] = (splitmix64() xx 64).List;
    }
    List.new(
        @psq.List,
        (splitmix64() xx 16).List,
        (splitmix64() xx 8).List,
        splitmix64(),
    )
};

constant @PSQ    = @BUNDLE[0];
constant @CASTLE = @BUNDLE[1];
constant @EP     = @BUNDLE[2];
constant $SIDE   = @BUNDLE[3];

our sub key(@board, Int $castle, Int $ep-file, Int $side --> UInt) {
    my $k = 0;
    loop (my $i = 0; $i < 64; $i++) {
        my $p = @board[$i];
        $k +^= @PSQ[$p][$i] if $p;
    }
    $k +^= @CASTLE[$castle];
    $k +^= @EP[$ep-file] if $ep-file >= 0;
    $k +^= $SIDE if $side == 1;
    $k
}
