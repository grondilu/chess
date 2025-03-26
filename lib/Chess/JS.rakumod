unit class Chess::JS;
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
class Move {...}
trusts Move;

constant WHITE  = 'w';
constant BLACK  = 'b';
constant PAWN   = 'p';
constant KNIGHT = 'n';
constant BISHOP = 'b';
constant ROOK   = 'r';
constant QUEEN  = 'q';
constant KING   = 'k';

constant DEFAULT_POSITION = q{rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1};

# emulate javascript's void 0??
constant void0 = 0 but role { method defined { False } }

constant EMPTY = -1;
constant %FLAGS = 
  NORMAL => 'n',
  CAPTURE => 'c',
  BIG_PAWN => 'b',
  EP_CAPTURE => 'e',
  PROMOTION  => 'p',
  KSIDE_CASTLE => 'k',
  QSIDE_CASTLE => 'q'
  ;

our constant @SQUARES = ([1..8] .reverse) X[R~] 'a'..'h';
constant %BITS =
  NORMAL       => 1,
  CAPTURE      => 2,
  BIG_PAWN     => 4,
  EP_CAPTURE   => 8,
  PROMOTION    => 16,
  KSIDE_CASTLE => 32,
  QSIDE_CASTLE => 64
  ;
constant %Ox88 = (@SQUARES Z=> ((0, 16 ... *) Z[X+] ^8 xx 8).flat);
constant %PAWN_OFFSETS = 
  b => [16, 32, 17, 15],
  w => [-16, -32, -17, -15]
  ;
constant %PIECE_OFFSETS = 
  n => [-18, -33, -31, -14, 18, 33, 31, 14],
  b => [-17, -15, 17, 15],
  r => [-16, 1, 16, -1],
  q => [-17, -16, -15, 1, 17, 16, 15, -1],
  k => [-17, -16, -15, 1, 17, 16, 15, -1]
;
constant @ATTACKS = 20, 0, 0, 0, 0, 0, 0, 24, 0, 0, 0, 0, 0, 0, 20, 0, 0, 20, 0, 0,
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
;
constant @RAYS = 17, 0, 0, 0, 0, 0, 0, 16, 0, 0, 0, 0, 0, 0, 15, 0, 0, 17, 0, 0, 0,
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
constant %PIECE_MASKS = p => 1, n => 2, b => 4, r => 8, q => 16, k => 32;
constant SYMBOLS = "pnbrqkPNBRQK";
constant @PROMOTIONS = KNIGHT, BISHOP, ROOK, QUEEN;
constant RANK_1 = 7;
constant RANK_2 = 6;
constant RANK_7 = 1;
constant RANK_8 = 0;
constant %SIDES = 
  (KING)  => %BITS<KSIDE_CASTLE>,
  (QUEEN) => %BITS<QSIDE_CASTLE>
;
constant %ROOKS = 
  w => [
    { square => %Ox88<a1>, flag => %BITS<QSIDE_CASTLE> },
    { square => %Ox88<h1>, flag => %BITS<KSIDE_CASTLE> }
  ],
  b => [
    { square => %Ox88<a8>, flag => %BITS<QSIDE_CASTLE> },
    { square => %Ox88<h8>, flag => %BITS<KSIDE_CASTLE> }
  ]
;
constant %SECOND_RANK = b => RANK_7, w => RANK_2;
constant @TERMINATION_MARKERS = <1-0 0-1 1/2-1/2 *>;

sub rank($square) { $square +> 4 }
sub file($square) { $square +& 15 }

sub isDigit($c) { $c ~~ /<[0..9]>/ }
sub algebraic($square) { ('a'..'h')[file($square)] ~ [1..8].reverse[rank($square)] }
sub swapColor($color) { $color eq WHITE ?? BLACK !! WHITE }

our sub validateFen($fen) {
  my @tokens = $fen.words;
  fail "Invalid FEN: must contain six space-delimited fields" if @tokens.elems !== 6;
  try my $moveNumber = @tokens[5].parse-base(10);
  fail "Invalid FEN: could not parse move number" if $!;
  try my $halfMoves = @tokens[4].parse-base(10);
  fail "Invalid FEN: could not parse number of half moves" if $!;
  fail "Invalid FEN: en-passant square is invalid" unless @tokens[3] ~~ /^[\-|<[a..h]><[36]>]$/;
  fail "Invalid FEN: castling availability is invalid" if @tokens[2] ~~ /<-[KQkq-]>/;
  fail "Invalid FEN: side-to-move is invalid" unless @tokens[1] eq 'w'|'b';
  my @rows = @tokens[0].split('/');
  fail "Invalid FEN: piece data does not contain 8 '/'-delimited rows" unless @rows == 8;
  for @rows -> $row {
    state $rank = 0;
    my UInt $sumFields = 0;
    my Bool $previousWasNumber = False;
    for ^$row.chars -> $k {
      if isDigit($row.substr($k, 1)) {
	if $previousWasNumber {
	  fail "Invalid FEN : piece data is invalid (consecutive numbers)";
	}
	$sumFields += $row.substr($k, 1);
	$previousWasNumber = True;
      } else {
	unless $row.substr($k, 1) eq "prnbqkPRNBQK".comb.any {
	  fail "Invalid FEN : piece data is invalid (invalid piece)";
	}
	$sumFields++;
	$previousWasNumber = False;
      }
    }
    $rank++;
    fail "Invalid FEN: piece data is invalid (too many or too few squares in rank {[1..8][8-$rank]})" unless $sumFields == 8;
    if @tokens[3] ~~ /3/ && @tokens[1] eq 'w' || @tokens[3] ~~ /6/ && @tokens[1] eq 'b' {
      fail "Invalid FEN: illegal en-passant square"
    }
    constant @kings =
      { color => 'white', regex => rx/K/ },
      { color => 'black', regex => rx/k/ }
      ;
    for @kings {
      unless @tokens[0].contains(.<regex>) {
	fail "Invalid FEN: missing {.<color>} king";
      }
      if @tokens[0].match(.<regex>, :g) > 1 {
	fail "Invalid FEN: too many {.<color>} kings";
      }
    }
    if @rows[0,7].join.contains(/<[pP]>/) {
      fail "Invalid FEN: some pawns are on the edge rows";
    }
  }
}
sub getDisambiguator($move, @moves) {
  my ($from, $to, $piece) = $move<from>, $move<to>, $move<piece>;
  my $ambiguities = 0;
  my $sameRank    = 0;
  my $sameFile    = 0;
  loop (my ($i, $len) = 0, @moves.elems; $i < $len; $i++) {
    my $ambigFrom  = @moves[$i]<from>;
    my $ambigTo    = @moves[$i]<to>;
    my $ambigPiece = @moves[$i]<piece>;
    if $piece eq $ambigPiece && $from ne $ambigFrom && $to eq $ambigTo {
      $ambiguities++;
      if rank($from) == rank($ambigFrom) { $sameRank++ }
      if file($from) == file($ambigFrom) { $sameFile++ }
    }
  }
  if $ambiguities > 0 {
    if $sameRank > 0 && $sameFile > 0 {
      return algebraic($from);
    } elsif $sameFile > 0 {
      return algebraic($from).substr(1, 1);
    } else {
      return algebraic($from).substr(0, 1);
    }
  }
  return '';
}

