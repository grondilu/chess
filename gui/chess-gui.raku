#!/usr/bin/env raku
use v6.d;
use lib $?FILE.IO.parent.parent.add('lib').absolute.Str;
use NativeCall;

BEGIN {
    $*ERR.print: DateTime.now.local.hh-mm-ss
        ~ "  gui: loading Chess (first run precompiles; can take several minutes)\n";
    $*ERR.flush;
}
use Chess;
BEGIN {
    $*ERR.print: DateTime.now.local.hh-mm-ss ~ "  gui: Chess ready, starting GTK\n";
    $*ERR.flush;
}

# Chess board GUI: Lichess cburnett pieces, legal moves only
# (Chess::Position). Click-click or drag. Promotion becomes a queen.

# GTK 4.22: GSK_RENDERER=ngl is no longer valid and is ignored, so the
# default Vulkan renderer stays on and niri warns VK_SUBOPTIMAL_KHR.
# "gl"/"opengl" is the GL renderer. GDK_DISABLE=vulkan stops Gdk's
# swapchain too. Set these before any GTK call; leave existing values.
%*ENV<GSK_RENDERER> //= 'gl';
%*ENV<GDK_DISABLE>  //= 'vulkan';

# Absolute sonames: `is native(&callback)` on every GTK sub made Rakudo
# spend minutes compiling the script. Host and toolbox both have these.
constant GTK   = '/usr/lib64/libgtk-4.so.1';
constant GOBJ  = '/usr/lib64/libgobject-2.0.so.0';
constant GIO   = '/usr/lib64/libgio-2.0.so.0';
constant CAIRO = '/usr/lib64/libcairo.so.2';

# Sprite slots 1–6 white P–K, 7–12 black P–K (library black is 9–14).
constant PIECE-N = 13;
constant @PIECE-FILE = '', |<wP wN wB wR wQ wK bP bN bB bR bQ bK>;

constant @LIGHT  = 240e0 / 255e0, 217e0 / 255e0, 181e0 / 255e0;
constant @DARK   = 181e0 / 255e0, 136e0 / 255e0,  99e0 / 255e0;
constant @SELECT = 155e0 / 255e0, 199e0 / 255e0, 0e0, 0.55e0;
constant @DEST   = 20e0 / 255e0, 85e0 / 255e0, 30e0 / 255e0, 0.45e0;

constant GDK-BUTTON-PRIMARY = 1;
constant CAIRO-FONT-SLANT-NORMAL = 0;
constant CAIRO-FONT-WEIGHT-BOLD  = 1;
constant TAU = (2 * π).Num;

my Chess::Position $pos;
my Int $selected = -1;
my @dests;
my Bool $dragging = False;
my Bool $ignore-drag = False;
my Num $drag-x = 0e0;
my Num $drag-y = 0e0;
my Num $press-x = 0e0;
my Num $press-y = 0e0;
my @piece-surf[PIECE-N];
my Pointer $board-area;
my Pointer $window;

# --- cairo ---
sub cairo_image_surface_create_from_png(Str --> Pointer) is native(CAIRO) {*}
sub cairo_surface_status(Pointer --> int32) is native(CAIRO) {*}
sub cairo_image_surface_get_width(Pointer --> int32) is native(CAIRO) {*}
sub cairo_surface_destroy(Pointer) is native(CAIRO) {*}
sub cairo_save(Pointer) is native(CAIRO) {*}
sub cairo_restore(Pointer) is native(CAIRO) {*}
sub cairo_translate(Pointer, num64, num64) is native(CAIRO) {*}
sub cairo_scale(Pointer, num64, num64) is native(CAIRO) {*}
sub cairo_set_source_surface(Pointer, Pointer, num64, num64) is native(CAIRO) {*}
sub cairo_paint(Pointer) is native(CAIRO) {*}
sub cairo_set_source_rgb(Pointer, num64, num64, num64) is native(CAIRO) {*}
sub cairo_set_source_rgba(Pointer, num64, num64, num64, num64) is native(CAIRO) {*}
sub cairo_rectangle(Pointer, num64, num64, num64, num64) is native(CAIRO) {*}
sub cairo_arc(Pointer, num64, num64, num64, num64, num64) is native(CAIRO) {*}
sub cairo_fill(Pointer) is native(CAIRO) {*}
sub cairo_stroke(Pointer) is native(CAIRO) {*}
sub cairo_set_line_width(Pointer, num64) is native(CAIRO) {*}
sub cairo_move_to(Pointer, num64, num64) is native(CAIRO) {*}
sub cairo_show_text(Pointer, Str) is native(CAIRO) {*}
sub cairo_set_font_size(Pointer, num64) is native(CAIRO) {*}
sub cairo_select_font_face(Pointer, Str, int32, int32) is native(CAIRO) {*}

