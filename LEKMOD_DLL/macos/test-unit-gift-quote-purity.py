#!/usr/bin/env python3
"""Execute native unit-gift quote/payment bodies with independent accounting."""
from pathlib import Path
import subprocess,tempfile
root=Path(__file__).resolve().parents[2];source=(root/'LEKMOD_DLL/CvGameCoreDLL_Expansion2/CvMinorCivAI.cpp').read_text()
def body(signature):
 start=source.index(signature);a=source.index('{',start);level=1;b=a+1
 while level:level+=(source[b]=='{')-(source[b]=='}');b+=1
 return source[a+1:b-1]
quote=body('int CvMinorCivAI::GetFriendshipFromUnitGift(');payment=body('void CvMinorCivAI::DoUnitGiftFromMajor(')
cpp=r'''
#include <cassert>
#include <cstdio>
#include <initializer_list>
#define LEKMOD_GOLD_FROM_GIFTING_GP_TRAIT
#define LEKMOD_MINOR_CIV_PERSONALITIES
#define CvAssertMsg(condition,message) ((void)0)
typedef int PlayerTypes;const int MAX_MAJOR_CIVS=22,POLICYMOD_MILITARY_UNIT_GIFT_INFLUENCE=0;
struct Trait {int value=0;int GetGreatPersonGiftInfluence()const{return value;}};
struct Policy {int value=0;int GetNumericModifier(int)const{return value;}};
struct Treasury {int value=1000;void ChangeGold(int n){value+=n;}};
struct CvPlayer {Trait trait;Policy policy;Treasury treasury;Trait* GetPlayerTraits(){return &trait;}Policy* GetPlayerPolicies(){return &policy;}Treasury* GetTreasury(){return &treasury;}} major;
#define GET_PLAYER(id) major
struct Globals {int getFRIENDSHIP_PER_UNIT_GIFTED()const{return 5;}}GC;
struct CvUnit {bool great=false,dead=false;bool IsGreatPerson()const{return great;}void kill(bool){dead=true;}};
struct CvMinorCivPersonalityInfo {bool blocked=false;bool IsNoGifts()const{return blocked;}};
struct Minor {
 CvMinorCivPersonalityInfo personality;bool war=false,proxy=false;int count=0,influence=0;
 CvMinorCivPersonalityInfo* GetPersonalityInfo(){return &personality;}
 bool IsMajorBlockedByAlliedWar(int)const{return war;}bool IsProxyWarActiveForMajor(int)const{return proxy;}
 void ChangeNumUnitsGifted(int,int n){count+=n;}void ChangeFriendshipWithMajor(int,int n){influence+=n;}
 int GetFriendshipFromUnitGift(PlayerTypes eFromPlayer,bool bGreatPerson,bool bDistanceGift){QUOTE}
 void DoUnitGiftFromMajor(PlayerTypes eFromPlayer,CvUnit* pGiftUnit,bool bDistanceGift){PAYMENT}
};
int main(){
 int reads=0,readFailures=0,payments=0;
 for(int trait:{0,100})for(bool great:{false,true})for(bool distance:{false,true})for(bool proxy:{false,true})for(int policy:{0,10}){
  major=CvPlayer();major.trait.value=trait;major.policy.value=policy;Minor m;m.proxy=proxy;
  const int expected=great?trait:5+(proxy?5:0)+policy;
  for(int n=0;n<3;++n){int gold=major.treasury.value;assert(m.GetFriendshipFromUnitGift(0,great,distance)==expected);++reads;if(major.treasury.value!=gold)++readFailures;assert(m.count==0&&m.influence==0);}
  for(bool blocked:{false,true})for(bool war:{false,true}){
   major.treasury.value=1000;m.count=m.influence=0;m.personality.blocked=blocked;m.war=war;CvUnit u;u.great=great;m.DoUnitGiftFromMajor(0,&u,distance);bool allowed=!blocked&&!war;
   assert(major.treasury.value==1000+(allowed&&great?trait*2:0));assert(m.count==(allowed?1:0));assert(m.influence==(allowed?expected:0));assert(u.dead==(allowed&&great));++payments;
  }
 }
 Minor m;major=CvPlayer();m.DoUnitGiftFromMajor(-1,nullptr,false);m.DoUnitGiftFromMajor(MAX_MAJOR_CIVS,nullptr,false);m.DoUnitGiftFromMajor(0,nullptr,false);assert(m.count==0&&m.influence==0&&major.treasury.value==1000);
 std::printf("Native gift bodies: %d quote reads (%d treasury mutations), %d payment cases, 3 invalid-input guards\n",reads,readFailures,payments);
 return readFailures?1:0;
}
'''.replace('QUOTE',quote).replace('PAYMENT',payment)
with tempfile.TemporaryDirectory(prefix='lekmod-unit-gift-')as tmp:
 p=Path(tmp);(p/'probe.cpp').write_text(cpp);subprocess.run(['clang++','-std=c++11','-fsanitize=address,undefined',str(p/'probe.cpp'),'-o',str(p/'probe')],check=True);raise SystemExit(subprocess.run([str(p/'probe')]).returncode)
