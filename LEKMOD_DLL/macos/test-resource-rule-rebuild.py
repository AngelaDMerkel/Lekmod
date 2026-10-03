#!/usr/bin/env python3
"""Compile the actual narrow cache rebuild; verify idempotence and saved history."""
from pathlib import Path
import subprocess,tempfile
root=Path(__file__).resolve().parents[2] if 'LEKMOD_DLL' in str(Path(__file__)) else Path.cwd()
s=(root/'LEKMOD_DLL/CvGameCoreDLL_Expansion2/CvTraitClasses.cpp').read_text(errors='replace')
a=s.index('void CvPlayerTraits::RebuildResourceGrantRules()');b=s.index('\n}\n',a)+3;body=s[a:b]
assert s.count('RebuildResourceGrantRules();')==2
assert 'kStream >> m_vGroupPriority;\n\tRebuildResourceGrantRules();'in s
stub=r'''
#include <vector>
#include <utility>
#include <cassert>
#include <cstddef>
#include <cstdio>
#define LEKMOD_FREE_RESOURCE_CITY_GRANT 1
const int NUM_YIELD_TYPES=3;const int NO_LEADER=-1;
struct Player {int leader=0;int getLeaderType()const{return leader;}};
typedef int TraitTypes;
struct FreeResourceCities{int resource;};
struct CvTraitEntry{
 std::vector<FreeResourceCities> rules;int gold=0;
 const std::vector<FreeResourceCities>& GetFreeResourceCities()const{return rules;}
 int GetFreeResourceCityYieldChange(int yield)const{return yield==2?gold:0;}
};
struct Globals{
 CvTraitEntry entries[3];bool missing=false;int getNumTraitInfos()const{return 3;}
 const CvTraitEntry* getTraitInfo(int id){return missing?nullptr:&entries[id];}
}GC;
struct CvPlayerTraits{
 Player player;Player* m_pPlayer=&player;
 std::vector<FreeResourceCities> m_vFreeResourceCities;
 int m_aiFreeResourceCityYieldChange[NUM_YIELD_TYPES]={99,99,99};
 std::vector<std::pair<int,int>> m_vUsedGroupAreas{{1,42},{1,99}};
 std::vector<std::pair<int,int>> m_vGroupPriority{{1,2}};
 bool enabled[3]={true,false,true};
 bool HasTrait(int id)const{return enabled[id];}
 void RebuildResourceGrantRules();
};
'''
main=r'''
int main(){
 GC.entries[0].rules={{37},{36},{38}};GC.entries[0].gold=2;
 GC.entries[1].rules={{1}};GC.entries[1].gold=20;
 GC.entries[2].rules={{9}};GC.entries[2].gold=3;
 CvPlayerTraits p;
 auto areas=p.m_vUsedGroupAreas;auto priorities=p.m_vGroupPriority;
 p.RebuildResourceGrantRules();assert(p.m_vFreeResourceCities.size()==4);assert(p.m_aiFreeResourceCityYieldChange[0]==0&&p.m_aiFreeResourceCityYieldChange[1]==0&&p.m_aiFreeResourceCityYieldChange[2]==5);
 p.RebuildResourceGrantRules();assert(p.m_vFreeResourceCities.size()==4&&p.m_aiFreeResourceCityYieldChange[2]==5);
 p.enabled[0]=false;p.enabled[1]=true;p.RebuildResourceGrantRules();assert(p.m_vFreeResourceCities.size()==2&&p.m_vFreeResourceCities[0].resource==1&&p.m_aiFreeResourceCityYieldChange[2]==23);
 GC.missing=true;p.RebuildResourceGrantRules();assert(p.m_vFreeResourceCities.empty()&&p.m_aiFreeResourceCityYieldChange[2]==0);GC.missing=false;
 p.enabled[0]=p.enabled[1]=p.enabled[2]=false;p.RebuildResourceGrantRules();assert(p.m_vFreeResourceCities.empty()&&p.m_aiFreeResourceCityYieldChange[2]==0);
 p.enabled[0]=true;p.player.leader=NO_LEADER;p.RebuildResourceGrantRules();assert(p.m_vFreeResourceCities.empty());
 p.m_pPlayer=nullptr;p.RebuildResourceGrantRules();assert(p.m_vFreeResourceCities.empty());
 assert(p.m_vUsedGroupAreas==areas&&p.m_vGroupPriority==priorities);
 puts("Actual resource-rule rebuild: active-trait selection, additive yields, repeat idempotence, stale-value removal, null/empty guards and saved history preservation passed");
}
'''
with tempfile.TemporaryDirectory(prefix='lekmod-resource-rebuild-')as tmp:
 p=Path(tmp);(p/'probe.cpp').write_text(stub+body+main)
 subprocess.run(['clang++','-std=c++11','-fsanitize=address,undefined',str(p/'probe.cpp'),'-o',str(p/'probe')],check=True)
 subprocess.run([str(p/'probe')],check=True)
