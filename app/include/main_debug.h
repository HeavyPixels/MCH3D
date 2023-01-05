#pragma once

#define PAX_DEBUG 0
#if PAX_DEBUG
// Updates the screen with the last drawing.
void disp_flush();
void println(char* line);
char nibble_hex(int n);
#endif