

libjuliabdb.so: julia_bdb.c
	gcc -fPIC -shared -ldb $< -o $@
