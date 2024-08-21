#include "qs_render.h"

#include "clipping.h"
#include "qs_core.h"
#include "precalc.h"

#include "main.h"

void qs_render(TriList* frameblocks){
    for (int x = 0; x < 80; x++) {
        usleep(200);
        TriList* ptr = &(frameblocks[x]);
        if(ptr->num == 0){
            continue;
        }
        int j = 0;
        while (j < ptr->num) {
            qs_send_triangle_block(&(ptr->tris[j]));
            j++;
            if (j >= POLYLIST_MAX) {
                ptr = ptr->next;
                j = 0;
            }
        }
        if(x<79) qs_send_end_frameblock();
        else qs_send_end_frame();
    }
}
