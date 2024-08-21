#pragma once

#include "types.h"

// Takes a set of vertices, computes the triangleblock parameters, and inserts
// it into the frameblock list at the left-most x coordinate.
// TODO:
// - Add uv-coordinate support
bool precalc(Vert* va, Vert* vb, Vert* vc, TriList* frameblocks);