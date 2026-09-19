#!/usr/bin/env python3
"""Check actual incoming tourism expressions route each city's bonus to its partner."""
import argparse
from pathlib import Path
import re
import subprocess
import tempfile

root=Path(__file__).resolve().parents[2]
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--source',type=Path,default=root/'LEKMOD_DLL/CvGameCoreDLL_Expansion2/Lua/CvLuaPlayer.cpp')
args=parser.parse_args()
source=args.source.read_text()
method=re.search(r'int CvLuaPlayer::lGetTradeRoutesToYou\(lua_State\* L\)\n\{.*?\n\}',source,re.S)
assert method,'missing actual incoming binding'
expressions=re.search(r'int iToDelta =[^;]+;\s*int iFromDelta =[^;]+;',method.group())
assert expressions,'missing actual tourism expressions'
code=r'''
#include <cstdio>
#include <cassert>
struct CvPlayer {int id;int GetID(){return id;}};
struct Culture {int owner,base,modifier,target=-1;int GetBaseTourism(){return base;}
 int GetTourismMultiplier(int recipient,bool religion,bool borders,bool trade,bool policies,bool ideologies){
  assert(religion&&borders&&!trade&&policies&&ideologies);target=recipient;return recipient==owner?0:modifier;
 }};
struct CvCity {Culture culture;Culture* GetCityCulture(){return &culture;}};
int main(){
 int cases=0,failures=0;
 for(int from=0;from<4;++from)for(int to=0;to<4;++to)if(from!=to)
 for(int originBase:{0,2,6})for(int destinationBase:{0,2,6})for(int bonus:{0,25,40}){
  CvPlayer fromPlayer{from},toPlayer{to};auto* pkPlayer=&toPlayer;auto* pFromPlayer=&fromPlayer;auto* pToPlayer=&toPlayer;
  CvCity origin{{from,originBase,bonus}},destination{{to,destinationBase,bonus}};auto* pFromCity=&origin;auto* pToCity=&destination;
''' + expressions.group() + r'''
  ++cases;
  if(iToDelta!=originBase*bonus||iFromDelta!=destinationBase*bonus||origin.culture.target!=to||destination.culture.target!=from){
   ++failures;
   if(failures<=3)std::printf("FAIL origin=%d recipient=%d from_delta=%d expected=%d from_target=%d\n",from,to,iFromDelta,destinationBase*bonus,destination.culture.target);
  }
 }
 std::printf("%d actual incoming tourism routing/numeric cases; %d failures\n",cases,failures);return failures?1:0;
}
'''
code='#include <initializer_list>\n'+code
with tempfile.TemporaryDirectory(prefix='lekmod-incoming-tourism-') as d:
    cpp=Path(d)/'test.cpp';exe=Path(d)/'test';cpp.write_text(code)
    subprocess.run(['clang++','-std=c++14','-fsanitize=address,undefined','-fno-omit-frame-pointer',str(cpp),'-o',str(exe)],check=True)
    raise SystemExit(subprocess.run([str(exe)]).returncode)
