#include <db.h>
#include <string.h>

struct BDB {
  DB* db;
  void* open;
  void* close;
  void* cursor;
  void* get;
  void* put;
  void* associate;
  void* set_bt_compare;
  void* set_dup_compare;
};

struct BDBC {
  DBC* cursor;
  void* get;
  void* close;
};

int bdb_create(struct BDB* bdb,DB_ENV* dbenv, u_int32_t flags){
  int r; DB* d;
  r = db_create(&d, dbenv, flags);
  if(r == 0){
    bdb->db    = d;
    bdb->open  = d->open;
    bdb->close = d->close;
    bdb->cursor= d->cursor;
    bdb->get   = d->get;
    bdb->put   = d->put;
    bdb->associate = d->associate;
    bdb->set_bt_compare = d->set_bt_compare;
    bdb->set_dup_compare = d->set_dup_compare;

  }
  return r;
}

int bdb_cursor(DB* db,struct BDBC* dbc, uint32_t flags){
    int r;
    r = db->cursor(db, NULL, &dbc->cursor, flags);
    if( r == 0){
        dbc->get = dbc->cursor->get;
		dbc->close = dbc->cursor->close;
    }
    return r;
}
 
