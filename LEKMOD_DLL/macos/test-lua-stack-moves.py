#!/usr/bin/env python3
"""Execute the real read-only movement-allowance binding with Lua 5.1."""
from pathlib import Path
import re
import subprocess
import tempfile

root=Path(__file__).resolve().parents[2]
source=(root/'LEKMOD_DLL/CvGameCoreDLL_Expansion2/Lua/CvLuaUnit.cpp').read_text()
method=re.search(r'int CvLuaUnit::lMaxMovesWithStack\(lua_State\* L\)\n\{.*?\n\}',source,re.S)
if not method:raise SystemExit('Missing product stack-allowance binding')
unit_source=(root/'LEKMOD_DLL/CvGameCoreDLL_Expansion2/CvUnit.cpp').read_text()
native_max=re.search(r'int CvUnit::maxMoves\(\) const\n\{.*?\n\}',unit_source,re.S)
if not native_max:raise SystemExit('Missing product maxMoves method')
lua=root/'build/macos/test-deps/lua-5.1.4/src'
code=r'''
extern "C" {
#include "lua.h"
#include "lauxlib.h"
}
#include <algorithm>
#include <cassert>
#include <cstdio>
using std::max;
#define VALIDATE_OBJECT
struct Globals {int getMOVE_DENOMINATOR(){return 60;}} GC;
const int DOMAIN_LAND=0,DOMAIN_SEA=1,DOMAIN_AIR=2;
struct CvUnit {
 int base,generalStack,embarkedStack,landStack,domain,current=777;
 bool general,embarked,combat;
 int maxMoves() const;int baseMoves() const{return base/60;}
 bool IsGreatGeneral() const{return general;}bool isEmbarked() const{return embarked;}
 int getDomainType() const{return domain;}bool IsCombatUnit() const{return combat;}
 int GetGreatGeneralStackMovement() const{return generalStack?generalStack:base;}
 int GetEmbarkedUnitStackMovement() const{return embarkedStack?embarkedStack:base;}
 int GetLandUnitStackMovement() const{return landStack?landStack:base;}
};
struct CvLuaUnit {
 static CvUnit* GetInstance(lua_State* L){return static_cast<CvUnit*>(lua_touserdata(L,1));}
 static int lMaxMovesWithStack(lua_State* L);
};
'''+native_max.group()+'\n'+method.group()+r'''
int main(){
 lua_State* L=luaL_newstate();int count=0;
 auto check=[&](const char* name,int base,int generalStack,int embarkedStack,int landStack,int domain,bool general,bool embarked,bool combat,int withLand,int withoutLand){
  CvUnit u{base,generalStack,embarkedStack,landStack,domain,777,general,embarked,combat};
  lua_pushcfunction(L,CvLuaUnit::lMaxMovesWithStack);lua_pushlightuserdata(L,&u);
  assert(lua_pcall(L,1,1,0)==0);
#ifdef LEKMOD_LONGSHIP_ALL_PROMO
  int expected=withLand;
#else
  int expected=withoutLand;
#endif
  assert(lua_tointeger(L,-1)==expected&&u.current==777);lua_pop(L,1);++count;std::printf("PASS %s\n",name);
 };
 check("ordinary land combat",120,300,360,480,DOMAIN_LAND,false,false,true,120,120);
 check("land civilian escort",120,0,0,180,DOMAIN_LAND,false,false,false,180,120);
 check("slower civilian escort never reduces base",240,0,0,120,DOMAIN_LAND,false,false,false,240,240);
 check("sea unit excludes land stack",360,0,0,600,DOMAIN_SEA,false,false,true,360,360);
 check("air unit excludes land stack",120,0,0,600,DOMAIN_AIR,false,false,false,120,120);
 check("embarked combat escort",180,0,360,600,DOMAIN_LAND,false,true,true,360,360);
 check("embarked allowance follows active core configuration",180,0,120,600,DOMAIN_LAND,false,true,false,180,120);
 check("general escort",240,300,0,0,DOMAIN_LAND,true,false,false,300,300);
 check("general/civilian fallback follows core configuration",300,180,0,0,DOMAIN_LAND,true,false,false,300,180);
 check("embarked general combines valid maxima",180,300,420,600,DOMAIN_LAND,true,true,false,420,420);
 check("general and civilian allowances combine",240,300,0,420,DOMAIN_LAND,true,false,false,420,300);
 lua_close(L);std::printf("%d read-only stack-allowance binding cases passed\n",count);
}
'''
with tempfile.TemporaryDirectory(prefix='lekmod-stack-moves-') as directory:
 p=Path(directory);cpp=p/'test.cpp';cpp.write_text(code)
 for enabled in (False,True):
  binary=p/('test-'+str(int(enabled)))
  subprocess.run(['clang++','-std=c++14','-fsanitize=address,undefined','-fno-omit-frame-pointer',*(['-DLEKMOD_LONGSHIP_ALL_PROMO'] if enabled else []),'-I',str(lua),str(cpp),str(lua/'liblua.a'),'-o',str(binary)],check=True)
  print('LEKMOD_LONGSHIP_ALL_PROMO='+str(enabled),flush=True)
  subprocess.run([str(binary)],check=True)
