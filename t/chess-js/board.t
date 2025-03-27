use Test;
use lib <lib>;
use Chess::JS;

constant @tests = [
    {
      fen => 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      board => [
        [
          { square => 'a8', type => 'r', color => BLACK },
          { square => 'b8', type => 'n', color => BLACK },
          { square => 'c8', type => 'b', color => BLACK },
          { square => 'd8', type => 'q', color => BLACK },
          { square => 'e8', type => 'k', color => BLACK },
          { square => 'f8', type => 'b', color => BLACK },
          { square => 'g8', type => 'n', color => BLACK },
          { square => 'h8', type => 'r', color => BLACK },
        ],
        [
          { square => 'a7', type => 'p', color => BLACK },
          { square => 'b7', type => 'p', color => BLACK },
          { square => 'c7', type => 'p', color => BLACK },
          { square => 'd7', type => 'p', color => BLACK },
          { square => 'e7', type => 'p', color => BLACK },
          { square => 'f7', type => 'p', color => BLACK },
          { square => 'g7', type => 'p', color => BLACK },
          { square => 'h7', type => 'p', color => BLACK },
        ],
        [Any, Any, Any, Any, Any, Any, Any, Any],
        [Any, Any, Any, Any, Any, Any, Any, Any],
        [Any, Any, Any, Any, Any, Any, Any, Any],
        [Any, Any, Any, Any, Any, Any, Any, Any],
        [
          { square => 'a2', type => 'p', color => WHITE },
          { square => 'b2', type => 'p', color => WHITE },
          { square => 'c2', type => 'p', color => WHITE },
          { square => 'd2', type => 'p', color => WHITE },
          { square => 'e2', type => 'p', color => WHITE },
          { square => 'f2', type => 'p', color => WHITE },
          { square => 'g2', type => 'p', color => WHITE },
          { square => 'h2', type => 'p', color => WHITE },
        ],
        [
          { square => 'a1', type => 'r', color => WHITE },
          { square => 'b1', type => 'n', color => WHITE },
          { square => 'c1', type => 'b', color => WHITE },
          { square => 'd1', type => 'q', color => WHITE },
          { square => 'e1', type => 'k', color => WHITE },
          { square => 'f1', type => 'b', color => WHITE },
          { square => 'g1', type => 'n', color => WHITE },
          { square => 'h1', type => 'r', color => WHITE },
        ],
      ],
    },
    # checkmate
    {
      fen => 'r3k2r/ppp2p1p/2n1p1p1/8/2B2P1q/2NPb1n1/PP4PP/R2Q3K w kq - 0 8',
      board => [
        [
          { square => 'a8', type => 'r', color => BLACK },
          Any,
          Any,
          Any,
          { square => 'e8', type => 'k', color => BLACK },
          Any,
          Any,
          { square => 'h8', type => 'r', color => BLACK },
        ],
        [
          { square => 'a7', type => 'p', color => BLACK },
          { square => 'b7', type => 'p', color => BLACK },
          { square => 'c7', type => 'p', color => BLACK },
          Any,
          Any,
          { square => 'f7', type => 'p', color => BLACK },
          Any,
          { square => 'h7', type => 'p', color => BLACK },
        ],
        [
          Any,
          Any,
          { square => 'c6', type => 'n', color => BLACK },
          Any,
          { square => 'e6', type => 'p', color => BLACK },
          Any,
          { square => 'g6', type => 'p', color => BLACK },
          Any,
        ],
        [Any, Any, Any, Any, Any, Any, Any, Any],
        [
          Any,
          Any,
          { square => 'c4', type => 'b', color => WHITE },
          Any,
          Any,
          { square => 'f4', type => 'p', color => WHITE },
          Any,
          { square => 'h4', type => 'q', color => BLACK },
        ],
        [
          Any,
          Any,
          { square => 'c3', type => 'n', color => WHITE },
          { square => 'd3', type => 'p', color => WHITE },
          { square => 'e3', type => 'b', color => BLACK },
          Any,
          { square => 'g3', type => 'n', color => BLACK },
          Any,
        ],
        [
          { square => 'a2', type => 'p', color => WHITE },
          { square => 'b2', type => 'p', color => WHITE },
          Any,
          Any,
          Any,
          Any,
          { square => 'g2', type => 'p', color => WHITE },
          { square => 'h2', type => 'p', color => WHITE },
        ],
        [
          { square => 'a1', type => 'r', color => WHITE },
          Any,
          Any,
          { square => 'd1', type => 'q', color => WHITE },
          Any,
          Any,
          Any,
          { square => 'h1', type => 'k', color => WHITE },
        ],
      ],
    }
    ];


for @tests {
	is-deeply Chess::JS.new(.<fen>).board.Array, .<board>, "Board - {.<fen>}";
}

done-testing;

# vi: shiftwidth=4 ft=raku nu
