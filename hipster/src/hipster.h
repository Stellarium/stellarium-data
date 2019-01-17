/*
 * Stellarium
 * Copyright (C) 2018 Guillaume Chereau
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Suite 500, Boston, MA  02110-1335, USA.
 */

#define _GNU_SOURCE

#include <assert.h>
#include <math.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define LOG_D(msg, ...) \
    dolog("%s (%s:%d): " msg, __func__, __FILE__, __LINE__, ##__VA_ARGS__)

#define SWAP(x0, x) {typeof(x0) tmp = x0; x0 = x; x = tmp;}

#define min(a, b) ({ \
      __typeof__ (a) _a = (a); \
      __typeof__ (b) _b = (b); \
      _a < _b ? _a : _b; \
      })

#define max(a, b) ({ \
      __typeof__ (a) _a = (a); \
      __typeof__ (b) _b = (b); \
      _a > _b ? _a : _b; \
      })

#define clamp(x, a, b) (min(max(x, a), b))

#define cmp(a, b) ({ \
    __typeof__ (a) _a = (a); \
    __typeof__ (b) _b = (b); \
    (_a > _b) ? +1 : (_a < _b) ? -1 : 0; \
})

// Degree to radians
#define DD2R (1.745329251994329576923691e-2)


// System
void dolog(const char *msg, ...);


// Image
typedef struct img_t {
    uint8_t *data;
    int w;
    int h;
    int bpp;
} img_t;

#define IMG_ITER(img, x, y) \
    for (y = 0; y < (img)->h; y++) for (x = 0; x < (img)->w; x++)

#define IMG_AT(img, x, y) \
    (&((img)->data[((size_t)(y) * (img)->w + (x)) * (img)->bpp]))


void img_init(img_t *img, int w, int h, int bpp);
int img_load(img_t *img, const char *path, int bpp);
int img_load_from_memory(img_t *img, uint8_t *data, int size, int bpp);
int img_write(const img_t *img, const char *path);
void img_map(const img_t *src, img_t *out, const double (*pos)[2]);
void img_cleanup(img_t *img);
void img_downsample(const img_t *img, img_t *out);
void img_blit(const img_t *img, img_t *out, int x, int y);
// Test if image contain only alpha = 0 pixels.
bool img_is_empty(const img_t *img);
// Convert bump map to normal map.
void img_bump_to_normal(const img_t *img, img_t *out);


// Healpix

/* Get a 3x3 matrix that map uv coordinates to the xy healpix coordinate
 covering a healpix pixel.
 */
void healpix_get_mat3(int nside, int pix, double out[3][3]);

/* Compute position from healpix xy coordinates. */
void healpix_xy2vec(const double xy[2], double out[3]);

/* Convert healpix xyf coordinate to a nest pix index. */
int healpix_xyf2nest(int nside, int ix, int iy, int face_num);

/* Convert healpix nest index to cartesian 3d vector. */
void healpix_pix2vec(int nside, int pix, double out[3]);

/* Convert healpix nest index to polar angle. */
void healpix_pix2ang(int nside, int pix, double *theta, double *phi);

void healpix_xyf2ang(int nside, int ix, int iy, int face,
                     double *theta, double *phi);

void healpix_nest2xyf(int nside, int pix, int *ix, int *iy, int *face_num);

/* Convert polar angle to healpix next index */
void healpix_ang2pix(int nside, double theta, double phi, int *pix);
