#!/usr/bin/env python3
"""Exercise actual Consulates Lua with the native team-era argument contract.

Current product failures are retained evidence; this is not native-game proof.
"""
import argparse,subprocess,tempfile
from pathlib import Path
root=Path(__file__).resolve().parents[2];p=argparse.ArgumentParser(description=__doc__);p.add_argument('--source',type=Path,default=root/'LEKMOD/Lua/Lekmod_policies.lua');a=p.parse_args()
script=r'''
local events={}
GameEvents=setmetatable({},{__index=function(t,key)
 local callbacks={};local e={Add=function(fn)callbacks[#callbacks+1]=fn end,Remove=function(fn)for i=#callbacks,1,-1 do if callbacks[i]==fn then table.remove(callbacks,i)end end end}
 e.emit=function(...)local list={};for _,fn in ipairs(callbacks)do list[#list+1]=fn end;for _,fn in ipairs(list)do fn(...)end end
 rawset(t,key,e);return e
end})
GameInfoTypes={POLICY_CONSULATES=26,ERA_INDUSTRIAL=4,ERA_MODERN=5,ERA_POSTMODERN=6,ERA_FUTURE=7}
GameInfo={Policy_FreePromotionUnitCombats=function()return function()end end}
local function player(team,era,alive)
 local p={team=team,era=era,owned=false,votes=0,alive=alive~=false}
 function p:GetTeam()return self.team end
 function p:GetCurrentEra()return self.era end
 function p:IsAlive()return self.alive end
 function p:HasPolicy(id)return id==26 and self.owned end
 function p:GetNumPolicyLeagueVotes()return self.votes end
 function p:ChangeNumPolicyLeagueVotes(n)self.votes=self.votes+n end
 function p:Units()return function()end end
 return p
end
local function setup()
 GameEvents=setmetatable({},{__index=getmetatable(GameEvents).__index})
 Players=setmetatable({[0]=player(0,4),[1]=player(1,4),[2]=player(2,3)},{__index=function(t,id)local p=player(id,0,false);rawset(t,id,p);return p end})
 assert(loadfile(arg[1]))()
end
local function adopt(id)
 local p=Players[id];assert(not p.owned);p.owned=true;p.votes=p.votes+1 -- Native processPolicies base delegate precedes the Lua hook.
 GameEvents.PlayerAdoptPolicy.emit(id,26)
end
local function era(team,value)
 for _,p in pairs(Players)do if p.team==team then p.era=value end end
 GameEvents.TeamSetEra.emit(team,value)
end
local count,failed=0,0
local function check(name,fn)
 setup();count=count+1;local ok,e=pcall(fn);if not ok then failed=failed+1 end
 print((ok and'PASS 'or'FAIL ')..name..(ok and''or' '..tostring(e)))
end
check('first-Industrial-adopter-base-plus-era',function()adopt(0);assert(Players[0].votes==2)end)
check('second-independent-adopter-not-lost',function()adopt(0);adopt(1);assert(Players[1].votes==2,'second owner has '..Players[1].votes..', expected2')end)
check('reverse-owner-order',function()adopt(1);adopt(0);assert(Players[0].votes==2,'later human owner has '..Players[0].votes..', expected2')end)
check('unrelated-policy-keeps-listener',function()GameEvents.PlayerAdoptPolicy.emit(2,99);adopt(0);assert(Players[0].votes==2)end)
check('matching-team-era-increment',function()adopt(0);era(0,5);assert(Players[0].votes==3)end)
check('team-id-is-not-player-id',function()Players[0].team=7;adopt(0);era(7,5);assert(Players[0].votes==3,'team7 owner0 did not get its era vote')end)
check('all-owners-on-affected-team',function()Players[0].team=7;Players[1].team=7;Players[0].era=3;Players[1].era=3;adopt(0);adopt(1);era(7,4);assert(Players[0].votes==2 and Players[1].votes==2)end)
check('unrelated-player-index-not-rewarded',function()Players[0].team=7;Players[2].team=0;Players[0].era=3;adopt(0);era(0,4);assert(Players[0].votes==1,'team0 event credited unrelated player0')end)
check('dead-first-owner-does-not-consume-handler',function()Players[0].alive=false;GameEvents.PlayerAdoptPolicy.emit(0,26);adopt(1);assert(Players[1].votes==2)end)
check('nonowner-era-no-award',function()era(2,4);assert(Players[2].votes==0)end)
print(count..' cases, '..failed..' failures');os.exit(failed==0 and 0 or 1)
'''
with tempfile.TemporaryDirectory(prefix='lekmod-consulates-')as d:
 p=Path(d)/'test.lua';p.write_text(script);raise SystemExit(subprocess.run([str(root/'build/macos/test-deps/lua-5.1.4/src/lua'),str(p),str(a.source)]).returncode)
