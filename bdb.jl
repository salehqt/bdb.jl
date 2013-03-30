import Base.ensureroom
typealias PV Ptr{Void}

const shlib = "./libjuliabdb"

type BDB 
  db::PV
  open::PV
  close::PV
  cursor::PV
  get::PV
  put::PV
  associate::PV
  set_bt_compare::PV
  set_dup_compare::PV
  dbc_get::PV

  function BDB()
      a = new()
      r = ccall(("bdb_create",shlib), Int, (Ptr{BDB},PV,Int32), &a, C_NULL, 0)
      if r != 0
          error("Error occured while creating a new database handle")
      end
      a
   end
end

const DB_DBT_USERMEM = int32(0x100) #/* Return in user's memory. */
const DB_BUFFER_SMALL =	int32(-30999)#/* User memory too small for return. */

const DB_NOTFOUND = (-30988) #/* Key/data pair not found (EOF). */
type DBT
    data::Ptr{Uint8}
    size::Uint32
    ulen::Uint32
    dlen::Uint32
    doff::Uint32
    app_data::PV
    flags::Uint32
    function DBT(x::Vector{Uint8})
        new(convert(Ptr{Uint8},x),length(x),length(x),uint32(0),uint32(0),C_NULL,uint32(DB_DBT_USERMEM))
    end
end

type DBC
  cursor::PV
  get::PV

  function DBC(db::BDB)
      a = new()
      r = ccall(("bdb_cursor",shlib), Int32, (PV,Ptr{DBC},Uint32), db.db, &a, EMPTY_FLAGS)
      if r != 0
          error("Error occured while creating a cursor")
      end
      a
   end
end

DBT(io::IOBuffer) = ( d = DBT(io.data); d.size = io.size; d )
function accomodate(d::DBT,io::IOBuffer)
    newsize = convert(Int,d.size)
    io2 = ensureroom(io, newsize)
    io.size = newsize
    (DBT(io2),io2)
end

function boxBuffer(x)
    io = IOBuffer()
    write(io, x)
    io
end

function read(io,::Type{String})
    string(bytestring(io))
end

function unboxBuffer{T}(io::IOBuffer,::Type{T})
    read(io, T)
end


function check_err(r::Int32,e::String) 
    if r != 0
        error("Error number $r: $er")
    end
end

type DBNotFoundException <: Exception 
    key::IOBuffer
    data::IOBuffer
end

const DB_BTREE = int32(1)
const DB_HASH  = int32(2)
const DB_HEAP  = int32(6)
const DB_UNKNOWN = int32(5)
const DB_RECNO = int32(3)
const DB_QUEUE = int32(4)

const DB_CREATE  = int32(1)

function open(d::BDB, filename::String, dbtype::Int32, flags::Uint32)
    r = ccall(d.open, Int32, (PV,PV,Ptr{Uint8},Ptr{Uint8},Int32,Int32,Int)
          ,d.db,C_NULL,bytestring(filename),C_NULL,dbtype,flags,0)
    check_err(r,"Error opening file")
end

function close(d::BDB)
    r = ccall(d.close, Int32, (PV,Int32), d.db, 0)
    check_err(r,"Error closing database")
end

function cursor(d::BDB)
    DBC(d)
end

const EMPTY_FLAGS = uint32(0)



function put(d::BDB,key::IOBuffer,data::IOBuffer,flags::Uint32)
    kdbt = DBT(key)
    ddbt = DBT(data)
    r = ccall(d.put, Int32, (PV,PV,Ptr{DBT},Ptr{DBT},Uint32),d.db, C_NULL, &kdbt, &ddbt, flags)
    check_err(r,"Error putting $key $data")
    (key,data)
end

function internal_get(db::BDB,kdbt::DBT,ddbt::DBT,flags::Uint32)
    ccall(db.get, Int32, (PV,PV,Ptr{DBT},Ptr{DBT},Uint32),db.db, C_NULL, &kdbt, &ddbt, flags)
