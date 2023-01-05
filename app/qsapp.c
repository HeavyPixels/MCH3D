#define _CRT_SECURE_NO_WARNINGS

#include "qsapp.h"

#include "clipping.h"
#include "qs_core.h"
#include "qs_render.h"
#include "st_nicc.h"

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#include "main_debug.h"

#ifdef WIN32
FILE* file;
#else
extern const uint8_t scene1_bin_start[] asm("_binary_scene1_bin_start");
extern const uint8_t scene1_bin_end[] asm("_binary_scene1_bin_end");
Filoid filoid;
Filoid* file;
#endif

PolyList* tiles;
PolyList list;
Color palette[16];
bool more_frames;

int qsapp_init(){
    tiles = (PolyList*)malloc(80 * sizeof(PolyList));
    for (int i = 0; i < 80; i++) tiles[i].num = 0;
#ifdef WIN32
    file = fopen("scene1.bin", "rb");
    if (!file)
        exit(0);
#else
    file = &filoid;
    file->buffer=scene1_bin_start;
    file->index=0;
#endif
    list.num = 0;
    more_frames = true;
    return 1;
}

int qsapp_loop(qs_button_state button, float deltatime){
#ifdef WIN32
    if(more_frames){
#else
    if (more_frames && ((int)file->buffer+(int)file->index < (int)scene1_bin_end)) {
#endif
        for (int i = 0; i < 80; i++) clear_list(&(tiles[i]));
        clear_list(&list);
        Vert v[4] = {
            {{  0,   0, 200, 0.0f, 0.0f, 0.0f}},
            {{320,   0, 200, 0.0f, 0.0f, 0.0f}},
            {{320, 240, 200, 0.0f, 0.0f, 0.0f}},
            {{  0, 240, 200, 0.0f, 0.0f, 0.0f}}
        };
        list.num = 2;
        list.polys[0].verts[0] = v[0];
        list.polys[0].verts[1] = v[1];
        list.polys[0].verts[2] = v[2];
        list.polys[0].num = 3;
        list.polys[1].verts[0] = v[0];
        list.polys[1].verts[1] = v[2];
        list.polys[1].verts[2] = v[3];
        list.polys[1].num = 3;
        set_poly_aabb(&list.polys[0]);
        set_poly_aabb(&list.polys[1]);
        more_frames = load_frame(file, palette, &list);
        tile_polygons(&list, tiles);
#if PAX_DEBUG
        more_frames = false;
#else
        qs_render(tiles);
#endif
    } else {
        qs_render(tiles);
    }
    return 1;
}