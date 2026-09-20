use v6.d;

unit module Chess;
use Chess::Zobrist;

# ---------------------------------------------------------------------------
# Chess move generation and validation in Raku.
# Not an engine: no search, no evaluation. Zobrist hashing is C via NativeCall.
# Representation is a 64-square mailbox (a1 = 0, h8 = 63), the same
# indexing Stockfish uses. Legal moves are pseudo-legal moves that do
# not leave the moving side's king in check.
# ---------------------------------------------------------------------------

constant START-FEN is export =
    'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

enum Color is export <White Black>;
enum PieceType is export (
    Pawn   => 1,
    Knight => 2,
    Bishop => 3,
    Rook   => 4,
    Queen  => 5,
    King   => 6,
);

constant WK is export = 1;
constant WQ is export = 2;
constant BK is export = 4;
constant BQ is export = 8;

# Piece encoding: 0 empty, 1–6 white P–K, 9–14 black P–K.
constant EMPTY = 0;

sub opponent-color(Int $c --> Int) is export { $c == +White ?? +Black !! +White }
sub pack-piece(Int $color, Int $type --> Int) is export { $type + ($color == +Black ?? 8 !! 0) }
sub piece-color(Int $p --> Color) is export { $p >= 8 ?? Black !! White }
sub piece-type(Int $p --> Int) is export { $p +& 7 }

constant @PIECE-CHAR =
    '', 'P', 'N', 'B', 'R', 'Q', 'K', '',
    '', 'p', 'n', 'b', 'r', 'q', 'k';
constant @UNICODE-PIECE =
    '', '♙', '♘', '♗', '♖', '♕', '♔', '',
    '', '♟', '♞', '♝', '♜', '♛', '♚';

my %CHAR-PIECE = @PIECE-CHAR.kv.map(-> $i, $c { $c => $i if $c });

# ---------------------------------------------------------------------------
# Exceptions
# ---------------------------------------------------------------------------

class X::Chess is Exception { }

class X::Chess::InvalidSquare is X::Chess {
    has $.square;
    method message { "Invalid square: $!square" }
}

class X::Chess::InvalidFEN is X::Chess {
    has $.fen;
    has $.reason;
    method message { "Invalid FEN ({$!reason}): $!fen" }
}

class X::Chess::IllegalMove is X::Chess {
    has $.move;
    has $.reason = 'not a legal move in this position';
    method message { "Illegal move {$!move}: $!reason" }
}

class X::Chess::AmbiguousMove is X::Chess {
    has $.san;
    method message { "Ambiguous move: $!san" }
}

class X::Chess::InvalidMove is X::Chess {
    has $.text;
    has $.reason = 'could not parse';
    method message { "Invalid move '{$!text}': $!reason" }
}

# ---------------------------------------------------------------------------
# Squares
# ---------------------------------------------------------------------------

# Mailbox order a1=0 .. h8=63 (rank-major, files a–h within each rank).
enum Square is export (1..8 X[R~] "A".."H");

sub file-of(Int $s --> Int) is export { $s +& 7 }
sub rank-of(Int $s --> Int) is export { $s +> 3 }

sub square(Int $file, Int $rank --> Square) is export {
    X::Chess::InvalidSquare.new(:square("$file,$rank")).throw
        unless 0 <= $file <= 7 && 0 <= $rank <= 7;
    Square(($rank +< 3) + $file)
}

sub sq-name(Int $s --> Str) is export {
    X::Chess::InvalidSquare.new(:square($s)).throw unless 0 <= $s <= 63;
    Square($s).Str.lc
}

sub sq(Str() $name --> Square) is export {
    my $n = $name.lc;
    X::Chess::InvalidSquare.new(:square($name)).throw
        unless $n ~~ /^ <[a..h]> <[1..8]> $/;
    square($n.substr(0, 1).ord - ord('a'), $n.substr(1, 1).Int - 1)
}

# Attack tables, bound at compile time. @RAYS[$sq][$dir] is the ray from $sq
# in one of eight directions, nearest square first, stopping at the edge.
# Dirs 0–3 are rook (N S E W); 4–7 are bishop (NE NW SE SW).
# Built as nested Lists so `constant @` does not flatten a level of structure.

constant @KNIGHT-TO = do {
    my @d = (1, 2), (1, -2), (-1, 2), (-1, -2), (2, 1), (2, -1), (-2, 1), (-2, -1);
    my @t = [] xx 64;
    for ^64 -> $s {
        my $f = $s +& 7;
        my $r = $s +> 3;
        for @d -> [$df, $dr] {
            my $nf = $f + $df;
            my $nr = $r + $dr;
            @t[$s].push($nr * 8 + $nf) if 0 <= $nf <= 7 && 0 <= $nr <= 7;
        }
    }
    @t.map(*.List).List
};

