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
#include <argp.h>
#include <sys/stat.h>
#include <regex.h>

enum {
    FORMAT_PNG  = 1 << 0,
    FORMAT_JPEG = 1 << 1,
    FORMAT_WEBP = 1 << 2,
    FORMAT_END  = 1 << 3,
};

enum {
    FRAME_NONE,
    FRAME_EQUATORIAL,
    FRAME_GALACTIC,
    FRAME_ECLIPTIC,
};

typedef struct
{
    char *inputs[2];
    char *output;
    int format;
    bool pngquant;
    double theta;  // Theta value of center of the image (rad)
    double phi;    // Phi value of center of the image (rad)

    bool bump_to_normal;
    const char *props[16];  // Added to the properties file.
    int   props_nb;
    int   frame;
} args_t;

// Clever trick to check if int has only one bit set.
static bool has_only_one_bit(int x)
{
    return x == (x & -x);
}

// Normalize angle into the range 0 <= a < 2pi.
static double anp(double a)
{
   a = fmod(a, 2 * M_PI);
   if (a < 0) a += 2 * M_PI;
   return a;
}

static const char *get_format_ext(int format)
{
    assert(has_only_one_bit(format));
    switch (format) {
    case FORMAT_PNG: return "png";
    case FORMAT_JPEG: return "jpg";
    case FORMAT_WEBP: return "webp";
    default: return NULL;
    }
}

static void get_tile_path(int lev, int pix, const char *base,
                          int format, char *out)
{
    int dir = (pix / 10000) * 10000;
    mkdir(base, 0777);
    sprintf(out, "%s/Norder%d", base, lev);
    mkdir(out, 0777);
    sprintf(out, "%s/Norder%d/Dir%d", base, lev, dir);
    mkdir(out, 0777);
    sprintf(out, "%s/Norder%d/Dir%d/Npix%d.%s", base, lev, dir, pix,
                 get_format_ext(format));
}

static bool file_exists(const char *path)
{
    FILE *file;
    file = fopen(path, "r");
    if (file)
        fclose(file);
    return (bool)file;
}

static void create_tile(int lev, int pix, const img_t *src,
                        int size, double delta_theta, double delta_phi,
                        bool flip_phi, const char *base_dir, int format)
{
    char path[PATH_MAX];
    int x, y, xx, yy, ix, iy, face, f;
    int nside = 1 << lev;
    double theta, phi;
    double (*mapping)[2]; // function x,y -> theta, phi for image pos.
    img_t out;
    bool empty;

    healpix_nest2xyf(nside, pix, &ix, &iy, &face);
    mapping = calloc(size * size, sizeof(*mapping));

    for (y = 0; y < size; y++) {
        for (x = 0; x < size; x++) {
            healpix_xyf2ang(nside * size, ix * size + x, iy * size + y, face,
                            &theta, &phi);
            theta += delta_theta;
            phi += delta_phi;
            if (flip_phi) phi = 2 * M_PI - phi;
            theta = anp(theta);
            phi = anp(phi);
            // transform coordinates the way it works in HiPS.
            xx = y;
            yy = x;

            assert(phi >= 0 && phi <= 2 * M_PI);
            assert(theta >= 0 && theta <= M_PI);
            mapping[yy * size + xx][0] = phi / (2 * M_PI);
            mapping[yy * size + xx][1] = theta / M_PI;
        }
    }

    img_init(&out, size, size, src->bpp);
    img_map(src, &out, mapping);
    empty = img_is_empty(&out);
    if (!empty) {
        for (f = 1; f < FORMAT_END; f <<= 1) {
            if (!(f & format)) continue;
            get_tile_path(lev, pix, base_dir, f, path);
            img_write(&out, path);
        }
    }
    free(mapping);
    img_cleanup(&out);
}


