#include "qs_render.h"

#include "clipping.h"
#include "qs_core.h"

#include "main.h"

void convert_and_send_vertex(int idx, Vert* v){
    qs_send_vertex(idx,
        (int)(v->x+0.5f),
        (int)(v->y),
        (int)(v->z+0.5f),
        (int)(v->r*0x1F+0.5f),
        (int)(v->g*0x3F+0.5f),
        (int)(v->b*0x1F+0.5f));
}

void qs_render(PolyList* tiles){
    for (int y = 0; y < 8; y++) {
        for(int x=0; x < 10; x++) {
            PolyList* ptr = &(tiles[10*y+x]);
            if(ptr->num == 0){
                usleep(10);
                continue;
            }
            qs_send_tile(x,y);
            int j = 0;
            while (j < ptr->num) {
                Polygon* poly = &(ptr->polys[j]);
                convert_and_send_vertex(0, &(poly->verts[0]));
                convert_and_send_vertex(1, &(poly->verts[1]));
                for (int i = 2; i < poly->num; i++) {
                    if (i&1) {
                        convert_and_send_vertex(1, &(poly->verts[i]));
                        qs_send_triangle(0,2,1);
                    } else {
                        convert_and_send_vertex(2, &(poly->verts[i]));
                        qs_send_triangle(0,1,2);
                    }                
                }
                j++;
                if (j >= POLYLIST_MAX) {
                    ptr = ptr->next;
                    j = 0;
                }
            }
            //usleep(1);
        }
    }
}