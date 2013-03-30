require("db")

db = BDB()
open(db, "sample.db", DB_BTREE, EMPTY_FLAGS)

c = cursor(db)

println(c.cursor)

each(String,String,c) do k,d
    println("$k => $d")
end

close(db)
