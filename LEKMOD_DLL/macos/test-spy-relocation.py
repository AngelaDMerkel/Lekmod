#!/usr/bin/env python3
"""Exercise the actual relocation predicate, including dead and invalid spies."""
from pathlib import Path
import subprocess
import tempfile

root=Path(__file__).resolve().parents[2]
source=(root/'LEKMOD_DLL/CvGameCoreDLL_Expansion2/CvEspionageClasses.cpp').read_bytes().decode('latin1')
start=source.index('bool CvPlayerEspionage::CanMoveSpyTo(')
query=source[start:source.index('\n}\n',start)+3]
prefix=r'''
#include <vector>
#include <iostream>
#define CvAssertMsg(condition,message) ((void)0)
using uint=unsigned; using PlayerTypes=int;
const int SPY_STATE_UNASSIGNED=0, SPY_STATE_DEAD=7;
struct CvCityEspionage {int m_aiSpyAssignment[1]={-1};};
struct CvCity {
 bool allowed=true,capital=true,hasEspionage=true;int owner=1;
 CvCityEspionage espionage;
 CvCityEspionage* GetCityEspionage(){return hasEspionage?&espionage:nullptr;}
 bool isCapital(){return capital;} int getOwner(){return owner;} int getTeam(){return owner;}
};
struct Player {int GetID(){return 0;} int getTeam(){return 0;}} player;
struct Team {bool war=false;bool isAtWar(int){return war;}} team;
#define GET_TEAM(id) team
struct Spy {int m_eSpyState=SPY_STATE_UNASSIGNED;};
struct CvPlayerEspionage {
 Player* m_pPlayer=&player;std::vector<Spy> m_aSpyList={Spy()};
 bool CanEverMoveSpyTo(CvCity* c){return c->allowed;}
 bool CanMoveSpyTo(CvCity*,uint,bool);
};
'''
suffix=r'''
int main(){
 CvPlayerEspionage spies;CvCity city;int cases=0,failed=0;
 auto check=[&](const char* name,CvCity* c,uint index,bool diplomat,bool expected){
  bool result=spies.CanMoveSpyTo(c,index,diplomat);++cases;
  if(result!=expected){++failed;std::cout<<"FAIL "<<name<<"\n";}
 };
 check("live-foreign",&city,0,false,true);
 city.owner=0;check("live-home",&city,0,false,true);
 check("live-recall",nullptr,0,false,true);
 spies.m_aSpyList[0].m_eSpyState=SPY_STATE_DEAD;
 check("dead-home",&city,0,false,false);city.owner=1;
 check("dead-foreign",&city,0,false,false);
 check("dead-recall",nullptr,0,false,false);
 spies.m_aSpyList[0].m_eSpyState=SPY_STATE_UNASSIGNED;
 check("invalid-city-index",&city,1,false,false);
 check("invalid-recall-index",nullptr,1,false,false);
 city.espionage.m_aiSpyAssignment[0]=0;check("occupied",&city,0,false,false);
 city.espionage.m_aiSpyAssignment[0]=-1;city.allowed=false;check("inaccessible",&city,0,false,false);
 city.allowed=true;city.hasEspionage=false;check("missing-city-state",&city,0,false,false);
 city.hasEspionage=true;city.owner=0;check("diplomat-home",&city,0,true,false);
 city.owner=1;city.capital=false;check("diplomat-noncapital",&city,0,true,false);
 city.capital=true;team.war=true;check("diplomat-at-war",&city,0,true,false);
 team.war=false;check("diplomat-peace",&city,0,true,true);
 std::cout<<cases<<" relocation cases, "<<failed<<" failures\n";return failed?1:0;
}
'''
with tempfile.TemporaryDirectory(prefix='lekmod-spy-relocation-') as d:
    p=Path(d);(p/'test.cpp').write_text(prefix+query+suffix)
    subprocess.run(['clang++','-std=c++11','-fsanitize=address,undefined',str(p/'test.cpp'),'-o',str(p/'test')],check=True)
    raise SystemExit(subprocess.run([str(p/'test')]).returncode)
