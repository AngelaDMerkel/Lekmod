#!/usr/bin/env python3
"""Run actual EmptyTradeRoute and verify its Lua event sees fully cleared state."""
import argparse
from pathlib import Path
import re
import subprocess
import tempfile

root=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--source',type=Path,default=root/'LEKMOD_DLL/CvGameCoreDLL_Expansion2/CvTradeClasses.cpp')
a=p.parse_args();source=a.source.read_bytes().decode('latin1')
method=re.search(r'bool CvGameTrade::EmptyTradeRoute\(int iIndex\)\n\{.*?\n\}',source,re.S)
assert method,'actual removal method missing'
code=r'''
#include <vector>
#include <array>
#include <string>
#include <cstdio>
#include <cassert>
#define CvAssertMsg(condition,message) ((void)0)
using uint=unsigned int;using PlayerTypes=int;
const int NO_PLAYER=-1,NO_DOMAIN=-1,NUM_TRADE_CONNECTION_TYPES=3,NUM_YIELD_TYPES=8;
struct TradeConnection {int m_iID=77,m_iDestX=4,m_iDestY=5,m_eDestOwner=1,m_iOriginX=1,m_iOriginY=2,m_eOriginOwner=0,m_eDomain=0,m_eConnectionType=0,m_iTradeUnitLocationIndex=3,m_iCircuitsCompleted=1,m_iCircuitsToComplete=5,m_iTurnRouteComplete=9,m_unitID=42;bool m_bTradeUnitMovingForward=true;std::vector<int>m_aPlotList{1,2,3};std::array<int,8>m_aiOriginYields{{1,2,3,4,5,6,7,8}},m_aiDestYields{{8,7,6,5,4,3,2,1}};};
struct CvGameTrade {std::vector<TradeConnection>m_aTradeConnections;bool EmptyTradeRoute(int);};
CvGameTrade* current;int origin,destination,kills,events,failures;bool hasUnit,hasVM,destroyed;
struct CvUnit {void kill(bool delay){assert(!delay);++kills;assert(current->m_aTradeConnections[0].m_iID==77);}}unit;
struct Trade {int updates=0;void UpdateTradeConnectionValues(){++updates;}};
struct Player {Trade trade;Trade* GetTrade(){return &trade;}CvUnit* getUnit(int id){return hasUnit&&id==42?&unit:nullptr;}}players[3];
#define GET_PLAYER(id) players[id]
struct ICvEngineScriptSystem1 {}vm;
struct Args {std::vector<int>values;void Push(int v){values.push_back(v);}};
struct CvLuaArgsHandle {Args args;Args* operator->(){return &args;}Args* get(){return &args;}};
struct Engine {ICvEngineScriptSystem1* GetScriptSystem(){return hasVM?&vm:nullptr;}void TradeVisuals_DestroyRoute(int index,int owner){assert(index==0&&owner==origin);destroyed=true;}}engine;
Engine* gDLL=&engine;
namespace LuaSupport {bool CallHook(ICvEngineScriptSystem1*,const char*,Args*,bool&);}
''' + method.group()+r'''
namespace LuaSupport {bool CallHook(ICvEngineScriptSystem1* script,const char* name,Args* args,bool& result){
 ++events;const auto& c=current->m_aTradeConnections[0];
 bool cleared=c.m_iID==-1&&c.m_eOriginOwner==NO_PLAYER&&c.m_eDestOwner==NO_PLAYER&&c.m_unitID==-1&&c.m_aPlotList.empty();
 for(int i=0;i<NUM_YIELD_TYPES;++i)cleared=cleared&&c.m_aiOriginYields[i]==0&&c.m_aiDestYields[i]==0;
 if(script!=&vm||std::string(name)!="TradeRouteRemoved"||args->values!=std::vector<int>({origin,destination})||!cleared||!destroyed||players[origin].trade.updates!=(origin==destination?2:1)||players[destination].trade.updates!=(origin==destination?2:1))++failures;
 result=false;return true;
}}
int main(){int cases=0;
 for(origin=0;origin<3;++origin)for(destination=0;destination<3;++destination)for(int visual=0;visual<3;++visual)for(int vmMode=0;vmMode<2;++vmMode){
  CvGameTrade game;current=&game;game.m_aTradeConnections={TradeConnection{}};auto& c=game.m_aTradeConnections[0];c.m_eOriginOwner=origin;c.m_eDestOwner=destination;if(visual==0)c.m_unitID=-1;
  hasUnit=visual==1;hasVM=vmMode;destroyed=false;kills=events=0;for(auto& p:players)p.trade.updates=0;
  bool ok=game.EmptyTradeRoute(0);++cases;
  if(!ok||events!=(hasVM?1:0)||kills!=(hasUnit?1:0)||!destroyed||c.m_iID!=-1)++failures;
 }
 CvGameTrade game;current=&game;game.m_aTradeConnections={TradeConnection{}};events=0;
 for(int bad:{-1,1,99}){++cases;if(game.EmptyTradeRoute(bad)||events||game.m_aTradeConnections[0].m_iID!=77)++failures;}
 std::printf("%d actual removal/event-order cases; %d failures\n",cases,failures);return failures?1:0;
}
'''
with tempfile.TemporaryDirectory(prefix='lekmod-trade-removal-') as d:
    cpp=Path(d)/'test.cpp';exe=Path(d)/'test';cpp.write_text(code)
    subprocess.run(['clang++','-std=c++11','-fsanitize=address,undefined','-fno-omit-frame-pointer',str(cpp),'-o',str(exe)],check=True)
    raise SystemExit(subprocess.run([str(exe)]).returncode)
