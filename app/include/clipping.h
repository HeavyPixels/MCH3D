#pragma once

#include "types.h"

float clamp(float val, float min, float max);
float lerpf(float a, float b, float t);
Vert lerpv(Vert a, Vert b, float t);
bool clip_polygon_edge(Polygon* poly, int dim, bool side, float limit, Polygon* out);
bool clip_polygon(Polygon* poly, Coord min, Coord max, Polygon* out_poly);
Polygon* clip_to_new_polygon(Polygon* poly, Coord min, Coord max);
void tile_polygon(Polygon* poly, TriList* frameblocks);
void tile_polygons(PolyList* polys, TriList* frameblocks);