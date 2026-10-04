/*
 * Sandbox chess board: display pieces and let the user drag or
 * click-click them anywhere. No chess rules.
 *
 * Pieces are Lichess's default Cburnett SVGs, converted to PNG at build.
 */

#include <gtk/gtk.h>
#include <cairo.h>
#include <math.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#ifndef PIECE_DIR
#define PIECE_DIR "pieces/png"
#endif

enum {
    EMPTY = 0,
    WP, WN, WB, WR, WQ, WK,
    BP, BN, BB, BR, BQ, BK,
    PIECE_N
};

static const char *piece_file[PIECE_N] = {
    NULL,
    "wP", "wN", "wB", "wR", "wQ", "wK",
    "bP", "bN", "bB", "bR", "bQ", "bK",
};

/* Mailbox a1=0 … h8=63, white at the bottom of the window. */
static const int start_pos[64] = {
    WR, WN, WB, WQ, WK, WB, WN, WR,
    WP, WP, WP, WP, WP, WP, WP, WP,
     0,  0,  0,  0,  0,  0,  0,  0,
     0,  0,  0,  0,  0,  0,  0,  0,
     0,  0,  0,  0,  0,  0,  0,  0,
     0,  0,  0,  0,  0,  0,  0,  0,
    BP, BP, BP, BP, BP, BP, BP, BP,
    BR, BN, BB, BQ, BK, BB, BN, BR,
};

/* Lichess brown board. */
static const double LIGHT[3] = { 240 / 255.0, 217 / 255.0, 181 / 255.0 };
static const double DARK[3]  = { 181 / 255.0, 136 / 255.0,  99 / 255.0 };
static const double SELECT[4] = { 155 / 255.0, 199 / 255.0, 0.0, 0.55 };

static int board[64];
static int selected = -1;
static int dragging = 0;
static int ignore_drag = 0;
static double drag_x, drag_y;

static cairo_surface_t *piece_surf[PIECE_N];
static GtkWidget *board_area;

static void reset_board(void) {
    memcpy(board, start_pos, sizeof board);
    selected = -1;
    dragging = 0;
}

static void load_pieces(void) {
    for (int i = 1; i < PIECE_N; i++) {
        char path[512];
        snprintf(path, sizeof path, "%s/%s.png", PIECE_DIR, piece_file[i]);
        piece_surf[i] = cairo_image_surface_create_from_png(path);
        if (cairo_surface_status(piece_surf[i]) != CAIRO_STATUS_SUCCESS) {
            fprintf(stderr, "failed to load %s\n", path);
            exit(1);
        }
    }
}

static void board_geometry(GtkWidget *w, int *ox, int *oy, int *sq) {
    int width = gtk_widget_get_width(w);
    int height = gtk_widget_get_height(w);
    int side = width < height ? width : height;
    *sq = side / 8;
    if (*sq < 1)
        *sq = 1;
    side = *sq * 8;
    *ox = (width - side) / 2;
    *oy = (height - side) / 2;
}

static int square_at(GtkWidget *w, double x, double y) {
    int ox, oy, sq;
    board_geometry(w, &ox, &oy, &sq);
    int file = (int)((x - ox) / sq);
    int row  = (int)((y - oy) / sq);
    if (file < 0 || file > 7 || row < 0 || row > 7)
        return -1;
    int rank = 7 - row;
    return rank * 8 + file;
}

static void do_move(int from, int to) {
    if (from < 0 || to < 0 || from == to)
        return;
    board[to] = board[from];
    board[from] = EMPTY;
}

static void draw_piece(cairo_t *cr, int piece, double x, double y, double size) {
    cairo_surface_t *s = piece_surf[piece];
    if (!s)
        return;
    int pw = cairo_image_surface_get_width(s);
    if (pw <= 0)
        return;
    cairo_save(cr);
    cairo_translate(cr, x, y);
    cairo_scale(cr, size / pw, size / pw);
    cairo_set_source_surface(cr, s, 0, 0);
    cairo_paint(cr);
    cairo_restore(cr);
}

static void draw_board(GtkDrawingArea *area, cairo_t *cr,
                       int width, int height, gpointer data) {
    (void)width;
    (void)height;
    (void)data;

    int ox, oy, sq;
    board_geometry(GTK_WIDGET(area), &ox, &oy, &sq);

    cairo_select_font_face(cr, "sans-serif",
                           CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_BOLD);
    cairo_set_font_size(cr, sq * 0.18);

    for (int rank = 0; rank < 8; rank++) {
        for (int file = 0; file < 8; file++) {
            int idx = rank * 8 + file;
            int x = ox + file * sq;
            int y = oy + (7 - rank) * sq;
            int dark = (file + rank) & 1;
            const double *c = dark ? DARK : LIGHT;
            cairo_set_source_rgb(cr, c[0], c[1], c[2]);
            cairo_rectangle(cr, x, y, sq, sq);
            cairo_fill(cr);

            if (idx == selected) {
                cairo_set_source_rgba(cr, SELECT[0], SELECT[1], SELECT[2], SELECT[3]);
                cairo_rectangle(cr, x, y, sq, sq);
                cairo_fill(cr);
            }

            /* Coordinates like Lichess: files on the 1st rank, ranks on the a-file. */
            const double *ink = dark ? LIGHT : DARK;
            cairo_set_source_rgb(cr, ink[0], ink[1], ink[2]);
            if (rank == 0) {
                char label[2] = { (char)('a' + file), 0 };
                cairo_move_to(cr, x + sq * 0.08, y + sq * 0.92);
                cairo_show_text(cr, label);
            }
            if (file == 0) {
                char label[2] = { (char)('1' + rank), 0 };
                cairo_move_to(cr, x + sq * 0.08, y + sq * 0.22);
                cairo_show_text(cr, label);
            }

            int piece = board[idx];
            if (piece && !(dragging && idx == selected))
                draw_piece(cr, piece, x, y, sq);
        }
    }

    if (dragging && selected >= 0 && board[selected])
        draw_piece(cr, board[selected], drag_x - sq / 2.0, drag_y - sq / 2.0, sq);
}