sub addMove(@moves, $color, $from, $to, $piece, $captured = void0, $flags = %BITS<NORMAL>) {
  my $r = rank($to);
  if $piece eq PAWN && $r == RANK_1|RANK_8 {
    loop (my $i = 0; $i < @PROMOTIONS.elems; $i++) {
      my $promotion = @PROMOTIONS[$i];
      @moves.push: {
	:$color,
	:$from,
	:$to,
	:$piece,
	:$captured,
	:$promotion,
	:flags($flags +| %BITS<PROMOTION>)
      };
    }
  } else {
    @moves.push: {
      :$color,
      :$from,
      :$to,
      :$piece,
      :$captured,
      :$flags
    }
  }
}
sub inferPieceType($san) {
  my $pieceType = $san.substr(0, 1);
  if 'a' le $pieceType le 'h' {
    my @matches = $san.match(/<[a..h]>\d.*<[a..h]>\d/, :g);
    if @matches {
      return void0
    }
    return PAWN;
  }
  $pieceType .= lc;
  if $pieceType eq 'o' {
    return KING
  }
  return $pieceType;
}
sub strippedSan(Str $move) {
  $move
    .subst(/'='/, '')
    .subst(/<[+#]>?<[?!]>*$/, '')
}
sub trimFen($fen) {
  $fen.split(' ').slice(0, 4).join(' ')
}

class Move {
  has (
    $.color,
    $.from,
    $.to,
    $.piece,
    $.captured,
    $.promotion,
    #`{{
    /**
     * @deprecated This field is deprecated and will be removed in version 2.0.0.
     * Please use move descriptor functions instead: `isCapture`, `isPromotion`,
     * `isEnPassant`, `isKingsideCastle`, `isQueensideCastle`, `isCastle`, and
     * `isBigPawn`
     */
    }}
    $.flags,
    $.san,
    $.lan,
    $.before,
    $.after
  );

  method new($chess, %internal, :$debug = False) {
    self.bless: :$chess, :%internal, :$debug
  }
  submethod BUILD(:$chess, :%internal (:$!color, :$!piece, :$from, :$to, :$flags, :$!captured, :$!promotion), :$debug) {
    my $fromAlgebraic = algebraic($from);
    my $toAlgebraic   = algebraic($to);
    $!from = $fromAlgebraic;
    $!to   = $toAlgebraic;
    my @moves = $chess!Chess::JS::moves: { :legal }, :$debug;
    $!san = $chess!Chess::JS::moveToSan(%internal, @moves);
    $!lan  = $fromAlgebraic ~ $toAlgebraic;
    $!before = $chess.fen();
    $chess!Chess::JS::makeMove(%internal);
    $!after = $chess.fen();
    $chess!Chess::JS::undoMove;
    $!flags = '';
    for %BITS.keys -> $flag {
      if %BITS{$flag} +& $flags {
	$!flags ~= %FLAGS{$flag}
      }
    }
    if $!promotion {
      $!lan ~= $!promotion
    }
  }
  method isCapture         { $!flags.contains: %FLAGS<CAPTURE>      }
  method isPromotion       { $!flags.contains: %FLAGS<PROMOTION>    }
  method isEnPassant       { $!flags.contains: %FLAGS<EP_CAPTURE>   }
  method isKingsideCastle  { $!flags.contains: %FLAGS<KSIDE_CASTLE> }
  method isQueensideCastle { $!flags.contains: %FLAGS<QSIDE_CASTLE> }
  method isBigPawn         { $!flags.contains: %FLAGS<BIG_PAWN>     }
}

has @!board[128];
has $!turn = WHITE;
has %!header;
has %!kings = w => EMPTY, b => EMPTY;
has $!epSquare = -1;
has $!halfMoves = 0;
has $!moveNumber = 0;
has @!history;
has %!comments;
has %!castling = w => 0, b => 0;
# tracks number of times a position has been seen for repetition checking
has %!positionCount;

method new($fen = DEFAULT_POSITION, % (:$skipValidation = False) = {}) {
  self.bless(:$fen, :$skipValidation);
}
submethod TWEAK(:$fen, :$skipValidation) {
  self.load: my $ = $fen, { :$skipValidation };
}

