#pragma once

#include "bitval.h"

#include <stdbool.h>

typedef struct
{
    float x, y, z;
} Coord;

typedef struct
{
    float r, g, b;
} Color;

typedef union {
    struct {
        float x, y, z;
        float r, g, b;
    };
    float v[6];
} Vert;

typedef struct {
    Vert verts[7];
    int num;
    Coord min, max;
} Polygon;

void set_poly_aabb(Polygon* poly);

#define POLYLIST_MAX 16

typedef struct PolyList {
    Polygon polys[POLYLIST_MAX];
    int num;
    struct PolyList* next;
} PolyList;

Polygon* top_polygon(PolyList* list);
void add_polygon_count(PolyList* list);
void clear_polylist(PolyList* list);

typedef struct {
    Bitval x_curr, x2, x3;
    Bitval y_start, y_end, y2;
    Bitval m1, m2, m3;
    Bitval z1, mz, nz;
    Bitval r1, mr, nr;
    Bitval g1, mg, ng;
    Bitval b1, mb, nb;
    Bitval u1, mu, nu;
    Bitval v1, mv, nv;
    bool end_frameblock;
    bool end_frame;
} TriangleBlock;

#define TRILIST_MAX 16

typedef struct TriList {
    TriangleBlock tris[TRILIST_MAX];
    int num;
    struct TriList* next;
} TriList;

TriangleBlock* top_triangle(TriList* list);
void add_triangle_count(TriList* list);
void clear_trilist(TriList* list);