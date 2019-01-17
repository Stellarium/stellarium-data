/*
 * Stellarium Hipster
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

#include "hipster.h"

#define STB_IMAGE_IMPLEMENTATION
#define STB_IMAGE_WRITE_IMPLEMENTATION
#define STBI_FAILURE_USERMSG
#pragma GCC diagnostic ignored "-Wmaybe-uninitialized"
#pragma GCC diagnostic ignored "-Wunused-but-set-variable"

#include "stb_image.h"
#include <jpeglib.h>
#include <png.h>
#include <webp/encode.h>
#include <webp/decode.h>
#include <tiffio.h>

void img_init(img_t *img, int w, int h, int bpp)
{
    img->data = calloc(w * h, bpp);
    img->w = w;
    img->h = h;
    img->bpp = bpp;
}

/*
int img_load_from_memory(img_t *img, uint8_t *data, int size, int bpp)
{
    img->data = stbi_load_from_memory(data, size, &img->w, &img->h,
                                      &img->bpp, bpp);
    return img->data ? 0 : -1;
}
*/

static uint8_t *read_file(const char *path, size_t *size)
{
    FILE *file;
    uint8_t *ret = NULL;
    size_t read_size __attribute__((unused));
    size_t size_default;

    size = size ?: &size_default; // Allow to pass NULL as size;
    file = fopen(path, "rb");
    if (!file) return NULL;
    fseek(file, 0, SEEK_END);
    *size = (int)ftell(file);
    fseek(file, 0, SEEK_SET);
    ret = malloc(*size + 1);
    read_size = fread(ret, *size, 1, file);
    assert(read_size == 1 || *size == 0);
    ret[*size] = '\0';
    fclose(file);
    return ret;
}

static int img_load_webp(img_t *img, const char *path, int bpp)
{
    uint8_t *data;
    size_t size;
    data = read_file(path, &size);
    if (bpp == 3) {
        img->data = WebPDecodeRGB(data, size, &img->w, &img->h);
        img->bpp = 3;
    } else {
        img->data = WebPDecodeRGBA(data, size, &img->w, &img->h);
        img->bpp = 4;
    }
    free(data);
    if (!img->data) return -1;
    return 0;
}

static int img_load_tiff(img_t *img, const char *path, int bpp)
{
    uint16_t spp;
    uint8_t *data = NULL;
    int i, j, k, ret = 0;
    TIFF* tif = TIFFOpen(path, "r");
    if (!tif) return -1;
    assert(bpp == 0 || bpp == 4);
    TIFFGetField(tif, TIFFTAG_IMAGEWIDTH, &img->w);
    TIFFGetField(tif, TIFFTAG_IMAGELENGTH, &img->h);
    TIFFGetField(tif, TIFFTAG_SAMPLESPERPIXEL, &spp);
    data = calloc(img->w * img->h, 4);
    img->bpp = spp;
    if (!TIFFReadRGBAImage(tif, img->w, img->h, (uint32_t*)data, 0)) {
        ret = -1;
        goto end;
    }
    img->data = calloc(img->w * img->h, img->bpp);
    for (i = 0; i < img->h; i++)
    for (j = 0; j < img->w; j++)
    for (k = 0; k < img->bpp; k++) {
        img->data[(i * img->w + j) * img->bpp + k] =
            data[(i * img->w + j) * 4 + k];
    }
end:
    free(data);
    TIFFClose(tif);
    return ret;
}

static int img_load_png(img_t *img, const char *path, int bpp)
{
    FILE *file;
    png_structp png_ptr;
    png_infop info_ptr;
    int color_type, bit_depth, i;
    png_bytep *row_pointers = NULL;

    file = fopen(path, "rb");
    if (!file) goto error;
    png_ptr = png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
    info_ptr = png_create_info_struct(png_ptr);
    if (setjmp(png_jmpbuf(png_ptr))) abort();
    png_init_io(png_ptr, file);
    png_read_info(png_ptr, info_ptr);

    img->w = png_get_image_width(png_ptr, info_ptr);
    img->h = png_get_image_height(png_ptr, info_ptr);
    color_type = png_get_color_type(png_ptr, info_ptr);
    bit_depth = png_get_bit_depth(png_ptr, info_ptr);

    if (bit_depth == 16)
        png_set_strip_16(png_ptr);
    if (color_type == PNG_COLOR_TYPE_PALETTE)
        png_set_palette_to_rgb(png_ptr);

    if (bpp == 3 && (color_type & PNG_COLOR_MASK_ALPHA))
        png_set_strip_alpha(png_ptr);

    if ((bpp == 4) && (color_type == PNG_COLOR_TYPE_RGB ||
                       color_type == PNG_COLOR_TYPE_GRAY ||
                       color_type == PNG_COLOR_TYPE_PALETTE))
        png_set_filler(png_ptr, 0xFF, PNG_FILLER_AFTER);

    if ((bpp > 1) && (color_type == PNG_COLOR_TYPE_GRAY ||
                      color_type == PNG_COLOR_TYPE_GRAY_ALPHA))
        png_set_gray_to_rgb(png_ptr);

    if (!bpp) {
        switch (color_type) {
        case PNG_COLOR_TYPE_GRAY: bpp = 1; break;
        case PNG_COLOR_TYPE_RGB: bpp = 3; break;
        case PNG_COLOR_TYPE_RGB_ALPHA: bpp = 4; break;
        default: goto error;
        }
    }

    img->data = malloc((size_t)bpp * img->w * img->h);
    row_pointers = malloc(img->h * sizeof(*row_pointers));
    for (i = 0; i < img->h; i++)
        row_pointers[i] = img->data + (size_t)i * img->w * bpp;
    png_read_image(png_ptr, row_pointers);
    png_read_end(png_ptr, info_ptr);
    png_destroy_read_struct(&png_ptr, &info_ptr, NULL);
    fclose(file);
    img->bpp = bpp;
    free(row_pointers);
    return 0;

error:
    if (file) fclose(file);
    free(row_pointers);
    fprintf(stderr, "Error reading png file %s\n", path);
    return -1;
}

