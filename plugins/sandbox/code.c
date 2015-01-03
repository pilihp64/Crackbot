#include <lua5.1/lua.h>
#include <lua5.1/lualib.h>
#include <lua5.1/lauxlib.h>
#ifdef WIN32
#include <windows.h>
#endif
#include <pthread.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#define MEMLIMIT 5000000 //20MB

static int memused = 0;

void *alloc(void *ud, void *ptr, size_t osize, size_t nsize)
{
	if(nsize)
	{
		if(memused + nsize - osize> MEMLIMIT)
			return NULL;
		memused += nsize - osize;
		return realloc(ptr, nsize);
	}
	else
	{
		memused -= osize;
		free(ptr);
		return NULL;
	}
}

static int panic(lua_State *l)
{
  (void)l;
  printf("PANIC: unprotected error in call to Lua API (%s)\n", lua_tostring(l, -1));
  return 0;
}

int luaL_tostring (lua_State *L, int n)
{
	luaL_checkany(L, n);
	switch (lua_type(L, n)) {
		case LUA_TNUMBER:
			lua_pushstring(L, lua_tostring(L, n));
			break;
		case LUA_TSTRING:
			lua_pushvalue(L, n);
			break;
		case LUA_TBOOLEAN:
			lua_pushstring(L, (lua_toboolean(L, n) ? "true" : "false"));
			break;
		case LUA_TNIL:
			lua_pushliteral(L, "nil");
			break;
		default:
			lua_pushfstring(L, "%s: %p", lua_typename(L, lua_type(L, n)), lua_topointer(L, n));
			break;
	}
	return 1;
}

static lua_State *l;

void *thread(void *n)
{
	int p = lua_gettop(l);
	if(lua_pcall(l, 0, LUA_MULTRET, 0))
	{
		luaL_tostring(l, -1);
		printf("runtime error: %s\n", lua_tostring(l, -1));
		lua_pop(l, 1);
	}
	else
	{
		int c = lua_gettop(l);
		for(;c >= p;p++)
		{
			luaL_tostring(l, p);
			printf("%s\n", lua_tostring(l, -1));
			lua_pop(l, 1);
		}
	}
	exit(0);
}

int main(int argc, char *argv[])
{
	if(argc<2)
		return 0;
	l = lua_newstate(&alloc, NULL);
	lua_atpanic(l, &panic);
	luaL_openlibs(l);
	luaL_dostring(l,"math.randomseed(os.time())\n\
			 dofile('derp.lua')\n\
			 dofile('tableSave.lua')\n\
			 cashList = table.load('plugins/gameUsers.txt')\n\
			 table.load, table.save = nil\n\
			 debug,loadfile,module,require,dofile,package,os.remove,os.tmpname,os.rename,os.execute,os.getenv,string.dump=nil\n\
			 io={write=io.write}\n\
		");
	const char *h = argv[1];
	char *code = (char*)malloc(strlen(h)/2+1);
	char *c = code;
	for(;*h && h[1];h+=2)
	{
		*(c++) = (*h - 'A') * 16 + (h[1] - 'A');
	}
	*c = 0;
	if (luaL_loadbuffer(l, code, strlen(code), "@bot"))
	{
		printf("syntax error: %s\n", lua_tostring(l, -1));
		return 0;
	}
	pthread_t th;
	pthread_create(&th, NULL, &thread, NULL);
#ifdef WIN32
	Sleep(500);
#else
	sleep(1);
#endif
	pthread_cancel(th);
	printf("time limit exceeded\n");
}
