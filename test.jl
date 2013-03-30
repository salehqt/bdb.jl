
require("db")
db = BDB()


open(db, "sample.db", DB_BTREE, DB_CREATE)

k = boxBuffer("22O2O2")
d = boxBuffer("12345")
put(db, k, d, EMPTY_FLAGS)

#println(db[ASCIIString,"220202"])
#db[2] = "4"

assign(db, "OEOEO", 45)


#kk = boxBuffer("22O2O2")
#println(get(db,kk,IOBuffer(),EMPTY_FLAGS))
println(ref(db,String,"22O2O2"))

close(db)