int img_load(img_t *img, const char *path, int bpp)
{
    if (strcmp(strrchr(path, '.') + 1, "webp") == 0)
        return img_load_webp(img, path, bpp);
    if (strcasecmp(strrchr(path, '.') + 1, "tiff") == 0)
        return img_load_tiff(img, path, bpp);
    if (strcasecmp(strrchr(path, '.') + 1, "png") == 0)
        return img_load_png(img, path, bpp);
    // Fallback using stb.
    img->data = stbi_load(path, &img->w, &img->h, &img->bpp, bpp);
    if (!img->data) {
        fprintf(stderr, "Error reading %s: %s\n", path, stbi_failure_reason());
        return -1;
    }
    if (bpp) img->bpp = bpp;
    return 0;
}

static int img_write_jpeg(const img_t *img, const char *path)
{
    FILE *outfile;
    struct jpeg_compress_struct cinfo;
    struct jpeg_error_mgr jerr;
    JSAMPROW row_pointer[1];
    int row_stride;

    cinfo.err = jpeg_std_error(&jerr);
    jpeg_create_compress(&cinfo);

    if ((outfile = fopen(path, "wb")) == NULL) {
        LOG_D("Cannot open %s", path);
        return -1;
    }
    jpeg_stdio_dest(&cinfo, outfile);
    cinfo.image_width = img->w;
    cinfo.image_height = img->h;
    cinfo.input_components = img->bpp;
    cinfo.in_color_space = JCS_RGB;
    jpeg_set_defaults(&cinfo);
    jpeg_start_compress(&cinfo, true);
    row_stride = img->w * img->bpp;
    while (cinfo.next_scanline < cinfo.image_height) {
        row_pointer[0] = &img->data[cinfo.next_scanline * row_stride];
        jpeg_write_scanlines(&cinfo, row_pointer, 1);
    }
    jpeg_finish_compress(&cinfo);
    fclose(outfile);
    jpeg_destroy_compress(&cinfo);
    return 0;
}

static int img_write_png(const img_t *img, const char *path)
{
    int i;
    FILE *fp;
    png_structp png_ptr;
    png_infop info_ptr;

    fp = fopen(path, "wb");
    if (!fp) {
        LOG_D("Cannot open %s", path);
        return -1;
    }
    png_ptr = png_create_write_struct(PNG_LIBPNG_VER_STRING,
                                      NULL, NULL, NULL);
    info_ptr = png_create_info_struct(png_ptr);
    if (setjmp(png_jmpbuf(png_ptr))) {
       png_destroy_write_struct(&png_ptr, &info_ptr);
       fclose(fp);
       return -1;
    }
    png_init_io(png_ptr, fp);
    png_set_IHDR(png_ptr, info_ptr, img->w, img->h, 8,
                 img->bpp == 3 ? PNG_COLOR_TYPE_RGB : PNG_COLOR_TYPE_RGB_ALPHA,
                 PNG_INTERLACE_NONE,
                 PNG_COMPRESSION_TYPE_DEFAULT,
                 PNG_FILTER_TYPE_DEFAULT);

    png_write_info(png_ptr, info_ptr);
    for (i = 0; i < img->h; i++)
        png_write_row(png_ptr, (png_bytep)(img->data + i * img->w * img->bpp));
    png_write_end(png_ptr, info_ptr);
    png_destroy_write_struct(&png_ptr, &info_ptr);
    fclose(fp);
    return 0;
}

static int img_write_webp(const img_t *img, const char *path)
{
    float quality = 75.0f;
    uint8_t *data;
    size_t size;
    FILE *fp;
    int stride = img->w * img->bpp;

    if (img->bpp == 3)
        size = WebPEncodeRGB(img->data, img->w, img->h, stride,
                             quality, &data);
    else
        size = WebPEncodeRGBA(img->data, img->w, img->h, stride,
                              quality, &data);
    if (size == 0) return -1;

    fp = fopen(path, "wb");
    if (!fp) {
        LOG_D("Cannot open %s", path);
        return -1;
    }
    fwrite(data, size, 1, fp);
    fclose(fp);
    free(data);
    return 0;
}

