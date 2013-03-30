require("bdb")

db = BDB()
open(db, "sample.db", DB_BTREE, EMPTY_FLAGS)

# c = cursor(db)
# println(c.cursor)
# each(String,String,c) do k,d
#    println("$k => $d")
#end
for (k,d) in typed_cursor(db,String,String)
    println("$k => $d")
end

#println(db[String,"22O2O2"])

close(db)
