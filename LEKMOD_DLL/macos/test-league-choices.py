#!/usr/bin/env python3
"""Compile the product's major-member decision cases with small engine doubles."""
from pathlib import Path
import subprocess
import tempfile

root=Path(__file__).resolve().parents[2]
source=(root/"LEKMOD_DLL/CvGameCoreDLL_Expansion2/CvVotingClasses.cpp").read_text()
start=source.index("\tcase RESOLUTION_DECISION_MAJOR_CIV_MEMBER:",source.index("CvLeague::GetChoicesForDecision"))
end=source.index("\tcase RESOLUTION_DECISION_RELIGION:",start)
cases=source[start:end]
prefix=r'''
#include <vector>
#include <iostream>
typedef unsigned int uint;
typedef int PlayerTypes;
const int NO_PLAYER=-1;
enum { RESOLUTION_DECISION_MAJOR_CIV_MEMBER, RESOLUTION_DECISION_OTHER_MAJOR_CIV_MEMBER };
struct Player { bool human,minor; bool isHuman() const{return human;} bool isMinorCiv() const{return minor;} };
Player players[3]={{true,false},{false,false},{false,true}};
#define GET_PLAYER(i) players[i]
struct Effects { bool bDiplomaticVictory; };
struct Proposal { Effects effects; const Effects* GetEffects() const{return &effects;} };
typedef std::vector<Proposal> EnactProposalList;
struct Member { int ePlayer; };
std::vector<int> choices(int eDecision,int eDecider,EnactProposalList m_vEnactProposals){
 std::vector<Member> m_vMembers={{0},{1},{2}};
 std::vector<int> vChoices;
 switch(eDecision){
'''
suffix=r'''
 }
 return vChoices;
}
int main(){
 int failures=0;
 auto check=[&](const char* name,int decider,EnactProposalList proposals,std::vector<int> expected,int kind=RESOLUTION_DECISION_MAJOR_CIV_MEMBER){
  auto actual=choices(kind,decider,proposals);
  bool pass=actual==expected;
  std::cout<<(pass?"PASS ":"FAIL ")<<name<<" choices=";
  for(int value:actual)std::cout<<value<<",";
  std::cout<<"\n";
  failures+=!pass;
 };
 check("host-unique",0,{{{false}}},{0,1});
 check("multiple-proposals-no-duplicates",0,{{{false}},{{false}}},{0,1});
 check("no-proposals-preview",0,{}, {0,1});
#ifdef DIPLO_VICTORY_VOTING
 check("human-world-leader-self-only",0,{{{true}}},{0});
 check("human-mixed-session-self-only",0,{{{true}},{{false}}},{0});
#else
 check("feature-disabled-keeps-normal-choices",0,{{{true}}},{0,1});
#endif
 check("AI-world-leader-choices",1,{{{true}}},{0,1});
 check("unspecified-decider-preview",NO_PLAYER,{{{true}}},{0,1});
 check("minor-never-a-candidate",2,{{{true}}},{0,1});
 check("other-major-case",0,{}, {1},RESOLUTION_DECISION_OTHER_MAJOR_CIV_MEMBER);
 return failures?1:0;
}
'''
with tempfile.TemporaryDirectory(prefix="lekmod-league-choices-") as directory:
    path=Path(directory);cpp=path/"test.cpp";cpp.write_text(prefix+cases+suffix)
    failed=False
    for feature in (True,False):
        binary=path/("enabled" if feature else "disabled")
        command=["clang++","-std=c++14","-fsanitize=address,undefined",str(cpp),"-o",str(binary)]
        if feature: command.append("-DDIPLO_VICTORY_VOTING")
        subprocess.run(command,check=True)
        print("DIPLO_VICTORY_VOTING="+str(feature),flush=True)
        failed=subprocess.run([str(binary)]).returncode!=0 or failed
    raise SystemExit(1 if failed else 0)
