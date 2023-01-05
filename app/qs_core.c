#include <stdint.h>

#include "hardware.h"

#include "qs_core.h"

#define QS_TURBO 1

void qs_send_tile(int id_x, int id_y){
    uint8_t msg[2];
    msg[0] = 0x40;
    msg[1] = (id_y << 4) | id_x;
    #if QS_TURBO
    ice40_send_turbo(get_ice40(), msg, 2);
    #else
    //ice40_send(get_ice40(), msg, 2);
    #endif
}

void qs_send_vertex(int v_id, int x, int y, int z, int r, int g, int b){
    uint8_t msg[6];
    msg[0] = (0x3 << 6) | ((v_id << 4) & 0x30);
    msg[1] = (x & 0x3F);
    msg[2] = (y << 2) | ((z >> 8) & 0x03);
    msg[3] = (z & 0xFF);
    msg[4] = ((r << 3) & 0xF8) | ((g >> 3) & 0x07);
    msg[5] = ((g << 5) & 0xE0) | (b & 0x1F);
    #if QS_TURBO
    ice40_send_turbo(get_ice40(), msg, 6);
    #else
    //ice40_send(get_ice40(), msg, 6);
    #endif
}

void qs_send_triangle(int v1, int v2, int v3){
    uint8_t msg[1];
    msg[0] = (0x2 << 6) | ((v1 << 4) & 0x30) | ((v2 << 2) & 0x0C) | (v3 & 0x03);
    #if QS_TURBO
    ice40_send_turbo(get_ice40(), msg, 1);
    #else
    //ice40_send(get_ice40(), msg, 1);
    #endif
}