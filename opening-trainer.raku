use Raylib::Bindings;
use Chess::Board;
use Chess::Colors;
use Chess::Position;
use Chess::Pieces;

#use Chess::Engine;

# square size
constant SS = 100;

sub init-light { Color.init($_, $_, $_, 255) given 256*4 div 5 }
sub init-dark  { Color.init($_, $_, $_, 255) given 256*3 div 5 }

# Start and configure engine
my Proc::Async $uci-engine .= new: :w, |<ssh aldebaran stockfish>;
my Int $engine-evaluation = 0;
my Supplier $engine-best-move .= new;
$uci-engine.stdout.tap: {
    when /^info/ { .note }
    when /'bestmove ' ([<[a..h]><[1..8]>]**2 <[qrbn]>?) / { $engine-best-move.emit: "$/[0]" }
}
$uci-engine.stdout.tap: {
    when /"score cp "(\-?\d+)/ {
        $engine-evaluation = $/[0].Int;
    }
}
my Promise $engine-termination = $uci-engine.start.then: { note "stockfish has terminated" }

INIT {
    set-trace-log-level LOG_ERROR;
    with %*ENV<DEBUG> { when m:i/true/ { set-trace-log-level LOG_ALL } }
    init-window(8*SS, 8*SS, "raylib chessboard");
    set-target-fps(60);
}
END await Promise.allof(
        $uci-engine.say("quit"),
        $engine-termination
    ).then({ close-window });


package Sounds {
    INIT  init-audio-device;
    END  close-audio-device;
    constant $dir = "resources/sounds";
    our $move    = load-sound "$dir/Move.ogg";
    our $capture = load-sound "$dir/Capture.ogg";
    END unload-sound $_ for $move, $capture;
}

package Textures {
    our %pieces;
    for <k q b n r p> {
        for .lc, .uc {
            my $image = load-image("resources/images/piece/cburnett/$_.png");
            %pieces{$_} = load-texture-from-image $image;
            unload-image $image;
        }
    }
    END for <k q b n r p> { unload-texture %pieces{$_} for .lc, .uc; }
}

constant USAGE = q:to/END_USAGE/;
    - press :
        'h' to highlight last move
        'c' to display column and file names
        'f' to flip the board
    END_USAGE

