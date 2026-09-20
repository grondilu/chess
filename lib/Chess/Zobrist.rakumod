use v6.d;
use NativeCall;

unit module Chess::Zobrist;

sub zobrist-lib(--> Str) {
    state Str $path;
    return $path if $path.defined;
    my $root = $?FILE.IO.parent.parent.parent;
    my $so = $root.add('resources/libraries/libzobrist.so');
    die "Zobrist native library not found at $so; run `make`"
        unless $so.e;
    $path = $so.absolute;
}

sub chess_zobrist_key(CArray[uint8], uint8, int32, uint8 --> uint64)
    is native(&zobrist-lib) { * }

our sub key(@board, Int $castle, Int $ep-file, Int $side --> UInt) {
    my $buf = CArray[uint8].allocate(64);
    $buf[$_] = @board[$_] for ^64;
    chess_zobrist_key($buf, $castle, $ep-file, $side) +& 0xFFFFFFFFFFFFFFFF
}
