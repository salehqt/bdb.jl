from bsddb3.db import *

def iter_cursor(c, mode = DB_NEXT):
    while True:
        n = c.get(mode)
        if n != None :
            yield n
        else:
            c.close()
            raise StopIteration

db = DB()

db.open("sample.db", flags=DB_RDONLY)

for k,l in iter_cursor(db.cursor()):
   print "'%s':%d -> '%s':%d" % (k, len(k), l, len(l))

db.close()

