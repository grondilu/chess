use Test;
use lib <lib>;
use Chess;
use Chess::Colors;
use Chess::Board;

sub getAttackerCount(Chess::Position $position, $color) {
    square::{*}.sort(*.value).map: { $position.attackers($_, $color).elems }
}

subtest 'attackers - attacker count in default position', {
    is-deeply
	getAttackerCount(startpos, white).Array,
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
	getAttackerCount(startpos, black).Array,
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

    my Chess::Position $position .= new: 'r3kb1r/1b3ppp/pqnppn2/1p6/4PBP1/PNN5/1PPQBP1P/2KR3R b kq - 0 1';

    is-deeply
	getAttackerCount($position, white).Array,
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
	getAttackerCount($position, black).Array,
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

  my Chess::Position $position .=new: 'Q4K1k/1Q5p/2Q5/3Q4/4Q3/5Q2/6Q1/7Q w - - 0 1';

  is-deeply
      getAttackerCount($position, white).Array,
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
      getAttackerCount($position, black).Array,
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
    my Chess::Position $position;

    $position.=new;
    ok $position.attackers(c3) ≡ square::<b1 b2 d2>;
    ok $position.attackers(c6) ≡ ();

    $position *= 'e4';
    ok $position.attackers(c3) ≡ ();
    ok $position.attackers(c6) ≡ square::<b7 b8 d7>;

    $position *= 'e5';
    ok $position.attackers(c3) ≡ square::<b1 b2 d2>;
    ok $position.attackers(c6) ≡ ();

};

ok Chess::Position.new('2b5/4kp2/2r5/3q2n1/8/8/4P3/4K3 w - - 0 1')
    .attackers(e6, black) ≡ square::<c6 c8 d5 e7 f7 g5>,
    'attackers - every piece attacking empty square'
    ;

ok Chess::Position.new('4k3/8/8/8/5Q2/5p1R/4PK2/4N2B w - - 0 1')
    .attackers(f3) ≡ square::<e1 e2 f2 f4 h1 h3>,
    'attackers - every piece attacking another piece'
    ;

ok Chess::Position.new('B3k3/8/8/2K4R/3QPN2/8/8/8 w - - 0 1')
    .attackers(d5, white) ≡ square::<a8 c5 d4 e4 f4 h5>,
    'attackers - every piece defending empty square'
    ;

subtest {
    # knight on c3 is pinned, but it is still attacking d4 and defending e5
    my Chess::Position $position .= new: 'r1bqkbnr/ppp2ppp/2np4/1B2p3/3PP3/5N2/PPP2PPP/RNBQK2R b KQkq - 0 4';
    ok $position.attackers(d4, black) ≡ square::<c6 e5>;
    ok $position.attackers(e5, black) ≡ square::<c6 d6>;
}, 'attackers - pinned pieces still attack and defend';

ok Chess::Position.new('3k4/8/8/8/3b4/3R4/4Pq2/4K3 w - - 0 1')
    .attackers(f2, white) ≡ e1,
    'attackers - king can "attack" defended piece'
    ;

ok Chess::Position.new('5k2/8/3N1N2/2NBQQN1/3R1R2/2NPRPN1/3N1N2/4K3 w - - 0 1')
    .attackers(e4, white) ≡ square::<c3 c5 d2 d3 d4 d5 d6 e3 e5 f2 f3 f4 f5 f6 g3 g5>,
    'attackers - a lot of attackers'
    ;

ok Chess::Position.new.attackers(e4, white) ≡ (),
    'attackers - no attackers';

subtest 'attackers - readme tests', {
    my Chess::Position $position .= new;
    ok $position.attackers(f3) ≡ square::<e2 g2 g1>;
    ok $position.attackers(e2) ≡ square::<d1 e1 f1 g1>;
    ok $position.attackers(f6) ≡ ();
    $position *= 'e4';
    ok $position.attackers(f6)        ≡ square::<g8 e7 g7>;
    ok $position.attackers(f3, white) ≡ square::<g2 d1 g1>;
    $position.= new: '4k3/4n3/8/8/8/8/4R3/4K3 w - - 0 1';
    ok $position.attackers(c6, black) ≡ e7;
}

done-testing;
# vi: ft=raku shiftwidth=4 nu
