#!/usr/bin/env python3
"""Run the actual native local/distance eligibility and dispatch bodies."""
from pathlib import Path
import subprocess,tempfile
root=Path(__file__).resolve().parents[2]
def body(path,signature):
 s=path.read_text();a=s.index('{',s.index(signature));b=a+1;level=1
 while level:level+=(s[b]=='{')-(s[b]=='}');b+=1
 return s[a+1:b-1]
unit=root/'LEKMOD_DLL/CvGameCoreDLL_Expansion2/CvUnit.cpp';player=root/'LEKMOD_DLL/CvGameCoreDLL_Expansion2/CvPlayer.cpp'
local=body(unit,'bool CvUnit::canGift(');distance=body(unit,'bool CvUnit::CanDistanceGift(');dispatch=body(player,'void CvPlayer::DoDistanceGift(')
cpp=r'''
#include <cstdio>
#include <cassert>
#include <initializer_list>
#define LEKMOD_MINOR_CIV_PERSONALITIES
#define NET_FIX_SINGLE_USE_ABILITY_DUPE
#define VALIDATE_OBJECT
using PlayerTypes=int;using TeamTypes=int;using UnitClassTypes=int;const int NO_PLAYER=-1,NO_UNIT=-1,NO_UNITCLASS=-1;
struct CvUnit;struct IDInfo{};
struct CvMinorCivPersonalityInfo {bool noGifts=false;bool IsNoGifts()const{return noGifts;}};
struct CvMinorCivAI {CvMinorCivPersonalityInfo info;bool present=true,blocked=false;CvMinorCivPersonalityInfo* GetPersonalityInfo(){return present?&info:nullptr;}bool IsMajorBlockedByAlliedWar(int)const{return blocked;}};
struct Traits {int GetGreatPersonGiftInfluence()const{return 0;}};
struct CvPlayer {
 int id=0,incoming=-1,added=0;bool minor=false,cap=false;CvMinorCivAI ai;Traits traits;
 bool isMinorCiv()const{return minor;}int GetID()const{return id;}int getTeam()const{return id;}
 CvMinorCivAI* GetMinorCivAI(){return &ai;}Traits* GetPlayerTraits(){return &traits;}
 bool isUnitClassMaxedOut(int,int)const{return cap;}int getUnitClassMaking(int)const{return 0;}int GetIncomingUnitType(int)const{return incoming;}
 void AddIncomingUnit(PlayerTypes,CvUnit*);void DoDistanceGift(PlayerTypes,CvUnit*);
} players[3];
#define GET_PLAYER(id) players[id]
struct Team {bool isUnitClassMaxedOut(int,int)const{return false;}int getUnitClassMaking(int)const{return 0;}}team;
#define GET_TEAM(id) team
struct Globals {int getInfoTypeForString(const char*,bool)const{return 1;}}GC;
bool war=false;bool atWar(int,int){return war;}
struct CvPlot {
 int owner=2;bool owned=true;bool isOwned()const{return owned;}int getOwner()const{return owner;}int getTeam()const{return owner;}
 bool isVisibleEnemyUnit(const CvUnit*)const{return false;}bool isVisibleEnemyUnit(int)const{return false;}bool isValidDomainForLocation(const CvUnit&)const{return true;}
 IDInfo* headUnitNode(){return nullptr;}IDInfo* nextUnitNode(IDInfo*){return nullptr;}
} plot;
CvUnit* getUnit(IDInfo){return nullptr;}
struct UnitInfo {bool IsSpreadReligion()const{return false;}bool IsRemoveHeresy()const{return false;}}info;
struct CvUnit {
 int m_eOwner=0;bool delayed=false,consumed=false;CvPlot* location=&::plot;
 const CvPlot* plot()const{return location;}CvPlot* plot(){return location;}CvUnit* getTransportUnit()const{return nullptr;}
 bool isDelayedDeath()const{return delayed;}int getOwner()const{return m_eOwner;}int getTeam()const{return m_eOwner;}
 bool isFound()const{return false;}bool IsFoundAbroad()const{return false;}bool IsCombatUnit()const{return true;}bool IsGreatPerson()const{return false;}bool canAirAttack()const{return false;}
 int getUnitClassType()const{return 2;}const UnitInfo& getUnitInfo()const{return info;}
 bool canGift(bool bTestVisible=false,bool bTestTransport=false)const{LOCAL}
 bool CanDistanceGift(PlayerTypes eToPlayer)const{DISTANCE}
};
void CvPlayer::AddIncomingUnit(PlayerTypes,CvUnit* u){++added;u->consumed=true;}
void CvPlayer::DoDistanceGift(PlayerTypes eFromPlayer,CvUnit* pUnit){DISPATCH}
int main(){
 int checks=0,failures=0;
 for(bool minor:{false,true})for(bool present:{false,true})for(bool noGift:{false,true})for(bool blocked:{false,true})for(bool busy:{false,true})for(bool capped:{false,true})for(bool delayed:{false,true})for(bool enemy:{false,true}){
  for(int i=0;i<3;++i){players[i]=CvPlayer();players[i].id=i;}int recipient=minor?2:1;auto& p=players[recipient];p.minor=minor;p.ai.present=present;p.ai.info.noGifts=noGift;p.ai.blocked=blocked;p.incoming=busy?9:NO_UNIT;p.cap=capped;war=enemy;plot.owner=recipient;
  CvUnit u;u.m_eOwner=minor?0:2;u.delayed=delayed;players[u.m_eOwner].minor=!minor;
  const bool receiverBlocked=minor&&((present&&noGift)||blocked);
  for(bool visible:{false,true}){bool expected=!delayed&&!enemy&&!receiverBlocked&&(visible||!capped);if(u.canGift(visible,false)!=expected)++failures;++checks;}
  const bool expectedDistance=minor&&!enemy&&!receiverBlocked&&!busy&&!capped;
  if(u.CanDistanceGift(recipient)!=expectedDistance)++failures;++checks;
  p.DoDistanceGift(u.m_eOwner,&u);const bool expectedDispatch=!delayed&&(!minor||expectedDistance);if(u.consumed!=expectedDispatch||p.added!=(expectedDispatch?1:0))++failures;++checks;
 }
 players[2]=CvPlayer();players[2].id=2;players[2].minor=true;CvUnit u;u.location=nullptr;players[2].DoDistanceGift(0,&u);players[2].DoDistanceGift(0,nullptr);assert(!u.consumed&&players[2].added==0);
 std::printf("Actual gift guards: %d checks, %d mismatches; null unit/plot protected\n",checks,failures);return failures?1:0;
}
'''.replace('LOCAL',local).replace('DISTANCE',distance).replace('DISPATCH',dispatch)
with tempfile.TemporaryDirectory(prefix='lekmod-gift-guards-')as tmp:
 p=Path(tmp);(p/'test.cpp').write_text(cpp);subprocess.run(['clang++','-std=c++11','-fsanitize=address,undefined',str(p/'test.cpp'),'-o',str(p/'test')],check=True);raise SystemExit(subprocess.run([str(p/'test')]).returncode)
