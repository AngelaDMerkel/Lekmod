#!/usr/bin/env python3
"""Check actual Team:SetHasTech argument routing against Lua 5.1.4."""
from pathlib import Path
import re
import subprocess
import tempfile

root=Path(__file__).resolve().parents[2]
source=(root/"LEKMOD_DLL/CvGameCoreDLL_Expansion2/Lua/CvLuaTeam.cpp").read_text(errors="replace")
binding=re.search(r"int CvLuaTeam::lSetHasTech\(lua_State\* L\)\n\{.*?\n\}",source,re.S).group()
lua=root/"build/macos/test-deps/lua-5.1.4/src"
prefix=r'''
extern "C" {
#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"
}
#include <cstdio>
typedef int TechTypes;
typedef int PlayerTypes;
struct CvTeam {
    int tech=0,player=0;
    bool value=false,first=false,announce=false;
    void setHasTech(int t,bool v,int p,bool f,bool a) {tech=t;value=v;player=p;first=f;announce=a;}
} team;
struct CvLuaTeam {
    static CvTeam* GetInstance(lua_State*) {return &team;}
    static int lSetHasTech(lua_State*);
};
static int observed(lua_State* L) {
    lua_pushinteger(L,team.tech);lua_pushboolean(L,team.value);lua_pushinteger(L,team.player);
    lua_pushboolean(L,team.first);lua_pushboolean(L,team.announce);return 5;
}
'''
suffix=r'''
int main() {
    lua_State* L=luaL_newstate();luaL_openlibs(L);
    lua_newtable(L);lua_pushcfunction(L,CvLuaTeam::lSetHasTech);lua_setfield(L,-2,"SetHasTech");lua_setglobal(L,"team");
    lua_pushcfunction(L,observed);lua_setglobal(L,"observed");
    int result=luaL_dostring(L,R"LUA(
        local n=0
        for _,player in ipairs({0,2}) do
            for _,value in ipairs({false,true}) do
                for _,first in ipairs({false,true}) do
                    for _,announce in ipairs({false,true}) do
                        team:SetHasTech(7,value,player,first,announce)
                        local t,v,p,f,a=observed()
                        assert(t==7 and v==value and p==player and f==first and a==announce,
                            "SetHasTech did not forward its player/first/announce arguments")
                        n=n+1
                    end
                end
            end
        end
        print("Team:SetHasTech argument routing: "..n.." combinations passed")
    )LUA");
    if(result) std::fprintf(stderr,"%s\n",lua_tostring(L,-1));
    lua_close(L);return result?1:0;
}
'''
if not (lua/"liblua.a").is_file():
    raise SystemExit("Run bootstrap-test-lua.py first")
with tempfile.TemporaryDirectory(prefix="lekmod-team-tech-") as directory:
    cpp=Path(directory)/"test.cpp";binary=Path(directory)/"test"
    cpp.write_text(prefix+binding+suffix)
    subprocess.run(["clang++","-std=c++11","-I",str(lua),str(cpp),str(lua/"liblua.a"),"-o",str(binary)],check=True)
    raise SystemExit(subprocess.run([str(binary)]).returncode)
