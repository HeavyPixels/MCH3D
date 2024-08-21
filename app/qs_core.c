#include <stdint.h>

#include "hardware.h"

#include "qs_core.h"

#define QS_TURBO 1

void _convert_triangle_block(TriangleBlock* t, uint8_t *msg){
    // First word
    msg[ 0] = Bitval_slice(t->x_curr, 8, 1).value;
    msg[ 1] = Bitval_concat(Bitval_slice(t->x_curr, 0, 0), Bitval_slice(t->x2, 8, 2)).value;
    msg[ 2] = Bitval_concat(Bitval_slice(t->x2, 1, 0), Bitval_slice(t->x3, 8, 3)).value;
    msg[ 3] = Bitval_concat(Bitval_slice(t->x3, 2, 0), Bitval_slice(t->y_start, 16, 12)).value;
    msg[ 4] = Bitval_slice(t->y_start, 11, 4).value;
    msg[ 5] = Bitval_concat(Bitval_slice(t->y_start, 3, 0), Bitval_slice(t->y_end, 16, 13)).value;
    msg[ 6] = Bitval_slice(t->y_end, 12, 5).value;
    msg[ 7] = Bitval_concat(Bitval_slice(t->y_end, 4, 0), Bitval_slice(t->y2, 7, 5)).value;
    msg[ 8] = Bitval_concat(Bitval_slice(t->y2, 5, 0), Bitval_slice(t->m1, 17, 15)).value;
    msg[ 9] = Bitval_slice(t->m1, 14, 7).value;
    msg[10] = Bitval_concat(Bitval_slice(t->m1, 6, 0), Bitval_slice(t->m2, 17, 17)).value;
    msg[11] = Bitval_slice(t->m2, 16, 9).value;
    msg[12] = Bitval_slice(t->m2, 8, 1).value;
    msg[13] = Bitval_concat(Bitval_slice(t->m2, 0, 0), Bitval_slice(t->m3, 17, 11)).value;
    msg[14] = Bitval_slice(t->m3, 10, 3).value;
    msg[15] = Bitval_concat(Bitval_slice(t->m3, 2, 0), Bitval_slice(t->z1, 23, 19)).value;
    msg[16] = Bitval_slice(t->z1, 18, 11).value;
    msg[17] = Bitval_slice(t->z1, 10, 3).value;
    msg[18] = Bitval_concat(Bitval_slice(t->z1, 2, 0), Bitval_slice(t->r1, 13, 9)).value;
    msg[19] = Bitval_slice(t->r1, 8, 1).value;
    msg[20] = Bitval_concat(Bitval_slice(t->r1, 0, 0), Bitval_slice(t->g1, 14, 8)).value;
    msg[21] = Bitval_slice(t->g1, 7, 0).value;
    msg[22] = Bitval_slice(t->b1, 13, 6).value;
    msg[23] = Bitval_concat(Bitval_slice(t->b1, 5, 0), Bitval_slice(t->u1, 20, 19)).value;
    msg[24] = Bitval_slice(t->u1, 18, 11).value;
    msg[25] = Bitval_slice(t->u1, 10, 3).value;
    msg[26] = Bitval_concat(Bitval_slice(t->u1, 2, 0), Bitval_slice(t->v1, 20, 16)).value;
    msg[27] = Bitval_slice(t->v1, 15, 8).value;
    msg[28] = Bitval_slice(t->v1, 7, 0).value;
    msg[29] = (t->end_frameblock ? 0x80 : 0) | (t->end_frame ? 0x40: 0);

    // Second word
    msg[30] = Bitval_slice(t->mz, 24, 17).value;
    msg[31] = Bitval_slice(t->mz, 16, 9).value;
    msg[32] = Bitval_slice(t->mz, 8, 1).value;
    msg[33] = Bitval_concat(Bitval_slice(t->mz, 0, 0), Bitval_slice(t->nz, 24, 18)).value;
    msg[34] = Bitval_slice(t->nz, 17, 10).value;
    msg[35] = Bitval_slice(t->nz, 9, 2).value;
    msg[36] = Bitval_concat(Bitval_slice(t->nz, 1, 0), Bitval_slice(t->mr, 14, 9)).value;
    msg[37] = Bitval_slice(t->mr, 8, 1).value;
    msg[38] = Bitval_concat(Bitval_slice(t->mr, 0, 0), Bitval_slice(t->nr, 14, 8)).value;
    msg[39] = Bitval_slice(t->nr, 7, 0).value;
    msg[40] = Bitval_slice(t->mg, 15, 8).value;
    msg[41] = Bitval_slice(t->mg, 7, 0).value;
    msg[42] = Bitval_slice(t->ng, 15, 8).value;
    msg[43] = Bitval_slice(t->ng, 7, 0).value;
    msg[44] = Bitval_slice(t->mb, 14, 7).value;
    msg[45] = Bitval_concat(Bitval_slice(t->mb, 6, 0), Bitval_slice(t->nb, 14, 14)).value;
    msg[46] = Bitval_slice(t->nb, 13, 6).value;
    msg[47] = Bitval_concat(Bitval_slice(t->nb, 5, 0), Bitval_slice(t->mu, 21, 20)).value;
    msg[48] = Bitval_slice(t->mu, 19, 12).value;
    msg[49] = Bitval_slice(t->mu, 11, 4).value;
    msg[50] = Bitval_concat(Bitval_slice(t->mu, 3, 0), Bitval_slice(t->nu, 21, 18)).value;
    msg[51] = Bitval_slice(t->nu, 17, 10).value;
    msg[52] = Bitval_slice(t->nu, 9, 2).value;
    msg[53] = Bitval_concat(Bitval_slice(t->nu, 1, 0), Bitval_slice(t->mv, 21, 16)).value;
    msg[54] = Bitval_slice(t->mv, 15, 8).value;
    msg[55] = Bitval_slice(t->mv, 7, 0).value;
    msg[56] = Bitval_slice(t->nv, 21, 14).value;
    msg[57] = Bitval_slice(t->nv, 13, 6).value;
    msg[58] = Bitval_slice(t->nv, 5, 0).value << 2;
    msg[59] = 0x00;
}

void qs_send_triangle_block(TriangleBlock* t)
{
    uint8_t msg[60];
    _convert_triangle_block(t, msg);
    #if QS_TURBO
    ice40_send_turbo(get_ice40(), msg, 60);
    #else
    //ice40_send(get_ice40(), msg, 1);
    #endif
}

void qs_send_end_frameblock()
{
    uint8_t msg[60]= {0};
    msg[29] = 0x80;
    #if QS_TURBO
    ice40_send_turbo(get_ice40(), msg, 60);
    #else
    //ice40_send(get_ice40(), msg, 1);
    #endif
}

void qs_send_end_frame()
{
    uint8_t msg[60] = {0};
    msg[29] = 0x40;
    #if QS_TURBO
    ice40_send_turbo(get_ice40(), msg, 60);
    #else
    //ice40_send(get_ice40(), msg, 1);
    #endif
}