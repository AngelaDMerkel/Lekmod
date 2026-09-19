#!/usr/bin/env python3
"""Execute actual outgoing/incoming tooltip bindings with numeric capture sinks."""
from pathlib import Path
import argparse,re,subprocess,tempfile
root=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser(description=__doc__);p.add_argument('--source',type=Path,default=root/'LEKMOD_DLL/CvGameCoreDLL_Expansion2/Lua/CvLuaPlayer.cpp');a=p.parse_args()
source=a.source.read_text();methods=[]
for name in ['GetTradeYourRoutesTTString','GetTradeToYouRoutesTTString']:
 m=re.search(r'int CvLuaPlayer::l'+name+r'\(lua_State\* L\)\n\{.*?\n\}',source,re.S)
 if not m:raise SystemExit('Missing actual binding '+name)
 methods.append(m.group())
code=r'''
#include <string>
#include <vector>
#include <array>
#include <cmath>
#include <cstdio>
#include <cassert>
using uint=unsigned int;
using YieldTypes=int;
const int NUM_YIELD_TYPES=6,YIELD_FOOD=0,YIELD_PRODUCTION=1,YIELD_GOLD=2,YIELD_SCIENCE=3,YIELD_CULTURE=4,YIELD_FAITH=5,TRADE_CONNECTION_INTERNATIONAL=0;
struct CvString:std::string {using std::string::string;operator const char*()const{return c_str();}};
struct lua_State {int owner;std::string result;};
void lua_pushstring(lua_State* L,const char* s){L->result=s;}
std::vector<double> values;
template<class T>CvString GetLocalizedText(const char*,T n){values.push_back(static_cast<double>(n));return "yield";}
namespace Localization {struct String {template<class T>String& operator<<(T){return *this;}const char* toUTF8(){return "route";}};String Lookup(const char*){return {};}}
struct CvCity {int owner;int getOwner(){return owner;}const char* getNameKey(){return "city";}};
struct CvPlot {CvCity* city;CvCity* getPlotCity(){return city;}};
struct TradeConnection {int m_eOriginOwner=0,m_eDestOwner=1,m_iOriginX=0,m_iOriginY=0,m_iDestX=1,m_iDestY=0,m_eConnectionType=0;std::array<int,6> origin{},destination{};};
struct CvPlayerTrade {int GetTradeConnectionValueTimes100(const TradeConnection& c,int yield,bool from){return from?c.origin[yield]:c.destination[yield];}};
struct CvGameTrade {std::vector<TradeConnection> m_aTradeConnections;bool IsTradeRouteIndexEmpty(uint i){return false;}};
struct Game {CvGameTrade trade;CvGameTrade* GetGameTrade(){return &trade;}};
struct Map {CvCity cities[2]={{0},{1}};CvPlot plots[2]={{&cities[0]},{&cities[1]}};CvPlot* plot(int x,int){return x>=0&&x<2?&plots[x]:nullptr;}};
struct Globals {Game game;Map map;Game& getGame(){return game;}Map& getMap(){return map;}}GC;
struct CvPlayerAI {int id;CvPlayerTrade trade;int GetID(){return id;}CvPlayerTrade* GetTrade(){return &trade;}bool isMinorCiv(){return false;}const char* getCivilizationShortDescription(){return "civilization";}} players[2]={{0},{1}};
#define GET_PLAYER(i) players[i]
struct CvLuaPlayer {static CvPlayerAI* GetInstance(lua_State* L){return &players[L->owner];}static int lGetTradeYourRoutesTTString(lua_State*);static int lGetTradeToYouRoutesTTString(lua_State*);};
'''+ '\n'.join(methods)+r'''
int main(){
 int checked=0,failed=0;const int inputs[]={1,25,75,100,175,350,575,-75,-175,10000};
 for(int path=0;path<3;++path)for(int yield=0;yield<6;++yield)for(int raw:inputs){
  TradeConnection c;if(path==0)c.origin[yield]=raw;else c.destination[yield]=raw;
  GC.game.trade.m_aTradeConnections={c};values.clear();lua_State L{path==2?1:0};
  if(path==2)CvLuaPlayer::lGetTradeToYouRoutesTTString(&L);else CvLuaPlayer::lGetTradeYourRoutesTTString(&L);
  ++checked;if(values.size()!=1||std::abs(values[0]-raw/100.0)>0.00001){++failed;std::printf("FAIL path=%d yield=%d raw=%d observed=%g\n",path,yield,raw,values.empty()?0:values[0]);}
 }
 GC.game.trade.m_aTradeConnections={TradeConnection{}};values.clear();lua_State outgoing{0},incoming{1};
 CvLuaPlayer::lGetTradeYourRoutesTTString(&outgoing);CvLuaPlayer::lGetTradeToYouRoutesTTString(&incoming);++checked;if(!values.empty())++failed;
 TradeConnection c;c.destination[0]=175;GC.game.trade.m_aTradeConnections={c};values.clear();lua_State wrongOrigin{1},wrongRecipient{0};
 CvLuaPlayer::lGetTradeYourRoutesTTString(&wrongOrigin);CvLuaPlayer::lGetTradeToYouRoutesTTString(&wrongRecipient);++checked;if(!values.empty())++failed;
 c.m_eConnectionType=1;c.m_eOriginOwner=1;c.m_eDestOwner=1;GC.game.trade.m_aTradeConnections={c};values.clear();CvLuaPlayer::lGetTradeToYouRoutesTTString(&incoming);++checked;if(!values.empty())++failed;
 std::printf("%d actual-tooltip numeric/filter cases; %d failures\n",checked,failed);return failed?1:0;
}
'''
with tempfile.TemporaryDirectory(prefix='lekmod-trade-tooltip-') as d:
 cpp=Path(d)/'test.cpp';exe=Path(d)/'test';cpp.write_text(code)
 subprocess.run(['clang++','-std=c++14','-fsanitize=address,undefined','-fno-omit-frame-pointer',str(cpp),'-o',str(exe)],check=True)
 raise SystemExit(subprocess.run([str(exe)]).returncode)
