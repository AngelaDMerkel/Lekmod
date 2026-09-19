#!/usr/bin/env python3
"""Run the actual incoming route identity field assignments with varied owners."""
import argparse
from pathlib import Path
import re
import subprocess
import tempfile

root = Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--source', type=Path, default=root / 'LEKMOD_DLL/CvGameCoreDLL_Expansion2/Lua/CvLuaPlayer.cpp')
args = parser.parse_args()
source = args.source.read_text()
method = re.search(r'int CvLuaPlayer::lGetTradeRoutesToYou\(lua_State\* L\)\n\{.*?\n\}', source, re.S)
assert method, 'actual incoming binding missing'
fields = []
for field in ('FromCivilizationType', 'FromID', 'ToCivilizationType', 'ToID'):
    statement = re.search(r'lua_pushinteger\(L\s*,[^;]+;\s*lua_setfield\(L, t, "' + field + r'"\);', method.group())
    assert statement, 'actual identity field missing: ' + field
    fields.append(statement.group())
code = r'''
#include <map>
#include <string>
#include <cstdio>
struct lua_State {int pending;std::map<std::string,int> values;};
void lua_pushinteger(lua_State* L,int value){L->pending=value;}
void lua_setfield(lua_State* L,int,const char* field){L->values[field]=L->pending;}
struct CvPlayer {int id,civilization;int GetID(){return id;}int getCivilizationType(){return civilization;}} players[4];
#define GET_PLAYER(i) players[i]
struct CvCity {int owner;int getOwner(){return owner;}};
struct TradeConnection {int m_eOriginOwner,m_eDestOwner;};
void actual(lua_State* L,int from,int to){
 auto* pkPlayer=&players[to];auto* pFromPlayer=&players[from];auto* pToPlayer=&players[to];
 CvCity origin{from},destination{to};auto* pFromCity=&origin;auto* pToCity=&destination;
 TradeConnection connection{from,to};auto* pConnection=&connection;int t=0;
''' + '\n'.join(fields) + r'''
}
int main(){
 int cases=0,failures=0;
 const int civilizations[][4]={{14,46,3,99},{46,14,99,3},{14,14,46,46}};
 for(auto& ids:civilizations){
  for(int i=0;i<4;++i)players[i]={i,ids[i]};
  for(int from=0;from<4;++from)for(int to=0;to<4;++to)if(from!=to){
   lua_State L{};actual(&L,from,to);++cases;
   if(L.values["FromCivilizationType"]!=ids[from]||L.values["ToCivilizationType"]!=ids[to]||L.values["FromID"]!=from||L.values["ToID"]!=to){
    ++failures;std::printf("FAIL from=%d/civ%d to=%d/civ%d observed_from_civ=%d\n",from,ids[from],to,ids[to],L.values["FromCivilizationType"]);
   }
  }
 }
 std::printf("%d actual incoming identity cases; %d failures\n",cases,failures);return failures?1:0;
}
'''
with tempfile.TemporaryDirectory(prefix='lekmod-incoming-owner-') as directory:
    cpp=Path(directory)/'test.cpp';exe=Path(directory)/'test';cpp.write_text(code)
    subprocess.run(['clang++','-std=c++11','-fsanitize=address,undefined','-fno-omit-frame-pointer',str(cpp),'-o',str(exe)],check=True)
    raise SystemExit(subprocess.run([str(exe)]).returncode)
