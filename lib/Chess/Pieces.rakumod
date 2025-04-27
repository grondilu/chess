unit module Chess::Pieces;
use Chess::Colors;

enum piece is export (
    '♙' => 1, |<♘ ♗ ♖ ♕ ♔>,
    '♟' => 9, |<♞ ♝ ♜ ♛ ♚>
);

subset pawn   of piece is export where piece::<♙ ♟>.any;
subset knight of piece is export where piece::<♘ ♞>.any;
subset bishop of piece is export where piece::<♗ ♝>.any;
subset rook   of piece is export where piece::<♖ ♜>.any;
subset queen  of piece is export where piece::<♕ ♛>.any;
subset king   of piece is export where piece::<♔ ♚>.any;

our sub get-color(piece $piece --> color) { $piece +& 0b1000 ?? black !! white }
multi sub infix:<≡>(piece $piece, color $color) is export { get-color($piece) ~~ $color }
multi prefix:<¬>(piece $piece) is export { piece(0b1000 +^ $piece) }

constant wp is export = piece::<♙>;
constant wn is export = piece::<♘>;
constant wb is export = piece::<♗>;
constant wr is export = piece::<♖>;
constant wq is export = piece::<♕>;
constant wk is export = piece::<♔>;
constant bp is export = piece::<♟>;
constant bn is export = piece::<♞>;
constant bb is export = piece::<♝>;
constant br is export = piece::<♜>;
constant bq is export = piece::<♛>;
constant bk is export = piece::<♚>;

our proto get-offsets(piece) is export {*}
multi get-offsets(pawn $pawn) {
    map (get-color($pawn) ~~ white ?? -* !! +*), 16, 32, 15, 17;
}
multi get-offsets(knight) { -18, -33, -31, -14, 18, 33, 31, 14 }

multi get-offsets(bishop) { -17, -15, 17, 15 }
multi get-offsets(rook  ) { -16, 1, 16, -1 }
multi get-offsets(queen ) { flat samewith(bishop), samewith(rook) }
multi get-offsets(king  ) { samewith(queen) }

our sub get-mask(piece $piece --> UInt) is export { 1 +< (($piece +& 0b111) - 1) }

our sub symbol(piece $piece) is export { ($piece +& 8 ?? *.lc !! *.uc)(<p n b r q k>[$piece +& 0b0111 - 1]) }

our sub infix:<attacks>(piece $piece, UInt $index --> Bool) is looser(&infix:<+>) is export {
    so (
	constant $ = blob8.new:
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
    )[$index] +& (1 +< (($piece +& 0b111) -1));
}

# vi: shiftwidth=4 nu nowrap
