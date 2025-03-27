use Test;
use lib <lib>;
use Chess::JS;
use Chess::JS :colors;

sub getAttackerCount(Chess::JS $chess, $color) {
    Square::{'a'..'h' X~ 1..8}
    .sort(+*)
    .map: -> $sq { $chess.attackers($sq, $color).elems }
}

subtest 'attackers - attacker count in default position', {
    is-deeply
	getAttackerCount(Chess::JS.new, WHITE).Array,
	[
	    0, 0, 0, 0, 0, 0, 0, 0,
	    0, 0, 0, 0, 0, 0, 0, 0,
	    0, 0, 0, 0, 0, 0, 0, 0,
	    0, 0, 0, 0, 0, 0, 0, 0,
	    0, 0, 0, 0, 0, 0, 0, 0,
	    2, 2, 3, 2, 2, 3, 2, 2,
	    1, 1, 1, 4, 4, 1, 1, 1,
	    0, 1, 1, 1, 1, 1, 1, 0
	],
    ;

    is-deeply
	getAttackerCount(Chess::JS.new, BLACK).Array,
	[
	    0, 1, 1, 1, 1, 1, 1, 0,
	    1, 1, 1, 4, 4, 1, 1, 1,
	    2, 2, 3, 2, 2, 3, 2, 2,
	    0, 0, 0, 0, 0, 0, 0, 0,
	    0, 0, 0, 0, 0, 0, 0, 0,
	    0, 0, 0, 0, 0, 0, 0, 0,
	    0, 0, 0, 0, 0, 0, 0, 0,
	    0, 0, 0, 0, 0, 0, 0, 0,
	];

};
subtest 'attackers - attacker count in middlegame position', {

    my Chess::JS $chess .= new: 'r3kb1r/1b3ppp/pqnppn2/1p6/4PBP1/PNN5/1PPQBP1P/2KR3R b kq - 0 1';

    is-deeply
	getAttackerCount($chess, WHITE).Array,
	[
	    0, 0, 0, 0, 0, 0, 0, 0,
	    0, 0, 0, 0, 0, 0, 0, 0,
	    0, 0, 0, 2, 0, 0, 0, 1,
	    1, 2, 1, 3, 1, 2, 1, 1,
	    1, 1, 1, 2, 1, 1, 1, 0,
	    1, 1, 2, 3, 3, 1, 3, 0,
	    1, 1, 2, 4, 2, 0, 0, 2,
	    1, 2, 3, 5, 3, 3, 2, 1,
	];

    is-deeply
	getAttackerCount($chess, BLACK).Array,
	[
	    1, 2, 2, 4, 2, 2, 2, 0,
	    3, 1, 1, 2, 3, 1, 1, 2,
	    3, 0, 2, 1, 1, 1, 2, 1,
	    2, 2, 2, 2, 2, 1, 0, 1,
	    1, 1, 1, 2, 1, 0, 1, 0,
	    0, 0, 0, 0, 1, 0, 0, 0,
	    0, 0, 0, 0, 0, 1, 0, 0,
	    0, 0, 0, 0, 0, 0, 0, 0,
	];

};
subtest 'attackers - attacker count when all but one square is covered', {

  my Chess::JS $chess .=new: 'Q4K1k/1Q5p/2Q5/3Q4/4Q3/5Q2/6Q1/7Q w - - 0 1';

  is-deeply
      getAttackerCount($chess, WHITE).Array,
      [
	  1, 2, 3, 2, 4, 2, 3, 0,
	  2, 2, 2, 3, 3, 4, 3, 3,
	  3, 2, 2, 2, 3, 2, 3, 2,
	  2, 3, 2, 2, 2, 3, 2, 3,
	  3, 2, 3, 2, 2, 2, 3, 2,
	  2, 3, 2, 3, 2, 2, 2, 3,
	  3, 2, 3, 2, 3, 2, 2, 2,
	  2, 3, 2, 3, 2, 3, 2, 1,
      ];

  is-deeply
      getAttackerCount($chess, BLACK).Array,
      [
	    0, 0, 0, 0, 0, 0, 1, 0,
	    0, 0, 0, 0, 0, 0, 1, 1,
	    0, 0, 0, 0, 0, 0, 1, 0,
	    0, 0, 0, 0, 0, 0, 0, 0,
	    0, 0, 0, 0, 0, 0, 0, 0,
	    0, 0, 0, 0, 0, 0, 0, 0,
	    0, 0, 0, 0, 0, 0, 0, 0,
	    0, 0, 0, 0, 0, 0, 0, 0,
      ];

};
subtest 'attackers - return value depends on side to move', {
    my Chess::JS $chess;

    $chess.=new;
    ok $chess.attackers(c3) ≡ <b1 b2 d2>;
    ok $chess.attackers(c6) ≡ ();

    $chess.move: 'e4';
    ok $chess.attackers(c3) ≡ ();
    ok $chess.attackers(c6) ≡ <b7 b8 d7>;

    $chess.move: 'e5';
    ok $chess.attackers(c3) ≡ <b1 b2 d2>;
    ok $chess.attackers(c6) ≡ ();

};

