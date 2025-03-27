use Test;
use lib <lib>;
use Chess::JS;
use Chess::JS :colors, :pieces;

subtest {
    my Chess::JS $chess .= new;

    ok $chess.setCastlingRights(WHITE, { (KING) => False });
    nok $chess.getCastlingRights(WHITE){KING};

}, 'setCastlingRights - clear white kingside';

subtest {
    my Chess::JS $chess .= new;

    ok $chess.setCastlingRights(WHITE, { (QUEEN) => False });
    nok $chess.getCastlingRights(WHITE){QUEEN};

}, 'setCastlingRights - clear white queenside';

subtest {
    my Chess::JS $chess .= new;

    ok $chess.setCastlingRights(BLACK, { (KING) => False });
    nok $chess.getCastlingRights(BLACK){KING};

}, 'setCastlingRights - clear black kingside';

subtest {
    my Chess::JS $chess .= new;

    ok $chess.setCastlingRights(BLACK, { (QUEEN) => False });
    nok $chess.getCastlingRights(BLACK){QUEEN};

}, 'setCastlingRights - clear black queenside';

subtest {
    my Chess::JS $chess .= new: 'r3k2r/8/8/8/8/8/8/R3K2R w - - 0 1';

    ok $chess.setCastlingRights(WHITE, { (KING) => True });
    ok $chess.getCastlingRights(WHITE){KING};

}, 'setCastlingRights - set white kingside';

subtest {
    my Chess::JS $chess .= new: 'r3k2r/8/8/8/8/8/8/R3K2R w - - 0 1';

    ok $chess.setCastlingRights(WHITE, { (QUEEN) => True });
    ok $chess.getCastlingRights(WHITE){QUEEN};

}, 'setCastlingRights - set white queenside';

subtest {
    my Chess::JS $chess .= new: 'r3k2r/8/8/8/8/8/8/R3K2R w - - 0 1';

    ok $chess.setCastlingRights(BLACK, { (KING) => True });
    ok $chess.getCastlingRights(BLACK){KING};

}, 'setCastlingRights - set black kingside';

subtest {
    my Chess::JS $chess .= new: 'r3k2r/8/8/8/8/8/8/R3K2R w - - 0 1';

    ok $chess.setCastlingRights(BLACK, { (QUEEN) => True });
    ok $chess.getCastlingRights(BLACK){QUEEN};

}, 'setCastlingRights - set black queenside';

subtest {
    my Chess::JS $chess .= new;
    $chess.clear;

    nok $chess.setCastlingRights(WHITE, { (KING) => True });
    nok $chess.getCastlingRights(WHITE){KING};

}, 'setCastlingRights - fail to set white kingside';

subtest {
    my Chess::JS $chess .= new;
    $chess.clear;

    nok $chess.setCastlingRights(WHITE, { (QUEEN) => True });
    nok $chess.getCastlingRights(WHITE){QUEEN};

}, 'setCastlingRights - fail to set white queenside';

subtest {
    my Chess::JS $chess .= new;
    $chess.clear;

    nok $chess.setCastlingRights(BLACK, { (KING) => True });
    nok $chess.getCastlingRights(BLACK){KING};

}, 'setCastlingRights - fail to set black kingside';

subtest {
    my Chess::JS $chess .= new;
    $chess.clear;

    nok $chess.setCastlingRights(BLACK, { (QUEEN) => True });
    nok $chess.getCastlingRights(BLACK){QUEEN};

}, 'setCastlingRights - fail to set black queenside';

subtest {
    my Chess::JS $chess .= new;
    $chess.clear;

    nok $chess.setCastlingRights(WHITE, { (KING) => True });
    nok $chess.getCastlingRights(WHITE){KING};

}, 'setCastlingRights - fail to set white kingside';

done-testing;

#vi: ft=raku shiftwidth=4
