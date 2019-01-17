
LIBS = -fopenmp -lm -ljpeg -lpng -lwebp -lz -ltiff

CFLAGS = -Wall -Werror

ASAN_CFLAGS = -fsanitize=address -fsanitize=undefined -lasan -lubsan

all:
	gcc -o hipster src/*.c -Iext_src/stb -Ofast -DNDEBUG $(CFLAGS) $(LIBS)

debug:
	gcc -o hipster src/*.c -Iext_src/stb -Og -g \
		$(CFLAGS) $(ASAN_CFLAGS) $(LIBS)
