#!/usr/bin/env python3
"""Execute the actual GP building-reward block with sparse city slots and game speeds."""
from pathlib import Path
import subprocess
import tempfile
root=Path(__file__).resolve().parents[2]
source=(root/'LEKMOD_DLL/CvGameCoreDLL_Expansion2/CvPlayer.cpp').read_bytes().decode('latin1')
start=source.index('#ifdef LEKMOD_BUILDING_GP_EXPEND_YIELD',source.index('void CvPlayer::DoGreatPersonExpended('))
end=source.index('\n#endif',start)
block=source[source.index('\n',start)+1:end]
program=r'''
#include <cassert>
#include <cstdio>
#include <vector>
using BuildingTypes=int;using YieldTypes=int;using TechTypes=int;
enum {YIELD_FOOD,YIELD_PRODUCTION,YIELD_GOLD,YIELD_SCIENCE,YIELD_CULTURE,YIELD_FAITH,NUM_YIELD_TYPES};
const int NO_BUILDING=-1,NO_TECH=-1;
struct CvBuildingEntry {int yields[NUM_YIELD_TYPES]{};int GetGreatPersonExpendYield(int y){return yields[y];}};
struct Speed {int percent;int getTrainPercent(){return percent;}} speed;
struct Game {Speed& getGameSpeedInfo(){return speed;}} game;
struct Globals {CvBuildingEntry buildings[2];int getNumBuildingInfos(){return 2;}CvBuildingEntry* getBuildingInfo(int b){return &buildings[b];}Game& getGame(){return game;}} GC;
struct Buildings {int counts[2]{};int GetNumBuilding(int b){return counts[b];}};
struct CvCity {int id;Buildings buildings;int food=0,production=0,overflow=0;Buildings* GetCityBuildings(){return &buildings;}void changeFood(int n){food+=n;}bool isProductionProcess(){return false;}void changeProduction(int n){production+=n;}int getOverflowProduction(){return overflow;}void setOverflowProduction(int n){overflow=n;}};
struct TeamTechs {int progress=0;void ChangeResearchProgress(int,int n,int){progress+=n;}};
struct Team {TeamTechs techs;TeamTechs* GetTeamTechs(){return &techs;}} teams[2];
#define GET_TEAM(id) teams[id]
struct Treasury {int gold=0;void ChangeGold(int n){gold+=n;}};
struct PlayerTechs {int current;int GetCurrentResearch(){return current;}};
struct Player {
 int id=0,faith=0,culture=0,overflow=0;Treasury treasury;PlayerTechs techs;std::vector<CvCity*> slots;
 int getNumCities(){int n=0;for(auto*c:slots)if(c)++n;return n;}
 // Slot-only lookups follow FFreeListTrashArray::GetAt; removed slots remain holes.
 CvCity* getCity(int id){int i=id&8191;if(i>=int(slots.size()))return nullptr;auto*c=slots[i];return c&&(!(id&~8191)||c->id==id)?c:nullptr;}
 CvCity* firstCity(int*i){*i=0;return nextCity(i);}
 CvCity* nextCity(int*i){while(*i<int(slots.size())){auto*c=slots[(*i)++];if(c)return c;}return nullptr;}
 void TestMidTurnPopGrowth(CvCity*,bool){} Treasury* GetTreasury(){return &treasury;}
 PlayerTechs* GetPlayerTechs(){return &techs;}int getTeam(){return id;}int GetID(){return id;}
 void changeOverflowResearch(int n){overflow+=n;}void changeJONSCulture(int n){culture+=n;}void ChangeFaith(int n){faith+=n;}
 void award(){ PRODUCT_BLOCK }
};
int main(){
 GC.buildings[0].yields[YIELD_SCIENCE]=75;GC.buildings[0].yields[YIELD_FAITH]=75;
 GC.buildings[1].yields[YIELD_SCIENCE]=11;GC.buildings[1].yields[YIELD_FAITH]=23;
 int checked=0,failed=0;
 for(int mask=0;mask<16;++mask)for(int percent:{67,100,150,300})for(int current:{-1,7}){
  Player p,foreign;p.slots.resize(4);foreign.id=1;CvCity cities[4];int science=0,faith=0;speed.percent=percent;teams[0].techs.progress=0;teams[1].techs.progress=0;p.techs.current=current;
  for(int i=0;i<4;++i){cities[i].id=((i+1)<<13)|i;cities[i].buildings.counts[0]=(i%2)?1:0;cities[i].buildings.counts[1]=(i%3)?0:1;
   if(mask&(1<<i)){p.slots[i]=&cities[i];for(int b=0;b<2;++b)if(cities[i].buildings.counts[b]){science+=GC.buildings[b].yields[YIELD_SCIENCE]*percent/100;faith+=GC.buildings[b].yields[YIELD_FAITH]*percent/100;}}
  }
  p.award();++checked;
  if(p.faith!=faith||p.overflow!=(current==-1?science:0)||teams[0].techs.progress!=(current==-1?0:science)||foreign.faith||teams[1].techs.progress){
   ++failed;if(failed<=3)std::printf("FAIL slots=%x speed=%d research=%d expected science/faith=%d/%d actual=%d/%d\n",mask,percent,current,science,faith,p.overflow+teams[0].techs.progress,p.faith);
  }
 }
 std::printf("%d actual building-reward block cases; %d failures\n",checked,failed);return failed?1:0;
}
'''.replace('PRODUCT_BLOCK',block)
with tempfile.TemporaryDirectory(prefix='lekmod-building-rewards-')as directory:
 p=Path(directory);(p/'test.cpp').write_text(program)
 subprocess.run(['clang++','-std=c++11','-fsanitize=address,undefined',str(p/'test.cpp'),'-o',str(p/'test')],check=True)
 raise SystemExit(subprocess.run([str(p/'test')]).returncode)
