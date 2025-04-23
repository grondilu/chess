unit module Chess::Pieces;
use Chess::Colors;

# the order here matters as it's used later...
enum piece-type is export <pawn knight bishop rook queen king>;

# ...like here for instance
sub symbol(piece-type $type) is export { <p n b r q k>[$type] }

class Piece {...}
subset Pawn   of Piece is export where { .type ~~   pawn }
subset Rook   of Piece is export where { .type ~~   rook }
subset Knight of Piece is export where { .type ~~ knight }
subset Bishop of Piece is export where { .type ~~ bishop }
subset Queen  of Piece is export where { .type ~~  queen }
subset King   of Piece is export where { .type ~~   king }

class Piece is export {
    has color      $.color;
    has piece-type $.type;

    # again, we're using the order in the piece-type enum here!
    method !mask { 1 +< $!type }

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
	))[$index] +& self!mask
    }
    proto method offsets returns Blob[int] { Blob[int].new: {*} }
    multi method offsets(Pawn:  ) {  map ($!color ~~ white ?? -* !! +*), 16, 32, 17, 15 }
    multi method offsets(Rook:  ) { -16, 1, 16, -1 }
    multi method offsets(Knight:) { -18, -33, -31, -14, 18, 33, 31, 14 }
    multi method offsets(Bishop:) { -17, -15, 17, 15 }
    multi method offsets(Queen: ) { -17, -16, -15, 1, 17, 16, 15, -1 }
    multi method offsets(King:  ) { -17, -16, -15, 1, 17, 16, 15, -1 }

    method symbol returns Str { ($!color ~~ white ?? *.uc !! *.lc)(symbol($!type)) }

    method unicode-symbol returns Str {
	%(
	    (white) => < ♙ ♘ ♗ ♖ ♕ ♔ >,
	    (black) => < ♟ ♞ ♝ ♜ ♛ ♚ >
	){$!color}[$!type];
    }
}

constant grey-pawn   is export = Piece.new(:type(pawn  ));
constant grey-knight is export = Piece.new(:type(knight));
constant grey-bishop is export = Piece.new(:type(bishop));
constant grey-rook   is export = Piece.new(:type(rook  ));
constant grey-queen  is export = Piece.new(:type(queen ));
constant grey-king   is export = Piece.new(:type(king  ));

constant white-pawn   is export = Piece.new(:type(pawn  ), :color(white));
constant white-knight is export = Piece.new(:type(knight), :color(white));
constant white-bishop is export = Piece.new(:type(bishop), :color(white));
constant white-queen  is export = Piece.new(:type(queen ), :color(white));
constant white-rook   is export = Piece.new(:type(rook  ), :color(white));
constant white-king   is export = Piece.new(:type(king  ), :color(white));

constant black-pawn   is export = Piece.new(:type(pawn  ), :color(black));
constant black-knight is export = Piece.new(:type(knight), :color(black));
constant black-bishop is export = Piece.new(:type(bishop), :color(black));
constant black-rook   is export = Piece.new(:type(rook  ), :color(black));
constant black-queen  is export = Piece.new(:type(queen ), :color(black));
constant black-king   is export = Piece.new(:type(king  ), :color(black));


# vi: shiftwidth=4 nu