sub MAIN($master!) {

    use Chess::Book;
    my $filename = qq[resources/masters/$master.bin];
    die "no polyglot book found for master $master" unless $filename.IO ~~ :e;

    my Chess::Book $book .= new: $filename.IO;

    my Chess::Position $position .= new;

    $uci-engine.say: "setoption name Threads value 15";

    until window-should-close {

        state $selected-square;
        state @legal-moves;
        state @history;

        state Bool $engine-is-running = False;

        # Display options
        state Bool $flip-board = False;
        state Bool $show-coordinates = False;
        state Bool $highlight-last-move = False;

        sub make-move($move) {
            use Chess::Moves;
            $position.make: $move;
            @history.push: $move;
            play-sound $move ~~ Chess::Moves::capture ?? $Sounds::capture !! $Sounds::move;
            $uci-engine.say: "position fen {$position.fen}"
        }
        once $engine-best-move.Supply.tap: -> $best-move { make-move $best-move }

        ENTER {
            begin-drawing;
            #= draw chessboard
            for ^8 X ^8 -> ($i, $j) {
                draw-rectangle $i * SS, $j * SS, SS, SS, (($i + $j) mod 2 ?? init-dark() !! init-light);
            }
            if $show-coordinates {
                for ^8 {
                    draw-text
                    { $flip-board ?? .reverse !! $_ }("a".."h")[$_],
                    SS*$_ + SS div 20,
                    7*SS + (SS * 3 div 4),
                    SS div 5,
                    (($_ mod 2) ?? init-dark() !! init-light);
                    draw-text
                    { $flip-board ?? 9 - $_ !! $_ }(8 - $_).Str,
                    7*SS + (SS * 5 div 6),
                    SS*$_ + SS div 20,
                    SS div 5,
                    (($_ mod 2) ?? init-dark() !! init-light)
                    ;
                }
            }
            if $highlight-last-move {
                if @history.elems {
                    given @history.tail {
                        for .from, .to {
                            my ($f, $r) = .&file, .&rank;
                            ($f, $r) .= map: 7-* if $flip-board;
                            draw-rectangle $f*SS, $r*SS, SS, SS, Color.init(255, 255, 0, 64);
                        }
                    }
                }
            }
        }
        LEAVE {
            # draw pieces
            for @Chess::Board::squares -> $s {
                my $x = file($s) * SS;
                my $y = rank($s) * SS;
                if $flip-board {
                    $x = 7*SS - $x;
                    $y = 7*SS - $y;
                }
                with $position.board[$s] {
                    draw-texture %Textures::pieces{symbol $_}, $x, $y, init-white;
                }
            }

            # draw eval bar
            if $engine-is-running {
                my $height-delta = SS*$engine-evaluation div 100;
                draw-rectangle 8*SS - 10, 0, 10, 4*SS - $height-delta, Color.init(0, 0, 0, 128);
                draw-rectangle 8*SS - 10, 4*SS - $height-delta + 1, 10, 4*SS + $height-delta, Color.init(255, 255, 255, 128);
            }

            clear-background(init-white);
            draw-fps(10,10);
            end-drawing;
        }

        with chr get-char-pressed {
            when 'f' { $flip-board          = !$flip-board          }
            when 'c' { $show-coordinates    = !$show-coordinates    }
            when 'h' { $highlight-last-move = !$highlight-last-move }
            when 'n' { $position .= new; @history = ()              }
            when 'u' {
                if @history {
                    @history.pop();
                    $position.=new;
                    $position.make: $_ for @history;
                }
            }
        }
        if is-key-pressed KEY_SPACE {
            $uci-engine.say: $engine-is-running ?? "stop" !! "go infinite";
            $engine-is-running = !$engine-is-running;
        }


        if $position.turn ~~ white {
            if is-cursor-on-screen {
                my ($x, $y) = get-mouse-x, get-mouse-y;
                my ($f, $r) = $x, $y Xdiv SS;
                ($f, $r) .= map(7 - *) if $flip-board;

                my $square-name = ("a".."h")[$f] ~ (1..8).reverse[$r];
                my $square = square-enum::{$square-name};
                #set-mouse-cursor $position{$square} ?? 4 !! 0;
                if is-mouse-button-pressed(0) {
                    with $selected-square {
                        with @legal-moves.first: { .to ~~ $square } {
                            make-move $_;
                            with $book{$position} {
                                my $move = .map({ .<move> => .<weight> }).Bag.pick;
                                if $move.defined {
                                    make-move $move;
                                } else {
                                    note "it seems that $master never faced this position with black";
                                    note "history is ", @history;
                                }
                            } else {
                                note "unkown move {@history.pop.LAN}";
                                note "known moves are:";
                                my Chess::Position $position .= new;
                                $position.make: $_ for @history;
                                note $book{$position};
                            };
                        }
                        $selected-square = Any;
                    } else {
                        with $position{$square} {
                            if Chess::Pieces::get-color($_) ~~ $position.turn {
                                @legal-moves = $position.moves: :$square;
                                $selected-square = $square if @legal-moves.elems > 0;
                            }
                        }
                    }
                } else {
                    # the mouse is just hovering
                    with $selected-square {
                        # an move origin square has been selected
                        if $square ~~ @legal-moves».to.any {
                            # the hovered square is a legal move destination square
                            # so we highlight it
                            ($f, $r) .= map(7 - *) if $flip-board;
                            draw-rectangle SS*$f, SS*$r, SS, SS, Color.init(0, 245, 0, 128);
                        }
                    }

                }
            }

            with $selected-square {
                my ($f, $r) = .&file, .&rank;
                ($f, $r) .=map: 7 - * if $flip-board;
                if @legal-moves > 0 {
                    # mark move destination square with a colored rectangle
                    draw-rectangle $f*SS, $r*SS, SS, SS, Color.init(0, 255, 0, 128);
                    for @legal-moves {
                        # mark possible move destination squares with a colored disk
                        my ($f, $r) = file(.to), rank(.to);
                        ($f, $r) .= map(7 - *) if $flip-board;
                        draw-circle SS*$f + SS div 2, SS*$r + SS div 2, SS/5e0, Color.init(0, 128, 0, 128);
                    }
                }
            }
        }
        

    }

}


# vim: shiftwidth=4 nowrap expandtab
