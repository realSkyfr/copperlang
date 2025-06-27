#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
#include <stdio.h>


int main(int argc, char *argv[]) {
    // Check if the correct number of arguments is provided
    if (argc < 4 || argc > 5) {
        fprintf(stderr, "Usage: %s <file.cpr> -o <file.cim>\n", argv[0]);
        return 1;
    }

    lua_State *L = luaL_newstate();
    luaL_openlibs(L);

    if (luaL_dofile(L, "compiler-lua/main.lua") != LUA_OK) {
        fprintf(stderr, "Failed to load Lua file: %s\n", lua_tostring(L, -1));
        lua_close(L);
        return 1;
    }

    lua_getglobal(L, "Compile");
    lua_pushstring(L, argv[1]); // Push the input file name
    lua_pushstring(L, argv[3]); // Push the output file name

    if (lua_pcall(L, 2, 1, 0) != LUA_OK) {
        fprintf(stderr, "Lua error: %s\n", lua_tostring(L, -1));
        lua_pop(L, 1);
    } else {
        const char *result = lua_tostring(L, -1);
        printf("%s\n", result);
        lua_pop(L, 1);
    }

    lua_close(L);
    return 0;
}