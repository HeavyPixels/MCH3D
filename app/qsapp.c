#define _CRT_SECURE_NO_WARNINGS

#include "qsapp.h"

#include "clipping.h"
#include "qs_core.h"
#include "qs_render.h"
#include "st_nicc.h"

#include "precalc.h"

#include "main.h"

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

TriList* frameblocks;
PolyList list;
Color palette[16];
bool more_frames;

int counter = 0;

int qsapp_init(){
    frameblocks = (TriList*)malloc(80 * sizeof(TriList));
    for (int i = 0; i < 80; i++){
        frameblocks[i].num = 0;
        frameblocks[i].next = NULL;
    }
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
    if (more_frames && ((int)file->buffer+(int)file->index < (int)scene1_bin_end)) {
        for (int i = 0; i < 80; i++) clear_trilist(&(frameblocks[i]));
        clear_polylist(&list);
        Vert v[4] = {
            {{  0,   0, 10000, 0.0f, 0.0f, 0.0f}},
            {{320,   0, 10000, 0.0f, 0.0f, 0.0f}},
            {{320, 240, 10000, 0.0f, 0.0f, 0.0f}},
            {{  0, 240, 10000, 0.0f, 0.0f, 0.0f}}
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
        //char line[41];
        //sprintf(line, "Polys: %d", list.num);
        //println(line);
        //for(int i=0; i<list.num; i++){
        //    sprintf(line, "%d:[%5.1f,%5.1f],[%5.1f,%5.1f]", list.polys[i].num, list.polys[i].verts[0].x, list.polys[i].verts[0].y, list.polys[i].verts[1].x, list.polys[i].verts[1].y);
        //    println(line);
        //}
        tile_polygons(&list, frameblocks);
#if PAX_DEBUG
        more_frames = false;
#else
        qs_render(frameblocks);
#endif
    } else {
        qs_render(frameblocks);
    }
    return 1;
    
    // PRECALC TEST:
    /*for (int i = 0; i < 80; i++) clear_trilist(&(frameblocks[i]));
    Polygon a = {
        .verts = {
            {{  0,   0, 200, 31.0f,  0.0f,  0.0f}},
            {{320,   0, 200,  0.0f, 63.0f,  0.0f}},
            {{320, 240, 200,  0.0f,  0.0f, 31.0f}},
            {{  0, 240, 200, 31.0f,  0.0f, 31.0f}}
        },
        .num = 4
    };
    
    set_poly_aabb(&a);
    tile_polygon(&a, frameblocks);
    qs_render(frameblocks);*/

    /*int x_plus = (counter / 3) % 160;
    int y_plus = (counter / 4) % 120;

    Vert a1 = {{  0,   0, 200, 23, 31, 15}};
    Vert a2 = {{319,   0, 200, 15, 47, 15}};
    Vert a3 = {{319, 239, 200, 15, 31, 23}};
    Vert a4 = {{  0, 239, 200, 23, 15, 23}};
    
    Vert b1 = {{  0 + x_plus,   0 + y_plus, 20, 31, 31,  0}};
    Vert b2 = {{159 + x_plus,   0 + y_plus, 20,  0, 64,  0}};
    Vert b3 = {{159 + x_plus, 119 + y_plus, 20,  0, 31, 31}};
    Vert b4 = {{  0 + x_plus, 119 + y_plus, 20, 31,  0, 31}};*/


    /*TriangleBlock t;
    precalc_triangle(&a1, &a2, &a3, &t);
    qs_send_triangle_block(&t);
    precalc_triangle(&a1, &a4, &a3, &t);
    qs_send_triangle_block(&t);

    precalc_triangle(&b1, &b2, &b3, &t);
    qs_send_triangle_block(&t);
    precalc_triangle(&b1, &b4, &b3, &t);
    qs_send_triangle_block(&t);
    for(int i = 0; i < 79; i++) qs_send_end_frameblock();
    qs_send_end_frame();
    usleep(16000);

    counter++;

    return 1;*/

    // SIMPLE TEST:    
    /*
    uint8_t a[60] = {0x00, x_curr, 0x28, 0x27, 0xfd, 0xe0, 0x0e, 0xf0, 0x00, 0x07, 0xfe, 0x85, 0xfe, 0x82, 0x00, 0x30, 0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xf8, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                     0x00, 0x01, 0x91, 0x7f, 0xfd, 0xe9, 0x40, 0x00, 0x7f, 0xa8, 0x00, 0x65, 0x00, 0x5a, 0xff, 0x9e, 0x00, 0xb0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
    uint8_t b[60] = {0x00, 0x00, 0x00, 0x27, 0xfd, 0xe0, 0x00, 0x00, 0x00, 0x07, 0xfd, 0x02, 0x00, 0x00, 0x00, 0x00, 0x04, 0xe2, 0x00, 0x0f, 0x00, 0x3e, 0x00, 0x78, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
    uint8_t c[60] = {0x00, 0x00, 0x4f, 0xe7, 0xfd, 0xe0, 0x0e, 0xf0, 0x07, 0x7f, 0xfd, 0x02, 0x00, 0x00, 0x00, 0x00, 0x04, 0xe2, 0x00, 0x0f, 0x00, 0x3e, 0x00, 0x78, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
    uint8_t efb[2] = {0x80, 0x00};
    uint8_t ef[2] = {0x40, 0x00};

    ice40_send_turbo(get_ice40(), a, 60); usleep(10);
    ice40_send_turbo(get_ice40(), b, 60); usleep(10);
    ice40_send_turbo(get_ice40(), c, 60); usleep(10);
    for(int i = 0; i < 79; i++){
        ice40_send_turbo(get_ice40(), efb, 2); usleep(10);
    }
    ice40_send_turbo(get_ice40(), ef, 2); usleep(10);
    usleep(16000);

    return 1;*/
    //return 0;
}