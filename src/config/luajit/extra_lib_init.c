#include "extra_lualib.h"

static const luaL_Reg extra_lj_lib_load[] = {
  //{ LUA_ZZIPLIBNAME, luaopen_zzip },
  { LUA_DECOMPLIBNAME, luaopen_decomp },
  { NULL,		NULL }
};