end

function get(db::BDB,key::IOBuffer,data::IOBuffer,flags::Uint32)
    k = DBT(key)
    d = DBT(data)
    r = internal_get(db,k,d,flags)
    if r == DB_BUFFER_SMALL
        (k,key) = accomodate(k,key)
        (d,data) = accomodate(d,data)
        r = internal_get(db,k,d,flags)
    elseif r == DB_NOTFOUND
        error("Not Found Exception")
    end
    check_err(r,"Error getting $key $data")
    (key,data)
end


const	DB_FIRST		 =uint32(7)	# Dbc.get, DbLogc->get */
const	DB_GET_BOTH		 =uint32(8)	# Db.get, Dbc.get */
const	DB_GET_BOTHC	=	 uint32(9)	# Dbc.get (internal) */
const	DB_GET_BOTH_RANGE=	uint32(10)	# Db.get, Dbc.get */
const	DB_GET_RECNO	=	uint32(11)	# Dbc.get */
const	DB_JOIN_ITEM	=	uint32(12)	# Dbc.get; don't do primary lookup */
const	DB_KEYFIRST	=	uint32(13)	# Dbc.put */
const	DB_KEYLAST	=	uint32(14)	# Dbc.put */
const	DB_LAST		=	uint32(15)	# Dbc.get, DbLogc->get */
const	DB_NEXT		=	uint32(16)	# Dbc.get, DbLogc->get */
const	DB_NEXT_DUP	=	uint32(17)	# Dbc.get */
const	DB_NEXT_NODUP=		uint32(18)	# Dbc.get */
const	DB_NODUPDATA=		uint32(19)	# Db.put, Dbc.put */
const	DB_NOOVERWRITE=		uint32(20)	# Db.put */
const	DB_NOSYNC	=	uint32(21)	# Db.close */
const	DB_POSITION	=	uint32(22)	# Dbc.dup */
const	DB_PREV		=	uint32(23)	# Dbc.get, DbLogc->get */
const	DB_PREV_DUP	=	uint32(24)	# Dbc.get */
const	DB_PREV_NODUP=uint32(	25)	# Dbc.get */
const	DB_SET		= uint32(  26 )  # Dbc.get, DbLogc->get */
const	DB_SET_RANGE= uint32(  	27)	# Dbc.get */
const	DB_SET_RECNO= uint32(  	28)	# Db.get, Dbc.get */

function internal_get(c::DBC,kdbt::DBT,ddbt::DBT,flags::Uint32)
    ccall(c.get, Int32, (PV,Ptr{DBT},Ptr{DBT},Uint32),c.cursor, &kdbt, &ddbt, flags)
end

function get(c::DBC,key::IOBuffer,data::IOBuffer,flags::Uint32)
    k = DBT(key)
    d = DBT(data)
    r = internal_get(c,k,d,flags)
    if r == DB_BUFFER_SMALL
        (k,key) = accomodate(k,key)
        (d,data) = accomodate(d,data)
        r = internal_get(c,k,d,flags)
    elseif r == DB_NOTFOUND
        #throw(DBNotFoundException(key,data))
        return ()
    end
    check_err(r,"Error getting $key $data")
    (key,data)
end

function ref{D}(db::BDB,::Type{D},key)
    k,d = get(db,boxBuffer(key),IOBuffer(),EMPTY_FLAGS)
    unboxBuffer(d,D)
end

function assign(d::BDB,data,key)
    put(d,boxBuffer(key),boxBuffer(data),EMPTY_FLAGS)
    ()
end

function each(f,K::Type,D::Type, c::DBC)
	while true
        retval = get(c,IOBuffer(),IOBuffer(),DB_NEXT)
        if isa(retval,())
            break
        else
            (k,d)  = retval
            key = unboxBuffer(k,K)
            data = unboxBuffer(d,D)
            f(key,data)
        end
	end
end