static void on_drag_begin(GtkGestureDrag *g, double x, double y, gpointer w) {
    (void)g;
    int sq = square_at(GTK_WIDGET(w), x, y);
    if (selected >= 0 && sq >= 0 && sq != selected) {
        do_move(selected, sq);
        selected = -1;
        ignore_drag = 1;
        dragging = 0;
    } else if (sq >= 0 && board[sq]) {
        selected = sq;
        ignore_drag = 0;
        dragging = 0;
        drag_x = x;
        drag_y = y;
    } else {
        selected = -1;
        ignore_drag = 1;
        dragging = 0;
    }
    gtk_widget_queue_draw(GTK_WIDGET(w));
}

static void on_drag_update(GtkGestureDrag *g, double dx, double dy, gpointer w) {
    if (ignore_drag || selected < 0)
        return;
    double x, y;
    if (!gtk_gesture_drag_get_start_point(g, &x, &y))
        return;
    if (!dragging && dx * dx + dy * dy > 25.0)
        dragging = 1;
    if (!dragging)
        return;
    drag_x = x + dx;
    drag_y = y + dy;
    gtk_widget_queue_draw(GTK_WIDGET(w));
}

static void on_drag_end(GtkGestureDrag *g, double dx, double dy, gpointer w) {
    if (ignore_drag) {
        ignore_drag = 0;
        dragging = 0;
        gtk_widget_queue_draw(GTK_WIDGET(w));
        return;
    }
    if (dragging && selected >= 0) {
        double x, y;
        if (gtk_gesture_drag_get_start_point(g, &x, &y)) {
            int sq = square_at(GTK_WIDGET(w), x + dx, y + dy);
            if (sq >= 0 && sq != selected) {
                do_move(selected, sq);
                selected = -1;
            }
        }
    }
    dragging = 0;
    gtk_widget_queue_draw(GTK_WIDGET(w));
}

static void on_reset(GtkButton *btn, gpointer w) {
    (void)btn;
    reset_board();
    gtk_widget_queue_draw(GTK_WIDGET(w));
}

static void activate(GtkApplication *app, gpointer user_data) {
    (void)user_data;

    GtkWidget *win = gtk_application_window_new(app);
    gtk_window_set_title(GTK_WINDOW(win), "Chess");
    gtk_window_set_default_size(GTK_WINDOW(win), 720, 760);

    GtkWidget *header = gtk_header_bar_new();
    gtk_window_set_titlebar(GTK_WINDOW(win), header);

    GtkWidget *reset = gtk_button_new_with_label("Reset");
    gtk_header_bar_pack_start(GTK_HEADER_BAR(header), reset);

    board_area = gtk_drawing_area_new();
    gtk_widget_set_hexpand(board_area, TRUE);
    gtk_widget_set_vexpand(board_area, TRUE);
    gtk_widget_set_size_request(board_area, 480, 480);
    gtk_drawing_area_set_draw_func(GTK_DRAWING_AREA(board_area),
                                   draw_board, NULL, NULL);

    GtkGesture *drag = gtk_gesture_drag_new();
    gtk_gesture_single_set_button(GTK_GESTURE_SINGLE(drag), GDK_BUTTON_PRIMARY);
    g_signal_connect(drag, "drag-begin", G_CALLBACK(on_drag_begin), board_area);
    g_signal_connect(drag, "drag-update", G_CALLBACK(on_drag_update), board_area);
    g_signal_connect(drag, "drag-end", G_CALLBACK(on_drag_end), board_area);
    gtk_widget_add_controller(board_area, GTK_EVENT_CONTROLLER(drag));

    g_signal_connect(reset, "clicked", G_CALLBACK(on_reset), board_area);

    gtk_window_set_child(GTK_WINDOW(win), board_area);
    gtk_window_present(GTK_WINDOW(win));
}

int main(int argc, char **argv) {
    reset_board();
    load_pieces();

    if (!getenv("GSK_RENDERER"))
        setenv("GSK_RENDERER", "gl", 0);
    if (!getenv("GDK_DISABLE"))
        setenv("GDK_DISABLE", "vulkan", 0);

    GtkApplication *app = gtk_application_new("dev.chess.sandbox",
                                              G_APPLICATION_DEFAULT_FLAGS);
    g_signal_connect(app, "activate", G_CALLBACK(activate), NULL);
    int status = g_application_run(G_APPLICATION(app), argc, argv);
    g_object_unref(app);

    for (int i = 1; i < PIECE_N; i++) {
        if (piece_surf[i])
            cairo_surface_destroy(piece_surf[i]);
    }
    return status;
}
