#!/usr/bin/env python3
"""Execute the product follower recomputation with controlled cache/event sinks."""
import argparse
from pathlib import Path
import re
import subprocess
import tempfile

root = Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--source', type=Path, default=root/'LEKMOD_DLL/CvGameCoreDLL_Expansion2/CvReligionClasses.cpp')
args = parser.parse_args()
source = args.source.read_text()
method = re.search(r'void CvCityReligions::RecomputeFollowers\([^\n]+\)\n\{.*?\n\}', source, re.S)
if not method:
    raise SystemExit('Product RecomputeFollowers method not found')
code = r'''
#include <array>
#include <cassert>
#include <cstdio>
#include <initializer_list>
#include <stdexcept>
#define CvAssertMsg(x,m) assert(x)
#define AUI_ITERATOR_POSTFIX_INCREMENT_OPTIMIZATIONS
#define AUI_WARNING_FIXES
using ReligionTypes=int;
using PlayerTypes=int;
using CvReligiousFollowChangeReason=int;
const int NO_RELIGION=-1,RELIGION_PANTHEON=0,CityInfo_DIRTY_BIT=1;
struct CvReligionInCity {int m_eReligion=-1;bool m_bFoundedHere=false;int m_iFollowers=0,m_iPressure=0,m_iTemp=0;};
struct ReligionInCityList {
 using iterator=CvReligionInCity*;
 std::array<CvReligionInCity,16> data;int count=0;
 iterator begin(){return data.data();}iterator end(){return begin()+count;}
 void clear(){count=0;}void push_back(const CvReligionInCity& r){data[count++]=r;}
};
struct Interface {int dirty=0;void setDirty(int flag,bool value){assert(flag==1&&value);++dirty;}};
struct Globals {Interface ui;Interface* GetEngineUserInterface(){return &ui;}int getRELIGION_ATHEISM_PRESSURE_PER_POP(){return 100;}} GC;
struct CvCityReligions;
struct City {
 int population=20,updates=0,cachedHappiness=0,cachedYield=0;CvCityReligions* religions=nullptr;
 int getPopulation(){return population;}void UpdateReligion(int);
};
struct CvCityReligions {
 ReligionInCityList m_ReligionStatus;City city;City* m_pCity=&city;int conversions=0,logs=0;
 CvCityReligions(){city.religions=this;}
 int GetNumFollowers(int id){for(auto& r:m_ReligionStatus)if(r.m_eReligion==id)return r.m_iFollowers;return 0;}
 int GetNumReligionsWithFollowers(){int n=0;for(auto& r:m_ReligionStatus)if(r.m_eReligion>0&&r.m_iFollowers>0)++n;return n;}
 int GetReligiousMajority(){
  int total=0,most=-1,pressure=0,result=-1;
  for(auto& r:m_ReligionStatus){total+=r.m_iFollowers;if(r.m_iFollowers>most||(r.m_iFollowers==most&&r.m_iPressure>pressure)){most=r.m_iFollowers;pressure=r.m_iPressure;result=r.m_eReligion;}}
  return most*2>=total?result:-1;
 }
 void CityConvertsReligion(int majority,int,int){++conversions;city.UpdateReligion(majority);}
 void LogFollowersChange(int){++logs;}
 void RecomputeFollowers(int,int,int);
 void load(std::initializer_list<std::array<int,3>> rows){
  for(auto v:rows){CvReligionInCity r;r.m_eReligion=v[0];r.m_iFollowers=v[1];r.m_iPressure=v[2];m_ReligionStatus.push_back(r);}
  city.cachedHappiness=-14+GetNumReligionsWithFollowers();city.cachedYield=2*GetNumReligionsWithFollowers();
 }
};
void City::UpdateReligion(int){++updates;cachedHappiness=-14+religions->GetNumReligionsWithFollowers();cachedYield=2*religions->GetNumReligionsWithFollowers();}
void require(bool value,const char* message){if(!value)throw std::runtime_error(message);}
'''+method.group()+r'''
int main(){
 int count=0,failed=0;
 auto test=[&](const char* name,auto body){++count;GC.ui.dirty=0;try{body();std::printf("PASS %s\n",name);}catch(const std::exception& e){++failed;std::printf("FAIL %s: %s\n",name,e.what());}};
 test("native 12-majority/8-atheist minority addition",[]{
  CvCityReligions r;r.load({{1,12,1200},{-1,8,400},{2,0,400}});r.RecomputeFollowers(1,1,0);
  require(r.GetNumFollowers(1)==12&&r.GetNumFollowers(2)==4,"follower distribution differs");
  require(r.city.cachedHappiness==-12&&r.city.cachedYield==4,"minority addition left derived caches stale");
  require(r.conversions==0&&r.city.updates==1&&r.logs==1&&GC.ui.dirty==1,"minority change emitted conversion or skipped refresh");
 });
 test("minority removal with unchanged majority followers",[]{
  CvCityReligions r;r.load({{1,12,1200},{-1,4,800},{2,4,0}});r.RecomputeFollowers(1,1,0);
  require(r.GetNumFollowers(1)==12&&r.GetNumFollowers(2)==0,"removal distribution differs");
  require(r.city.cachedHappiness==-13&&r.city.cachedYield==2&&r.city.updates==1&&r.conversions==0,"minority removal left stale cache or emitted conversion");
 });
 test("third religion appears without changing majority",[]{
  CvCityReligions r;r.load({{1,12,1200},{2,4,400},{-1,4,0},{3,0,400}});r.RecomputeFollowers(1,1,0);
  require(r.GetNumFollowers(1)==12&&r.GetNumReligionsWithFollowers()==3,"third-religion distribution differs");
  require(r.city.cachedHappiness==-11&&r.city.cachedYield==6&&r.conversions==0,"third religion did not refresh cache");
 });
 test("no-majority city still refreshes religion-count yields",[]{
  CvCityReligions r;r.load({{1,8,800},{2,8,400},{-1,4,400},{3,0,400}});r.RecomputeFollowers(1,-1,0);
  require(r.GetReligiousMajority()==-1&&r.GetNumFollowers(-1)==4,"no-majority fixture changed");
  require(r.city.cachedHappiness==-11&&r.city.cachedYield==6&&r.conversions==0,"no-majority diversity cache stayed stale");
 });
 test("pressure-only change with identical followers does not refresh",[]{
  CvCityReligions r;r.load({{1,12,1206},{-1,8,804}});r.RecomputeFollowers(1,1,0);
  require(r.GetNumFollowers(1)==12&&r.city.updates==0&&r.conversions==0&&r.logs==0&&GC.ui.dirty==0,"unchanged followers triggered needless refresh");
 });
 test("pantheon does not count as a world religion",[]{
  CvCityReligions r;r.load({{1,12,1200},{-1,8,400},{0,0,400}});r.RecomputeFollowers(1,1,0);
  require(r.GetNumFollowers(0)==4&&r.city.cachedHappiness==-13&&r.city.updates==0&&r.conversions==0,"pantheon changed diversity cache");
 });
 test("same religion count does not add diversity",[]{
  CvCityReligions r;r.load({{1,12,1200},{2,4,300},{3,4,500}});r.RecomputeFollowers(1,1,0);
  require(r.GetNumFollowers(1)==12&&r.city.cachedHappiness==-11&&r.city.updates==0,"same count incorrectly changed diversity");
 });
 test("majority conversion retains existing conversion path",[]{
  CvCityReligions r;r.load({{1,12,800},{2,8,1200}});r.RecomputeFollowers(1,1,0);
  require(r.GetReligiousMajority()==2&&r.conversions==1&&r.city.updates==1&&GC.ui.dirty==1,"majority conversion path changed");
 });
 test("majority-follower change retains existing path",[]{
  CvCityReligions r;r.load({{1,12,1400},{2,8,600}});r.RecomputeFollowers(1,1,0);
  require(r.GetNumFollowers(1)==14&&r.conversions==1&&r.city.updates==1&&GC.ui.dirty==1,"majority-follower update changed");
 });
 std::printf("%d religion-cache cases; %d failures\n",count,failed);return failed?1:0;
}
'''
with tempfile.TemporaryDirectory(prefix='lekmod-religion-cache-') as directory:
    cpp=Path(directory)/'test.cpp';binary=Path(directory)/'test'
    cpp.write_text(code)
    subprocess.run(['clang++','-std=c++14','-fsanitize=address,undefined','-fno-omit-frame-pointer',str(cpp),'-o',str(binary)],check=True)
    raise SystemExit(subprocess.run([str(binary)]).returncode)
