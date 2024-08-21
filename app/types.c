#include "types.h"

#include <stdlib.h>

Polygon* top_polygon(PolyList* list) {
    while (list->num >= POLYLIST_MAX) list = list->next;
    return &(list->polys[list->num]);
}

void add_polygon_count(PolyList* list) {
    while (list->num >= POLYLIST_MAX) list = list->next;
    list->num += 1;
    if (list->num >= POLYLIST_MAX) {
        list->next = (PolyList*)malloc(sizeof(PolyList));
        list->next->num = 0;
    }
}

void clear_polylist(PolyList* list) {
    if (list->num < POLYLIST_MAX) {
        list->num = 0;
        return;
    }
    list->num = 0;
    list = list->next;
    while (list->num >= POLYLIST_MAX) {
        PolyList* next = list->next;
        free(list);
        list = next;
    }
    free(list);
}

TriangleBlock* top_triangle(TriList* list) {
    while (list->num >= TRILIST_MAX) list = list->next;
    return &(list->tris[list->num]);
}

void add_triangle_count(TriList* list) {
    while (list->num >= TRILIST_MAX) list = list->next;
    list->num += 1;
    if (list->num >= TRILIST_MAX) {
        list->next = (TriList*)malloc(sizeof(TriList));
        list->next->num = 0;
    }
}

void clear_trilist(TriList* list) {
    if (list->num < TRILIST_MAX) {
        list->num = 0;
        return;
    }
    list->num = 0;
    list = list->next;
    while (list->num >= TRILIST_MAX) {
        TriList* next = list->next;
        free(list);
        list = next;
    }
    free(list);
}

/*PolyList* insert_item(PolyList* node, Polygon* poly) {
    PolyList* new_node = (PolyList*)malloc(sizeof(PolyList));
    new_node->poly = poly;
    new_node->next = node->next;
    node->next = new_node;
    return new_node;
}

void remove_child(PolyList* node) {
    PolyList* child = node->next;
    node->next = child->next;
    free(child);
}*/