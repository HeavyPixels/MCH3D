#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "clipping.h"

#include "main_debug.h"

#include "st_nicc.h"

char line[41];

size_t sread(void *buffer, size_t size, size_t count, Filoid* stream ){
	memcpy(buffer, (stream->buffer)+(stream->index), size*count);
	stream->index += size*count;
	return size*count;
}

size_t read(void *buffer, size_t size, size_t count, void* stream ){
#if ST_NICC_FILE_MODE
	return fread(buffer, size, count, stream);
#else
	return sread(buffer, size, count, stream);
#endif
}

int sseek(Filoid *stream, long offset, int origin ){
	stream->index = offset;
	return 0;
}

int seek(void *stream, long offset, int origin ){
#if ST_NICC_FILE_MODE
	return fseek(stream, offset, origin);
#else
	return sseek(stream, offset, origin);
#endif
}

long stell(Filoid* stream){
	return stream->index;
}

long tell(void *stream ){
#if ST_NICC_FILE_MODE
	return ftell(stream);
#else
	return stell(stream);
#endif
}

#if ST_NICC_FILE_MODE
void load_color(FILE* file, Color* color){
#else
void load_color(Filoid* file, Color* color){
#endif
	uint16_t data;
	sread(&data, 2, 1, file);
	// Color format is 00000rrr0ggg0bbb, Big Endian
	// Readout is flipped for little endian CPU
	color->r = (data & 0x0007) / 7.0f;
	color->g = ((data >> 12) & 0x0007) / 7.0f;
	color->b = ((data >> 8) & 0x0007) / 7.0f;
}

#if ST_NICC_FILE_MODE
void load_palette(FILE* file, Color* palette){
#else
void load_palette(Filoid* file, Color* palette){
#endif
	uint16_t bitmask;
	sread(&bitmask, 2, 1, file);
	bitmask = (bitmask >> 8) | (bitmask << 8); // Flip endianness
	for (int i = 0; i < 16; i++) {
		if (bitmask & 0x8000) {
			load_color(file, palette + i);
		}
		bitmask <<= 1;
	}
}

float xs[256];
float ys[256];

#if ST_NICC_FILE_MODE
bool load_frame(FILE* file, Color* palette, PolyList* list){
#else
bool load_frame(Filoid* file, Color* palette, PolyList* list){
#endif
	uint8_t flag;
	sread(&flag, 1, 1, file);
	//bool clear_screen = flag & FLAG_MASK_CLEAR_SCREEN;
	bool has_palette = flag & FLAG_MASK_HAS_PALETTE;
	bool is_indexed = flag & FLAG_MASK_IS_INDEXED;

	if (has_palette) {
		load_palette(file, palette);
	}

	if (is_indexed) {
		// Read Vertices
		uint8_t num_vertices;
		sread(&num_vertices, 1, 1, file);
		for (int i = 0; i < num_vertices; i++) {
			uint8_t x_byte, y_byte;
			sread(&x_byte, 1, 1, file);
			sread(&y_byte, 1, 1, file);
			xs[i] = x_byte / 256.0f * 320.0f;
			ys[i] = y_byte / 200.0f * 240.0f;
		}
		// Read Polygons
		while (true) {
			uint8_t poly_flag;
			sread(&poly_flag, 1, 1, file);
			switch (poly_flag)
			{
			case 0xff: // Next frame
				return true;
				break;
			case 0xfe: // Next 64K block
				{
				long cur_pos = stell(file);
				long new_pos = (cur_pos / 65536 + 1) * 65536;
				sseek(file, new_pos, SEEK_SET);
				return true;
				break;
				}
			case 0xfd: // EOF
				return false;
				break;
			default:
				{
				int cidx = (poly_flag >> 4) & 0x0F;
				int poly_verts = poly_flag & 0x0F;
				Polygon* poly = top_polygon(list);
				int i = 0;
				for (; i < 3; i++) {
					uint8_t vert_id;
					sread(&vert_id, 1, 1, file);
					poly->verts[i].x = xs[vert_id];
					poly->verts[i].y = ys[vert_id];
					poly->verts[i].z = 1;
					poly->verts[i].r = palette[cidx].r;
					poly->verts[i].g = palette[cidx].g;
					poly->verts[i].b = palette[cidx].b;
				}
				float xa = poly->verts[0].x;
				float ya = poly->verts[0].y;
				float xb = poly->verts[2].x;
				float yb = poly->verts[2].y;
				poly->num = 3;
				set_poly_aabb(poly);
				add_polygon_count(list);
				for (; i < poly_verts; i++) {
					poly = top_polygon(list);
					uint8_t vert_id;
					sread(&vert_id, 1, 1, file);
					poly->verts[0].x = xa;
					poly->verts[0].y = ya;
					poly->verts[0].z = 1;
					poly->verts[0].r = palette[cidx].r;
					poly->verts[0].g = palette[cidx].g;
					poly->verts[0].b = palette[cidx].b;
					poly->verts[1].x = xb;
					poly->verts[1].y = yb;
					poly->verts[1].z = 1;
					poly->verts[1].r = palette[cidx].r;
					poly->verts[1].g = palette[cidx].g;
					poly->verts[1].b = palette[cidx].b;
					poly->verts[2].x = xs[vert_id];
					poly->verts[2].y = ys[vert_id];
					poly->verts[2].z = 1;
					poly->verts[2].r = palette[cidx].r;
					poly->verts[2].g = palette[cidx].g;
					poly->verts[2].b = palette[cidx].b;
					poly->num = 3;
					set_poly_aabb(poly);
					add_polygon_count(list);
					xb = xs[vert_id];
					yb = ys[vert_id];
				}
				}
				break;
			}
		}
	}
	else {
		// Read Polygons
		while (true) {
			uint8_t poly_flag;
			sread(&poly_flag, 1, 1, file);
			switch (poly_flag)
			{
			case 0xff: // Next frame
				return true;
				break;
			case 0xfe: // Next 64K block
				{
				long cur_pos = stell(file);
				long new_pos = (cur_pos / 65536 + 1) * 65536;
				sseek(file, new_pos, SEEK_SET);
				return true;
				}
				break;
			case 0xfd: // EOF
				return false;
				break;
			default:
				{
				int cidx = (poly_flag >> 4) & 0x0F;
				int poly_verts = poly_flag & 0x0F;
				Polygon* poly = top_polygon(list);
				int i = 0;
				for (; i < 3; i++) {
					uint8_t x_byte, y_byte;
					sread(&x_byte, 1, 1, file);
					sread(&y_byte, 1, 1, file);
					float x = x_byte / 256.0f * 320.0f;
					float y = y_byte / 200.0f * 240.0f;
					poly->verts[i].x = x;
					poly->verts[i].y = y;
					poly->verts[i].z = 1;
					poly->verts[i].r = palette[cidx].r;
					poly->verts[i].g = palette[cidx].g;
					poly->verts[i].b = palette[cidx].b;
				}
				float xa = poly->verts[0].x;
				float ya = poly->verts[0].y;
				float xb = poly->verts[2].x;
				float yb = poly->verts[2].y;
				poly->num = 3;
				set_poly_aabb(poly);
				add_polygon_count(list);
				for (; i < poly_verts; i++) {
					poly = top_polygon(list);
					uint8_t x_byte, y_byte;
					sread(&x_byte, 1, 1, file);
					sread(&y_byte, 1, 1, file);
					float x = x_byte / 256.0f * 320.0f;
					float y = y_byte / 200.0f * 240.0f;
					poly->verts[0].x = xa;
					poly->verts[0].y = ya;
					poly->verts[0].z = 1;
					poly->verts[0].r = palette[cidx].r;
					poly->verts[0].g = palette[cidx].g;
					poly->verts[0].b = palette[cidx].b;
					poly->verts[1].x = xb;
					poly->verts[1].y = yb;
					poly->verts[1].z = 1;
					poly->verts[1].r = palette[cidx].r;
					poly->verts[1].g = palette[cidx].g;
					poly->verts[1].b = palette[cidx].b;
					poly->verts[2].x = x;
					poly->verts[2].y = y;
					poly->verts[2].z = 1;
					poly->verts[2].r = palette[cidx].r;
					poly->verts[2].g = palette[cidx].g;
					poly->verts[2].b = palette[cidx].b;
					poly->num = 3;
					set_poly_aabb(poly);
					add_polygon_count(list);
					xb = x;
					yb = y;
				}
				}
				break;
			}
		}
	}
}