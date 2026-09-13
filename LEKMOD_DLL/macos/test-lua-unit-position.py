#!/usr/bin/env python3
"""Execute the actual SetXY binding against Lua 5.1.4 and a recording unit."""
from pathlib import Path
import re
import subprocess
import tempfile

ROOT=Path(__file__).resolve().parents[2]
source=(ROOT/"LEKMOD_DLL/CvGameCoreDLL_Expansion2/Lua/CvLuaUnit.cpp").read_text()
binding=re.search(r"int CvLuaUnit::lSetXY\(lua_State\* L\)\n\{.*?\n\}",source,re.S).group()
helper=re.search(r"static bool OptionalPositionFlag\(.*?\n\}",source,re.S)
lua=ROOT/"build/macos/test-deps/lua-5.1.4/src"
if not (lua/"liblua.a").is_file():
    raise SystemExit("Run bootstrap-test-lua.py first")
prefix=r'''
extern "C" {
#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"
}
#include <cstdio>
struct CvUnit {
    int x=0,y=0,calls=0;
    bool group=false,update=false,show=false,check=false;
    void setXY(int a,int b,bool c,bool d,bool e,bool f) {
        x=a;y=b;group=c;update=d;show=e;check=f;++calls;
    }
} unit;
struct CvLuaUnit {
    static CvUnit* GetInstance(lua_State*) { return &unit; }
    static int lSetXY(lua_State*);
};
static int observed(lua_State* L) {
    lua_pushinteger(L,unit.x);lua_pushinteger(L,unit.y);
    lua_pushboolean(L,unit.group);lua_pushboolean(L,unit.update);
    lua_pushboolean(L,unit.show);lua_pushboolean(L,unit.check);
    lua_pushinteger(L,unit.calls);return 7;
}
'''
script=r'''
local checks=0
local function check(args,g,u,s,c)
    local ok,err=pcall(assert(loadstring("unit:SetXY(7,9"..args..")")))
    assert(ok,err)
    local x,y,ag,au,as,ac=observed()
    assert(x==7 and y==9 and ag==g and au==u and as==s and ac==c,"flag mismatch")
    checks=checks+1
end
check("",false,true,false,false)
check(",nil,nil,nil,nil",false,true,false,false)
for n=0,15 do
    local flags={}
    for i=1,4 do flags[i]=math.floor(n/2^(i-1))%2==1 end
    local bools,numbers={},{}
    for i,v in ipairs(flags) do bools[i]=tostring(v);numbers[i]=v and "1" or "0" end
    check(","..table.concat(bools,","),unpack(flags))
    check(","..table.concat(numbers,","),unpack(flags))
end
local _,_,_,_,_,_,before=observed()
assert(not pcall(function() unit:SetXY(7,9,{}) end),"invalid flag accepted")
local _,_,_,_,_,_,after=observed()
assert(before==after,"invalid flags moved the unit")
print("SetXY binding: "..checks.." default/boolean/numeric cases and invalid-type guard passed")
'''
escaped=script.replace('\\','\\\\').replace('"','\\"').replace('\n','\\n')
suffix=r'''
int main() {
    lua_State* L=luaL_newstate();luaL_openlibs(L);
    lua_newtable(L);lua_pushcfunction(L,CvLuaUnit::lSetXY);lua_setfield(L,-2,"SetXY");lua_setglobal(L,"unit");
    lua_pushcfunction(L,observed);lua_setglobal(L,"observed");
    int result=luaL_dostring(L,SCRIPT);
    if(result) std::fprintf(stderr,"%s\n",lua_tostring(L,-1));
    lua_close(L);return result?1:0;
}
'''.replace('SCRIPT','"'+escaped+'"')
with tempfile.TemporaryDirectory(prefix="lekmod-setxy-") as temp:
    cpp=Path(temp)/"test.cpp";binary=Path(temp)/"test"
    cpp.write_text(prefix+(helper.group() if helper else "")+binding+suffix)
    subprocess.run(["clang++","-std=c++11","-I",str(lua),str(cpp),str(lua/"liblua.a"),"-o",str(binary)],check=True)
    raise SystemExit(subprocess.run([str(binary)]).returncode)
