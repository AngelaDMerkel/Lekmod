#!/usr/bin/env python3
"""Execute the actual garrison loader and saved-count rebuild against shipped data."""
from pathlib import Path
import re
import subprocess
import tempfile
import xml.etree.ElementTree as ET
root=Path(__file__).resolve().parents[2]
source=(root/'LEKMOD_DLL/CvGameCoreDLL_Expansion2/CvBuildingClasses.cpp').read_text()
loader=re.search(r'm_bGarrisonMaintenanceFree\s*=.*?;',source,re.S).group()
read=source[source.index('void CvCityBuildings::Read('):source.index('void CvCityBuildings::Write(')]
start=read.find('// Rebuild the derived garrison-maintenance count')
rebuild=read[start:read.index('\n#endif',start)] if start>=0 else ''
xml=ET.parse(root/'LEKMOD/Override/CIV5Units.xml').getroot()
row=next(r for r in xml.findall('Buildings/Row')if r.findtext('Type')=='BUILDING_MUGHALS_CARAVANSARY')
columns={node.tag:node.text.strip().lower()in('true','1') for node in row if node.text}
values=','.join('{"'+k+'",'+str(v).lower()+'}'for k,v in columns.items())
program=r'''
#include <algorithm>
#include <cstdio>
#include <map>
#include <string>
using BuildingTypes=int;
struct Results {std::map<std::string,bool> values;bool GetBool(const char*key){auto i=values.find(key);return i!=values.end()&&i->second;}};
struct CvBuildingEntry {
 bool m_bGarrisonMaintenanceFree=false;
 void load(Results&kResults){ LOADER }
 bool IsGarrisonMaintenanceFree(){return m_bGarrisonMaintenanceFree;}
};
struct Entries {
 CvBuildingEntry rows[4];
 int GetNumBuildings(){return 4;}
 CvBuildingEntry* GetEntry(int i){return i==3?nullptr:&rows[i];}
};
struct City {
 Entries*m_pBuildings;
 int m_iGarrisonMaintenanceFreeCount=0,real[4]{},free[4]{},limit=1;
 int GetNumBuilding(int i){return limit<=1?std::max(real[i],free[i]):real[i]+free[i];}
 void rebuild(){ REBUILD }
};
int main(){
 Results shipped;shipped.values={ VALUES };
 Results ordinary;
 Entries entries;entries.rows[0].load(shipped);entries.rows[1].load(ordinary);entries.rows[2].load(shipped);
 int checked=2,failed=0;
 if(!entries.rows[0].IsGarrisonMaintenanceFree()){++failed;puts("FAIL shipped Mughal flag not loaded");}
 if(entries.rows[1].IsGarrisonMaintenanceFree()){++failed;puts("FAIL ordinary building marked free");}
 for(int real=0;real<3;++real)for(int free=0;free<3;++free)for(int limit:{1,5})for(int stale:{-3,0,1,8}){
  City city;city.m_pBuildings=&entries;city.real[0]=real;city.free[0]=free;city.real[1]=7;city.real[2]=1;city.real[3]=9;city.limit=limit;
  const int expected=(limit==1?std::max(real,free):real+free)+1;
  city.m_iGarrisonMaintenanceFreeCount=stale;city.rebuild();++checked;
  if(city.m_iGarrisonMaintenanceFreeCount!=expected){++failed;if(failed<5)printf("FAIL saved count %d -> %d expected %d\n",stale,city.m_iGarrisonMaintenanceFreeCount,expected);}
  city.rebuild();++checked;if(city.m_iGarrisonMaintenanceFreeCount!=expected)++failed;
  city.real[0]=city.free[0]=city.real[2]=0;city.rebuild();++checked;if(city.m_iGarrisonMaintenanceFreeCount!=0)++failed;
 }
 printf("%d source-block loader/rebuild/idempotence/removal checks; %d failures\n",checked,failed);return failed?1:0;
}
'''.replace('LOADER',loader).replace('REBUILD',rebuild).replace('VALUES',values)
with tempfile.TemporaryDirectory(prefix='lekmod-garrison-cache-')as directory:
 p=Path(directory);(p/'test.cpp').write_text(program)
 subprocess.run(['clang++','-std=c++11','-fsanitize=address,undefined','-fno-omit-frame-pointer',str(p/'test.cpp'),'-o',str(p/'test')],check=True)
 raise SystemExit(subprocess.run([str(p/'test')]).returncode)
