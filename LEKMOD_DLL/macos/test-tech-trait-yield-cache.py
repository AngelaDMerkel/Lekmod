#!/usr/bin/env python3
"""Exercise actual trait-refresh statements and owned-plot refresh with engine stand-ins.

Trait data, plot calculations and worked-city deltas are controlled inputs here.
Native farm scenarios separately verify the shipped database and engine results.
"""
import argparse
from pathlib import Path
import re
import subprocess
import tempfile

root = Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--source', type=Path, default=root/'LEKMOD_DLL/CvGameCoreDLL_Expansion2/CvTeam.cpp')
args = parser.parse_args()
source = args.source.read_text(encoding='latin-1')
refresh = re.search(r'\t\t\t// Update our traits.*?(?=\t\t\t// Does our trait give us a new unit)', source, re.S)
player_source = (root/'LEKMOD_DLL/CvGameCoreDLL_Expansion2/CvPlayer.cpp').read_text(encoding='latin-1')
update = re.search(r'void CvPlayer::updateYield\(\)\n\{.*?\n\}', player_source, re.S)
if not refresh or not update:
    raise SystemExit('Product trait-refresh or owned-plot refresh code not found')
code = r'''
#include <array>
#include <cstdio>
#include <stdexcept>
#include <vector>
using PlayerTypes = int;
struct CvPlayer;
struct CvPlot {
 int owner, base, cached; bool fresh, worked; int updates=0;
 int getOwner(){return owner;}
 int calculateYield();
 void updateYield();
};
struct CvMap {
 std::vector<CvPlot> plots;
 int numPlots(){return static_cast<int>(plots.size());}
 CvPlot* plotByIndexUnchecked(int index){return &plots.at(index);}
};
struct Globals {CvMap map;CvMap& getMap(){return map;}} GC;
struct Traits {
 bool nabatea=false,math=false,civil=false;int freshBonus=0;
 void Reset(){freshBonus=0;}
 void InitPlayerTraits(){freshBonus=nabatea&&math&&!civil?1:0;}
};
struct CvPlayer {
 int id=0,techBonus=0,cityFood=0;Traits traits;
 PlayerTypes GetID(){return id;}
 Traits* GetPlayerTraits(){return &traits;}
 void recomputePolicyCostModifier(){}
 void updateYield();
};
std::array<CvPlayer,2> players;
int CvPlot::calculateYield(){return base+(owner>=0&&fresh?players[owner].techBonus+players[owner].traits.freshBonus:0);}
void CvPlot::updateYield(){int next=calculateYield();if(worked&&owner>=0)players[owner].cityFood+=next-cached;cached=next;++updates;}
void require(bool result,const char* message){if(!result)throw std::runtime_error(message);}
''' + update.group() + '\nvoid refreshTraits(CvPlayer& kPlayer){\n' + refresh.group() + r'''
}
int main(){
 int count=0,failures=0;
 // Math activation/removal, Civil Service replacement/removal, and unrelated tech.
 const std::array<std::array<int,4>,6> transitions={{{0,0,1,0},{1,0,0,0},{1,0,1,1},{1,1,1,0},{0,0,0,0},{1,1,1,1}}};
 for(int actor=0;actor<2;++actor)for(bool nabatea:{false,true})for(const auto& state:transitions){
  ++count;
  try{
   players={};GC.map.plots.clear();
   for(int owner=0;owner<2;++owner){
    auto& p=players[owner];p.id=owner;p.traits.nabatea=nabatea;p.traits.math=state[0];p.traits.civil=state[1];p.techBonus=state[1];p.traits.InitPlayerTraits();
    for(bool fresh:{false,true})for(bool worked:{false,true}){
     CvPlot plot{owner,2,0,fresh,worked};plot.cached=plot.calculateYield();if(worked)p.cityFood+=plot.cached;GC.map.plots.push_back(plot);
    }
   }
   GC.map.plots.push_back({-1,2,2,true,false});
   const int otherFood=players[1-actor].cityFood;
   std::vector<int> otherCache;
   for(auto& p:GC.map.plots)otherCache.push_back(p.cached);
   auto& p=players[actor];p.traits.math=state[2];p.traits.civil=state[3];
   if(p.techBonus!=state[3]){p.techBonus=state[3];p.updateYield();}
   refreshTraits(p);
   int expectedFood=0;
   for(unsigned i=0;i<GC.map.plots.size();++i){auto& plot=GC.map.plots[i];
    if(plot.owner==actor){
     const int expected=2+(plot.fresh?(state[3]+(nabatea&&state[2]&&!state[3]?1:0)):0);
     require(plot.cached==expected,"owned plot retained old trait yield");
     if(plot.worked)expectedFood+=expected;
    }else require(plot.cached==otherCache[i]&&plot.updates==0,"other-owner or unowned plot was changed");
   }
   require(p.cityFood==expectedFood,"worked-city food was not reconciled");
   require(players[1-actor].cityFood==otherFood,"other-owner city food changed");
   refreshTraits(p);
   require(p.cityFood==expectedFood,"repeated refresh accumulated a yield");
  }catch(const std::exception& e){++failures;std::printf("FAIL owner%d nabatea%d %d%d->%d%d: %s\n",actor,nabatea,state[0],state[1],state[2],state[3],e.what());}
 }
 std::printf("%d technology/trait cache cases; %d failures\n",count,failures);return failures?1:0;
}
'''
with tempfile.TemporaryDirectory(prefix='lekmod-tech-trait-cache-') as directory:
    cpp=Path(directory)/'test.cpp';binary=Path(directory)/'test'
    cpp.write_text(code)
    subprocess.run(['clang++','-std=c++14','-fsanitize=address,undefined','-fno-omit-frame-pointer',str(cpp),'-o',str(binary)],check=True)
    raise SystemExit(subprocess.run([str(binary)]).returncode)
