#!/usr/bin/env python3
"""Compile the actual per-turn settlement block against exact influence storage."""
from pathlib import Path
import subprocess,tempfile
root=Path(__file__).resolve().parents[2]
source=(root/'LEKMOD_DLL/CvGameCoreDLL_Expansion2/CvMinorCivAI.cpp').read_text()
start=source.index('// Look at the base friendship (not counting war status etc.) and change it',source.index('void CvMinorCivAI::DoFriendship()'))
end=source.index('// Notification for status changes',start)
body=source[start:end]
rate_start=source.index('// Relation to anchor point?',source.index('int CvMinorCivAI::GetFriendshipChangePerTurnTimes100('))
rate_end=source.index('// Shift on top of base rate',rate_start)
rate_body=source[rate_start:rate_end]
stub=r'''
#include <cassert>
#include <algorithm>
#include <cstdio>
#include <initializer_list>
struct Major {int getTeam()const{return 0;}int GetMinorFriendshipDecayMod()const{return 0;}}major;
struct Team {bool IsMinorCivAggressor()const{return false;}}team;
struct Globals {
 int getMINOR_FRIENDSHIP_DROP_PER_TURN_HOSTILE()const{return -150;}
 int getMINOR_FRIENDSHIP_DROP_PER_TURN_AGGRESSOR()const{return -200;}
 int getMINOR_FRIENDSHIP_DROP_PER_TURN()const{return -100;}
 int getMINOR_FRIENDSHIP_NEGATIVE_INCREASE_PER_TURN()const{return 100;}
}GC;
#define GET_PLAYER(id) major
#define GET_TEAM(id) team
const int MINOR_CIV_PERSONALITY_HOSTILE=1;
struct Minor {
 int raw,anchor,rate,sets=0,changes=0,effects=0;
 int GetBaseFriendshipWithMajor(int)const{return raw/100;}
 int GetBaseFriendshipWithMajorTimes100(int)const{return raw;}
 int GetFriendshipChangePerTurnTimes100(int)const{return rate;}
 int GetFriendshipAnchorWithMajor(int)const{return anchor;}
 void SetFriendshipWithMajor(int,int value){raw=value*100;++sets;}
 void ChangeFriendshipWithMajorTimes100(int,int value){raw+=value;++changes;}
 void DoFriendshipChangeEffects(int,int,int){++effects;}
 int GetPersonality()const{return 0;}
 int quote(){int ePlayer=0,iTraitMod=0,iReligionMod=0,iChangeThisTurn=0;Major& kPlayer=major;RATE_BODY return iChangeThisTurn;}
 void settle(int ePlayer){BODY}
};
int main(){
 int count=0;
 for(int anchor:{-60,0,5,20,45,65})
  for(int offset:{-501,-150,-101,-100,-99,-25,-1,0,1,25,99,100,101,125,150,199,500})
   for(int rate:{-375,-250,-187,-156,-125,-100,-93,-62,-31,-1,0,1,31,62,93,100,125,156,187,250,375}){
    const int original=anchor*100+offset;if(original < -6000)continue;Minor m;m.raw=original;m.anchor=anchor;m.rate=rate;
    assert(m.quote()==(original==anchor*100?0:original>anchor*100?-100:100));
    int expected=original+rate;
    if(original>=anchor*100&&expected<anchor*100)expected=anchor*100;
    m.settle(0);
    if(m.raw!=expected){std::fprintf(stderr,"anchor=%d raw=%d rate=%d observed=%d expected=%d\n",anchor,original,rate,m.raw,expected);return 1;}
    if(rate==0&&original>=anchor*100)assert(m.raw==original&&m.effects==1&&m.sets==0&&m.changes==0);
    ++count;
   }
 std::printf("Actual minor settlement: %d signed/fractional/boundary cases passed\n",count);
}
'''
with tempfile.TemporaryDirectory(prefix='lekmod-influence-clamp-')as tmp:
 p=Path(tmp);(p/'probe.cpp').write_text(stub.replace('RATE_BODY',rate_body).replace('BODY',body))
 subprocess.run(['clang++','-std=c++11','-fsanitize=address,undefined',str(p/'probe.cpp'),'-o',str(p/'probe')],check=True)
 raise SystemExit(subprocess.run([str(p/'probe')]).returncode)