static void create_tile_from_parents(int lev, int pix, int size,
                                     const char *base_dir, int format)
{
    char path[PATH_MAX];
    int dx, dy, ppix, f;
    img_t src = {}, tmp = {}, out = {};
    bool first_iter = true;
    bool empty;

    // If we have multiple format call the function once per format.
    if (!has_only_one_bit(format)) {
        for (f = 1; f < FORMAT_END; f <<= 1) {
            if (!(f & format)) continue;
            create_tile_from_parents(lev, pix, size, base_dir, f);
        }
        return;
    }

    get_tile_path(lev, pix, base_dir, format, path);
    for (dy = 0; dy < 2; dy++)
    for (dx = 0; dx < 2; dx++) {
        ppix = pix * 4 + dx * 2 + dy;
        get_tile_path(lev + 1, ppix, base_dir, format, path);
        if (img_load(&src, path, 0) != 0) continue;

        if (first_iter) {
            // We cannot init outside the loop because we don't know the
            // bpp yet. XXX: change that.
            img_init(&out, size, size, src.bpp);
            img_init(&tmp, size / 2, size / 2, src.bpp);
            first_iter = false;
        }
        img_downsample(&src, &tmp);
        img_blit(&tmp, &out, dx * size / 2, dy * size / 2);
        img_cleanup(&src);
    }
    empty = img_is_empty(&out);
    get_tile_path(lev, pix, base_dir, format, path);
    if (!empty) img_write(&out, path);
    img_cleanup(&tmp);
    img_cleanup(&out);
}

static void create_allsky(int lev, int size, const char *base_dir,
                          int format)
{
    char path[PATH_MAX];
    char out_path[PATH_MAX];
    int pix, nb, nbw, nbh, bpp = 0, f;
    img_t src = {}, tmp = {}, out = {};

    // If we have multiple format call the function once per format.
    if (!has_only_one_bit(format)) {
        for (f = 1; f < FORMAT_END; f <<= 1) {
            if (!(f & format)) continue;
            create_allsky(lev, size, base_dir, f);
        }
        return;
    }

    sprintf(out_path, "%s/Norder%d/Allsky.%s",
            base_dir, lev, get_format_ext(format));

    nb = 12 * 1 << (2 * lev);
    nbw = (int)sqrt(nb);
    nbh = (int)ceil((double)nb / nbw);
    LOG_D("Create allsky %s %d %d", out_path, nbw, nbh);

    // Get the bpp from the first img we find.
    // XXX: we probably should pass it as an argument instead!
    for (pix = 0; pix < 12 * (1 << (2 * lev)); pix++) {
        get_tile_path(lev, pix, base_dir, format, path);
        if (img_load(&src, path, 0) == 0) {
            bpp = src.bpp;
            img_cleanup(&src);
            break;
        }
    }
    if (bpp == 0) {
        LOG_D("ERROR");
        return;
    }
    img_init(&out, size * nbw, size * nbh, bpp);
    img_init(&tmp, size, size, bpp);

    for (pix = 0; pix < 12 * (1 << (2 * lev)); pix++) {
        get_tile_path(lev, pix, base_dir, format, path);
        if (img_load(&src, path, 0) != 0) continue;
        assert(src.bpp == bpp);
        img_downsample(&src, &tmp);
        img_blit(&tmp, &out, size * (pix % nbw), size * (pix / nbw));
        img_cleanup(&src);
    }
    img_write(&out, out_path);
    img_cleanup(&out);
    img_cleanup(&tmp);
}


