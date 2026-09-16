#!/usr/bin/env python3
"""Run the product heresy-removal predicate at city-center/adjacent boundaries."""
from pathlib import Path
import subprocess
import tempfile

root=Path(__file__).resolve().parents[2]
source=(root/'LEKMOD_DLL/CvGameCoreDLL_Expansion2/CvUnit.cpp').read_bytes().decode('latin1')
start=source.index('bool CvUnit::CanRemoveHeresy(')
query=source[start:source.index('\n}\n',start)+3]
prefix=r'''
#include <iostream>
#define VALIDATE_OBJECT
const int NO_RELIGION=-1;
struct Info {bool enabled=true;bool IsRemoveHeresy()const{return enabled;}};
struct ReligionData {int religion=1;int GetReligion()const{return religion;}};
struct Religions {bool foreign=true;bool IsReligionHereOtherThan(int)const{return foreign;}};
struct CvCity {int owner=0;Religions religions;int getOwner()const{return owner;}
 Religions* GetCityReligions(){return &religions;}};
struct CvPlot {CvCity* center=nullptr;CvCity* adjacent=nullptr;
 CvCity* getPlotCity()const{return center;}CvCity* GetAdjacentCity()const{return adjacent;}};
struct CvUnit {Info info;Info* m_pUnitInfo=&info;ReligionData religion;bool dead=false;
 const ReligionData* GetReligionData()const{return &religion;}
 int getOwner()const{return 0;}bool isDelayedDeath()const{return dead;}
 bool CanRemoveHeresy(const CvPlot*)const;};
'''
suffix=r'''
int main(){
 CvUnit unit;CvCity city;CvPlot plot;int cases=0,failed=0;
 auto check=[&](const char* name,bool expected){++cases;bool result=unit.CanRemoveHeresy(&plot);
  if(result!=expected){++failed;std::cout<<"FAIL "<<name<<"\n";}};
 check("no-city",false);plot.center=&city;check("own-center",true);
 plot.center=nullptr;plot.adjacent=&city;check("own-adjacent",true);
 city.owner=1;check("foreign-adjacent",false);
 plot.adjacent=nullptr;plot.center=&city;check("foreign-center",false);
 city.owner=0;city.religions.foreign=false;check("no-other-religion",false);
 city.religions.foreign=true;unit.dead=true;check("consumed-inquisitor",false);
 unit.dead=false;unit.religion.religion=NO_RELIGION;check("no-unit-religion",false);
 unit.religion.religion=1;unit.info.enabled=false;check("non-inquisitor",false);
 std::cout<<cases<<" cases, "<<failed<<" failures\n";return failed?1:0;
}
'''
with tempfile.TemporaryDirectory(prefix='lekmod-inquisitor-owner-') as d:
    p=Path(d);(p/'test.cpp').write_text(prefix+query+suffix)
    subprocess.run(['clang++','-std=c++11','-fsanitize=address,undefined',str(p/'test.cpp'),'-o',str(p/'test')],check=True)
    raise SystemExit(subprocess.run([str(p/'test')]).returncode)
