use Test;
use lib <lib>;
use Chess;
use Chess::Board;

constant @tests = [
    {
	fen => 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
	board => [
	    [
		(a8) => 'r',
		(b8) => 'n',
		(c8) => 'b',
		(d8) => 'q',
		(e8) => 'k',
		(f8) => 'b',
		(g8) => 'n',
		(h8) => 'r',
	    ],
	    [
		(a7) => 'p',
		(b7) => 'p',
		(c7) => 'p',
		(d7) => 'p',
		(e7) => 'p',
		(f7) => 'p',
		(g7) => 'p',
		(h7) => 'p',
	    ],
	    [Any, Any, Any, Any, Any, Any, Any, Any],
	    [Any, Any, Any, Any, Any, Any, Any, Any],
	    [Any, Any, Any, Any, Any, Any, Any, Any],
	    [Any, Any, Any, Any, Any, Any, Any, Any],
	    [
		(a2) => 'P',
		(b2) => 'P',
		(c2) => 'P',
		(d2) => 'P',
		(e2) => 'P',
		(f2) => 'P',
		(g2) => 'P',
		(h2) => 'P',
	    ],
	    [
		(a1) => 'R',
		(b1) => 'N',
		(c1) => 'B',
		(d1) => 'Q',
		(e1) => 'K',
		(f1) => 'B',
		(g1) => 'N',
		(h1) => 'R',
	    ],
	],
    },
    # checkmate
    {
	fen => 'r3k2r/ppp2p1p/2n1p1p1/8/2B2P1q/2NPb1n1/PP4PP/R2Q3K w kq - 0 8',
	board => [
	    [
		(a8) => 'r',
		Any,
		Any,
		Any,
		(e8) => 'k',
		Any,
		Any,
		(h8) => 'r',
	    ],
	    [
		(a7) => 'p',
		(b7) => 'p',
		(c7) => 'p',
		Any,
		Any,
		(f7) => 'p',
		Any,
		(h7) => 'p',
	    ],
	    [
		Any,
		Any,
		(c6) => 'n',
		Any,
		(e6) => 'p',
		Any,
		(g6) => 'p',
		Any,
	    ],
	    [Any, Any, Any, Any, Any, Any, Any, Any],
	    [
		Any,
		Any,
		(c4) => 'B',
		Any,
		Any,
		(f4) => 'P',
		Any,
		(h4) => 'q',
	    ],
	    [
		Any,
		Any,
		(c3) => 'N',
		(d3) => 'P',
		(e3) => 'b',
		Any,
		(g3) => 'n',
		Any,
	    ],
	    [
		(a2) => 'P',
		(b2) => 'P',
		Any,
		Any,
		Any,
		Any,
		(g2) => 'P',
		(h2) => 'P',
	    ],
	    [
		(a1) => 'R',
		Any,
		Any,
		(d1) => 'Q',
		Any,
		Any,
		Any,
		(h1) => 'K',
	    ],
	],
    }
];


for @tests {
    is-deeply Chess::Position.new(.<fen>).all-pairs.map({ .value.defined ?? (square(.key) => .value.symbol) !! Any }).rotor(8).map(*.Array).Array, .<board>, "Board - {.<fen>}";
}

done-testing;

# vi: shiftwidth=4 ft=raku nu