static void create_properties_file(const char *base_dir,
                                   int lev, int lev_min,
                                   int size, int format, int frame,
                                   const char **props, int props_nb)
{
    FILE *file;
    char *path, format_str[128] = "", frame_str[128] = "";
    int r, i;
    regex_t reg;
    regmatch_t ms[3];

    r = asprintf(&path, "%s/properties", base_dir);
    (void)r;
    file = fopen(path, "w");

    if (format & FORMAT_WEBP) strcat(format_str, "webp ");
    if (format & FORMAT_JPEG) strcat(format_str, "jpeg ");
    if (format & FORMAT_PNG) strcat(format_str, "png ");
    format_str[strlen(format_str) - 1] = '\0'; // Remove last ' '.

    switch (frame) {
    case FRAME_EQUATORIAL: strcat(frame_str, "equatorial"); break;
    case FRAME_GALACTIC: strcat(frame_str, "galactic"); break;
    case FRAME_ECLIPTIC: strcat(frame_str, "ecliptic"); break;
    default: break;
    }

#define P(name, f, v) fprintf(file, "%-21s = " f "\n", name, v)
    P("hips_order", "%d", lev);
    P("hips_order_min", "%d", lev_min);
    if (size) P("hips_tile_width", "%d", size);
    P("hips_tile_format", "%s", format_str);
    P("dataproduct_type", "%s", "image");
    if (frame) P("hips_frame", "%s", frame_str);
#undef P

    // Add the custom properties.
    regcomp(&reg, "^ *([^ ]+) *= *(.*) *$", REG_EXTENDED);
    for (i = 0; i < props_nb; i++) {
        r = regexec(&reg, props[i], 3, ms, 0);
        assert(!r);
        fprintf(file, "%-21.*s = %.*s\n",
                ms[1].rm_eo - ms[1].rm_so, props[i] + ms[1].rm_so,
                ms[2].rm_eo - ms[2].rm_so, props[i] + ms[2].rm_so);
    }

    fclose(file);
    free(path);
}


// Run a bash command.
static void run_cmd(const char *cmd, ...)
{
    va_list args;
    char *buff;
    int r;
    va_start(args, cmd);
    r = vasprintf(&buff, cmd, args);
    (void)r;
    va_end(args);
    LOG_D("run: %s", buff);
    r = system(buff);
    (void)r;
    free(buff);
}

static void post_process(int lev, int pix, args_t *args)
{
    char path[PATH_MAX];
    get_tile_path(lev, pix, args->output, args->format, path);
    if (!file_exists(path)) return;
    if (args->format == FORMAT_PNG && args->pngquant) {
        run_cmd("pngquant --ext .png -f %s", path);
    }
}

// Keys for options without short-option
#define OPT_PNGQUANT 1
#define OPT_THETA 2
#define OPT_PHI 3
#define OPT_BUMP_TO_NORMAL 4
#define OPT_FRAME 5

const char *argp_program_version = "hipster 0.1";
static char doc[] = "Create hips surveys from images";
static char args_doc[] = "INPUTS";
static struct argp_option options[] = {
    {"output",   'o', "DIR", 0, "Output to DIR" },
    {"format",   'f', "FORMAT", 0, "png|jpeg|webp" },
    {"frame",    OPT_FRAME, "FRAME", 0, "equatorial|galactic|ecliptic" },
    {"pngquant", OPT_PNGQUANT, NULL, 0,
                 "use pngquant to compress the images" },
    {"propertie", 'p', "LINE", 0, "Add a propertie to the survey"},
    {"theta", OPT_THETA, "DEG", 0, "Theta angle of center of src image"},
    {"phi", OPT_PHI, "DEG", 0, "Phi angle of center of src image"},
    {"bump-to-normal", OPT_BUMP_TO_NORMAL, NULL, 0,
                 "Convert bump texture to normal map"},
    { 0 }
};

