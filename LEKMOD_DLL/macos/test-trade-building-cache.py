#!/usr/bin/env python3
"""Exercise the actual derived trade-cache helpers, including save/load rebuild."""
from pathlib import Path
import re
import subprocess
import tempfile

root=Path(__file__).resolve().parents[2]
text=(root/"LEKMOD_DLL/CvGameCoreDLL_Expansion2/CvCity.cpp").read_text(errors="replace")
names=['ApplyBuildingTradeYieldChange','RebuildBuildingTradeYields','ChangeTradeConnectionOriginExtraYield',
       'ChangeTradeConnectionDestExtraYield','ChangeIncomingTradeConnectionExtraYield']
methods=[]
for name in names:
    match=re.search(r'void CvCity::'+name+r'\([^\n]*\)\n\{.*?\n\}',text,re.S)
    if not match: raise SystemExit('Missing real method: '+name)
    methods.append(match.group())
prefix=r'''
#include <cassert>
#include <vector>
#include <cstdio>
#define CvAssert(x) assert(x)
#define CvAssertMsg(x,m) assert(x)
#define VALIDATE_OBJECT
typedef int BuildingTypes;
typedef int YieldTypes;
typedef int TradeConnectionType;
const int NUM_TRADE_CONNECTION_TYPES=4,NUM_YIELD_TYPES=8;
const int TRADE_CONNECTION_INTERNATIONAL=0,YIELD_GOLD=2,NO_TRADE_CONNECTION=-1;
struct CvBuildingEntry {
    int data[6][4][8]{};
    int land=0,sea=0,target=0,recipient=0;
    int GetTradeRouteLandGoldBonus(){return land;}
    int GetTradeRouteSeaGoldBonus(){return sea;}
    int GetTradeRouteTargetBonus(){return target;}
    int GetTradeRouteRecipientBonus(){return recipient;}
    int GetTradeConnectionOriginLandYieldChange(int t,int y){return data[0][t][y];}
    int GetTradeConnectionOriginSeaYieldChange(int t,int y){return data[1][t][y];}
    int GetTradeConnectionDestinationLandYieldChange(int t,int y){return data[2][t][y];}
    int GetTradeConnectionDestinationSeaYieldChange(int t,int y){return data[3][t][y];}
    int GetIncomingTradeConnectionLandYieldChange(int t,int y){return data[4][t][y];}
    int GetIncomingTradeConnectionSeaYieldChange(int t,int y){return data[5][t][y];}
};
struct Globals {
    CvBuildingEntry info[3];
    int getNumBuildingInfos(){return 3;}
    CvBuildingEntry* getBuildingInfo(int i){return &info[i];}
} GC;
struct Buildings {
    int counts[3]{};
    int GetNumActiveBuilding(int i){return counts[i];}
};
struct CvCity {
    int m_aaiTradeConnectionOriginLandYieldChange[4][8]{};
    int m_aaiTradeConnectionOriginSeaYieldChange[4][8]{};
    int m_aaiTradeConnectionDestinationLandYieldChange[4][8]{};
    int m_aaiTradeConnectionDestinationSeaYieldChange[4][8]{};
    int m_aaiIncomingTradeConnectionLandYieldChange[4][8]{};
    int m_aaiIncomingTradeConnectionSeaYieldChange[4][8]{};
    Buildings buildings;
    Buildings* m_pCityBuildings=&buildings;
    void ApplyBuildingTradeYieldChange(BuildingTypes,YieldTypes,int);
    void RebuildBuildingTradeYields();
    void ChangeTradeConnectionOriginExtraYield(TradeConnectionType,YieldTypes,bool,int);
    void ChangeTradeConnectionDestExtraYield(TradeConnectionType,YieldTypes,bool,int);
    void ChangeIncomingTradeConnectionExtraYield(TradeConnectionType,YieldTypes,bool,int);
    std::vector<int> snapshot() const {
        std::vector<int> out;
        for(int t=0;t<4;++t) for(int y=0;y<8;++y) {
            out.push_back(m_aaiTradeConnectionOriginLandYieldChange[t][y]);
            out.push_back(m_aaiTradeConnectionOriginSeaYieldChange[t][y]);
            out.push_back(m_aaiTradeConnectionDestinationLandYieldChange[t][y]);
            out.push_back(m_aaiTradeConnectionDestinationSeaYieldChange[t][y]);
            out.push_back(m_aaiIncomingTradeConnectionLandYieldChange[t][y]);
            out.push_back(m_aaiIncomingTradeConnectionSeaYieldChange[t][y]);
        }
        return out;
    }
};
'''
main=r'''
int main() {
    // The native reproduction: a 200/100 building bonus and a 25% river modifier.
    GC.info[0].land=200;
    CvCity original;
    original.buildings.counts[0]=1;
    for(int y=0;y<8;++y) original.ApplyBuildingTradeYieldChange(0,y,1);
    CvCity loaded;
    loaded.buildings.counts[0]=1; // Buildings persist; these derived arrays do not.
    assert((448+loaded.m_aaiTradeConnectionOriginLandYieldChange[0][2])*125/100==560);
    loaded.RebuildBuildingTradeYields();
    assert((448+loaded.m_aaiTradeConnectionOriginLandYieldChange[0][2])*125/100==810);
    assert(loaded.snapshot()==original.snapshot());
    for(int seed=0;seed<128;++seed) {
        for(int b=0;b<3;++b) {
            auto& info=GC.info[b];
            info.land=seed+b;info.sea=seed-b;info.target=b;info.recipient=2*b;
            for(int t=0;t<4;++t) for(int y=0;y<8;++y) for(int a=0;a<6;++a)
                info.data[a][t][y]=(seed+b+t+y+a)%11-5;
        }
        CvCity before,after;
        for(int b=0;b<3;++b) {
            int count=(seed+b)%3; // Includes absent/obsolete, free and repeated buildings.
            before.buildings.counts[b]=after.buildings.counts[b]=count;
            for(int y=0;y<8;++y) before.ApplyBuildingTradeYieldChange(b,y,count);
        }
        after.ChangeTradeConnectionOriginExtraYield(0,2,false,9999); // stale cache
        after.RebuildBuildingTradeYields();assert(before.snapshot()==after.snapshot());
        after.RebuildBuildingTradeYields();assert(before.snapshot()==after.snapshot());
        int removed=after.buildings.counts[0];after.buildings.counts[0]=0;
        for(int y=0;y<8;++y) before.ApplyBuildingTradeYieldChange(0,y,-removed);
        after.RebuildBuildingTradeYields();assert(before.snapshot()==after.snapshot());
    }
    std::puts("Trade building caches: native 8.10/5.60 reproduction and 128 six-array rebuild/idempotence/removal cases passed");
}
'''
with tempfile.TemporaryDirectory(prefix='lekmod-trade-cache-') as directory:
    cpp=Path(directory)/'test.cpp';binary=Path(directory)/'test'
    cpp.write_text(prefix+'\n'.join(methods)+main)
    subprocess.run(['clang++','-std=c++11','-fsanitize=address,undefined','-fno-omit-frame-pointer',str(cpp),'-o',str(binary)],check=True)
    raise SystemExit(subprocess.run([str(binary)]).returncode)
