#pragma once

#include <stdlib.h>
#include <stdio.h>
#include "clipping.h"

#define FLAG_MASK_CLEAR_SCREEN 1
#define FLAG_MASK_HAS_PALETTE 2
#define FLAG_MASK_IS_INDEXED 4

#ifdef WIN32
#define ST_NICC_FILE_MODE 1
#else
#define ST_NICC_FILE_MODE 0
#endif

typedef struct{
    uint8_t* buffer;
    size_t index;
} Filoid;


#if ST_NICC_FILE_MODE
void load_color(FILE* file, Color* color);
#else
void load_color(Filoid* file, Color* color);
#endif

#if ST_NICC_FILE_MODE
void load_palette(FILE* file, Color* palette);
#else
void load_palette(Filoid* file, Color* palette);
#endif

#if ST_NICC_FILE_MODE
bool load_frame(FILE* file, Color* palette, PolyList* list);
#else
bool load_frame(Filoid* file, Color* palette, PolyList* list);
#endif