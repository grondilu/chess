use lib <lib>;
use Test;
use Chess::JS;

# Test suite begins
plan 6; # Number of subtests

# 1. Move Generation
subtest 'Move Generation' => {
    my Chess::JS $game;
    sub prefix:<?>(@l) { @l.sort.join(':') }

    plan 3;
    $game .= new;
    is ?$game.moves, ?<a3 a4 b3 b4 c3 c4 d3 d4 e3 e4 f3 f4 g3 g4 h3 h4 Na3 Nc3 Nf3 Nh3>, 'Starting position moves';

    $game .= new: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
    is ?$game.moves, ?<a3 a4 b3 b4 c3 c4 d3 d4 e3 e4 f3 f4 g3 g4 h3 h4 Na3 Nc3 Nf3 Nh3>, 'FEN starting position';

    $game .= new: 'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1';
    is ?$game.moves, ?<a6 a5 b6 b5 c6 c5 d6 d5 e6 e5 f6 f5 g6 g5 h6 h5 Na6 Nc6 Nf6 Nh6>, 'After 1. e4';
}

# 2. Move Execution and SAN Notation
subtest 'Move Execution and SAN' => {
    plan 7;
    my $game = Chess::JS.new;
    my $e4 = $game.move('e4');
    is $e4.san, 'e4', 'SAN for e4';
    is $e4.flags, 'b', 'Flags for e4 (big pawn move)';

    my $d5 = $game.move('d5');
    is $d5.san, 'd5', 'SAN for d5';
    is $d5.flags, 'b', 'Flags for d5 (big pawn move)';

    my $exd5 = $game.move('exd5');
    is $exd5.san, 'exd5', 'SAN for exd5';
    is $exd5.flags, 'c', 'Flags for capture';
    is $game.fen, 'rnbqkbnr/ppp1pppp/8/3P4/8/8/PPPP1PPP/RNBQKBNR b KQkq - 0 2', 'FEN after exd5';
}

# 3. Castling
subtest 'Castling' => {
    plan 4;
    my $game = Chess::JS.new('r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1');
    my $moves = $game.moves;
    ok $moves.contains('O-O'), 'White can castle kingside';
    ok $moves.contains('O-O-O'), 'White can castle queenside';

    my $oo = $game.move('O-O');
    is $oo.san, 'O-O', 'SAN for kingside castling';
    is $game.fen, 'r3k2r/8/8/8/8/8/8/R4RK1 b kq - 1 1', 'FEN after O-O';
}

# 4. En Passant
subtest 'En Passant' => {
    plan 4;
    my $game = Chess::JS.new('rnbqkbnr/ppp1p1pp/8/3pPp2/8/8/PPPP1PPP/RNBQKBNR w KQkq f6 0 3');
    my $moves = $game.moves;
    ok $moves.contains('exf6'), 'En passant available';

    my $ep = $game.move('exf6');
    is $ep.san, 'exf6', 'SAN for en passant';
    is $ep.flags, 'e', 'Flags for en passant';
    is $game.fen, 'rnbqkbnr/ppp1p1pp/5P2/3p4/8/8/PPPP1PPP/RNBQKBNR b KQkq - 0 3', 'FEN after en passant';
}

# 5. Promotion
subtest 'Promotion' => {
    plan 4;
    my $game = Chess::JS.new('8/2P5/8/8/8/8/8/8 w - - 0 1');
    my $moves = $game.moves({:verbose});
    ok $moves.grep(*.promotion eq 'q'), 'Promotion to queen available';
    my $promote = $game.move('c8=Q');
    is $promote.san, 'c8=Q', 'SAN for promotion';
    ok $promote.flags.contains('p'), 'Flags contains "p"';
    is $game.fen, '2Q5/8/8/8/8/8/8/8 b - - 0 1', 'FEN after promotion';
}

# 6. Game State
subtest 'Game State' => {
    plan 4;
    my $game = Chess::JS.new('rnb1kbnr/pppp1ppp/8/4p3/5PPq/8/PPPPP2P/RNBQKBNR w KQkq - 1 3');
    ok $game.isCheck, 'White is in check';

    $game = Chess::JS.new('rnb1kbnr/pppp1ppp/8/4p3/5PPq/8/PPPPP2P/RNBQKBNR b KQkq - 0 3');
    ok !$game.isCheck, 'Black is not in check';

    $game = Chess::JS.new('8/8/8/8/8/8/8/8 w - - 0 1');
    ok $game.isStalemate, 'Stalemate for White';

    $game = Chess::JS.new('8/8/8/8/8/8/8/8 b - - 0 1');
    ok $game.isStalemate, 'Stalemate for Black';
}

done-testing;

# vi: shiftwidth=4 nowrap
