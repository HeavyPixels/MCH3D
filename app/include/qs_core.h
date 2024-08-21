/*
 * qs_core.h - GPU commands for the MCH badge demo.
 *
 */

#pragma once

#include "types.h"

void qs_send_triangle_block(TriangleBlock* t);
void qs_send_end_frameblock();
void qs_send_end_frame();