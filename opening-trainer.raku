use Raylib::Bindings;
use Raygui::Bindings;
use Chess::Board;
use Chess::Colors;
use Chess::Position;
use Chess::Pieces;
use Chess::Moves;

# square size
constant SS = 100;

package GUI {
    our constant %status-bar = height => 40;
    our constant width = 8*SS;
    our constant height = 8*SS + %status-bar<height>;
}

my &sigmoid = 8*(* - 1/2) ∘ {$_/(1+$_)} ∘ &exp ∘ (.51082569 * *); # ∘

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
    init-window(GUI::width, GUI::height, "raylib chessboard");
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
    our $correct = load-sound "$dir/correct-156911.mp3";
    our $wrong   = load-sound "$dir/wronganswer-37702.mp3";
    END unload-sound $_ for $move, $capture, $correct, $wrong;
}

package Textures {
    our %pieces;
    constant @symbols = <k q b n r p>;
    for @symbols {
        for .lc, .uc {
            my $image = load-image("resources/images/piece/cburnett/$_.png");
            %pieces{$_} = load-texture-from-image $image;
            unload-image $image;
        }
    }
    END for @symbols { unload-texture %pieces{$_} for .lc, .uc; }
}

enum MoveDiscoveryMethod <USER BOOK ENGINE>;

