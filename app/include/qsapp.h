#pragma once

#include "stdbool.h"

typedef struct {
    bool up, down, left, right, push;
    bool a, b, x, y, l, r;
    bool home, menu, select, start;
} qs_button_state;

int qsapp_init();
int qsapp_loop(qs_button_state button, float deltatime);