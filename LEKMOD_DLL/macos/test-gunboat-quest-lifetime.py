#!/usr/bin/env python3
"""Compile the native quest revocation method with recent-tribute/policy controls."""
from pathlib import Path
import subprocess,tempfile,re
root=Path(__file__).resolve().parents[2]
source=(root/'LEKMOD_DLL/CvGameCoreDLL_Expansion2/CvMinorCivAI.cpp').read_text()
start=source.index('bool CvMinorCivQuest::IsRevoked()');opening=source.index('{',start);depth=1;end=opening+1
while depth:
 depth+=(source[end]=='{')-(source[end]=='}');end+=1
body=source[opening+1:end-1]
obsolete_start=source.index('bool CvMinorCivQuest::IsObsolete()');a=source.index('{',obsolete_start);b=source.index('}',a);obsolete=source[a+1:b]
revoked=['MINOR_CIV_QUEST_ROUTE','MINOR_CIV_QUEST_CONNECT_RESOURCE','MINOR_CIV_QUEST_CONSTRUCT_WONDER','MINOR_CIV_QUEST_GREAT_PERSON','MINOR_CIV_QUEST_FIND_PLAYER','MINOR_CIV_QUEST_FIND_NATURAL_WONDER','MINOR_CIV_QUEST_GIVE_GOLD','MINOR_CIV_QUEST_PLEDGE_TO_PROTECT','MINOR_CIV_QUEST_INVEST','MINOR_CIV_QUEST_BULLY_CITY_STATE','MINOR_CIV_QUEST_DENOUNCE_MAJOR','MINOR_CIV_QUEST_SPREAD_RELIGION','MINOR_CIV_QUEST_TRADE_ROUTE']
controls=['MINOR_CIV_QUEST_CONTEST_CULTURE','MINOR_CIV_QUEST_CONTEST_FAITH','MINOR_CIV_QUEST_CONTEST_TECHS']
assert set(re.findall(r'm_eType == (MINOR_CIV_QUEST_\w+)',body))==set(revoked)
assert re.search(r'^\s*#define\s+LEKMOD_POLICY_MINOR_BULLY_TRIBUTE\b',(root/'LEKMOD_DLL/CvGameCoreDLL_Expansion2/_Defines.h').read_text(),re.M)
cpp=r'''
#include <cstdio>
#include <cassert>
#define LEKMOD_POLICY_MINOR_BULLY_TRIBUTE
ENUMS
struct Policies {bool noPenalty=false;bool IsMinorBullyNoPenalty()const{return noPenalty;}};
struct MinorAI {bool recent=false;bool IsRecentlyBulliedByMajor(int)const{return recent;}};
struct Player {Policies policies;MinorAI minor;Policies* GetPlayerPolicies(){return &policies;}MinorAI* GetMinorCivAI(){return &minor;}} players[23];
#define GET_PLAYER(id) players[id]
struct CvMinorCivQuest {
 int m_eMinor=22,m_eAssignedPlayer=0,m_eType;bool expired=false;
 bool IsExpired()const{return expired;}
 bool IsObsolete(){OBSOLETE}
 bool IsRevoked(){BODY}
};
int main(){
 int cases=0,failed=0;
 for(int recent=0;recent<2;++recent)for(int protectedQuest=0;protectedQuest<2;++protectedQuest)for(int quest=0;quest<16;++quest){
  players[22].minor.recent=recent;players[0].policies.noPenalty=protectedQuest;
  CvMinorCivQuest q;q.m_eType=quest;bool expected=recent&&!protectedQuest&&quest<13;bool actual=q.IsRevoked();++cases;
  if(actual!=expected){++failed;std::printf("recent=%d no_penalty=%d quest=%d: revoked=%d expected=%d\n",recent,protectedQuest,quest,actual,expected);}
  for(int expired=0;expired<2;++expired){q.expired=expired;assert(q.IsObsolete()==(actual||bool(expired)));++cases;}
  assert(players[22].minor.recent==bool(recent));
 }
 std::printf("Actual quest revocation: %d cases, %d failures; recent-tribute cooldown input unchanged\n",cases,failed);
 return failed?1:0;
}
'''.replace('ENUMS','enum Quest {'+','.join(revoked+controls)+'};').replace('BODY',body).replace('OBSOLETE',obsolete)
with tempfile.TemporaryDirectory(prefix='lekmod-gunboat-quest-')as tmp:
 p=Path(tmp);(p/'probe.cpp').write_text(cpp)
 subprocess.run(['clang++','-std=c++11','-fsanitize=address,undefined',str(p/'probe.cpp'),'-o',str(p/'probe')],check=True)
 raise SystemExit(subprocess.run([str(p/'probe')]).returncode)
