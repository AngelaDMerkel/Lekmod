#!/usr/bin/env python3
"""Run the actual initial color allocator against shipped and sparse color data."""
import argparse
from pathlib import Path
import re
import subprocess
import tempfile
import xml.etree.ElementTree as ET

root=Path(__file__).resolve().parents[2]
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--source',type=Path,default=root/'LEKMOD_DLL/CvGameCoreDLL_Expansion2/CvGame.cpp')
args=parser.parse_args()
source=args.source.read_text(encoding='latin-1')
match=re.search(r'void CvGame::InitPlayers\(\)\n\{(.*?)\n\tint iNumMinors = CvPreGame::numMinorCivs\(\);',source,re.S)
if not match:raise SystemExit('Initial player-color allocator not found')
data=ET.parse(root/'LEKMOD/Override/CIV5Units.xml').getroot()
colors={int(row.findtext('ID')):row.findtext('Type')for row in data.find('PlayerColors').findall('Row')}
color_ids={name:id for id,name in colors.items()}
civs={row.findtext('Type'):row.findtext('DefaultPlayerColor')for row in data.find('Civilizations').findall('Row')}
rome=color_ids[civs['CIVILIZATION_ROME']]
nz=color_ids[civs['CIVILIZATION_NEW_ZEALAND']]
barbarian=color_ids[civs['CIVILIZATION_BARBARIAN']]
code=r'''
#include <array>
#include <cstdio>
#include <set>
#include <stdexcept>
#include <vector>
using PlayerColorTypes=int;using PlayerTypes=int;using TeamTypes=int;using CivilizationTypes=int;using SlotStatus=int;
const int REALLY_MAX_PLAYERS=64,MAX_TEAMS=64,MAX_MAJOR_CIVS=22,NO_PLAYERCOLOR=-1,SS_CLOSED=0,SS_TAKEN=1,SS_COMPUTER=2,SS_OBSERVER=3;
#define AUI_WARNING_FIXES
struct CvTeam{void init(int){}};
std::array<CvTeam,64> teams;
CvTeam& GET_TEAM(int i){return teams.at(i);}
struct CvCivilizationInfo{int color=-1;int getDefaultPlayerColor(){return color;}};
struct CvPlayerColorInfo{};
struct Globals{
 std::vector<bool> valid;std::array<CvCivilizationInfo,24> civs;CvPlayerColorInfo entry;
 int getBARBARIAN_CIVILIZATION(){return 22;}int getMINOR_CIVILIZATION(){return 23;}
 CvCivilizationInfo* getCivilizationInfo(int id){return &civs.at(id);}
 int GetNumPlayerColorInfos(){return static_cast<int>(valid.size());}
 CvPlayerColorInfo* GetPlayerColorInfo(int id){return id>=0&&id<GetNumPlayerColorInfos()&&valid[id]?&entry:nullptr;}
}GC;
namespace CvPreGame{
 std::array<int,22> selected,slots;
 int playerColor(int p){return selected.at(p);}int slotStatus(int p){return slots.at(p);}int civilization(int p){return p;}
}
struct CvGame{std::vector<int> result;void InitPlayers();};
void CvGame::InitPlayers(){
''' + match.group(1) + r'''
 result.assign(aePlayerColors,aePlayerColors+MAX_MAJOR_CIVS);
}
void require(bool b,const char* message){if(!b)throw std::runtime_error(message);}
int main(){
 int cases=0,failed=0;
 const int rome=ROME,nz=NZ,barbarian=BARB;
 const std::vector<int> shipped={SHIPPED};
 auto setup=[&](int n,int maxColor){
  GC.valid.assign(maxColor+1,false);CvPreGame::selected.fill(-1);CvPreGame::slots.fill(SS_CLOSED);
  for(int i=0;i<22;++i){GC.civs[i].color=rome;if(i<n)CvPreGame::slots[i]=i==0?SS_TAKEN:SS_COMPUTER;}
  GC.civs[22].color=barbarian;
 };
 auto verify=[&](int n){
  CvGame game;game.InitPlayers();std::set<int> used;
  for(int i=0;i<22;++i){
   if(i>=n){require(game.result[i]==NO_PLAYERCOLOR,"closed slot acquired a color");continue;}
   require(GC.GetPlayerColorInfo(game.result[i])!=nullptr,"allocator selected a missing color row");
   require(game.result[i]!=GC.civs[22].color,"allocator selected reserved barbarian color");
   require(used.insert(game.result[i]).second,"allocator failed to separate duplicate colors");
   if(CvPreGame::selected[i]!=NO_PLAYERCOLOR)require(game.result[i]==CvPreGame::selected[i],"valid distinct user selection changed");
  }
 };
 auto test=[&](const char* label,int n,auto body){++cases;try{body();verify(n);}catch(const std::exception& e){++failed;std::printf("FAIL %s n=%d: %s\n",label,n,e.what());}};
 for(int n=1;n<=22;++n)test("shipped duplicate Rome",n,[&]{setup(n,183);for(int c:shipped)GC.valid[c]=true;});
 test("native two New Zealand plus ten Rome",12,[&]{setup(12,183);for(int c:shipped)GC.valid[c]=true;GC.civs[0].color=nz;GC.civs[1].color=nz;});
 test("shipped selected colors",12,[&]{setup(12,183);for(int c:shipped)GC.valid[c]=true;CvPreGame::selected[0]=5;CvPreGame::selected[1]=6;});
 for(int hole=1;hole<12;++hole)test("sparse interior and trailing holes",8,[&]{
  setup(8,25);for(int i=0;i<24;++i)GC.valid[i]=true;GC.valid[hole]=false;GC.valid[23]=false;
  GC.civs[22].color=0;for(int i=0;i<8;++i)GC.civs[i].color=24;GC.valid[24]=true;
 });
 test("dense compatibility",12,[&]{setup(12,25);for(int i=0;i<26;++i)GC.valid[i]=true;GC.civs[22].color=0;for(int i=0;i<12;++i)GC.civs[i].color=1;});
 test("observer color",3,[&]{setup(3,183);for(int c:shipped)GC.valid[c]=true;CvPreGame::slots[2]=SS_OBSERVER;});
 std::printf("%d player-color allocation cases; %d failures\n",cases,failed);return failed?1:0;
}
'''
code=code.replace('ROME',str(rome)).replace('NZ',str(nz)).replace('BARB',str(barbarian)).replace('SHIPPED',','.join(map(str,sorted(colors))))
with tempfile.TemporaryDirectory(prefix='lekmod-player-colors-')as directory:
    cpp=Path(directory)/'test.cpp';binary=Path(directory)/'test';cpp.write_text(code)
    subprocess.run(['clang++','-std=c++14','-fsanitize=address,undefined','-fno-omit-frame-pointer',str(cpp),'-o',str(binary)],check=True)
    raise SystemExit(subprocess.run([str(binary)]).returncode)
