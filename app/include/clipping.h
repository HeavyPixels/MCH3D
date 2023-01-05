#pragma once

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
void clear_list(PolyList* list);

float clamp(float val, float min, float max);
float lerpf(float a, float b, float t);
Vert lerpv(Vert a, Vert b, float t);
bool clip_polygon_edge(Polygon* poly, int dim, bool side, float limit, Polygon* out);
bool clip_polygon(Polygon* poly, Coord min, Coord max, Polygon* out_poly);
Polygon* clip_to_new_polygon(Polygon* poly, Coord min, Coord max);
void tile_polygon(Polygon* poly, PolyList* tiles);
void tile_polygons(PolyList* polys, PolyList* tiles);