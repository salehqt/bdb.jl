

libjuliabdb.so: julia_bdb.c
	gcc -fPIC -shared -ldb -I/usr/local/BerkeleyDB.5.3/include -L/usr/local/BerkeleyDB.5.3/lib $< -o $@

libjuliabdb.dylib: julia_bdb.c
	gcc -fPIC -shared -ldb -I/usr/local/BerkeleyDB.5.3/include -L/usr/local/BerkeleyDB.5.3/lib $< -o $@
