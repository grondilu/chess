#include <stdint.h>

static uint64_t PSQ[16][64];
static uint64_t CASTLE[16];
static uint64_t EP[8];
static uint64_t SIDE;
static int ready;

static uint64_t splitmix64(uint64_t *state) {
    uint64_t z = (*state += UINT64_C(0x9E3779B97F4A7C15));
    z = (z ^ (z >> 30)) * UINT64_C(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)) * UINT64_C(0x94D049BB133111EB);
    return z ^ (z >> 31);
}

static void init(void) {
    uint64_t state = UINT64_C(0xA5A5A5A512345678);
    /* Same order as the old Raku generator: white 1–6, then black 9–14. */
    for (int p = 1; p <= 6; p++) {
        for (int s = 0; s < 64; s++) {
            PSQ[p][s] = splitmix64(&state);
        }
    }
    for (int p = 9; p <= 14; p++) {
        for (int s = 0; s < 64; s++) {
            PSQ[p][s] = splitmix64(&state);
        }
    }
    for (int c = 0; c < 16; c++) {
        CASTLE[c] = splitmix64(&state);
    }
    for (int f = 0; f < 8; f++) {
        EP[f] = splitmix64(&state);
    }
    SIDE = splitmix64(&state);
    ready = 1;
}

uint64_t chess_zobrist_key(const uint8_t *board, uint8_t castle,
                           int32_t ep_file, uint8_t side) {
    if (!ready) {
        init();
    }

    uint64_t k = 0;
    for (int i = 0; i < 64; i++) {
        uint8_t p = board[i];
        if (p) {
            k ^= PSQ[p][i];
        }
    }
    k ^= CASTLE[castle];
    if (ep_file >= 0) {
        k ^= EP[ep_file];
    }
    if (side == 1) {
        k ^= SIDE;
    }
    return k;
}
