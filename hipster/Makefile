
CFLAGS = -Ofast -DNDEBUG -Wall -Werror -fopenmp \
		 -lm -ljpeg -lpng -lwebp -lz -ltiff

all:
	gcc -o hipster src/*.c -Iext_src/stb $(CFLAGS)