ok Chess::JS.new('2b5/4kp2/2r5/3q2n1/8/8/4P3/4K3 w - - 0 1')
    .attackers(e6, BLACK) ≡ <c6 c8 d5 e7 f7 g5>,
    'attackers - every piece attacking empty square'
    ;

ok Chess::JS.new('4k3/8/8/8/5Q2/5p1R/4PK2/4N2B w - - 0 1')
    .attackers(f3) ≡ <e1 e2 f2 f4 h1 h3>,
    'attackers - every piece attacking another piece'
    ;

ok Chess::JS.new('B3k3/8/8/2K4R/3QPN2/8/8/8 w - - 0 1')
    .attackers(d5, WHITE) ≡ <a8 c5 d4 e4 f4 h5>,
    'attackers - every piece defending empty square'
    ;

subtest {
    # knight on c3 is pinned, but it is still attacking d4 and defending e5
    my Chess::JS $chess .= new: 'r1bqkbnr/ppp2ppp/2np4/1B2p3/3PP3/5N2/PPP2PPP/RNBQK2R b KQkq - 0 4';
    ok $chess.attackers(d4, BLACK) ≡ <c6 e5>;
    ok $chess.attackers(e5, BLACK) ≡ <c6 d6>;
}, 'attackers - pinned pieces still attack and defend';

ok Chess::JS.new('3k4/8/8/8/3b4/3R4/4Pq2/4K3 w - - 0 1')
    .attackers(f2, WHITE) ≡ <e1>,
    'attackers - king can "attack" defended piece'
    ;

ok Chess::JS.new('5k2/8/3N1N2/2NBQQN1/3R1R2/2NPRPN1/3N1N2/4K3 w - - 0 1')
    .attackers(e4, WHITE) ≡ <c3 c5 d2 d3 d4 d5 d6 e3 e5 f2 f3 f4 f5 f6 g3 g5>,
    'attackers - a lot of attackers'
    ;

ok Chess::JS.new.attackers(e4, WHITE) ≡ (),
    'attackers - no attackers';

subtest 'attackers - readme tests', {
    my Chess::JS $chess .= new;
    ok $chess.attackers(f3) ≡ <e2 g2 g1>;
    ok $chess.attackers(e2) ≡ <d1 e1 f1 g1>;
    ok $chess.attackers(f6) ≡ ().Set;
    $chess.move('e4');
    ok $chess.attackers(f6) ≡ <g8 e7 g7>;
    ok $chess.attackers(f3, WHITE) ≡ <g2 d1 g1>;
    $chess.load('4k3/4n3/8/8/8/8/4R3/4K3 w - - 0 1');
    ok $chess.attackers(c6, BLACK) ≡ <e7>;
}

done-testing;
# vi: ft=raku shiftwidth=4 nu