# --- GObject / GIO ---
sub g_object_unref(Pointer) is native(GOBJ) {*}
sub g_application_run(Pointer, int32, Pointer --> int32) is native(GIO) {*}
sub g_signal_connect_2(
    Pointer, Str, &handler (Pointer, Pointer), Pointer, Pointer, int32 --> uint64
) is native(GOBJ) is symbol('g_signal_connect_data') {*}
sub g_signal_connect_drag(
    Pointer, Str, &handler (Pointer, num64, num64, Pointer), Pointer, Pointer, int32 --> uint64
) is native(GOBJ) is symbol('g_signal_connect_data') {*}

# --- GTK 4 ---
sub gtk_application_new(Str, int32 --> Pointer) is native(GTK) {*}
sub gtk_application_window_new(Pointer --> Pointer) is native(GTK) {*}
sub gtk_window_set_title(Pointer, Str) is native(GTK) {*}
sub gtk_window_set_default_size(Pointer, int32, int32) is native(GTK) {*}
sub gtk_window_set_titlebar(Pointer, Pointer) is native(GTK) {*}
sub gtk_window_set_child(Pointer, Pointer) is native(GTK) {*}
sub gtk_window_present(Pointer) is native(GTK) {*}
sub gtk_header_bar_new(--> Pointer) is native(GTK) {*}
sub gtk_header_bar_pack_start(Pointer, Pointer) is native(GTK) {*}
sub gtk_button_new_with_label(Str --> Pointer) is native(GTK) {*}
sub gtk_drawing_area_new(--> Pointer) is native(GTK) {*}
sub gtk_drawing_area_set_draw_func(
    Pointer, &draw (Pointer, Pointer, int32, int32, Pointer), Pointer, Pointer
) is native(GTK) {*}
sub gtk_widget_set_hexpand(Pointer, int32) is native(GTK) {*}
sub gtk_widget_set_vexpand(Pointer, int32) is native(GTK) {*}
sub gtk_widget_set_size_request(Pointer, int32, int32) is native(GTK) {*}
sub gtk_widget_get_width(Pointer --> int32) is native(GTK) {*}
sub gtk_widget_get_height(Pointer --> int32) is native(GTK) {*}
sub gtk_widget_queue_draw(Pointer) is native(GTK) {*}
sub gtk_widget_add_controller(Pointer, Pointer) is native(GTK) {*}
sub gtk_gesture_drag_new(--> Pointer) is native(GTK) {*}
sub gtk_gesture_single_set_button(Pointer, uint32) is native(GTK) {*}

sub piece-dir(--> IO::Path) {
    my $dir = $*PROGRAM.IO.parent.add('pieces/png');
    $dir.d ?? $dir !! $?FILE.IO.parent.add('pieces/png')
}

sub packed-at(Int $sq --> Int) {
    my $p = $pos.piece-at($sq);
    $p ?? $p.packed !! 0
}

sub sprite(Int $packed --> Int) {
    return 0 unless $packed;
    $packed <= 6 ?? $packed !! $packed - 2
}

sub own-piece(Int $sq --> Bool) {
    my $p = $pos.piece-at($sq);
    so $p && $p.color == $pos.side-to-move
}

sub dests-from(Int $from) {
    $pos.legal-moves.grep({ +.from == $from }).map({ +.to }).unique.List
}

sub try-play(Int $from, Int $to --> Bool) {
    my @cands = $pos.legal-moves.grep({ +.from == $from && +.to == $to });
    return False unless @cands;
    my $m = @cands.first({ .promotion == +Queen }) // @cands.head;
    $pos.make-move($m);
    True
}

sub title-text(--> Str) {
    return 'Chess — Checkmate' if $pos.is-checkmate;
    return 'Chess — Stalemate' if $pos.is-stalemate;
    return 'Chess — Draw' if $pos.is-draw;
    my $side = $pos.side-to-move == White ?? 'White' !! 'Black';
    "Chess — $side to move"
}

sub set-title() {
    gtk_window_set_title($window, title-text) if $window;
}

sub reset-board() {
    $pos = Chess::Position.new;
    $selected = -1;
    @dests = ();
    $dragging = False;
    set-title();
}

