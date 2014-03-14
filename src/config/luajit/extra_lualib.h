#ifndef _EXTRA_LUALIB_H
#define _EXTRA_LUALIB_H

#include "lua.h"

//#define LUA_ZZIPLIBNAME	"zzip"
//LUALIB_API int luaopen_zzip(lua_State *L);

#define LUA_DECOMPLIBNAME	"decomp"
LUALIB_API int luaopen_decomp(lua_State *L);

#endif
