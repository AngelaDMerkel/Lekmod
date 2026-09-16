#!/usr/bin/env python3
"""Compare the product countdown with actual StepUnit circuit progression."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[2]
source = (root / "LEKMOD_DLL/CvGameCoreDLL_Expansion2/CvTradeClasses.cpp").read_bytes().decode("latin1")
start = source.index("int TradeConnection::GetTurnsRemaining(")
query = source[start:source.index("\n}\n", start) + 3]
start = source.index("\t// if the unit needs to turn around", source.index("bool CvGameTrade::StepUnit"))
step = source[start:source.index("\n\t// Move the visualization", start)]
prefix = r'''
#include <vector>
#include <iostream>
#include <cstring>
#define AUI_WARNING_FIXES
struct TradeConnection {
 unsigned m_iTradeUnitLocationIndex=0;
 bool m_bTradeUnitMovingForward=true;
 std::vector<int> m_aPlotList;
 int m_iCircuitsCompleted=0, m_iCircuitsToComplete=10;
 int GetTurnsRemaining(int iRouteSpeed) const;
};
struct CvGameTrade {
 std::vector<TradeConnection> m_aTradeConnections;
 void StepUnit(int iIndex);
};
'''
suffix = r'''
int main() {
 int cases=0;
 // Walk actual movement states, including both endpoints/directions and the
 // fractional 10-step / 4-speed sea circuit reproduced by the native fixture.
 for (int length: {2,3,6,7,10,20,40}) for (int speed: {1,2,3,4,7,10})
 for (int circuits: {1,2,3,10}) {
  CvGameTrade game; TradeConnection initial;
  initial.m_aPlotList.resize(length); initial.m_iCircuitsToComplete=circuits;
  game.m_aTradeConnections.push_back(initial);
  while (true) {
   const TradeConnection before=game.m_aTradeConnections[0];
   const int predicted=before.GetTurnsRemaining(speed);
   CvGameTrade simulation=game; int turns=0;
   while(simulation.m_aTradeConnections[0].m_iCircuitsCompleted<circuits) {
    for(int i=0;i<speed && simulation.m_aTradeConnections[0].m_iCircuitsCompleted<circuits;++i)
     simulation.StepUnit(0);
    ++turns;
   }
   if(predicted!=turns) {
    std::cerr<<"FAIL path="<<length<<" speed="<<speed<<" circuits="<<circuits
     <<" index="<<before.m_iTradeUnitLocationIndex<<" predicted="<<predicted<<" actual="<<turns<<"\n";
    return 1;
   }
   ++cases;
   if(before.m_iCircuitsCompleted==circuits) break;
   game.StepUnit(0);
  }
 }
 TradeConnection oldSave; oldSave.m_aPlotList.resize(6);
 oldSave.m_iCircuitsCompleted=9; oldSave.m_iTradeUnitLocationIndex=4;
 oldSave.m_bTradeUnitMovingForward=false;
 if(oldSave.GetTurnsRemaining(4)!=1) return 2;
 oldSave.m_iTradeUnitLocationIndex=0;
 if(oldSave.GetTurnsRemaining(4)!=3) return 3;
 if(oldSave.GetTurnsRemaining(0)!=-1) return 4;
 oldSave.m_aPlotList.clear();
 if(oldSave.GetTurnsRemaining(4)!=-1) return 5;
 std::cout<<cases<<" reachable route states match actual StepUnit progression; late-save and invalid-speed/path boundaries pass\n";
}
'''
with tempfile.TemporaryDirectory(prefix="lekmod-trade-countdown-") as d:
    path = Path(d)
    (path / "test.cpp").write_text(prefix + query + "\nvoid CvGameTrade::StepUnit(int iIndex) {\n" + step + "\n}\n" + suffix)
    subprocess.run(["clang++", "-std=c++11", "-fsanitize=address,undefined", str(path / "test.cpp"), "-o", str(path / "test")], check=True)
    raise SystemExit(subprocess.run([str(path / "test")]).returncode)