constant @KING-TO = do {
    my @d = (1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (1, -1), (-1, 1), (-1, -1);
    my @t = [] xx 64;
    for ^64 -> $s {
        my $f = $s +& 7;
        my $r = $s +> 3;
        for @d -> [$df, $dr] {
            my $nf = $f + $df;
            my $nr = $r + $dr;
            @t[$s].push($nr * 8 + $nf) if 0 <= $nf <= 7 && 0 <= $nr <= 7;
        }
    }
    @t.map(*.List).List
};

# [color][from] -> squares a pawn of that color attacks
constant @PAWN-ATK = do {
    my @w = [] xx 64;
    my @b = [] xx 64;
    for ^64 -> $s {
        my $f = $s +& 7;
        my $r = $s +> 3;
        @w[$s].push($s + 9) if $f < 7 && $r < 7;
        @w[$s].push($s + 7) if $f > 0 && $r < 7;
        @b[$s].push($s - 7) if $f < 7 && $r > 0;
        @b[$s].push($s - 9) if $f > 0 && $r > 0;
    }
    List.new(@w.map(*.List).List, @b.map(*.List).List)
};

constant @RAYS = do {
    my @d = (0, 1), (0, -1), (1, 0), (-1, 0), (1, 1), (-1, 1), (1, -1), (-1, -1);
    my @t = [] xx 64;
    for ^64 -> $s {
        my $f = $s +& 7;
        my $r = $s +> 3;
        for @d -> [$df, $dr] {
            my @ray;
            my $nf = $f + $df;
            my $nr = $r + $dr;
            while 0 <= $nf <= 7 && 0 <= $nr <= 7 {
                @ray.push($nr * 8 + $nf);
                $nf += $df;
                $nr += $dr;
            }
            @t[$s].push(@ray.List);
        }
    }
    @t.map(*.List).List
};

# Rights to clear when a piece moves from or to this square.
constant @CR-MASK = do {
    my @m = 0 xx 64;
    @m[A1] = WQ;
    @m[E1] = WK +| WQ;
    @m[H1] = WK;
    @m[A8] = BQ;
    @m[E8] = BK +| BQ;
    @m[H8] = BK;
    @m.List
};

sub knight-dest(Int $s) is export { @KNIGHT-TO[$s].map({ Square($_) }).List }
sub king-dest(Int $s)   is export { @KING-TO[$s].map({ Square($_) }).List }

# ---------------------------------------------------------------------------
# Piece
# ---------------------------------------------------------------------------

class Piece is export {
    has Color     $.color;
    has PieceType $.type;

    method packed(--> Int) { pack-piece(+$!color, +$!type) }
    method symbol(--> Str) { @PIECE-CHAR[self.packed] }
    method unicode(--> Str) { @UNICODE-PIECE[self.packed] }
    method gist(--> Str) { self.symbol }
    method Str(--> Str) { self.symbol }

    method WHICH(Piece:D:) {
        ValueObjAt.new("Chess::Piece|{self.packed}")
    }

    method from-packed(Piece:U: Int $p --> Piece) {
        die "empty square has no piece" if $p == EMPTY;
        self.new(color => piece-color($p), type => PieceType(piece-type($p)))
    }

    method from-symbol(Piece:U: Str $s --> Piece) {
        my $p = %CHAR-PIECE{$s} // die "unknown piece symbol '$s'";
        self.from-packed($p)
    }
}

# ---------------------------------------------------------------------------
# Move  (from, to, optional promotion). Castling is king-moves-two-files;
# en passant is a pawn capturing onto the EP square.
# ---------------------------------------------------------------------------

class Move is export {
    has Square $.from is required;
    has Square $.to   is required;
    has Int $.promotion = 0;

    method new(:$from!, :$to!, :$promotion = 0) {
        my $f = $from ~~ Int ?? +$from !! sq($from.Str);
        my $t = $to   ~~ Int ?? +$to   !! sq($to.Str);
        my $p = $promotion ~~ PieceType ?? +$promotion
              !! $promotion ?? +$promotion
              !! 0;
        self.bless(:from(Square($f)), :to(Square($t)), :promotion($p))
    }

    method uci(--> Str) {
        my $u = sq-name($!from) ~ sq-name($!to);
        $u ~= ('', '', 'n', 'b', 'r', 'q')[$!promotion] if $!promotion;
        $u
    }
    method gist(--> Str) { self.uci }
    method Str(--> Str) { self.uci }

    method WHICH(Move:D:) {
        ValueObjAt.new("Chess::Move|$!from|$!to|$!promotion")
    }

    method matches(Move:D: Move:D $o --> Bool) {
        $!from == $o.from && $!to == $o.to && $!promotion == $o.promotion
    }

    method from-uci(Move:U: Str $uci --> Move) {
        my $s = $uci.trim.lc;
        X::Chess::InvalidMove.new(:text($uci), :reason('not UCI')).throw
            unless $s ~~ /^ (<[a..h]><[1..8]>) (<[a..h]><[1..8]>) (<[nbrq]>)? $/;
        my $promo = 0;
        if $2.defined {
            $promo = { n => +Knight, b => +Bishop, r => +Rook, q => +Queen }{$2.Str};
        }
        self.new(from => sq($0.Str), to => sq($1.Str), promotion => $promo)
    }
}

# ---------------------------------------------------------------------------
# Undo record for make/unmake
# ---------------------------------------------------------------------------

my class Undo {
    has Int $.captured;
    has Int $.cap-sq;
    has Int $.ep;
    has uint8 $.castle;
    has Int $.halfmove;
    has Int $.fullmove;
}

# ---------------------------------------------------------------------------
# Position
# ---------------------------------------------------------------------------

class Position is export {
    has @!board;          # 64 ints, packed pieces
    has uint8 $!side;     # +White / +Black
    has uint8 $!castle;   # WK|WQ|BK|BQ
    has Int $!ep;         # 0–63 or -1
    has Int $!halfmove;
    has Int $!fullmove;
    has @!king;           # king square per color
    has @!history;        # stack of (Move, Undo)
    has UInt @!keys;      # zobrist keys, including current

    multi method new() { self.from-fen(START-FEN) }
    multi method new(Str $fen) { self.from-fen($fen) }
    multi method new(:$fen!) { self.from-fen($fen) }

    method from-fen(Position:U: Str $fen --> Position) {
        my $p = self.bless;
        $p!setup-fen($fen);
        $p
    }

    method clone(Position:D: --> Position) {
        my $n = Position.bless;
        $n!copy-from(self);
        $n
    }

    method !copy-from(Position:D $o) {
        @!board    = $o!board-copy;
        $!side     = $o!side-of;
        $!castle   = $o!castle-of;
        $!ep       = $o!ep-of;
        $!halfmove = $o!halfmove-of;
        $!fullmove = $o!fullmove-of;
        @!king     = $o!king-copy;
        @!history  = ();
        @!keys     = ($o!hash-key,);
    }

    method !board-copy { @!board.List.Array }
    method !king-copy  { @!king.List.Array }
    method !side-of    { $!side }
    method !castle-of  { $!castle }
    method !ep-of      { $!ep }
    method !halfmove-of { $!halfmove }
    method !fullmove-of { $!fullmove }

    # -- FEN ----------------------------------------------------------------

    method !setup-fen(Str $fen) {
        my @parts = $fen.trim.split(/\s+/);
        X::Chess::InvalidFEN.new(:$fen, :reason('expected at least 4 fields')).throw
            unless @parts >= 4;

        my ($place, $stm, $castle, $ep, $hm, $fm) =
            @parts[0], @parts[1], @parts[2], @parts[3],
            @parts[4] // '0', @parts[5] // '1';

        @!board = 0 xx 64;
        @!king  = -1, -1;

        my @ranks = $place.split('/');
        X::Chess::InvalidFEN.new(:$fen, :reason('need 8 ranks')).throw
            unless @ranks == 8;

        for @ranks.kv -> $ri, $rank {
            my $file = 0;
            my $rank-i = 7 - $ri;
            for $rank.comb -> $ch {
                if $ch ~~ /<[1..8]>/ {
                    $file += $ch.Int;
                }
                elsif %CHAR-PIECE{$ch}:exists {
                    X::Chess::InvalidFEN.new(:$fen, :reason("rank overflow on rank {$rank-i + 1}")).throw
                        if $file > 7;
                    my $sq = $rank-i * 8 + $file;
                    my $p  = %CHAR-PIECE{$ch};
                    my $t  = piece-type($p);
                    if $t == +Pawn && ($rank-i == 0 || $rank-i == 7) {
                        X::Chess::InvalidFEN.new(:$fen, :reason("pawn on {sq-name($sq)}")).throw;
                    }
                    @!board[$sq] = $p;
                    @!king[piece-color($p)] = $sq if $t == +King;
                    $file++;
                }
                else {
                    X::Chess::InvalidFEN.new(:$fen, :reason("unknown character '$ch'")).throw;
                }
            }
            X::Chess::InvalidFEN.new(:$fen, :reason("rank {8 - $ri} does not have 8 files")).throw
                unless $file == 8;
        }

        my $white-kings = @!board.grep(* == pack-piece(+White, +King)).elems;
        my $black-kings = @!board.grep(* == pack-piece(+Black, +King)).elems;
        X::Chess::InvalidFEN.new(:$fen, :reason('white must have exactly one king')).throw
            unless $white-kings == 1;
        X::Chess::InvalidFEN.new(:$fen, :reason('black must have exactly one king')).throw
            unless $black-kings == 1;

        given $stm {
            when 'w' { $!side = +White }
            when 'b' { $!side = +Black }
            default {
                X::Chess::InvalidFEN.new(:$fen, :reason("side to move must be w or b")).throw;
            }
        }

        $!castle = 0;
        if $castle ne '-' {
            for $castle.comb -> $ch {
                given $ch {
                    when 'K' {
                        $!castle +|= WK
                            if @!board[E1] == pack-piece(+White, +King)
                            && @!board[H1] == pack-piece(+White, +Rook);
                    }
                    when 'Q' {
                        $!castle +|= WQ
                            if @!board[E1] == pack-piece(+White, +King)
                            && @!board[A1] == pack-piece(+White, +Rook);
                    }
                    when 'k' {
                        $!castle +|= BK
                            if @!board[E8] == pack-piece(+Black, +King)
                            && @!board[H8] == pack-piece(+Black, +Rook);
                    }
                    when 'q' {
                        $!castle +|= BQ
                            if @!board[E8] == pack-piece(+Black, +King)
                            && @!board[A8] == pack-piece(+Black, +Rook);
                    }
                    when '-' { }
                    default {
                        X::Chess::InvalidFEN.new(:$fen, :reason("bad castling flag '$ch'")).throw;
                    }
                }
            }
        }

        $!ep = -1;
        if $ep ne '-' {
            my $esq = try { sq($ep) };
            X::Chess::InvalidFEN.new(:$fen, :reason("bad en passant square '$ep'")).throw
                unless $esq.defined;
            my $want-rank = $!side == +White ?? 5 !! 2;
            $!ep = $esq if rank-of($esq) == $want-rank;
        }

        X::Chess::InvalidFEN.new(:$fen, :reason('halfmove clock must be a non-negative integer')).throw
            unless $hm ~~ /^\d+$/;
        X::Chess::InvalidFEN.new(:$fen, :reason('fullmove number must be a positive integer')).throw
            unless $fm ~~ /^\d+$/ && $fm.Int >= 0;
        $!halfmove = $hm.Int;
        $!fullmove = max(1, $fm.Int);

        @!history = ();
        @!keys = (self!hash-key,);
    }

    method fen(--> Str) {
        my @ranks;
        for (7, 6, 5, 4, 3, 2, 1, 0) -> $r {
            my $row = '';
            my $empty = 0;
            for ^8 -> $f {
                my $p = @!board[$r * 8 + $f];
                if $p == EMPTY {
                    $empty++;
                }
                else {
                    $row ~= $empty if $empty;
                    $empty = 0;
                    $row ~= @PIECE-CHAR[$p];
                }
            }
            $row ~= $empty if $empty;
            @ranks.push($row);
        }
        my $place = @ranks.join('/');
        my $stm = $!side == +White ?? 'w' !! 'b';
        my $cr = '';
        $cr ~= 'K' if $!castle +& WK;
        $cr ~= 'Q' if $!castle +& WQ;
        $cr ~= 'k' if $!castle +& BK;
        $cr ~= 'q' if $!castle +& BQ;
        $cr = '-' unless $cr;
        my $ep = $!ep >= 0 ?? sq-name($!ep) !! '-';
        "$place $stm $cr $ep $!halfmove $!fullmove"
    }

    method Str(--> Str) { self.fen }
    method gist(--> Str) { self.ascii }

    method ascii(:$unicode = False --> Str) {
        my @lines;
        for (7, 6, 5, 4, 3, 2, 1, 0) -> $r {
            my @cells = ($r + 1) ~ ' ';
            for ^8 -> $f {
                my $p = @!board[$r * 8 + $f];
                @cells.push($p == EMPTY ?? '.' !! ($unicode ?? @UNICODE-PIECE[$p] !! @PIECE-CHAR[$p]));
            }
            @lines.push(@cells.join(' '));
        }
        @lines.push('  a b c d e f g h');
        @lines.join("\n")
    }

    # -- accessors ----------------------------------------------------------

    method side-to-move(--> Color) { Color($!side) }
    method castling-rights(--> Int) { $!castle }
    method en-passant-square() { $!ep >= 0 ?? Square($!ep) !! Nil }
    method halfmove-clock(--> Int) { $!halfmove }
    method fullmove-number(--> Int) { $!fullmove }
    method king-square(Color $c --> Square) { Square(@!king[+$c]) }

    method piece-at($square) {
        my $s = $square ~~ Int ?? +$square !! sq($square.Str);
        my $p = @!board[$s];
        $p == EMPTY ?? Nil !! Piece.from-packed($p)
    }

    method occupied($square --> Bool) {
        my $s = $square ~~ Int ?? +$square !! sq($square.Str);
        @!board[$s] != EMPTY
    }

    method can-castle(uint8 $right --> Bool) { so $!castle +& $right }

    # -- attacks ------------------------------------------------------------

    method !square-attacked(Int $sq, Int $by --> Bool) {
        my $them-pawn = pack-piece($by, +Pawn);
        # A pawn of $by attacks $sq from the squares a pawn of the other
        # color would attack *from* $sq.
        for @(@PAWN-ATK[opponent-color($by)][$sq]) -> $from {
            return True if @!board[$from] == $them-pawn;
        }
        my $them-knight = pack-piece($by, +Knight);
        for @(@KNIGHT-TO[$sq]) -> $from {
            return True if @!board[$from] == $them-knight;
        }
        my $them-king = pack-piece($by, +King);
        for @(@KING-TO[$sq]) -> $from {
            return True if @!board[$from] == $them-king;
        }
        my $them-bishop = pack-piece($by, +Bishop);
        my $them-rook   = pack-piece($by, +Rook);
        my $them-queen  = pack-piece($by, +Queen);
        for ^4 -> $d {
            for @(@RAYS[$sq][$d]) -> $s {
                my $p = @!board[$s];
                next unless $p;
                return True if $p == $them-rook || $p == $them-queen;
                last;
            }
        }
        for 4..7 -> $d {
            for @(@RAYS[$sq][$d]) -> $s {
                my $p = @!board[$s];
                next unless $p;
                return True if $p == $them-bishop || $p == $them-queen;
                last;
            }
        }
        False
    }

    method in-check(--> Bool) {
        self!square-attacked(@!king[$!side], opponent-color($!side))
    }

    method is-check(--> Bool) { self.in-check }

    method attackers($square, Color $by) {
        my $s = $square ~~ Int ?? +$square !! sq($square.Str);
        my $c = +$by;
        my @a;
        loop (my $i = 0; $i < 64; $i++) {
            my $p = @!board[$i];
            next unless $p && piece-color($p) == $c;
            @a.push($i) if self!attacks-from($i, $s);
        }
        @a
    }

    method !attacks-from(Int $from, Int $to --> Bool) {
        my $p = @!board[$from];
        return False unless $p;
        my $t = piece-type($p);
        my $c = piece-color($p);
        given $t {
            when +Pawn   { so $to == @(@PAWN-ATK[$c][$from]).any }
            when +Knight { so $to == @(@KNIGHT-TO[$from]).any }
            when +King   { so $to == @(@KING-TO[$from]).any }
            when +Bishop { self!slider-hits($from, $to, 4, 7) }
            when +Rook   { self!slider-hits($from, $to, 0, 3) }
            when +Queen  { self!slider-hits($from, $to, 0, 7) }
            default { False }
        }
    }

    method !slider-hits(Int $from, Int $to, Int $d0, Int $d1 --> Bool) {
        for $d0..$d1 -> $d {
            for @(@RAYS[$from][$d]) -> $s {
                return True if $s == $to;
                last if @!board[$s];
            }
        }
        False
    }

    # -- move generation ----------------------------------------------------

    method !is-castle(Move $m --> Bool) {
        piece-type(@!board[$m.from]) == +King && abs(file-of($m.to) - file-of($m.from)) == 2
    }

    method !is-en-passant(Move $m --> Bool) {
        $!ep >= 0
            && $m.to == $!ep
            && piece-type(@!board[$m.from]) == +Pawn
            && file-of($m.from) != file-of($m.to)
    }

    method !push-move(@moves, Int $from, Int $to, Int $promo = 0) {
        @moves.push(Move.new(:$from, :$to, :promotion($promo)));
    }

    method !push-promotions(@moves, Int $from, Int $to) {
        for +Queen, +Rook, +Bishop, +Knight -> $pr {
            self!push-move(@moves, $from, $to, $pr);
        }
    }

    method pseudo-legal-moves(--> List) {
        my @moves;
        my $us   = $!side;
        my $them = opponent-color($us);
        my $dir  = $us == +White ?? 8 !! -8;
        my $start-rank = $us == +White ?? 1 !! 6;
        my $promo-rank = $us == +White ?? 7 !! 0;

        loop (my $from = 0; $from < 64; $from++) {
            my $p = @!board[$from];
            next unless $p && piece-color($p) == $us;
            my $t = piece-type($p);

            given $t {
                when +Pawn {
                    my $one = $from + $dir;
                    if 0 <= $one <= 63 && @!board[$one] == EMPTY {
                        if rank-of($one) == $promo-rank {
                            self!push-promotions(@moves, $from, $one);
                        }
                        else {
                            self!push-move(@moves, $from, $one);
                            if rank-of($from) == $start-rank {
                                my $two = $from + 2 * $dir;
                                self!push-move(@moves, $from, $two) if @!board[$two] == EMPTY;
                            }
                        }
                    }
                    for @(@PAWN-ATK[$us][$from]) -> $to {
                        my $cap = @!board[$to];
                        if $cap && piece-color($cap) == $them && piece-type($cap) != +King {
                            if rank-of($to) == $promo-rank {
                                self!push-promotions(@moves, $from, $to);
                            }
                            else {
                                self!push-move(@moves, $from, $to);
                            }
                        }
                        elsif $!ep >= 0 && $to == $!ep {
                            self!push-move(@moves, $from, $to);
                        }
                    }
                }
                when +Knight {
                    for @(@KNIGHT-TO[$from]) -> $to {
                        my $cap = @!board[$to];
                        if $cap == EMPTY || (piece-color($cap) == $them && piece-type($cap) != +King) {
                            self!push-move(@moves, $from, $to);
                        }
                    }
                }
                when +Bishop {
                    self!gen-slider(@moves, $from, $us, $them, 4, 7);
                }
                when +Rook {
                    self!gen-slider(@moves, $from, $us, $them, 0, 3);
                }
                when +Queen {
                    self!gen-slider(@moves, $from, $us, $them, 0, 7);
                }
                when +King {
                    for @(@KING-TO[$from]) -> $to {
                        my $cap = @!board[$to];
                        if $cap == EMPTY || (piece-color($cap) == $them && piece-type($cap) != +King) {
                            self!push-move(@moves, $from, $to);
                        }
                    }
                    self!gen-castling(@moves, $from, $us);
                }
            }
        }
        @moves.List
    }

    method !gen-slider(@moves, Int $from, Int $us, Int $them, Int $d0, Int $d1) {
        for $d0..$d1 -> $d {
            for @(@RAYS[$from][$d]) -> $to {
                my $cap = @!board[$to];
                if $cap == EMPTY {
                    self!push-move(@moves, $from, $to);
                }
                else {
                    if piece-color($cap) == $them && piece-type($cap) != +King {
                        self!push-move(@moves, $from, $to);
                    }
                    last;
                }
            }
        }
    }

    method !gen-castling(@moves, Int $from, Int $us) {
        if $us == +White && $from == E1 {
            if ($!castle +& WK)
                && @!board[F1] == EMPTY && @!board[G1] == EMPTY
                && @!board[H1] == pack-piece(+White, +Rook)
            {
                self!push-move(@moves, E1, G1);
            }
            if ($!castle +& WQ)
                && @!board[D1] == EMPTY && @!board[C1] == EMPTY && @!board[B1] == EMPTY
                && @!board[A1] == pack-piece(+White, +Rook)
            {
                self!push-move(@moves, E1, C1);
            }
        }
        elsif $us == +Black && $from == E8 {
            if ($!castle +& BK)
                && @!board[F8] == EMPTY && @!board[G8] == EMPTY
                && @!board[H8] == pack-piece(+Black, +Rook)
            {
                self!push-move(@moves, E8, G8);
            }
            if ($!castle +& BQ)
                && @!board[D8] == EMPTY && @!board[C8] == EMPTY && @!board[B8] == EMPTY
                && @!board[A8] == pack-piece(+Black, +Rook)
            {
                self!push-move(@moves, E8, C8);
            }
        }
    }

    method !castle-path-safe(Move $m --> Bool) {
        my $them = opponent-color($!side);
        my $from = $m.from;
        my $to   = $m.to;
        my $step = $to > $from ?? 1 !! -1;
        my $s = $from;
        loop {
            return False if self!square-attacked($s, $them);
            last if $s == $to;
            $s += $step;
        }
        True
    }

    method !king-safe-after(Move $m --> Bool) {
        if self!is-castle($m) {
            return False unless self!castle-path-safe($m);
        }
        my $u = self!do-move($m);
        # After the move, $!side is the opponent; the mover's king is the
        # other one. It must not be attacked by the side now to move.
        my $ok = !self!square-attacked(@!king[opponent-color($!side)], $!side);
        self!undo-move($m, $u);
        $ok
    }

    method legal-moves(--> List) {
        self.pseudo-legal-moves.grep({ self!king-safe-after($_) }).List
    }

    method moves(--> List) { self.legal-moves }

    method is-legal(Move $m --> Bool) {
        return False unless 0 <= $m.from <= 63 && 0 <= $m.to <= 63;
        return False if $m.from == $m.to;
        my $p = @!board[$m.from];
        return False unless $p && piece-color($p) == $!side;
        if $m.promotion {
            return False unless piece-type($p) == +Pawn;
            return False unless $m.promotion == any(+Queen, +Rook, +Bishop, +Knight);
            my $pr = $!side == +White ?? 7 !! 0;
            return False unless rank-of($m.to) == $pr;
        }
        else {
            if piece-type($p) == +Pawn {
                my $pr = $!side == +White ?? 7 !! 0;
                return False if rank-of($m.to) == $pr;
            }
        }
        return False unless self.pseudo-legal-moves.first({ .matches($m) });
        self!king-safe-after($m)
    }

    # -- make / unmake ------------------------------------------------------

    method !do-move(Move $m --> Undo) {
        my $from = $m.from;
        my $to   = $m.to;
        my $pc   = @!board[$from];
        my $t    = piece-type($pc);
        my $us   = $!side;
        my $them = opponent-color($us);
        my $dir  = $us == +White ?? 8 !! -8;

        my $captured = EMPTY;
        my $cap-sq   = -1;
        my uint8 $is-ep = $t == +Pawn && $!ep >= 0 && $to == $!ep && file-of($from) != file-of($to) ?? 1 !! 0;
        my uint8 $is-castle = $t == +King && abs(file-of($to) - file-of($from)) == 2 ?? 1 !! 0;

        if $is-ep {
            $cap-sq   = $to - $dir;
            $captured = @!board[$cap-sq];
            @!board[$cap-sq] = EMPTY;
        }
        elsif !$is-castle {
            $captured = @!board[$to];
            $cap-sq   = $to if $captured;
        }

        my $undo = Undo.new(
            captured => $captured,
            cap-sq   => $cap-sq,
            ep       => $!ep,
            castle   => $!castle,
            halfmove => $!halfmove,
            fullmove => $!fullmove,
        );

        @!board[$from] = EMPTY;

        if $is-castle {
            @!board[$to] = $pc;
            @!king[$us] = $to;
            my $rank = rank-of($from);
            if file-of($to) == 6 {
                @!board[$rank * 8 + 7] = EMPTY;
                @!board[$rank * 8 + 5] = pack-piece($us, +Rook);
            }
            else {
                @!board[$rank * 8 + 0] = EMPTY;
                @!board[$rank * 8 + 3] = pack-piece($us, +Rook);
            }
        }
        else {
            if $m.promotion {
                @!board[$to] = pack-piece($us, $m.promotion);
            }
            else {
                @!board[$to] = $pc;
            }
            @!king[$us] = $to if $t == +King;
        }

        $!castle +&= (15 +^ (@CR-MASK[$from] +| @CR-MASK[$to]));
        if $cap-sq >= 0 {
            $!castle +&= (15 +^ @CR-MASK[$cap-sq]);
        }

        if $t == +Pawn && abs($to - $from) == 16 {
            $!ep = $from + $dir;
        }
        else {
            $!ep = -1;
        }

        if $t == +Pawn || $captured {
            $!halfmove = 0;
        }
        else {
            $!halfmove++;
        }

        $!fullmove++ if $us == +Black;
        $!side = $them;
        $undo
    }

    method !undo-move(Move $m, Undo $u) {
        my $from = $m.from;
        my $to   = $m.to;
        $!side     = opponent-color($!side);
        $!ep       = $u.ep;
        $!castle   = $u.castle;
        $!halfmove = $u.halfmove;
        $!fullmove = $u.fullmove;
        my $us = $!side;
        my uint8 $is-castle = abs(file-of($to) - file-of($from)) == 2
            && piece-type(@!board[$to]) == +King ?? 1 !! 0;

        my $pc = $m.promotion ?? pack-piece($us, +Pawn) !! @!board[$to];

        if $is-castle {
            @!board[$to]   = EMPTY;
            @!board[$from] = pack-piece($us, +King);
            @!king[$us]    = $from;
            my $rank = rank-of($from);
            if file-of($to) == 6 {
                @!board[$rank * 8 + 5] = EMPTY;
                @!board[$rank * 8 + 7] = pack-piece($us, +Rook);
            }
            else {
                @!board[$rank * 8 + 3] = EMPTY;
                @!board[$rank * 8 + 0] = pack-piece($us, +Rook);
            }
        }
        else {
            @!board[$to]   = EMPTY;
            @!board[$from] = $pc;
            @!king[$us]    = $from if piece-type($pc) == +King;
            if $u.cap-sq >= 0 {
                @!board[$u.cap-sq] = $u.captured;
            }
        }
    }

    method make-move(Move $m --> Move) {
        X::Chess::IllegalMove.new(:move($m.uci)).throw unless self.is-legal($m);
        my $u = self!do-move($m);
        @!history.push(($m, $u));
        @!keys.push(self!hash-key);
        $m
    }

    method unmake-move(--> Move) {
        die 'no move to unmake' unless @!history;
        my ($m, $u) = @!history.pop;
        @!keys.pop;
        self!undo-move($m, $u);
        $m
    }

    method play(Str $text --> Move) {
        self.make-move(self.parse-move($text))
    }

    method move-stack(--> List) { @!history.map(*.[0]).List }

    # -- parsing / SAN ------------------------------------------------------

    method parse-uci(Str $uci --> Move) {
        my $m = Move.from-uci($uci);
        X::Chess::IllegalMove.new(:move($uci)).throw unless self.is-legal($m);
        $m
    }

    method parse-move(Str $text --> Move) {
        my $s = $text.trim;
        if $s ~~ /^ <[a..h]> <[1..8]> <[a..h]> <[1..8]> <[nbrqNBRQ]>? $/ {
            return self.parse-uci($s);
        }
        self.parse-san($s)
    }

    method parse-san(Str $san --> Move) {
        my $orig = $san.trim;
        my $s = $orig;
        $s .= subst(/<[+#]>+ $/, '');
        $s .= subst(/<[!?]>+ $/, '');

        my @legal = self.legal-moves;

        if $s eq 'O-O' | '0-0' | 'o-o' {
            my @c = @legal.grep({ self!is-castle($_) && file-of(.to) == 6 });
            X::Chess::IllegalMove.new(:move($orig), :reason('no kingside castling')).throw unless @c;
            return @c[0];
        }
        if $s eq 'O-O-O' | '0-0-0' | 'o-o-o' {
            my @c = @legal.grep({ self!is-castle($_) && file-of(.to) == 2 });
            X::Chess::IllegalMove.new(:move($orig), :reason('no queenside castling')).throw unless @c;
            return @c[0];
        }

        my $promo = 0;
        if $s ~~ / ['='? (<[NBRQnbrq]>)] $/ {
            my $ch = $0.Str.uc;
            $promo = %CHAR-PIECE{$ch};
            $s .= subst(/ '='? <[NBRQnbrq]> $/, '');
        }

        X::Chess::InvalidMove.new(:text($orig), :reason('missing destination')).throw
            unless $s ~~ / (.*?) (<[a..h]> <[1..8]>) $/;
        my $dest = sq($1.Str);
        my $rest = ~$0;

        my $ptype = +Pawn;
        if $rest.chars && $rest.substr(0, 1) ~~ /<[NBRQK]>/ {
            $ptype = %CHAR-PIECE{$rest.substr(0, 1)};
            $rest = $rest.substr(1);
        }
        $rest .= subst(/x/, '', :g);

        my $from-file;
        my $from-rank;
        if $rest ~~ /^ (<[a..h]>)? (<[1..8]>)? $/ {
            $from-file = $0.defined && $0.Str.chars ?? $0.Str.ord - ord('a') !! Nil;
            $from-rank = $1.defined && $1.Str.chars ?? $1.Str.Int - 1 !! Nil;
        }
        else {
            X::Chess::InvalidMove.new(:text($orig)).throw;
        }

        my @cands = @legal.grep: -> $m {
            $m.to == $dest
            && piece-type(@!board[$m.from]) == $ptype
            && $m.promotion == $promo
            && (!$from-file.defined || file-of($m.from) == $from-file)
            && (!$from-rank.defined || rank-of($m.from) == $from-rank)
        };

        X::Chess::IllegalMove.new(:move($orig)).throw if @cands == 0;
        X::Chess::AmbiguousMove.new(:san($orig)).throw if @cands > 1;
        @cands[0]
    }

    method san(Move $m --> Str) {
        X::Chess::IllegalMove.new(:move($m.uci)).throw unless self.is-legal($m);
        my $pc   = @!board[$m.from];
        my $t    = piece-type($pc);
        my $text;

        if self!is-castle($m) {
            $text = file-of($m.to) == 6 ?? 'O-O' !! 'O-O-O';
        }
        elsif $t == +Pawn {
            if file-of($m.from) != file-of($m.to) {
                $text = chr(ord('a') + file-of($m.from)) ~ 'x' ~ sq-name($m.to);
            }
            else {
                $text = sq-name($m.to);
            }
            $text ~= '=' ~ ('', 'P', 'N', 'B', 'R', 'Q', 'K')[$m.promotion] if $m.promotion;
        }
        else {
            $text = ('', 'P', 'N', 'B', 'R', 'Q', 'K')[$t];
            my @others = self.legal-moves.grep: -> $o {
                !$o.matches($m)
                && $o.to == $m.to
                && $o.promotion == $m.promotion
                && piece-type(@!board[$o.from]) == $t
            };
            if @others {
                my $file-unique = !@others.first({ file-of(.from) == file-of($m.from) });
                my $rank-unique = !@others.first({ rank-of(.from) == rank-of($m.from) });
                if $file-unique {
                    $text ~= chr(ord('a') + file-of($m.from));
                }
                elsif $rank-unique {
                    $text ~= rank-of($m.from) + 1;
                }
                else {
                    $text ~= sq-name($m.from);
                }
            }
            my $dest-occ = @!board[$m.to] || self!is-en-passant($m);
            $text ~= 'x' if $dest-occ;
            $text ~= sq-name($m.to);
        }

        my $u = self!do-move($m);
        my $check = self.in-check;
        my $mate  = $check && !self.legal-moves;
        self!undo-move($m, $u);
        $text ~ ($mate ?? '#' !! $check ?? '+' !! '')
    }

    method uci(Move $m --> Str) { $m.uci }

    # -- status -------------------------------------------------------------

    method is-checkmate(--> Bool) { self.in-check && !self.legal-moves }
    method is-stalemate(--> Bool) { !self.in-check && !self.legal-moves }

    method is-insufficient-material(--> Bool) {
        my $pawns = 0;
        my $rooks = 0;
        my $queens = 0;
        my $wn = 0; my $bn = 0;
        my $wb-dark = 0; my $wb-light = 0;
        my $bb-dark = 0; my $bb-light = 0;

        loop (my $i = 0; $i < 64; $i++) {
            my $p = @!board[$i];
            next unless $p;
            my $t = piece-type($p);
            given $t {
                when +Pawn  { $pawns++ }
                when +Rook  { $rooks++ }
                when +Queen { $queens++ }
                when +Knight {
                    piece-color($p) == +White ?? $wn++ !! $bn++;
                }
                when +Bishop {
                    # a1 (file 0, rank 0) is a dark square.
                    my $dark = (file-of($i) + rank-of($i)) +& 1 == 0;
                    if piece-color($p) == +White {
                        $dark ?? $wb-dark++ !! $wb-light++;
                    }
                    else {
                        $dark ?? $bb-dark++ !! $bb-light++;
                    }
                }
            }
        }
        return False if $pawns || $rooks || $queens;

        my $wb = $wb-dark + $wb-light;
        my $bb = $bb-dark + $bb-light;
        my $w-minors = $wn + $wb;
        my $b-minors = $bn + $bb;

        return True if $w-minors == 0 && $b-minors == 0;
        return True if ($w-minors <= 1 && $b-minors == 0) || ($b-minors <= 1 && $w-minors == 0);

        if $wn == 0 && $bn == 0 {
            my $dark  = $wb-dark + $bb-dark;
            my $light = $wb-light + $bb-light;
            return True if $dark == 0 || $light == 0;
        }
        False
    }

    method is-fifty-move(--> Bool) { $!halfmove >= 100 }
    method is-seventy-five-move(--> Bool) { $!halfmove >= 150 }

    method !hash-key(--> UInt) {
        Chess::Zobrist::key(
            @!board,
            $!castle,
            ($!ep >= 0 && self!ep-capturable ?? file-of($!ep) !! -1),
            $!side,
        )
    }

    method !ep-capturable(--> Bool) {
        return False if $!ep < 0;
        for @(@PAWN-ATK[opponent-color($!side)][$!ep]) -> $from {
            return True if @!board[$from] == pack-piece($!side, +Pawn);
        }
        False
    }

    method is-repetition(Int $n = 3 --> Bool) {
        return False unless @!keys;
        my $key = @!keys[*-1];
        my $count = 0;
        my $i = @!keys.end;
        my $limit = max(0, $i - $!halfmove);
        while $i >= $limit {
            $count++ if @!keys[$i] == $key;
            $i--;
        }
        $count >= $n
    }

    method is-threefold(--> Bool) { self.is-repetition(3) }
    method is-fivefold(--> Bool) { self.is-repetition(5) }

    method is-draw(--> Bool) {
        self.is-stalemate
            || self.is-insufficient-material
            || self.is-fifty-move
            || self.is-threefold
    }

    method is-game-over(--> Bool) { self.is-checkmate || self.is-draw }

    method result(--> Str) {
        if self.is-checkmate {
            return $!side == +White ?? '0-1' !! '1-0';
        }
        return '1/2-1/2' if self.is-draw;
        '*'
    }

    # -- perft --------------------------------------------------------------

    method perft(Int $depth --> Int) {
        return 1 if $depth <= 0;
        my @moves = self.legal-moves;
        return +@moves if $depth == 1;
        my $nodes = 0;
        for @moves -> $m {
            my $u = self!do-move($m);
            $nodes += self.perft($depth - 1);
            self!undo-move($m, $u);
        }
        $nodes
    }

    method perft-divide(Int $depth --> Hash) {
        my %div;
        for self.legal-moves -> $m {
            if $depth <= 1 {
                %div{$m.uci} = 1;
            }
            else {
                my $u = self!do-move($m);
                %div{$m.uci} = self.perft($depth - 1);
                self!undo-move($m, $u);
            }
        }
        %div
    }

    method gives-check(Move $m --> Bool) {
        my $u = self!do-move($m);
        my $c = self.in-check;
        self!undo-move($m, $u);
        $c
    }
}

sub chess-position(Str $fen = START-FEN --> Position) is export {
    Position.from-fen($fen)
}
