use Test;
use lib <lib>;
use Chess::JS;

constant @tests = [
    {
      fen => 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      board => [
        [
          { square => 'a8', type => 'r', color => 'b' },
          { square => 'b8', type => 'n', color => 'b' },
          { square => 'c8', type => 'b', color => 'b' },
          { square => 'd8', type => 'q', color => 'b' },
          { square => 'e8', type => 'k', color => 'b' },
          { square => 'f8', type => 'b', color => 'b' },
          { square => 'g8', type => 'n', color => 'b' },
          { square => 'h8', type => 'r', color => 'b' },
        ],
        [
          { square => 'a7', type => 'p', color => 'b' },
          { square => 'b7', type => 'p', color => 'b' },
          { square => 'c7', type => 'p', color => 'b' },
          { square => 'd7', type => 'p', color => 'b' },
          { square => 'e7', type => 'p', color => 'b' },
          { square => 'f7', type => 'p', color => 'b' },
          { square => 'g7', type => 'p', color => 'b' },
          { square => 'h7', type => 'p', color => 'b' },
        ],
        [Any, Any, Any, Any, Any, Any, Any, Any],
        [Any, Any, Any, Any, Any, Any, Any, Any],
        [Any, Any, Any, Any, Any, Any, Any, Any],
        [Any, Any, Any, Any, Any, Any, Any, Any],
        [
          { square => 'a2', type => 'p', color => 'w' },
          { square => 'b2', type => 'p', color => 'w' },
          { square => 'c2', type => 'p', color => 'w' },
          { square => 'd2', type => 'p', color => 'w' },
          { square => 'e2', type => 'p', color => 'w' },
          { square => 'f2', type => 'p', color => 'w' },
          { square => 'g2', type => 'p', color => 'w' },
          { square => 'h2', type => 'p', color => 'w' },
        ],
        [
          { square => 'a1', type => 'r', color => 'w' },
          { square => 'b1', type => 'n', color => 'w' },
          { square => 'c1', type => 'b', color => 'w' },
          { square => 'd1', type => 'q', color => 'w' },
          { square => 'e1', type => 'k', color => 'w' },
          { square => 'f1', type => 'b', color => 'w' },
          { square => 'g1', type => 'n', color => 'w' },
          { square => 'h1', type => 'r', color => 'w' },
        ],
      ],
    },
    # checkmate
    {
      fen => 'r3k2r/ppp2p1p/2n1p1p1/8/2B2P1q/2NPb1n1/PP4PP/R2Q3K w kq - 0 8',
      board => [
        [
          { square => 'a8', type => 'r', color => 'b' },
          Any,
          Any,
          Any,
          { square => 'e8', type => 'k', color => 'b' },
          Any,
          Any,
          { square => 'h8', type => 'r', color => 'b' },
        ],
        [
          { square => 'a7', type => 'p', color => 'b' },
          { square => 'b7', type => 'p', color => 'b' },
          { square => 'c7', type => 'p', color => 'b' },
          Any,
          Any,
          { square => 'f7', type => 'p', color => 'b' },
          Any,
          { square => 'h7', type => 'p', color => 'b' },
        ],
        [
          Any,
          Any,
          { square => 'c6', type => 'n', color => 'b' },
          Any,
          { square => 'e6', type => 'p', color => 'b' },
          Any,
          { square => 'g6', type => 'p', color => 'b' },
          Any,
        ],
        [Any, Any, Any, Any, Any, Any, Any, Any],
        [
          Any,
          Any,
          { square => 'c4', type => 'b', color => 'w' },
          Any,
          Any,
          { square => 'f4', type => 'p', color => 'w' },
          Any,
          { square => 'h4', type => 'q', color => 'b' },
        ],
        [
          Any,
          Any,
          { square => 'c3', type => 'n', color => 'w' },
          { square => 'd3', type => 'p', color => 'w' },
          { square => 'e3', type => 'b', color => 'b' },
          Any,
          { square => 'g3', type => 'n', color => 'b' },
          Any,
        ],
        [
          { square => 'a2', type => 'p', color => 'w' },
          { square => 'b2', type => 'p', color => 'w' },
          Any,
          Any,
          Any,
          Any,
          { square => 'g2', type => 'p', color => 'w' },
          { square => 'h2', type => 'p', color => 'w' },
        ],
        [
          { square => 'a1', type => 'r', color => 'w' },
          Any,
          Any,
          { square => 'd1', type => 'q', color => 'w' },
          Any,
          Any,
          Any,
          { square => 'h1', type => 'k', color => 'w' },
        ],
      ],
    }
    ];


for @tests {
	is-deeply Chess::JS.new(.<fen>).board.Array, .<board>, "Board - {.<fen>}";
}

done-testing;

# vi: shiftwidth=4 ft=raku nu