int img_write(const img_t *img, const char *path)
{
    const char *ext = strrchr(path, '.');

    if (strcmp(ext, ".png") == 0) {
        return img_write_png(img, path);
    }
    if ((strcmp(ext, ".jpeg") == 0) || (strcmp(ext, ".jpg") == 0)) {
        return img_write_jpeg(img, path);
    }
    if (strcmp(ext, ".webp") == 0) {
        return img_write_webp(img, path);
    }
    assert(false);
    return -1;
}

#define IMG_AT_CLAMPED(img, x, y) \
    IMG_AT(img, (int)clamp(x, 0, img->w - 1), (int)clamp(y, 0, img->h - 1))

static void img_interpolate(const img_t *img, double pos[2], uint8_t *out)
{
    double x, y, x1, x2, y1, y2;
    int i;
    uint8_t q11[4], q12[4], q21[4], q22[4];
    x = pos[0];
    y = pos[1];
    x1 = floor(x - 0.5) + 0.5;
    y1 = floor(y - 0.5) + 0.5;
    x2 = x1 + 1;
    y2 = y1 + 1;
    assert(x >= x1 && x <= x2);
    assert(y >= y1 && y <= y2);
    memcpy(q11, IMG_AT_CLAMPED(img, x1, y1), img->bpp);
    memcpy(q12, IMG_AT_CLAMPED(img, x1, y2), img->bpp);
    memcpy(q21, IMG_AT_CLAMPED(img, x2, y1), img->bpp);
    memcpy(q22, IMG_AT_CLAMPED(img, x2, y2), img->bpp);
    for (i = 0; i < img->bpp; i++) {
        out[i] = (q11[i] * (x2 - x) * (y2 - y) +
                  q21[i] * (x - x1) * (y2 - y) +
                  q12[i] * (x2 - x) * (y - y1) +
                  q22[i] * (x - x1) * (y - y1)) / ((x2 - x1) * (y2 - y1));
    }
}

void img_map(const img_t *src, img_t *out, const double (*pos)[2])
{
    int i, j;//, x, y;
    double p[2];
    assert(src->bpp == out->bpp);
    IMG_ITER(out, j, i) {
        p[0] = pos[i * out->w + j][0] * src->w;
        p[1] = pos[i * out->w + j][1] * src->h;
        assert(p[0] >= 0 && p[0] <= src->w);
        assert(p[1] >= 0 && p[1] <= src->h);
        img_interpolate(src, p, IMG_AT(out, j, i));
    }
}

void img_cleanup(img_t *img)
{
    free(img->data);
    memset(img, 0, sizeof(*img));
}

void img_downsample(const img_t *img, img_t *out)
{
    // XXX: if the size of out is not exactly half the size of the source
    // image, then the algo doesn't work properly.
    int x, y, k, v, f, d;
    assert(img->data);
    assert(out->data);
    assert(img->bpp == out->bpp);
    f = img->w / out->w;
    d = f / 2;
    IMG_ITER(out, x, y) {
        for (k = 0; k < img->bpp; k++) {
            v = IMG_AT(img, f * x + 0, f * y + 0)[k] +
                IMG_AT(img, f * x + d, f * y + 0)[k] +
                IMG_AT(img, f * x + 0, f * y + d)[k] +
                IMG_AT(img, f * x + d, f * y + d)[k];
            IMG_AT(out, x, y)[k] = v / 4;
        }
    }
}

void img_blit(const img_t *img, img_t *out, int x, int y)
{
    int img_x, img_y;
    assert(img->bpp == out->bpp);
    IMG_ITER(img, img_x, img_y) {
        memcpy(IMG_AT(out, img_x + x, img_y + y),
               IMG_AT(img, img_x, img_y),
               img->bpp);
    }
}

bool img_is_empty(const img_t *img)
{
    int x, y;
    if (!img->data) return true;
    if (img->bpp != 4) return false;
    IMG_ITER(img, x, y) {
        if (IMG_AT(img, x, y)[3]) return false;
    }
    return true;
}

void img_bump_to_normal(const img_t *img, img_t *out)
{
    img_t tmp;
    int x, y;
    double n[3], norm;

    img_init(&tmp, img->w, img->h, 3);

    // XXX: very stupid algo for the moment!
    IMG_ITER(img, x, y) {
        // XXX: This would be correct for a donught, not for a sphere!
        n[0] = IMG_AT(img, x, y)[0] - IMG_AT(img, (x + 1) % img->w, y)[0];
        n[1] = IMG_AT(img, x, y)[0] - IMG_AT(img, x, (y + 1) % img->h)[0];
        // XXX: should be an argument!
        n[2] = 16.0;
        norm = sqrt(n[0] * n[0] + n[1] * n[1] + n[2] * n[2]);
        n[0] /= norm;
        n[1] /= norm;
        n[2] /= norm;
        IMG_AT(&tmp, x, y)[0] = (n[0] + 1.0) * 127;
        IMG_AT(&tmp, x, y)[1] = (n[1] + 1.0) * 127;
        IMG_AT(&tmp, x, y)[2] = (n[2] + 1.0) * 127;
    }

    img_cleanup(out);
    *out = tmp;
}
