#!/usr/bin/env python3
"""Execute the product MovementCost binding against real Lua object tables."""
import argparse,re,subprocess,tempfile
from pathlib import Path
root=Path(__file__).resolve().parents[2]
parser=argparse.ArgumentParser();parser.add_argument('--source-root',type=Path,default=root);args=parser.parse_args()
source=(args.source_root/'LEKMOD_DLL/CvGameCoreDLL_Expansion2/Lua/CvLuaPlot.cpp').read_text(errors='replace')
binding=re.search(r'int CvLuaPlot::lMovementCost\(lua_State\* L\)\n\{.*?\n\}',source,re.S).group()
lua=root/'build/macos/test-deps/lua-5.1.4/src'
code=r'''
extern "C" {
#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"
}
#include <cstdio>
#include "CvLuaMethodWrapper.h"
struct CvUnit {int id;};
struct CvPlot {int id;int movementCost(const CvUnit*,const CvPlot*,int)const;};
CvUnit units[]={{7},{9}};CvPlot plots[]={{11},{13},{17}};int calls=0;
int CvPlot::movementCost(const CvUnit* unit,const CvPlot* from,int remaining)const {
 ++calls;
 if((unit!=&units[0]&&unit!=&units[1])||(from!=&plots[1]&&from!=&plots[2]))return -1;
 return id*10000+unit->id*1000+from->id*10+remaining;
}
static void* instance(lua_State* L,int index) {
 if(!lua_istable(L,index))luaL_error(L,"missing object table");
 lua_getfield(L,index,"__instance");void* value=lua_touserdata(L,-1);lua_pop(L,1);
 if(!value)luaL_error(L,"missing native instance");return value;
}
struct CvLuaUnit {static CvUnit* GetInstance(lua_State* L,int index=1,bool=true){return static_cast<CvUnit*>(instance(L,index));}};
struct CvLuaPlot: CvLuaMethodWrapper<CvLuaPlot,CvPlot> {
 static CvPlot* GetInstance(lua_State* L,int index=1,bool=true){return static_cast<CvPlot*>(instance(L,index));}
 static int GetStartingArgIndex(){return 2;}
 static int lMovementCost(lua_State*);
};
static int observed(lua_State* L){lua_pushinteger(L,calls);return 1;}
static void object(lua_State* L,void* pointer,const char* name) {
 lua_newtable(L);lua_pushlightuserdata(L,pointer);lua_setfield(L,-2,"__instance");
 lua_pushcfunction(L,CvLuaPlot::lMovementCost);lua_setfield(L,-2,"MovementCost");lua_setglobal(L,name);
}
'''+binding+r'''
int main(){
 lua_State* L=luaL_newstate();luaL_openlibs(L);
 object(L,&plots[0],"destination");object(L,&plots[1],"from1");object(L,&plots[2],"from2");
 object(L,&units[0],"unit1");object(L,&units[1],"unit2");
 lua_pushcfunction(L,observed);lua_setglobal(L,"observed");
 int result=luaL_dostring(L,R"LUA(
 local count=0
 for _,u in ipairs({{unit1,7},{unit2,9}}) do for _,p in ipairs({{from1,13},{from2,17}}) do
  local base=110000+u[2]*1000+p[2]*10
  assert(destination:MovementCost(u[1],p[1])==base,"object/default routing mismatch");count=count+1
  assert(destination:MovementCost(u[1],p[1],nil)==base,"nil default differs");count=count+1
  for _,moves in ipairs({0,1,60,120})do assert(destination:MovementCost(u[1],p[1],moves)==base+moves,"explicit routing mismatch");count=count+1 end
 end end
 local invalid={
  function()destination:MovementCost(nil,from1)end,
  function()destination:MovementCost(unit1,nil)end,
  function()destination:MovementCost({},from1)end,
  function()destination:MovementCost(unit1,{})end,
  function()destination:MovementCost(1,from1)end,
  function()destination:MovementCost(unit1,from1,true)end}
 for _,fn in ipairs(invalid)do local before=observed();assert(not pcall(fn),"invalid argument accepted");assert(observed()==before,"invalid argument reached native movement");count=count+1 end
 print(count.." movement-cost argument cases passed")
 )LUA");
 if(result)std::fprintf(stderr,"%s\n",lua_tostring(L,-1));lua_close(L);return result?1:0;
}
'''
with tempfile.TemporaryDirectory(prefix='lekmod-movement-cost-') as d:
 p=Path(d);(p/'test.cpp').write_text(code)
 subprocess.run(['clang++','-std=c++11','-fsanitize=address','-fno-omit-frame-pointer','-I',str(lua),'-I',str(root/'LEKMOD_DLL/CvGameCoreDLL_Expansion2/CvGameCoreDLLUtil/include'),str(p/'test.cpp'),str(lua/'liblua.a'),'-o',str(p/'test')],check=True)
 raise SystemExit(subprocess.run([str(p/'test')]).returncode)
