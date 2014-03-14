#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

#include <stdio.h>
#include <string.h>

#include <archive.h>
#include <archive_entry.h>

// TODO: think about prefix for iOS apple store (as in ios-libarchive, tk_)

void aclose(struct archive *a) {
    archive_read_close(a);
    archive_read_free(a);
}

int process(lua_State *L, const char *name, const char* filter_name, int list_only) {
    struct archive *a = archive_read_new();
    archive_read_support_filter_all(a);
    archive_read_support_format_all(a);
    if ( (archive_read_open_filename(a, name, 10240)) ) {
        lua_pushnil(L);
        lua_pushfstring(L, "Error: can't read archive %s: %s\n", name, archive_error_string(a));
        return 2;
    }

    lua_newtable(L);
    int top = lua_gettop(L);
    struct archive_entry *entry;
    int r;
    int total = 0;
    for (;;) {
        r = archive_read_next_header(a, &entry);
        if (r == ARCHIVE_EOF)
            break;

        if (r != ARCHIVE_OK) {
            lua_pushnil(L);
            lua_pushfstring(L, "%s\n", archive_error_string(a));
            aclose(a);
            return 2;
        }

        if (r < ARCHIVE_WARN) {
            lua_pushnil(L);
            lua_pushfstring(L, "%s\n", "Warning from archive");
            aclose(a);
            return 2;
        }

        // skip dirs
        if (!S_ISREG(archive_entry_mode(entry)))
            continue;

        const char *name = archive_entry_pathname(entry);
        if(list_only) {
            lua_pushstring(L, name);
            lua_rawseti(L, top, ++total);
            archive_read_data_skip(a); // automatically called anyway
            continue;
        }

        if ( filter_name
                && ! ( strlen(filter_name)==strlen(name) && strncmp(filter_name, name, strlen(name))==0 ) )
        {
            archive_read_data_skip(a); // automatically called anyway
            continue;
        }

        size_t entry_size = archive_entry_size(entry);
        if (entry_size > 0) {
            char buff[entry_size];
            ssize_t size = archive_read_data(a, buff, entry_size);
            if(size <= 0) {
                //TODO: send a warning or a black image
                //lua_pushfstring(L, "Corrupted data: %s\n", name);
                //lua_error(L);
            }
            lua_pushlstring(L, buff, entry_size);
            if(filter_name)
                lua_rawseti(L, top, 1);
            else
                lua_setfield(L, top, name);
        }
        if(filter_name)break;
    }
    aclose(a);
    return 1;
}

int list(lua_State *L) {
    const char *arch = luaL_checkstring(L, 1);
    lua_remove(L, 1);
    return process(L, arch, NULL, 1);
}

int filter(lua_State *L) {
    const char *arch = luaL_checkstring(L, 1);
    lua_remove(L, 1);
    const char *f = luaL_checkstring(L, 1);
    lua_remove(L, 1);
    return process(L, arch, f, 0);
}

int all(lua_State *L) {
    const char *arch = luaL_checkstring(L, 1);
    lua_remove(L, 1);
    return process(L, arch, NULL, 0);
}

int luaopen_decomp(lua_State *L) {
    static luaL_reg funcs[] = {
        { "list"    ,  list },
        { "filter"  , filter },
        { "all"     , all },
        { NULL, NULL }
    };

    luaL_register(L,"decomp", funcs);

    return 1;
}