method clear( % (:$preserveHeaders = False) = {}) {
  @!board = Array.new: :shape(128);
  %!kings = w => EMPTY, b => EMPTY;
  $!turn = WHITE;
  %!castling = w => 0, b => 0;
  $!epSquare = EMPTY;
  $!halfMoves = 0;
  $!moveNumber = 1;
  @!history = [];
  %!comments := {};
  %!header := {} unless $preserveHeaders;
  %!positionCount := {};
  %!header<SetUp>:delete;
  %!header<FEN>:delete;
}
method load($fen, % (:$skipValidation = False, :$preserveHeaders = True) = {}) {
  my @tokens = $fen.words;
  if 2 ≤ @tokens < 6 {
    return samewith (|@tokens, |<- - 0 1>.slice(-(6 - @tokens))).join(" "),
      { :$skipValidation, :$preserveHeaders }
      ;
  }
  @tokens = $fen.words;
  unless $skipValidation {
    try validateFen $fen;
    fail $! if $!;
  }
  my $position = @tokens[0];
  my $square = 0;
  self.clear({ :preserveHeaders });
  loop (my $i = 0; $i < $position.chars; $i++) {
    my \piece = $position.substr($i, 1);
    if piece eq '/' {
      $square += 8;
    } elsif isDigit(piece) {
      $square += piece;
    } else {
      my \color = piece lt 'a' ?? WHITE !! BLACK;
      self.put: { type => piece.lc, :color(color) }, algebraic($square);
      $square++;
    }
  }
  $!turn = @tokens[1];
  given @tokens[2] {
    when /K/ { %!castling<w> +|= %BITS<KSIDE_CASTLE>; proceed }
    when /Q/ { %!castling<w> +|= %BITS<QSIDE_CASTLE>; proceed }
    when /k/ { %!castling<b> +|= %BITS<KSIDE_CASTLE>; proceed }
    when /q/ { %!castling<b> +|= %BITS<QSIDE_CASTLE>;         }
  }
  $!epSquare = @tokens[3] eq '-' ?? EMPTY !! %Ox88{@tokens[3]};
  $!halfMoves = @tokens[4].Int;
  $!moveNumber = @tokens[5].Int;
  self!updateSetup($fen);
  self!incPositionCount($fen);
}
method fen {
  my $empty = 0;
  my $fen = '';
  loop (my $i = %Ox88<a8>; $i ≤ %Ox88<h1>; $i++) {
    if @!board[$i] {
      if $empty > 0 {
	$fen ~= $empty;
	$empty = 0;
      }
      my (\color, \piece) = @!board[$i]<color type>;
      $fen ~= (color eq WHITE ?? *.uc !! *.lc)(piece);
    } else {
      $empty++
    }
    if ($i + 1) +& 136 {
      if $empty > 0 {
	$fen ~= $empty;
      }
      if $i !== %Ox88<h1> {
	$fen ~= '/';
      }
      $empty = 0;
      $i += 8;
    }
  }
  my $castling = '';
  if %!castling{WHITE} +& %BITS<KSIDE_CASTLE> {
    $castling ~= 'K'
  }
  if %!castling{WHITE} +& %BITS<QSIDE_CASTLE> {
    $castling ~= 'Q'
  }
  if %!castling{BLACK} +& %BITS<KSIDE_CASTLE> {
    $castling ~= 'k'
  }
  if %!castling{BLACK} +& %BITS<QSIDE_CASTLE> {
    $castling ~= 'q'
  }
  $castling ||= '-';
  my $epSquare = '-';
  if $!epSquare !== EMPTY {
    my \bigPawnSquare = $!epSquare + ($!turn eq WHITE ?? +16 !! -16);
    my \squares = [bigPawnSquare + 1, bigPawnSquare - 1];
    for squares -> \square {
      if square +& 136 {
	next;
      }
      my $color = $!turn;
      if @!board[square] && @!board[square]<color> eq $color && @!board[square]<type> eq PAWN {
	self!makeMove: {
	  :$color,
	  :from(square),
	  :to($!epSquare),
	  :piece(PAWN),
	  :captured(PAWN),
	  :flags(%BITS<EP_CAPTURE>)
	};
	my \isLegal = !self!isKingAttacked($color);
	self!undoMove();
	if isLegal {
	  $epSquare = algebraic($!epSquare);
	  last;
	}
      }
    }
  }
  return [
    $fen,
    $!turn,
    $castling,
    $epSquare,
    $!halfMoves,
    $!moveNumber
  ].join(' ');
}
#`[[[
/*
 * Called when the initial board setup is changed with put() or remove().
 * modifies the SetUp and FEN properties of the header object. If the FEN
 * is equal to the default position, the SetUp and FEN are deleted the setup
 * is only updated if history.length is zero, ie moves haven't been made.
 */
]]]
method !updateSetup($fen) {
  if @!history.elems > 0 { return }
  if $fen ne DEFAULT_POSITION {
    %!header<SetUp> = "1";
    %!header<FEN>   = $fen;
  } else {
    %!header<SetUp>:delete;
    %!header<FEN>  :delete;
  }
}
method reset { 
  self.load(DEFAULT_POSITION);
}
method get(\square) {
  @!board[%Ox88{square}];
}
method put(% (:$type, :$color), \square) {
  if self!put({ :$type, :$color }, square) {
    self!updateCastlingRights;
    self!updateEnPassantSquare;
    self!updateSetup(self.fen);
    return True;
  }
  return False;
}
method !put(% (:$type, :$color), \square) {
  unless SYMBOLS.match($type.lc) {
    return False;
  }
  unless %Ox88{square}:exists {
    return False;
  }
  my $sq = %Ox88{square};
  if $type eq KING && !(%!kings{$color} == EMPTY|$sq) {
    return False;
  }
  my \currentPieceOnSquare = @!board[$sq];
  if currentPieceOnSquare && currentPieceOnSquare<type> eq KING {
    %!kings{currentPieceOnSquare<color>} = EMPTY;
  }
  @!board[$sq] = { :$type, :$color };
  if $type eq KING {
    %!kings{$color} = $sq;
  }
  return True;
}
method remove(\square) {
  my $piece = self.get(square);
  @!board[%Ox88[square]]:delete;
  if $piece && $piece<type> eq KING {
    %!kings{$piece<color>} = EMPTY;
  }
  self!updateCastlingRights();
  self!updateEnPassantSquare();
  self!updateSetup(self.fen());
  return $piece
}
method !updateCastlingRights {
  my \whiteKingInPlace = .defined && .<type> eq KING && .<color> eq WHITE given @!board[%Ox88<e1>];
  my \blackKingInPlace = .defined && .<type> eq KING && .<color> eq BLACK given @!board[%Ox88<e8>];
  if !whiteKingInPlace || (@!board[%Ox88<a1>]<type> // '') ne ROOK || @!board[%Ox88<a1>]<color> ne WHITE {
    %!castling<w> +&= +^%BITS<QSIDE_CASTLE>;
  }
  if !whiteKingInPlace || (@!board[%Ox88<h1>]<type> // '') ne ROOK || @!board[%Ox88<h1>]<color> ne WHITE {
    %!castling<w> +&= +^%BITS<KSIDE_CASTLE>;
  }
  if !blackKingInPlace || (@!board[%Ox88<a8>]<type> // '') ne ROOK || @!board[%Ox88<a8>]<color> ne BLACK {
    %!castling<b> +&= +^%BITS<QSIDE_CASTLE>;
  }
  if !blackKingInPlace || (@!board[%Ox88<h8>]<type> // '') ne ROOK || @!board[%Ox88<h8>]<color> ne BLACK {
    %!castling<b> +&= +^%BITS<KSIDE_CASTLE>;
  }
}
method !updateEnPassantSquare {
  if $!epSquare == EMPTY {
    return
  }
  my \startSquare = $!epSquare + ($!turn eq WHITE ?? -16 !! 16);
  my \currentSquare = $!epSquare + ($!turn eq WHITE ?? -16 !! 16);
  my \attackers = [currentSquare + 1, currentSquare - 1];
  if @!board[startSquare] || @!board[$!epSquare] || @!board[currentSquare]<color> ne swapColor($!turn) || @!board[currentSquare]<type>  ne PAWN {
    $!epSquare = EMPTY;
    return;
  }
  my \canCapture = -> \square { !(square +& 136) && @!board[square]<color> eq $!turn && @!board[square]<type> eq PAWN };
  if attackers.grep(canCapture) {
    $!epSquare = EMPTY
  }
}
method !attacked(\color, \square, Bool :$verbose) {
  my @attackers;
  loop (my $i = %Ox88<a8>; $i ≤ %Ox88<h1> ; $i++) {
    if $i +& 136 {
      $i += 7;
      next;
    }
    if !@!board[$i] || (@!board[$i]<color> // '') ne color {
      next;
    }
    my $piece = @!board[$i];
    my \difference = $i - square;
    if difference == 0 {
      next;
    }
    my \index = difference + 119;
    if @ATTACKS[index] +& %PIECE_MASKS{$piece<type>} {
      if $piece<type> eq PAWN {
	if difference > 0 && $piece<color> eq WHITE || difference ≤ 0 && $piece<color> eq BLACK {
	  if !$verbose {
	    return True;
	  } else {
	    @attackers.push: algebraic($i)
	  }
	}
	next;
      }
      if $piece<type> eq 'n'|'k' {
	if !$verbose {
	  return True;
	} else {
	  @attackers.push: algebraic($i);
	  next;
	}
      }
      my \offset = @RAYS[index];
      my $j = $i + offset;
      my $blocked = False;
      while $j !== square {
	if @!board[$j] {
	  $blocked = True;
	  last;
	}
	$j += offset;
      }
      if !$blocked {
	if !$verbose {
	  return True;
	} else {
	  @attackers.push: algebraic($i);
	  next;
	}
      }
    }
  }
  if $verbose {
    return @attackers;
  } else {
    return False;
  }
}
method attackers(\square, $attackedBy?) {
  if !$attackedBy {
    return self!attacked($!turn, %Ox88{square}, :verbose);
  } else {
    return self!attacked($attackedBy, %Ox88{square}, :verbose);
  }
}
method !isKingAttacked(\color) {
  my \square = %!kings{color};
  square == -1 ?? False !! self!attacked(swapColor(color), square);
}
method isAttacked(\square, \attackedBy) {
  self!attacked(attackedBy, %Ox88[square])
}
method isCheck {
  self!isKingAttacked($!turn);
}
method inCheck {
  self.isCheck();
}
method isCheckmate {
  self.isCheck() && self!moves().elems == 0
}
method isStalemate {
  !self.isCheck && self!moves().elems == 0
}
method isInsufficientMaterial {
  my \pieces = {
    b => 0,
    n => 0,
    r => 0,
    q => 0,
    k => 0,
    p => 0
  };
  my \bishops = [];
  my $numPieces = 0;
  my $squareColor = 0;
  loop (my $i = %Ox88<a8>; $i ≤ %Ox88<h1>; $i++) {
    $squareColor = ($squareColor + 1) % 2;
    if $i +& 136 {
      $i += 7;
      next;
    }
    my $piece = @!board[$i];
    if $piece {
      pieces{$piece<type>} = pieces{$piece<type>}:exists ?? pieces{$piece<type>} + 1 !! 1;
      if $piece<type> eq BISHOP {
	bishops.push($squareColor);
      }
      $numPieces++;
    }
  }
  if $numPieces == 2 {
    return True;
  } elsif 
  # k vs. kn .... or .... k vs. kb
  $numPieces === 3 && (pieces{BISHOP} == 1 || pieces{KNIGHT} == 1)
  {
    return True;
  } elsif $numPieces == pieces{BISHOP} + 2 {
    my $sum = 0;
    my \len = bishops.elems;
    loop (my $i = 0; $i < len; $i++) {
      $sum += bishops[$i]
    }
    if $sum == 0|len {
      return True
    }
  }
  return False;
}
method isThreefoldRepetition {
  self!getPositionCount(self.fen()) ≥ 3
}
method isDrawByFiftyMoves {
  $!halfMoves ≥ 100
}
method isDraw {
  self.isDrawByFiftyMoves || self.isStalemate || self.isInsufficientMaterial || self.isThreefoldRepetition
}
method isGameOver {
  self.isCheckmate || self.isStalemate || self.isDraw
}
method moves(% (:$verbose = False, :$square = void0, :$piece = void0) = {}) {
  my \moves = self!moves({ :$square, :$piece });
  if $verbose {
    return moves.map( -> \move { Move.new(self, move) } );
  } else {
    return moves.map( -> \move { self!moveToSan(move, moves) } )
  }
}
method !moves(% (:$legal = True, :$piece = void0, :$square = void0) = {}, :$debug = False) {
  my \forSquare = $square.defined ?? $square.toLowerCase !! void0;
  my \forPiece = $piece.defined ?? $piece.lc !! $piece<>;
  my \moves = [];
  my $us = $!turn;
  my $them = swapColor($us);
  my $firstSquare = %Ox88<a8>;
  my $lastSquare = %Ox88<h1>;
  my $singleSquare = False;
  if forSquare {
    if %Ox88{forSquare}:!exists {
      return []
    } else {
      $firstSquare = $lastSquare = %Ox88{forSquare};
      $singleSquare = True;
    }
  }
  loop (my $from = $firstSquare; $from ≤ $lastSquare; $from++) {
    if $from +& 136 {
      $from += 7;
      next;
    }
    if !@!board[$from] || @!board[$from]<color> eq $them {
      next;
    }
    my \type = @!board[$from]<type><>;
    my $to;
    if type eq PAWN {
      next if forPiece && forPiece ne type;
	
      $to = $from + %PAWN_OFFSETS{$us}[0];
      if !@!board[$to] {
	addMove(moves, $us, $from, $to, PAWN);
	$to = $from + %PAWN_OFFSETS{$us}[1];
	if %SECOND_RANK{$us} == rank($from) && !@!board[$to] {
	  addMove(moves, $us, $from, $to, PAWN, void0, %BITS<BIG_PAWN>);
	}
      }
      loop (my $j = 2; $j < 4; $j++) {
	$to = $from + %PAWN_OFFSETS{$us}[$j];
	next if $to +& 136;

	if (@!board[$to]<color> // '') eq $them {
	  addMove(moves, $us, $from, $to, PAWN, @!board[$to]<type>, %BITS<CAPTURE>);
	} elsif $to == $!epSquare {
	  addMove(moves, $us, $from, $to, PAWN, PAWN, %BITS<EP_CAPTURE>);
	}
      }
    } else {
      if forPiece && forPiece ne type {
	next; }
      loop (my ($j, \len) = 0, %PIECE_OFFSETS{type}.elems; $j < len; $j++) {
	my \offset = %PIECE_OFFSETS{type}[$j];
	$to = $from;
	loop {
	  $to += offset;
	  last if $to +& 136;

	  if !@!board[$to] {
	    addMove(moves, $us, $from, $to, type);
	  } else {
	    last if @!board[$to]<color> eq $us;

	    addMove(moves, $us, $from, $to, type, @!board[$to]<type>, %BITS<CAPTURE>);
	    last;
	  }
	  if type eq KNIGHT|KING {
	    last;
	  }
	}
      }
    }
  }
  if !forPiece.defined  || forPiece eq KING {
    if !$singleSquare || $lastSquare == %!kings{$us} {
      if %!castling{$us} +& %BITS<KSIDE_CASTLE> {
	my \castlingFrom = %!kings{$us}<>;
	my \castlingTo = castlingFrom + 2;
	if !@!board[castlingFrom + 1] &&
	  !@!board[castlingTo] &&
	  !self!attacked($them, %!kings{$us}) &&
	  !self!attacked($them, castlingFrom + 1)
	  && !self!attacked($them, castlingTo) {
	  addMove(moves, $us, %!kings{$us}, castlingTo, KING, void0, %BITS<KSIDE_CASTLE>);
	}
      }
      if %!castling{$us} +& %BITS<QSIDE_CASTLE> {
	my \castlingFrom = %!kings{$us};
	my \castlingTo = castlingFrom - 2;
	if !@!board[castlingFrom - 1] && !@!board[castlingFrom - 2] && !@!board[castlingFrom - 3] && !self!attacked($them, %!kings{$us}) && !self!attacked($them, castlingFrom - 1) && !self!attacked($them, castlingTo) {
	  addMove(moves, $us, %!kings{$us}, castlingTo, KING, void0, %BITS<QSIDE_CASTLE>);
	}
      }
    }
  }
  if !$legal || %!kings{$us} == -1 {
    return moves;
  }
  my \legalMoves = [];
  loop (my ($i, \len) = 0, moves.elems; $i < len; $i++) {
    self!makeMove(moves[$i]);
    if !self!isKingAttacked($us) {
      legalMoves.push(moves[$i]);
    }
    self!undoMove();
  }
  return legalMoves
}
method move($move, % (:$strict = False) = {}) {
  my %moveObj;
  if $move ~~ Str {
    %moveObj := self!moveFromSan($move, $strict);
  } elsif $move ~~ Hash {
    my \moves = self!moves();
    loop (my ($i, \len) = 0, moves.elems; $i < len; $i++) {
      if $move<from> eq algebraic(moves[$i]<from>) && $move<to> eq algebraic(moves[$i]<to>) && (!moves[$i]<promotion>:exists || $move<promotion> eq moves[$i]<promotion>) {
	%moveObj := moves[$i];
	last;
      }
    }
  }
  if !%moveObj {
    if $move ~~ Str {
      die "Invalid move: $move";
    } else {
      die "Invalid move: {$move.raku}";
    }
  }
  my $prettyMove = Move.new(self, %moveObj<>);
  self!makeMove(%moveObj);
  self!incPositionCount($prettyMove.after);
  return $prettyMove;
}
method !push($move) {
  @!history.push: {
    :$move,
    :kings(%!kings.clone),
    :$!turn,
    :castling(%!castling.clone),
    :$!epSquare,
    :$!halfMoves,
    :$!moveNumber
  }
}
method !makeMove($move) {
  my $us = $!turn;
  my $them = swapColor($us);
  self!push($move);
  @!board[$move<to>] = @!board[$move<from>];
  @!board[$move<from>]:delete;
  if $move<flags> +& %BITS<EP_CAPTURE> {
    if $!turn eq BLACK {
      @!board[$move<to> - 16]:delete;
    } else {
      @!board[$move<to> + 16]:delete;
    }
  }
  if $move<promotion> {
    @!board[$move<to>] = { type => $move<promotion>, color => $us }
  }
  if (@!board[$move<to>]<type> // '') eq KING {
    %!kings{$us} = $move<to>;
    if $move<flags> +& %BITS<KSIDE_CASTLE> {
      my \castlingTo = $move<to> - 1;
      my \castlingFrom = $move<to> + 1;
      @!board[castlingTo] = @!board[castlingFrom];
      @!board[castlingFrom]:delete;
    } elsif $move<flags> +& %BITS<QSIDE_CASTLE> {
      my \castlingTo = $move<to> + 1;
      my \castlingFrom = $move<to> - 2;
      @!board[castlingTo] = @!board[castlingFrom];
      @!board[castlingFrom]:delete;
    }
    %!castling{$us} = 0;
  }
  if %!castling{$us} {
    loop (my ($i, \len) = 0, %ROOKS{$us}.elems; $i < len; $i++) {
      if $move<from> == %ROOKS{$us}[$i]<square> && %!castling{$us} +& %ROOKS{$us}[$i]<flag> {
	%!castling{$us} +^= %ROOKS{$us}[$i]<flag>;
	last;
      }
    }
  }
  if %!castling{$them} {
    loop (my ($i, \len) = 0, %ROOKS{$them}.elems; $i < len; $i++) {
      if $move<to> == %ROOKS{$them}[$i]<square> && %!castling{$them} +& %ROOKS{$them}[$i]<flag> {
	%!castling{$them} +^= %ROOKS{$them}[$i]<flag>;
	last;
      }
    }
  }
  if $move<flags> +& %BITS<BIG_PAWN> {
    if $us eq BLACK {
      $!epSquare = $move<to> - 16;
    } else {
      $!epSquare = $move<to> + 16;
    }
  } else {
    $!epSquare = EMPTY
  }
  if $move<piece> eq PAWN {
    $!halfMoves = 0;
  } elsif $move<flags> +& (%BITS<CAPTURE> +| %BITS<EP_CAPTURE>) {
    $!halfMoves = 0;
  } else {
    $!halfMoves++;
  }
  if $us eq BLACK {
    $!moveNumber++;
  }
  $!turn = $them;
}
method undo {
  my \move = self!undoMove;
  if \move {
    my \prettyMove = Move.new(self, move);
    self!decPositionCount(prettyMove.after);
    return prettyMove;
  }
  return Nil
}
method !undoMove {
  my \old = @!history.pop;
  if !old.defined {
    return Nil
  }
  my \move = old<move>;
  %!kings := old<kings>;
  $!turn  = old<turn>;
  %!castling := old<castling>;
  $!epSquare = old<epSquare>;
  $!halfMoves = old<halfMoves>;
  $!moveNumber = old<moveNumber>;
  my \us = $!turn;
  my \them = swapColor(us);
  @!board[move<from>] = @!board[move<to>];
  @!board[move<from>]<type> = move<piece>;
  @!board[move<to>]:delete;
  if move<captured> {
    if move<flags> +& %BITS<EP_CAPTURE> {
      my $index;
      if us eq BLACK {
	$index = move<to> - 16;
      } else {
	$index = move<to> + 16;
      }
      @!board[$index] = { type => PAWN, color => them };
    } else {
      @!board[move<to>] = { type => move<captured>, color => them };
    }
  }
  if move<flags> +& (%BITS<KSIDE_CASTLE> +| %BITS<QSIDE_CASTLE>) {
    my ($castlingTo, $castlingFrom);
    if move<flags> +& %BITS<KSIDE_CASTLE> {
      $castlingTo = move<to> + 1;
      $castlingFrom = move<to> - 1;
    } else {
      $castlingTo = move<to> - 2;
      $castlingFrom = move<to> + 1;
    }
    @!board[$castlingTo] = @!board[$castlingFrom]:delete;

  }
  return move;
}
method pgn(% (:$newline = "\n", :$maxWidth = 0) = {}) {
  my \result = [];
  my $headerExists = False;
  for %!header.keys -> $key {
    result.push: qq{[$key "%!header{$key}"]$newline};
    FIRST $headerExists = True;
  }
  if $headerExists && @!history.elems {
    result.push: $newline;
  }
  my &appendComment = sub ($moveString2 is rw) {
    my $comment = %!comments{self.fen};
    if $comment.defined {
      my $delimiter = $moveString2.chars > 0 ?? ' ' !! '';
      $moveString2 = "$moveString2$delimiter\{$comment\}";
    }
    return $moveString2;
  }
  my \reversedHistory = [];
  while @!history.elems > 0 {
    reversedHistory.push: self!undoMove;
  }
  my \moves = [];
  my $moveString = '';
  if reversedHistory.elems == 0 {
    moves.push: &appendComment('');
  }
  while reversedHistory.elems > 0 {
    $moveString = appendComment($moveString);
    my $move = reversedHistory.pop;
    if !$move {
      last;
    }
    if !@!history.elems && $move<color> eq 'b' {
      my $prefix = "$!moveNumber...";
      $moveString = $moveString eq '' ?? "$moveString $prefix" !! $prefix;
    } elsif $move<color> eq 'w' {
      if $moveString.chars {
	moves.push: $moveString;
      }
      $moveString = $!moveNumber ~ '.';
    }
    $moveString ~= ' ' ~ self!moveToSan($move, self!moves({ :legal }));
    self!makeMove($move);
  }
  if $moveString.chars {
    moves.push(appendComment($moveString));
  }
  if %!header<Result>:exists {
    moves.push: %!header<Result>;
  }
  if $maxWidth == 0 {
    return result.join('') ~ moves.join(' ');
  }
  my &strip = sub {
    if result.elems > 0 && result.tail eq ' ' {
      result.pop();
      return True;
    }
    return False;
  }
  my &wrapComment = sub ($width, $move) {
    for $move.words -> $token {
      if !$token {
	next;
      }
      if $width + $token.chars > $maxWidth {
	while &strip() {
	  $width--;
	}
	result.push($newline);
	$width = 0;
      }
      result.push($token);
      $width += $token.chars;
      result.push(' ');
      $width++;
    }
    return $width;
  }
  my $currentWidth = 0;
  loop (my $i = 0; $i < moves.elems; $i++) {
    if $currentWidth + moves[$i].chars > $maxWidth {
      if moves[$i] ~~ /'{'/ {
	$currentWidth = wrapComment($currentWidth, moves[$i]);
	next;
      }
    }
    if $currentWidth + moves[$i].chars > $maxWidth && $i !== 0 {
      if result.tail eq ' ' {
	result.pop;
      }
      result.push($newline);
      $currentWidth = 0;
    } elsif $i !== 0 {
      result.push(' ');
      $currentWidth++;
    }
    result.push(moves[$i]);
    $currentWidth += moves[$i].chars;
  }
  return result.join('');
}
# deprecated Use `setHeader` and `getHeaders` instead
method header(*@args) {
  loop (my $i = 0; $i < @args.elems; $i += 2) {
    if @args[$i] ~~ Str && @args[$i+1] ~~ Str {
      %!header{@args[$i]} = @args[$i + 1];
    }
  }
  return %!header;
}
method setHeader($key, $value) {
  %!header{$key} = $value;
  return %!header;
}
method removeHeader($key) {
  if %!header{$key}:exists {
    %!header{$key}:delete;
    return True;
  }
  return False;
}
method getHeaders {
  %!header
}