sub load-pieces() {
    my $dir = piece-dir();
    for 1 ..^ PIECE-N -> $i {
        my $path = $dir.add(@PIECE-FILE[$i] ~ '.png').Str;
        my $s = cairo_image_surface_create_from_png($path);
        if cairo_surface_status($s) != 0 {
            die "failed to load $path";
        }
        @piece-surf[$i] = $s;
    }
}

sub board-geometry(Pointer $w) {
    my int32 $width  = gtk_widget_get_width($w);
    my int32 $height = gtk_widget_get_height($w);
    my $side = $width min $height;
    my $sq = ($side div 8) max 1;
    $side = $sq * 8;
    my $ox = ($width - $side) div 2;
    my $oy = ($height - $side) div 2;
    ($ox, $oy, $sq)
}

sub square-at(Pointer $w, Num() $x, Num() $y --> Int) {
    my ($ox, $oy, $sq) = board-geometry($w);
    my $file = (($x - $ox) / $sq).Int;
    my $row  = (($y - $oy) / $sq).Int;
    return -1 unless 0 <= $file <= 7 && 0 <= $row <= 7;
    my $rank = 7 - $row;
    $rank * 8 + $file
}

sub draw-piece(Pointer $cr, Int $packed, Num() $x, Num() $y, Num() $size) {
    my $slot = sprite($packed);
    my $s = @piece-surf[$slot];
    return unless $s;
    my $pw = cairo_image_surface_get_width($s);
    return unless $pw > 0;
    cairo_save($cr);
    cairo_translate($cr, $x.Num, $y.Num);
    cairo_scale($cr, ($size / $pw).Num, ($size / $pw).Num);
    cairo_set_source_surface($cr, $s, 0e0, 0e0);
    cairo_paint($cr);
    cairo_restore($cr);
}

sub draw-dest(Pointer $cr, Num() $x, Num() $y, Num() $sq, Bool $capture) {
    my $cx = ($x + $sq / 2).Num;
    my $cy = ($y + $sq / 2).Num;
    cairo_set_source_rgba($cr, @DEST[0], @DEST[1], @DEST[2], @DEST[3]);
    if $capture {
        cairo_set_line_width($cr, ($sq * 0.08).Num);
        cairo_arc($cr, $cx, $cy, ($sq * 0.42).Num, 0e0, TAU);
        cairo_stroke($cr);
    }
    else {
        cairo_arc($cr, $cx, $cy, ($sq * 0.17).Num, 0e0, TAU);
        cairo_fill($cr);
    }
}

sub draw-board(Pointer $area, Pointer $cr, int32 $width, int32 $height, Pointer $data) {
    my ($ox, $oy, $sq) = board-geometry($area);
    cairo_select_font_face($cr, 'sans-serif',
        CAIRO-FONT-SLANT-NORMAL, CAIRO-FONT-WEIGHT-BOLD);
    cairo_set_font_size($cr, ($sq * 0.18).Num);

    my %dest = @dests.map({ $_ => True });

    for ^8 -> $rank {
        for ^8 -> $file {
            my $idx = $rank * 8 + $file;
            my $x = $ox + $file * $sq;
            my $y = $oy + (7 - $rank) * $sq;
            my $dark = ($file + $rank) +& 1;
            my @c := $dark ?? @DARK !! @LIGHT;
            cairo_set_source_rgb($cr, @c[0], @c[1], @c[2]);
            cairo_rectangle($cr, $x.Num, $y.Num, $sq.Num, $sq.Num);
            cairo_fill($cr);

            if $idx == $selected {
                cairo_set_source_rgba($cr, @SELECT[0], @SELECT[1], @SELECT[2], @SELECT[3]);
                cairo_rectangle($cr, $x.Num, $y.Num, $sq.Num, $sq.Num);
                cairo_fill($cr);
            }

            my @ink := $dark ?? @LIGHT !! @DARK;
            cairo_set_source_rgb($cr, @ink[0], @ink[1], @ink[2]);
            if $rank == 0 {
                cairo_move_to($cr, ($x + $sq * 0.08).Num, ($y + $sq * 0.92).Num);
                cairo_show_text($cr, chr(ord('a') + $file));
            }
            if $file == 0 {
                cairo_move_to($cr, ($x + $sq * 0.08).Num, ($y + $sq * 0.22).Num);
                cairo_show_text($cr, chr(ord('1') + $rank));
            }

            my $packed = packed-at($idx);
            if %dest{$idx} {
                draw-dest($cr, $x, $y, $sq, $packed != 0);
            }
            draw-piece($cr, $packed, $x, $y, $sq)
                if $packed && !($dragging && $idx == $selected);
        }
    }

    if $dragging && $selected >= 0 {
        my $packed = packed-at($selected);
        draw-piece($cr, $packed, $drag-x - $sq / 2, $drag-y - $sq / 2, $sq) if $packed;
    }
}

