#!/usr/bin/env python3
"""Execute the actual plot-yield binding and optional-boolean helper in Lua 5.1."""
from pathlib import Path
import re
import subprocess
import tempfile
root=Path(__file__).resolve().parents[2]
source=(root/'LEKMOD_DLL/CvGameCoreDLL_Expansion2/Lua/CvLuaPlot.cpp').read_text(errors="replace")
support=(root/'LEKMOD_DLL/CvGameCoreDLL_Expansion2/Lua/CvLuaSupport.cpp').read_text(errors="replace")
binding=re.search(r'int CvLuaPlot::lCalculateImprovementYieldChange\(lua_State\* L\)\n\{.*?\n\}',source,re.S).group()
helper=re.search(r'bool luaL_optbool\(.*?\n\}',support,re.S).group()
lua=root/'build/macos/test-deps/lua-5.1.4/src'
prefix=r'''
extern "C" {
#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"
}
#include <cstdio>
using ImprovementTypes=int;using YieldTypes=int;using PlayerTypes=int;using RouteTypes=int;
const int NUM_ROUTE_TYPES=2;
struct CvPlot {
 int improvement=0,yield=0,player=0,route=0,calls=0;bool optimal=false;
 int calculateImprovementYieldChange(int i,int y,int p,bool o,int r){improvement=i;yield=y;player=p;optimal=o;route=r;++calls;return 72;}
} plot;
struct CvLuaPlot {static CvPlot* GetInstance(lua_State*){return &plot;} static int lCalculateImprovementYieldChange(lua_State*);};
static int observed(lua_State* L){lua_pushinteger(L,plot.improvement);lua_pushinteger(L,plot.yield);lua_pushinteger(L,plot.player);lua_pushboolean(L,plot.optimal);lua_pushinteger(L,plot.route);lua_pushinteger(L,plot.calls);return 6;}
'''
suffix=r'''
int main(){
 lua_State* L=luaL_newstate();luaL_openlibs(L);lua_newtable(L);
 lua_pushcfunction(L,CvLuaPlot::lCalculateImprovementYieldChange);lua_setfield(L,-2,"CalculateImprovementYieldChange");lua_setglobal(L,"plot");
 lua_pushcfunction(L,observed);lua_setglobal(L,"observed");
 int result=luaL_dostring(L,R"LUA(
 local checks=0
 local function check(player,extra,optimal,route)
   local value=assert(loadstring("return plot:CalculateImprovementYieldChange(23,4,"..player..extra..")"))()
   local i,y,p,o,r=observed()
   assert(value==72 and i==23 and y==4 and p==player and o==optimal and r==route,"yield/optimal/route routing mismatch")
   checks=checks+1
 end
 check(0,"",false,2);check(0,",nil,nil",false,2);check(0,",nil,0",false,0)
 for _,player in ipairs({0,2}) do for _,optimal in ipairs({false,true}) do for _,route in ipairs({-1,0,1,2}) do
   check(player,","..tostring(optimal)..","..route,optimal,route)
 end end end
 local _,_,_,_,_,before=observed()
 assert(not pcall(function() plot:CalculateImprovementYieldChange(23,4,0,false,true) end),"boolean route accepted")
 local _,_,_,_,_,after=observed();assert(after==before,"invalid route reached the native plot")
 print("Improvement-yield binding: "..checks.." valid combinations and invalid-route guard passed")
 )LUA");
 if(result)std::fprintf(stderr,"%s\n",lua_tostring(L,-1));lua_close(L);return result?1:0;
}
'''
with tempfile.TemporaryDirectory(prefix='lekmod-improvement-yield-') as d:
 p=Path(d);(p/'test.cpp').write_text(prefix+helper+binding+suffix)
 subprocess.run(['clang++','-std=c++11','-I',str(lua),str(p/'test.cpp'),str(lua/'liblua.a'),'-o',str(p/'test')],check=True)
 raise SystemExit(subprocess.run([str(p/'test')]).returncode)