method loadPgn($pgn, % (:$strict = False) = {}) {
    use URI::Encode;

    sub parse_pgn_header($header) {
        my %headerObj;
        for $header.lines -> $line { # Split headers with Raku's logical newlines
            next unless $line ~~ /^\s* '[' \s* (<[A..Za..z]>+) \s* '"' (<-["]>*) '"' \s* ']' \s* $/;
            my ($key, $value) = ~$0, ~$1;
            %headerObj{$key} = $value if $key.trim.chars > 0;
        }
        %headerObj;
    }

    return self.loadPgn($pgn.trim, { :$strict }) if $pgn ~~ /\s+$/;
    my $headerRegex = rx/^ (\[ (\n | . )* \]) ( \s* \n ** 2 | \s* \n* $ ) /; # Match headers with logical \n
    my $headerMatch = $pgn ~~ $headerRegex;
    my $headerString = $headerMatch ?? ($headerMatch[0] // '') !! '';

    self.reset;
    my %headers = parse_pgn_header($headerString);
    my $fen = '';
    for %headers {
        $fen = .value if .key eq 'fen'|'FEN';
        self.setHeader(.key, .value);
    }

    if !$strict {
        self.load($fen, :preserveHeaders) if $fen;
    } else {
        if %headers<SetUp>:exists && %headers<SetUp> eq '1' {
            fail "Invalid PGN: FEN tag must be supplied with SetUp tag" unless %headers<FEN>:exists;
            self.load(%headers<FEN>, :preserveHeaders);
        }
    }

    # Comment encoding/decoding helper functions
    sub toHex($s) {
        $s.comb.map({ .ord < 128 ?? .ord.fmt('%02x') !! .encode('utf-8').map(*.fmt('%02x')).join }).join
    }

    sub fromHex($s) {
        return '' unless $s.chars;
        my $encoded = '%' ~ $s.comb(/.. | . /).join('%');
        uri_decode($encoded); # Use URI::Encode inside the method
    }

    sub encodeComment($s) {
        my $cleaned = $s.subst(/\n/, ' ', :g); # Replace logical \n with spaces
        '{' ~ toHex($cleaned.substr(1, *-1)) ~ '}';
    }

    sub decodeComment($s) {
        return fromHex($s.substr(1, *-1)) if $s.starts-with('{') && $s.ends-with('}');
    }

    # Process moves, mimicking chess.js
    #
    my $ms = $pgn.substr($headerString.chars);

    $ms .= subst(
        rx/ (\{ <-[}]>* \}) | (\; <-[\n]>* ) /, # Capture comments, exclude logical \n
        -> $m { $m[0] ?? encodeComment($m[0]) !! ' ' ~ encodeComment('{' ~ $m[1].substr(1) ~ '}') },
        :g
    );
    $ms .= subst(/\n/, ' ', :g); # Normalize logical \n to spaces
    

    my $ravRegex = rx/ '(' ~ ')' <-[()]>+ /;
    while $ms ~~ $ravRegex {
        $ms .= subst($ravRegex, '');
    }

    $ms .= subst(/\d+ '.' '..'?/, '', :g);
    $ms .= subst(/'... '/, '', :g);
    $ms .= subst(/'\$' \d+/, '', :g);
    my @moves = $ms.trim.words;

    my $result = '';
    for @moves -> $move {
        my $comment = decodeComment($move);
        if $comment.defined {
            %!comments{self.fen} = $comment;
            next;
        }
        try my %move-obj = self!moveFromSan($move, $strict);
        if $! {
            if $move eq any(@TERMINATION_MARKERS) {
                $result = $move;
            } else {
                fail "Invalid move in PGN: $move" if $strict;
                last;
            }
        } else {
            $result = '';
            self!makeMove(%move-obj);
	    note %move-obj.raku unless %move-obj<color>;
            self!incPositionCount(self.fen);
        }
    }

    self.header('Result', $result) if $result && %!header && !%!header<Result>;
    True;
}

#`[[[
/*
 * Convert a move from 0x88 coordinates to Standard Algebraic Notation
 * (SAN)
 *
 * @param {boolean} strict Use the strict SAN parser. It will throw errors
 * on overly disambiguated moves (see below):
 *
 * r1bqkbnr/ppp2ppp/2n5/1B1pP3/4P3/8/PPPP2PP/RNBQK1NR b KQkq - 2 4
 * 4. ... Nge7 is overly disambiguated because the knight on c6 is pinned
 * 4. ... Ne7 is technically the valid SAN
 */
]]]
method !moveToSan($move, @moves) {
  my $output = '';
  if $move<flags> +& %BITS<KSIDE_CASTLE> {
    $output = 'O-O';
  } elsif $move<flags> +& %BITS<QSIDE_CASTLE> {
    $output = 'O-O-O';
  } else {
    if $move<piece> ne PAWN {
      my \disambiguator = getDisambiguator($move, @moves);
      $output ~= $move<piece>.uc ~ disambiguator;
    }
    if $move<flags> +& (%BITS<CAPTURE> +| %BITS<EP_CAPTURE>) {
      if $move<piece> eq PAWN {
	$output ~= algebraic($move<from>).substr(0,1);
      }
      $output ~= 'x';
    }
    $output ~= algebraic($move<to>);
    if $move<promotion> {
      $output ~= '=' ~ $move<promotion>.uc
    }
  }
  self!makeMove($move);
  if self.isCheck {
    if self.isCheckmate {
      $output ~= '#';
    } else {
      $output ~= '+';
    }
  }
  self!undoMove;
  return $output;
}
# convert a move from Standard Algebraic Notation (SAN) to 0x88 coordinates
method !moveFromSan($move, $strict = False) {
  my \cleanMove = strippedSan($move);
  my $pieceType = inferPieceType(cleanMove);
  my @moves = self!moves({ :legal, piece => $pieceType });
  loop (my ($i, \len) = 0, @moves.elems; $i < len; $i++) {
    if cleanMove eq strippedSan(self!moveToSan(@moves[$i], @moves)) {
      return @moves[$i];
    }
  }
  if $strict {
    fail "can't parse $move in strict mode";
  }
  my Match $matches;
  my Str (
    $piece,
    $from,
    $to,
    $promotion
  );
  my $overlyDisambiguated = False;
  $matches = cleanMove.match(/(<[pnbrqkPNBRQK]>)?(<[a..h]><[1..8]>)x?\-?(<[a..h]><[1..8]>)(<[qrbnQRBN]>)?/);
  if $matches {
    $piece = ~$matches[0] if $matches[0];
    $from  = ~$matches[1] if $matches[1];
    $to    = ~$matches[2] if $matches[2];
    $promotion = ~$matches[3] if $matches[3];
    if $from.chars == 1 {
      $overlyDisambiguated = True;
    }
  } else {
    $matches = cleanMove.match(/(<[pnbrqkPNBRQK]>)?(<[a..h]>?<[1..8]>?)x?\-?(<[a..h]><[1..8]>)(<[qrbnQRBN]>)?/);
    if $matches {
      $piece = ~$matches[0] if $matches[0];
      $from  = ~$matches[1] if $matches[1];
      $to    = ~$matches[2] if $matches[2];
      $promotion = ~$matches[3] if $matches[3];
      if $from.chars == 1 {
	$overlyDisambiguated = True;
      }
    }
  }
  $pieceType = inferPieceType(cleanMove);
  @moves = self!moves: {
    :legal,
    :piece( $piece ?? $piece !! $pieceType )
  };
  if !$to {
    fail "could not parse $move (no destination square)";
  }
  {
    loop (my ($i, \len) = 0, @moves.elems; $i < len; $i++) {
      if !$from {
	if cleanMove eq strippedSan(self!moveToSan(@moves[$i], @moves)).subst(/x/, '') {
	  return @moves[$i];
	}
      } elsif (!$piece || $piece.lc eq @moves[$i]<piece>) && %Ox88{$from} == @moves[$i]<from> && %Ox88{$to} == @moves[$i]<to> && (!$promotion || $promotion.lc eq @moves[$i]<promotion>) {
	return @moves[$i];
      } elsif $overlyDisambiguated {
	my \square = algebraic(@moves[$i]<from>);
	if (!$piece || $piece.lc == @moves[$i]<piece>) && %Ox88{$to} == @moves[$i]<to> && ($from == square[0] || $from == square[1]) && (!$promotion || $promotion.lc == @moves[$i]<promotion>) {
	  return @moves[$i];
	}
      }
    }
  }
  fail "could not parse $move";
}
method ascii {
  my $s = "   +------------------------+\n";
  loop (my $i = %Ox88<a8>; $i ≤ %Ox88<h1>; $i++) {
    if file($i) == 0 {
      $s ~= " " ~ [1..8].reverse[rank($i)] ~ " |";
    }
    if @!board[$i] {
      my $piece = @!board[$i]<type>;
      my $color = @!board[$i]<color>;
      my $symbol = $color eq WHITE ?? $piece.uc !! $piece.lc;
      $s ~= " $symbol ";
    } else {
      $s ~= " . ";
    }
    if ($i + 1) +& 136 {
      $s ~= "|\n";
      $i += 8;
    }
  }
  $s ~= "   +------------------------+\n";
  $s ~= "     a  b  c  d  e  f  g  h";
  return $s;
}
method perft($depth) {
  my @moves = self!moves({ :!legal });
  my $nodes = 0;
  my $color = $!turn;
  loop (my ($i, \len) = 0, @moves.elems; $i < len; $i++) {
    self!makeMove(@moves[$i]);
    if !self!isKingAttacked($color) {
      if $depth - 1 > 0 {
	$nodes += self.perft: $depth - 1;
      } else {
	$nodes++;
      }
    }
    self!undoMove();
  }
  return $nodes;
}