sub select-square(Int $sq) {
    if $sq >= 0 && own-piece($sq) {
        $selected = $sq;
        @dests = dests-from($sq);
    }
    else {
        $selected = -1;
        @dests = ();
    }
}

sub on-drag-begin(Pointer $g, num64 $x, num64 $y, Pointer $w) {
    my $sq = square-at($w, $x, $y);
    $press-x = $x;
    $press-y = $y;
    $ignore-drag = False;
    $dragging = False;

    if $selected >= 0 && $sq >= 0 && $sq != $selected {
        if try-play($selected, $sq) {
            $selected = -1;
            @dests = ();
            $ignore-drag = True;
            set-title();
            gtk_widget_queue_draw($w);
            return;
        }
    }

    if $sq >= 0 && own-piece($sq) {
        select-square($sq);
        $drag-x = $x;
        $drag-y = $y;
    }
    else {
        select-square(-1);
        $ignore-drag = True;
    }
    gtk_widget_queue_draw($w);
}

sub on-drag-update(Pointer $g, num64 $dx, num64 $dy, Pointer $w) {
    return if $ignore-drag || $selected < 0;
    unless $dragging {
        $dragging = True if $dx * $dx + $dy * $dy > 25e0;
    }
    return unless $dragging;
    $drag-x = $press-x + $dx;
    $drag-y = $press-y + $dy;
    gtk_widget_queue_draw($w);
}

sub on-drag-end(Pointer $g, num64 $dx, num64 $dy, Pointer $w) {
    if $ignore-drag {
        $ignore-drag = False;
        $dragging = False;
        gtk_widget_queue_draw($w);
        return;
    }
    if $dragging && $selected >= 0 {
        my $sq = square-at($w, $press-x + $dx, $press-y + $dy);
        if $sq >= 0 && $sq != $selected && try-play($selected, $sq) {
            $selected = -1;
            @dests = ();
            set-title();
        }
    }
    $dragging = False;
    gtk_widget_queue_draw($w);
}

sub on-reset(Pointer $btn, Pointer $w) {
    reset-board();
    gtk_widget_queue_draw($w);
}

sub activate(Pointer $app, Pointer $data) {
    $window = gtk_application_window_new($app);
    gtk_window_set_default_size($window, 720, 760);
    set-title();

    my $header = gtk_header_bar_new();
    gtk_window_set_titlebar($window, $header);

    my $reset = gtk_button_new_with_label('Reset');
    gtk_header_bar_pack_start($header, $reset);

    $board-area = gtk_drawing_area_new();
    gtk_widget_set_hexpand($board-area, 1);
    gtk_widget_set_vexpand($board-area, 1);
    gtk_widget_set_size_request($board-area, 480, 480);
    gtk_drawing_area_set_draw_func($board-area, &draw-board, Pointer, Pointer);

    my $drag = gtk_gesture_drag_new();
    gtk_gesture_single_set_button($drag, GDK-BUTTON-PRIMARY);
    g_signal_connect_drag($drag, 'drag-begin',  &on-drag-begin,  $board-area, Pointer, 0);
    g_signal_connect_drag($drag, 'drag-update', &on-drag-update, $board-area, Pointer, 0);
    g_signal_connect_drag($drag, 'drag-end',    &on-drag-end,    $board-area, Pointer, 0);
    gtk_widget_add_controller($board-area, $drag);

    g_signal_connect_2($reset, 'clicked', &on-reset, $board-area, Pointer, 0);

    gtk_window_set_child($window, $board-area);
    gtk_window_present($window);
}

my @KEEP-CALLBACKS = &activate, &draw-board, &on-drag-begin, &on-drag-update, &on-drag-end, &on-reset;

reset-board();
load-pieces();

my $app = gtk_application_new('dev.chess.legal.raku', 0);
g_signal_connect_2($app, 'activate', &activate, Pointer, Pointer, 0);
my $status = g_application_run($app, 0, Pointer);
g_object_unref($app);

for 1 ..^ PIECE-N -> $i {
    cairo_surface_destroy(@piece-surf[$i]) if @piece-surf[$i];
}
exit $status;
