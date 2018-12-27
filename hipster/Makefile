
LIBS = -fopenmp -lm -ljpeg -lpng -lwebp -lz -ltiff

CFLAGS = -Wall -Werror

all:
	gcc -o hipster src/*.c -Iext_src/stb -Ofast -DNDEBUG $(CFLAGS) $(LIBS)

debug:
	gcc -o hipster src/*.c -Iext_src/stb -Og -g $(CFLAGS) $(LIBS)