sub MAIN(*@masters) {

    use Chess::Book;
    use Chess::Database;
    my %books;
    for Chess::Database::Master::{*} -> $master {
        my $filename = qq[resources/masters/$master.bin];
        die "no polyglot book found for master $master" unless $filename.IO ~~ :e;

        %books{$master} = 
            my Chess::Book $book .= new: $filename.IO;
    }

    my Chess::Position $position .= new;

    await $uci-engine.say: "setoption name Threads value 15";

    until window-should-close {
        ENTER begin-drawing;
        LEAVE end-drawing;

        state $selected-square;
        state @legal-moves;
        state @history;
        state @undo;

        state Str $status;

        state Move (
            $last-computed-best-move,
            $book-move
        );
        state Bool $engine-is-running = False;



        # Display options
        state Bool $flipped-board = False;
        state Bool $show-coordinates = False;
        state UInt %highlights =
            last-move => 0,
            best-move => 0,
            book-move => 0;

        sub find-book-move(Bool :$from-masters = True) {
            if $from-masters {
                for %books {
                    my $master = .key;
                    next if @masters and $master eq @masters.none;
                    #note "searching $master.bin";
                    with .value{$position} {
                        my $move = .map({ .<move> => .<weight> }).Bag.pick;
                        if $move.defined {
                            $status = "found {$move.LAN} from $master";
                            return %( :$master, :$move );
                        } else { $status = "$master never faced this position with {$position.turn}"; }
                    }
                }
            } else {
                for %books {
                    with .value{$position} {
                        return %( :move(.map({ .<move> }).pick) )
                    }
                }
            }
            play-sound $Sounds::wrong;
            fail "unknown move";
        }
        sub find-and-highlight-move(Bool :$from-masters = False) {
            try {
                my %find = find-book-move :!from-masters;
                %highlights<book-move> = 60;
                $book-move = %find<move>;
                CATCH {
                    when X::AdHoc {
                        .note;
                        $status = "no move found in books";
                    }
                }
            }
        }
        sub make-move($move) {
            @undo.push: $position.make: $move;
            @history.push: $move;
            play-sound $move ~~ Chess::Moves::capture ?? $Sounds::capture !! $Sounds::move;
            if $engine-is-running {
                $uci-engine.say("stop")
                    .then({ $uci-engine.say: "position fen {$position.fen}" })
                    .then({ $uci-engine.say: "go inifinite" });
            } else { $uci-engine.say: "position fen {$position.fen}" }
        }
        sub undo {
            if @history {
                @undo.pop.();
                @history.pop();
                if $engine-is-running {
                    await $uci-engine.say: "stop";
                    $engine-is-running = False;
                }
                $uci-engine.say: "position fen {$position.fen}";
                $status = "move undone";
            }
        }
        sub reset {
            @undo = ();
            @history = ();
            if $engine-is-running {
                await $uci-engine.say: "stop";
                $engine-is-running = False;
            }
            %highlights{$_} = 0 for %highlights.keys;
            $selected-square = Any;
            $position .= new;
            $uci-engine.say: "position startpos";
        }

        sub highlight-move(Move $move, $color) {
            for
            $move.from => -> $f, $r { draw-rectangle $f*SS, $r*SS, SS, SS, $color; },
            $move.to   => -> $f, $r { draw-circle $f*SS + (SS div 2), $r*SS + (SS div 2), SS/2e0, $color; }
            {
                my ($f, $r) = .key.&file, .key.&rank;
                ($f, $r) .= map: 7-* if $flipped-board;
                .value.($f, $r);
            }
        }
        once $engine-best-move.Supply.tap: -> $best-move {
            use Chess::Moves;
            $last-computed-best-move = Move.new: $best-move, :color($position.turn), :board($position);
            $status = "best move is $best-move";
            %highlights<best-move> = 120;
        }

        my MoveDiscoveryMethod $move-discovery-method = do
            given $position.turn {
                when white { $flipped-board ?? BOOK !! USER }
                when black { $flipped-board ?? USER !! BOOK }
                default { USER }
            }

        ENTER {
            begin-drawing;
            #= draw chessboard
            for ^8 X ^8 -> ($i, $j) {
                draw-rectangle $i * SS, $j * SS, SS, SS, (($i + $j) mod 2 ?? init-dark() !! init-light);
            }
            if $show-coordinates {
                for ^8 {
                    draw-text
                    { $flipped-board ?? .reverse !! $_ }("a".."h")[$_],
                    SS*$_ + SS div 20,
                    7*SS + (SS * 3 div 4),
                    SS div 5,
                    (($_ mod 2) ?? init-dark() !! init-light);
                    draw-text
                    { $flipped-board ?? 9 - $_ !! $_ }(8 - $_).Str,
                    7*SS + (SS * 5 div 6),
                    SS*$_ + SS div 20,
                    SS div 5,
                    (($_ mod 2) ?? init-dark() !! init-light)
                    ;
                }
            }
        }
        LEAVE {
            # draw pieces
            for @Chess::Board::squares -> $s {
                my $x = file($s) * SS;
                my $y = rank($s) * SS;
                if $flipped-board {
                    $x = 7*SS - $x;
                    $y = 7*SS - $y;
                }
                with $position.board[$s] {
                    draw-texture %Textures::pieces{symbol $_}, $x, $y, init-white;
                }
            }

            # draw eval bar
            if $engine-is-running {
                my $height-delta = round(SS*($position.turn ~~ black ?? -1 !! +1)*&sigmoid($engine-evaluation / 100));
                draw-rectangle 8*SS - 10, 0, 10, 4*SS - $height-delta, Color.init(0, 0, 0, 128);
                draw-rectangle 8*SS - 10, 4*SS - $height-delta + 1, 10, 4*SS + $height-delta, Color.init(255, 255, 255, 128);
            }

            gui-status-bar Rectangle.init(0e0, Num(8*SS), Num(8*SS), Num(%GUI::status-bar<height>)), $status // '';
            clear-background(Color.init(128, 128, 128, 255));
            draw-fps(10,10) with %*ENV<DEBUG>;
        }

        if %highlights<last-move> > 0 {
            if @history.elems {
                given @history.tail {
                    highlight-move $_, Color.init: 255, 255, 0, %highlights<last-move>--;
                }
            }
        }
        if %highlights<best-move> > 0 {
            with $last-computed-best-move {
                highlight-move $_, Color.init: 0, 255, 0, %highlights<best-move>--;
            }
        }
        if %highlights<book-move> > 0 {
            with $book-move {
                highlight-move $_, Color.init: 0, 0, 255, %highlights<book-move>--;
            }
        }
        with chr get-char-pressed {
            when 'f' { $flipped-board       = !$flipped-board unless $engine-is-running; }
            when 'c' { $show-coordinates    = !$show-coordinates    }
            when 'h' { %highlights<last-move> = 60 }
            when 'r' { reset }
            when 'g' { use Chess::Game; put Chess::Game.new(@history.map: *.LAN).pgn; }
            when 'b' { find-and-highlight-move :!from-masters }
            when 'u' { undo; undo }
        }
        if is-key-pressed KEY_SPACE {
            $uci-engine.say: $engine-is-running ?? "stop" !! "go infinite";
            $engine-is-running = !$engine-is-running;
        }

        given $move-discovery-method {
            when USER {
                if is-cursor-on-screen {
                    my ($x, $y) = get-mouse-x, get-mouse-y;
                    if $x & $y < SS*8 {
                        my ($f, $r) = $x, $y Xdiv SS;
                        ($f, $r) .= map(7 - *) if $flipped-board;

                        my $square-name = ("a".."h")[$f] ~ (1..8).reverse[$r];
                        my $square = square-enum::{$square-name};
                        set-mouse-cursor $position{$square} ?? MOUSE_CURSOR_POINTING_HAND !! MOUSE_CURSOR_DEFAULT;

                        if is-mouse-button-pressed(MOUSE_BUTTON_LEFT) {
                            with $selected-square {
                                with @legal-moves.first: { .to ~~ $square } {
                                    make-move $_;
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
                                    ($f, $r) .= map(7 - *) if $flipped-board;
                                    draw-rectangle SS*$f, SS*$r, SS, SS, Color.init(0, 245, 0, 128);
                                }
                            }

                        }
                    }
                }

                with $selected-square {
                    my ($f, $r) = .&file, .&rank;
                    ($f, $r) .=map: 7 - * if $flipped-board;
                    if @legal-moves > 0 {
                        # mark move destination square with a colored rectangle
                        draw-rectangle $f*SS, $r*SS, SS, SS, Color.init(0, 255, 0, 128);
                        for @legal-moves {
                            # mark possible move destination squares with a colored disk
                            my ($f, $r) = file(.to), rank(.to);
                            ($f, $r) .= map(7 - *) if $flipped-board;
                            draw-circle SS*$f + SS div 2, SS*$r + SS div 2, SS/5e0, Color.init(0, 128, 0, 128);
                        }
                    }
                }
            }
            when BOOK {
                my %find;
                try {
                    %find = find-book-move;
                    make-move %find<move>;
                    $status = "found move {%find<move>.LAN} from %find<master>";
                    CATCH {
                        when X::AdHoc {
                            .note;
                            $status = "reverting";
                            undo;
                            find-and-highlight-move :!from-masters;
                        }
                    }
                }
            }
        }
    }

}


# vim: shiftwidth=4 nowrap expandtab nu
