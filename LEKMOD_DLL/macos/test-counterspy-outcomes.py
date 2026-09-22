#!/usr/bin/env python3
"""Execute the actual Lekmod counterspy decision block across rank/building boundaries."""
from pathlib import Path
import subprocess
import tempfile

root=Path(__file__).resolve().parents[2]
source=(root/'LEKMOD_DLL/CvGameCoreDLL_Expansion2/CvEspionageClasses.cpp').read_bytes().decode('latin1')
start=source.index('int iCounterspyRank = 0;')
end=source.index('\n#else\n\t\t\tint iSpyResult;',start)
block=source[start:end]
program=r'''
#include <algorithm>
#include <iostream>
#include <string>
#define UNDERGROUND_SECT_REWORK
using BuildingTypes=int;
enum {SPY_RESULT_UNDETECTED,SPY_RESULT_DETECTED,SPY_RESULT_IDENTIFIED,SPY_RESULT_SPOTTED,SPY_RESULT_KILLED};
struct Spy { int m_eRank; };
struct City {};
struct Buildings {int mask;int GetNumBuilding(int kind){return(mask&(1<<kind))?1:0;}} buildings;
struct TestCity:City {Buildings* GetCityBuildings(){return &buildings;}} city;
struct Espionage {Spy m_aSpyList[1];int GetSpyIndexInCity(City*){return 0;}} espionage;
struct Religion {int pressure;int GetSpyPressure(){return pressure;}} religion;
struct Player {Espionage* GetEspionage(){return &espionage;}Religion* GetReligions(){return &religion;}} players[2];
#define GET_PLAYER(i) players[i]
struct Globals {
 int getCITY_MAX_NUM_BUILDINGS(){return 1;}
 int getInfoTypeForString(const char* name){std::string n(name);return n=="BUILDING_CONSTABLE"?0:n=="BUILDING_AUSTRALIA_CONSTABULARY"?1:2;}
} GC;
struct CityEspionage {bool counter;int result;bool HasCounterSpy(){return counter;}void SetSpyResult(int,int value){result=value;}} cityEspionage;
int main(){
 int checked=0,failed=0;
 // Standard/Australian constabularies are alternatives; NIA is independent.
 for(int mask:{0,1,2,4,5,6})for(int a=0;a<3;++a)for(int d=0;d<3;++d)
 for(int pressure=0;pressure<3;++pressure)for(int counter=0;counter<2;++counter){
  buildings.mask=mask;espionage.m_aSpyList[0].m_eRank=d;religion.pressure=pressure;
  cityEspionage.counter=counter;cityEspionage.result=-1;
  auto* pCity=&city;auto* pCityEspionage=&cityEspionage;
  Spy attacking{a};auto* pSpy=&attacking;int eCityOwner=1,ePlayer=0;
  PRODUCT_BLOCK
  const int buildingBonus=((mask&3)!=0)+((mask&4)!=0);
  const int advantage=a+pressure+2-(counter?d+buildingBonus+1:0);
  int expected;
  bool attackUpgrade,defendUpgrade;
  if(!counter){expected=advantage>=4?SPY_RESULT_UNDETECTED:advantage==3?SPY_RESULT_DETECTED:SPY_RESULT_IDENTIFIED;attackUpgrade=true;defendUpgrade=false;}
  else if(advantage<=-1){expected=SPY_RESULT_KILLED;attackUpgrade=false;defendUpgrade=true;}
  else if(advantage==0){expected=SPY_RESULT_SPOTTED;attackUpgrade=false;defendUpgrade=true;}
  else{expected=advantage<=2?SPY_RESULT_IDENTIFIED:SPY_RESULT_DETECTED;attackUpgrade=true;defendUpgrade=false;}
  ++checked;
  if(cityEspionage.result!=expected||bSpyUpgrade!=attackUpgrade||bCounterSpyUpgrade!=defendUpgrade){++failed;std::cerr<<"FAIL attacker="<<a<<" defender="<<d<<" buildings="<<mask<<" pressure="<<pressure<<" counter="<<counter<<"\n";}
 }
 std::cout<<checked<<" actual counterspy decision cases; "<<failed<<" failures\n";
 return failed?1:0;
}
'''.replace('PRODUCT_BLOCK',block)
with tempfile.TemporaryDirectory(prefix='lekmod-counterspy-')as directory:
 p=Path(directory);(p/'test.cpp').write_text(program)
 subprocess.run(['clang++','-std=c++11','-fsanitize=address,undefined',str(p/'test.cpp'),'-o',str(p/'test')],check=True)
 raise SystemExit(subprocess.run([str(p/'test')]).returncode)
