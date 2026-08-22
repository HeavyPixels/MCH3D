#include "bitval.h"

#ifndef max
    #define max(a,b) (((a) > (b)) ? (a) : (b))
#endif
#ifndef min
    #define min(a,b) (((a) < (b)) ? (a) : (b))
#endif

Bitval Bitval_initf(float value, bool is_signed, unsigned int iwidth, unsigned int fwidth){
    Bitval bv;
    bv.is_signed = is_signed;
    bv.iwidth = iwidth;
    bv.fwidth = fwidth;
    bv.width = (is_signed ? 1 : 0) + iwidth + fwidth;
    value *= (1 << fwidth);
    if (is_signed){
        bv.value = max(min(value, (1 << (bv.width-1)) - 1), -(1 << (bv.width-1)));
    } else {
        bv.value = max(min(value, (1 << bv.width) - 1), 0);
    }
    return bv;
}

Bitval Bitval_initi(int value, bool is_signed, unsigned int iwidth){
    Bitval bv;
    bv.is_signed = is_signed;
    bv.iwidth = iwidth;
    bv.fwidth = 0;
    bv.width = (is_signed ? 1 : 0) + iwidth;
    if (is_signed){
        bv.value = max(min(value, (1 << iwidth) - 1), -(1 << (iwidth)));
    } else {
        bv.value = max(min(value, (1 << iwidth) - 1), 0);
    }
    return bv;
}

Bitval Bitval_concat(Bitval a, Bitval b){
    return Bitval_initi((a.value << b.width) + b.value, false, a.width + b.width);
}

Bitval Bitval_slice(Bitval bv, int top, int bottom){
    int width = top - bottom + 1;
    int mask = (1 << width) - 1;
    return Bitval_initi((bv.value >> bottom) & mask, false, width);
}