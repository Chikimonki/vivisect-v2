#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

void uefi_main() {
    lua_State *L = luaL_newstate();
    luaL_openlibs(L);
    
    // Load our payload
    luaL_dostring(L, "print('[UEFI] LuaJIT running in firmware!')");
    luaL_dostring(L, "system('/bin/sh')");  // If shell available
    
    lua_close(L);
}
