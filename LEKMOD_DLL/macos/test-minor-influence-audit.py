#!/usr/bin/env python3
"""Compile the actual probe; refuse opt-out/invalid owners before native reads."""
from pathlib import Path
import subprocess,tempfile
port=Path(__file__).resolve().parent
source=(port/'minor-influence-audit.cpp').read_text()
body=source[source.index('int LekmodMacReadMinorInfluence'):]
stub=r'''
#include <cassert>
#include <cmath>
#include <cstdlib>
#include <cstring>
#include <limits>
#include <initializer_list>
#include <stdexcept>
#include <cstdio>
using lua_Number=double;using PlayerTypes=int;
const int MAX_MAJOR_CIVS=2,MAX_CIV_PLAYERS=5;
static int lookups=0,reads=0;
struct lua_State {double minor=2,major=0;int result=0;};
int luaL_error(lua_State*,const char*,...){throw std::runtime_error("guard");}
double luaL_checknumber(lua_State*L,int index){return index==1?L->minor:L->major;}
void lua_pushinteger(lua_State*L,int value){L->result=value;}
struct CvMinorCivAI {
 int influence[2]={1234,-567};
 int GetBaseFriendshipWithMajorTimes100(PlayerTypes id)const{++reads;return influence[id];}
};
struct CvPlayer {
 bool alive=true,minor=false,barbarian=false,missing=false;CvMinorCivAI ai;
 bool isAlive()const{return alive;}bool isMinorCiv()const{return minor;}bool isBarbarian()const{return barbarian;}
 const CvMinorCivAI* GetMinorCivAI()const{return missing?nullptr:&ai;}
}players[MAX_CIV_PLAYERS];
CvPlayer& getPlayer(int id){++lookups;return players[id];}
#define GET_PLAYER(id) getPlayer(id)
'''
main=r'''
void rejects(lua_State& L){int before=reads;try{LekmodMacReadMinorInfluence(&L);assert(false);}catch(const std::runtime_error&){}assert(reads==before);}
int main(){
 lua_State L;players[2].minor=true;players[3].minor=true;players[4].barbarian=true;
 unsetenv("LEKMOD_CONFIG_AUDIT");rejects(L);assert(lookups==0);
 setenv("LEKMOD_CONFIG_AUDIT","true",1);rejects(L);assert(lookups==0);
 setenv("LEKMOD_CONFIG_AUDIT","1",1);
 for(double bad:{-1.,0.,1.,5.,2.5,std::numeric_limits<double>::infinity(),std::numeric_limits<double>::quiet_NaN()}){L.minor=bad;int before=lookups;rejects(L);assert(lookups==before);}
 L.minor=2;
 for(double bad:{-1.,2.,0.5,std::numeric_limits<double>::infinity(),std::numeric_limits<double>::quiet_NaN()}){L.major=bad;int before=lookups;rejects(L);assert(lookups==before);}
 L.major=0;L.minor=4;rejects(L);L.minor=2;
 players[2].alive=false;rejects(L);players[2].alive=true;
 players[0].alive=false;rejects(L);players[0].alive=true;
 players[0].minor=true;rejects(L);players[0].minor=false;
 players[2].minor=false;rejects(L);players[2].minor=true;
 players[2].missing=true;rejects(L);players[2].missing=false;
 for(int owner=0;owner<2;++owner){L.major=owner;int expected=players[2].ai.influence[owner];for(int n=0;n<4;++n){assert(LekmodMacReadMinorInfluence(&L)==1);assert(L.result==expected);assert(players[2].ai.influence[owner]==expected);}}
 assert(reads==8);puts("Actual influence probe: opt-in, finite/integer/bounded indices, live owner roles, null state, signed hundredths and repeated read-only access passed");
}
'''
with tempfile.TemporaryDirectory(prefix='lekmod-minor-influence-')as tmp:
 p=Path(tmp);(p/'probe.cpp').write_text(stub+body+main)
 subprocess.run(['clang++','-std=c++11','-fsanitize=address,undefined',str(p/'probe.cpp'),'-o',str(p/'probe')],check=True)
 subprocess.run([str(p/'probe')],check=True)
