#include <math.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "clipping.h"
#include "precalc.h"

#ifndef max
    #define max(a,b) (((a) > (b)) ? (a) : (b))
#endif
#ifndef min
    #define min(a,b) (((a) < (b)) ? (a) : (b))
#endif

//typedef enum { REJECT=0, TRIVIAL_ACCEPT, CLIPPED } ClipState;

void set_poly_aabb(Polygon* poly) {
    float xmin = poly->verts[0].x;
    float xmax = poly->verts[0].x;
    float ymin = poly->verts[0].y;
    float ymax = poly->verts[0].y;
    float zmin = poly->verts[0].z;
    float zmax = poly->verts[0].z;
    for (int i = 1; i < poly->num; i++) {
        xmin = min(xmin, poly->verts[i].x);
        xmax = max(xmax, poly->verts[i].x);
        ymin = min(ymin, poly->verts[i].y);
        ymax = max(ymax, poly->verts[i].y);
        zmin = min(zmin, poly->verts[i].z);
        zmax = max(zmax, poly->verts[i].z);
    }
    poly->min.x = xmin;
    poly->min.y = ymin;
    poly->min.z = zmin;
    poly->max.x = xmax;
    poly->max.y = ymax;
    poly->max.z = zmax;
}

inline float clamp(float val, float min, float max) {
    return (val < min) ? min : (val > max) ? max : val;
}

inline float lerpf(float a, float b, float t) {
    return (1 - t) * a + t * b;
}

inline Vert lerpv(Vert a, Vert b, float t) {
    Vert o = {
        .x = lerpf(a.x, b.x, t),
        .y = lerpf(a.y, b.y, t),
        .z = lerpf(a.z, b.z, t),
        .r = lerpf(a.r, b.r, t),
        .g = lerpf(a.g, b.g, t),
        .b = lerpf(a.b, b.b, t)
    };
    return o;
}

bool clip_polygon_edge(Polygon* poly, int dim, bool side, float limit, Polygon* out) {
    bool test[7];
    bool all = true;
    bool any = false;
    for (int i = 0; i < poly->num; i++) {
        if (side)
            test[i] = poly->verts[i].v[dim] <= limit;
        else
            test[i] = poly->verts[i].v[dim] >= limit;
        all &= test[i];
        any |= test[i];
    }
    if (all) {
        for (int i = 0; i < poly->num; i++) {
            out->verts[out->num++] = poly->verts[i];
        }
        return true;
    }
    if (!any) {
        return false;
    }
    for (int i = 0; i < poly->num; i++) {       
        int j = (i + 1) % poly->num;
        if (test[i] & test[j])
            out->verts[out->num++] = poly->verts[i];
        else if (!test[i] & !test[j]) {
            continue;
        }
        else if (!test[i] & test[j]) {
            float t = (limit - poly->verts[i].v[dim]) / (poly->verts[j].v[dim] - poly->verts[i].v[dim]);
            Vert v = lerpv(poly->verts[i], poly->verts[j], t);
            out->verts[out->num++] = v;
        }
        else if (test[i] & !test[j]) {
            float t = (limit - poly->verts[i].v[dim]) / (poly->verts[j].v[dim] - poly->verts[i].v[dim]);
            Vert v = lerpv(poly->verts[i], poly->verts[j], t);
            out->verts[out->num++] = poly->verts[i];
            out->verts[out->num++] = v;
        }
    }
    return true;
}


bool clip_polygon(Polygon* poly, Coord min, Coord max, Polygon* out_poly) {
    Polygon poly_a = { .num = 0 };
    if(!clip_polygon_edge(poly, 0, false, min.x, &poly_a)) return false;
    out_poly->num = 0;
    if(!clip_polygon_edge(&poly_a, 1, false, min.y, out_poly)) return false;
    poly_a.num = 0;
    if(!clip_polygon_edge(out_poly, 0, true, max.x, &poly_a)) return false;
    out_poly->num = 0;
    if(!clip_polygon_edge(&poly_a, 1, true, max.y, out_poly)) return false;
    return true;
}

Polygon* clip_to_new_polygon(Polygon* poly, Coord min, Coord max) {
    Polygon* new_poly = (Polygon*)malloc(sizeof(Polygon));
    if (clip_polygon(poly, min, max, new_poly)) {
        return new_poly;
    }
    else {
        free(new_poly);
        return NULL;
    }
}

void tile_polygon(Polygon* poly, TriList* frameblocks) {
    Coord min = {.x = 0, .y = 0};
    Coord max = {.x = 320, .y = 240};
    Polygon clipped;
    if (clip_polygon(poly, min, max, &clipped)){
        for (int i = 2; i < poly->num; i++) {            
            precalc(&(poly->verts[0]), &(poly->verts[i-1]), &(poly->verts[i]), frameblocks);
        }
    }
}

void tile_polygons(PolyList* list, TriList* frameblocks) {
    int j = 0;
    while (j < list->num) {
        Polygon* poly = &(list->polys[j]);
        tile_polygon(poly, frameblocks);
        j++;
        if (j >= POLYLIST_MAX) {
            list = list->next;
            j = 0;
        }
    }
}