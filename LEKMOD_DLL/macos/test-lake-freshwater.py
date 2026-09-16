#!/usr/bin/env python3
"""Execute the product freshwater query with controlled plot/feature inputs."""
from pathlib import Path
import subprocess
import tempfile
root=Path(__file__).resolve().parents[2]
source=(root/'LEKMOD_DLL/CvGameCoreDLL_Expansion2/CvPlot.cpp').read_text()
start=source.index('bool CvPlot::isFreshWater() const')
end=source.index('\n#ifdef LEKMOD_NEW_LUA_METHODS',source.index('\n\treturn false;\n}',start))
query=source[start:end]
prefix=r'''
#include <iostream>
#define LEKMOD_NEW_LUA_METHODS
#define LEKMOD_BUGANDA_LAKE
using FeatureTypes=int;
const int NO_FEATURE=-1;
struct Feature { bool isAddsFreshWater() const{return true;} };
struct Globals { Feature feature; Feature* getFeatureInfo(int){return &feature;} } GC;
struct CvPlot {
 bool forced=false,water=false,impassable=false,mountain=false,river=false,lake=false,pseudo=false;
 int feature=NO_FEATURE;
 bool isSetFreshWater() const{return forced;}
 bool isWater() const{return water;} bool isImpassable() const{return impassable;}
 bool isMountain() const{return mountain;} bool isRiver() const{return river;}
 bool isLake() const{return lake;} bool isPseudoLake() const{return pseudo;}
 int getX() const{return 0;} int getY() const{return 0;}
 int getFeatureType() const{return feature;}
 bool isFreshWater() const;
};
CvPlot* neighbors[9]={};
CvPlot* plotXYWithRangeCheck(int,int,int x,int y,int){return neighbors[(y+1)*3+x+1];}
'''
suffix=r'''
int main(){
 int failures=0,cases=0;
 auto check=[&](const char* name,CvPlot p,bool expected){bool result=p.isFreshWater();++cases;
   std::cout<<(result==expected?"PASS ":"FAIL ")<<name<<"\n";failures+=result!=expected;};
 CvPlot p;check("dry-land",p,false);
 p.forced=true;check("scripted-freshwater-preserved",p,true);p={};
 p.river=true;check("river",p,true);p={};
 p.water=true;check("ordinary-water",p,false);p={};
 p.mountain=true;check("ordinary-mountain",p,false);p={};
 p.pseudo=true;check("artificial-lake-own-tile",p,true);p={};
 CvPlot other;other.lake=true;neighbors[0]=&other;check("natural-lake-neighbor",p,true);
 other.lake=false;other.feature=1;check("freshwater-feature-neighbor",p,true);
 neighbors[0]=nullptr;check("unrelated-dry-plot",p,false);
 std::cout<<cases<<" cases, "<<failures<<" failures\n";return failures?1:0;
}
'''
with tempfile.TemporaryDirectory(prefix='lekmod-lake-water-') as d:
 p=Path(d);(p/'test.cpp').write_text(prefix+query+suffix)
 subprocess.run(['clang++','-std=c++14','-fsanitize=address,undefined',str(p/'test.cpp'),'-o',str(p/'test')],check=True)
 raise SystemExit(subprocess.run([str(p/'test')]).returncode)