/* Parse a single option. */
static error_t parse_opt(int key, char *arg, struct argp_state *state)
{
    args_t *args = state->input;

    switch (key)
    {
    case 'o':
        args->output = arg;
        break;
    case 'f':
        if (strstr(arg, "png")) args->format |= FORMAT_PNG;
        if (strstr(arg, "jpeg")) args->format |= FORMAT_JPEG;
        if (strstr(arg, "webp")) args->format |= FORMAT_WEBP;
        if (!args->format)
            argp_error(state, "Unknown format: '%s'", arg);
        break;
    case OPT_FRAME:
        if (strstr(arg, "equatorial")) args->frame = FRAME_EQUATORIAL;
        if (strstr(arg, "galactic")) args->frame = FRAME_GALACTIC;
        if (strstr(arg, "ecliptic")) args->frame = FRAME_ECLIPTIC;
        if (!args->frame)
            argp_error(state, "Unknown frame: '%s'", arg);
        break;
    case 'p':
        args->props[args->props_nb++] = arg;
        break;
    case OPT_PNGQUANT:
        args->pngquant = true;
        break;
    case OPT_THETA:
        args->theta = atoi(arg) * DD2R;
        break;
    case OPT_PHI:
        args->phi = atoi(arg) * DD2R;
        break;
    case OPT_BUMP_TO_NORMAL:
        args->bump_to_normal = true;
        break;
    case ARGP_KEY_ARG:
        if (state->arg_num >= 2)
            argp_error(state, "Too many inputs");
        args->inputs[state->arg_num] = arg;
        break;

    case ARGP_KEY_END:
        if (state->arg_num < 1) argp_error(state, "Input missing");
        if (!args->output) argp_error(state, "Output missing");
        break;

    default:
        return ARGP_ERR_UNKNOWN;
    }
    return 0;
}


/* Our argp parser. */
static struct argp argp = { options, parse_opt, args_doc, doc };


static int create_image_survey(args_t args)
{
    int tile_size = 512;
    int lev, pix, l, lev_min;
    bool flip_phi;
    img_t src = {};

    LOG_D("load %s", args.inputs[0]);
    if (img_load(&src, args.inputs[0], (args.format & FORMAT_JPEG) ? 3 : 0)) {
        fprintf(stderr, "Cannot read source\n");
        return -1;
    }
    LOG_D("image size: %dx%d bpp:%d", src.w, src.h, src.bpp);
    if (args.bump_to_normal) img_bump_to_normal(&src, &src);

    // Compute the max order.
    lev = ceil(log2(src.w / (4.0 * sqrt(2.0) * tile_size)));
    lev = max(lev, 0);
    lev_min = min(lev, 0);
    flip_phi = args.frame != FRAME_NONE;
    LOG_D("creating tiles from level %d to %d", lev_min, lev);

    LOG_D("creating all tiles at level %d", lev);
    #pragma omp parallel for private(pix)
    for (pix = 0; pix < 12 * (1 << (2 * lev)); pix++) {
        create_tile(lev, pix, &src, tile_size, args.theta, args.phi,
                    flip_phi, args.output, args.format);
        printf("\r%d/%d    ", pix, 12 * (1 << (2 * lev)));
        fflush(stdout);
    }
    img_cleanup(&src);
    printf("\n");

    // Merge the tiles to generate the lower levels.
    for (l = lev - 1; l >= lev_min; l--) {
        LOG_D("create tiles at level %d", l);
        #pragma omp parallel for private(pix)
        for (pix = 0; pix < 12 * (1 << (2 * l)); pix++) {
            create_tile_from_parents(l, pix, tile_size, args.output,
                                     args.format);
            printf("\r%d/%d    ", pix, 12 * (1 << (2 * l)));
            fflush(stdout);
        }
        printf("\n");
    }

    // Generate the allsky for min level
    create_allsky(lev_min, 64, args.output, args.format);

    // Post process
    for (l = lev_min; l <= lev; l++) {
        #pragma omp parallel for private(pix)
        for (pix = 0; pix < 12 * (1 << (2 * l)); pix++) {
            post_process(l, pix, &args);
        }
    }

    // Add the properties file.
    create_properties_file(args.output, lev, lev_min, tile_size, args.format,
                           args.frame, args.props, args.props_nb);
    return 0;
}

int stars_generate_survey(const char *bsc_path, const char *hip_path,
                          const char *out, int *lev);

int main(int argc, char **argv)
{
    args_t args = {0};

    argp_parse(&argp, argc, argv, 0, 0, &args);
    if (!args.format) {
        args.format = FORMAT_JPEG;
        if (strcmp(strrchr(args.inputs[0], '.') + 1, "png") == 0)
            args.format = FORMAT_PNG;
        if (strcmp(strrchr(args.inputs[0], '.') + 1, "webp") == 0)
            args.format = FORMAT_WEBP;
    }
    return create_image_survey(args);
}
