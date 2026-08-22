#pragma once

#include "types.h"

// Takes a set of vertices, computes the triangleblock parameters, and inserts
// it into the frameblock list at the left-most x coordinate.
// TODO:
// - Add uv-coordinate support
bool precalc(Vert* va, Vert* vb, Vert* vc, TriList* frameblocks);

bool precalc_triangle(Vert* v1, Vert* v2, Vert* v3, TriangleBlock *t);

bool vert_sort(Vert* va, Vert* vb, Vert* vc, Vert** v1, Vert** v2, Vert** v3);