method board {
  gather {
    my @row = [];
    loop (my $i = %Ox88<a8>; $i < %Ox88<h1>; $i++) {
      if !@!board[$i] {
	@row.push(Nil)
      } else {
	@row.push: %(
	  :square(algebraic($i)),
	  :type(@!board[$i]<type>),
	  :color(@!board[$i]<color>)
	)
      }
      if ($i + 1) +& 136 {
	take @row;
	@row = [];
	$i += 8
      }
    }
    take @row;
  }
}
method squareColor($square) {
  if %Ox88{$square}:exists {
    my $sq = %Ox88{$square};
    return (rank($sq) + file($sq)) % 2 == 0 ?? 'light' !! 'dark';
  }
}
method history(% (:$verbose = False) = {}) {
  my \reversedHistory = [];
  my \moveHistory = [];
  while @!history.elems > 0 {
    reversedHistory.push(self!undoMove);
  }
  loop {
    my \move = reversedHistory.pop;
    if !move {
      last;
    }
    if $verbose {
      moveHistory.push: Move.new(self, move);
    } else {
      moveHistory.push: self!moveToSan(move, self!moves)
    }
    self!makeMove(move);
  }
  return moveHistory;
}
#`[[[
/*
 * Keeps track of position occurrence counts for the purpose of repetition
 * checking. All three methods (`_inc`, `_dec`, and `_get`) trim the
 * irrelevent information from the fen, initialising new positions, and
 * removing old positions from the record if their counts are reduced to 0.
 */
]]]
method !getPositionCount($fen) {
  my \trimmedFen = trimFen($fen);
  %!positionCount{trimmedFen} // 0;
}
method !incPositionCount($fen) {
  my \trimmedFen = trimFen($fen);
  if %!positionCount{trimmedFen} === void0 {
    %!positionCount{trimmedFen} = 0
  }
  %!positionCount{trimmedFen} += 1;
}
method !decPositionCount($fen) {
  my \trimmedFen = trimFen($fen);
  if %!positionCount{trimmedFen} == 1 {
    %!positionCount{trimmedFen}:delete
  } else {
    %!positionCount{trimmedFen} -= 1;
  }
}

# vi: shiftwidth=2 nu nowrap
