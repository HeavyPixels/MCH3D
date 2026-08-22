#pragma once

#include <stdbool.h>
#include <stdint.h>

typedef struct{
    bool is_signed;
    unsigned int iwidth;
    unsigned int fwidth;
    unsigned int width;
    long int value;

} Bitval;

Bitval Bitval_initf(float value, bool is_signed, unsigned int iwidth, unsigned int fwidth);
Bitval Bitval_initi(int value, bool is_signed, unsigned int iwidth);

int Bitval_width(Bitval* bv);

Bitval Bitval_concat(Bitval a, Bitval b);
Bitval Bitval_slice(Bitval bv, int top, int bottom);