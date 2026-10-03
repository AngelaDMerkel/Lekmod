#!/usr/bin/env python3
"""Execute actual global-building Lua against pinned shipped rows/event signatures.

Players enumeration includes owner zero, matching the observed native container;
this deliberately avoids the earlier plain-ipairs false failure. These tests are
callback evidence, not native gameplay.
"""
import argparse,hashlib,json,sqlite3,subprocess,tempfile,sys
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
from playtest_batch import lua
root=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser(description=__doc__);p.add_argument('--source',type=Path,default=root/'LEKMOD/Lua/Lekmod_global_dummies.lua');a=p.parse_args()
db=root/'build/macos/startup-stat-fix-20260926/installed-20260926T225114Z/cache-after/files/Civ5DebugDatabase.db'
assert hashlib.sha256(db.read_bytes()).hexdigest()=='8c0f687004e87d239e2bfae9c84c7cb485c48d892a97e66a983230927428427c'
c=sqlite3.connect('file:'+str(db)+'?immutable=1',uri=True);c.row_factory=sqlite3.Row
rows=[dict(r)for r in c.execute('select * from Global_Dummy_Buildings')]
for r in rows:
 for k in ['IsCapitalOnly','RequiresGoldenAge']:r[k]=bool(r[k])
 for k in list(r):
  if r[k] is None:del r[k]
types={}
for t in ['Buildings','Civilizations','Technologies','Policies','PolicyBranchTypes']:
 types.update((r['Type'],r['ID'])for r in c.execute('select ID,Type from '+t))
c.close()
script='GameInfoTypes='+lua(types)+'\nlocal rows='+lua(rows)+r'''
local originalIpairs=ipairs
function ipairs(t)
 if t~=Players then return originalIpairs(t)end
 local i=-1;return function()i=i+1;if i<8 then return i,Players[i]end end
end
GameDefines={MAX_MAJOR_CIVS=8}
local function iterator(t)local i=0;return function()i=i+1;return t[i]end end
GameInfo={Global_Dummy_Buildings=function()return iterator(rows)end,Civilization_Dummy_Policies=function()return function()end end}
local function events()
 return setmetatable({},{__index=function(t,key)local callbacks={};local e={Add=function(fn)callbacks[#callbacks+1]=fn end};e.emit=function(...)for _,fn in originalIpairs(callbacks)do fn(...)end end;rawset(t,key,e);return e end})
end
local function city(capital)
 local c={capital=capital,buildings={}}
 function c:IsCapital()return self.capital end
 function c:SetNumRealBuilding(id,n)self.buildings[id]=n end
 function c:GetNumRealBuilding(id)return self.buildings[id]or 0 end
 return c
end
local names={'WALES','MONGOL','TIMURIDS','UKRAINE','COLOMBIA','YUGOSLAVIA','ROME','ROME'}
local function setup()
 GameEvents=events();Events=events();Players={};Teams={}
 for team=0,7 do local t={techs={}};function t:IsHasTech(id)return self.techs[id]or false end;Teams[team]=t end
 for id=0,7 do local p={id=id,team=id,civ=GameInfoTypes['CIVILIZATION_'..names[id+1]],alive=true,minor=false,barbarian=false,policies={},branches={},finished={},golden=false,cities={city(true),city(false)}}
  function p:GetID()return self.id end
  function p:GetTeam()return self.team end
  function p:GetCivilizationType()return self.civ end
  function p:IsAlive()return self.alive end
  function p:IsMinorCiv()return self.minor end
  function p:IsBarbarian()return self.barbarian end
  function p:IsGoldenAge()return self.golden end
  function p:HasPolicy(id)return self.policies[id]or false end
  function p:HasPolicyBranch(id)return self.branches[id]or false end
  function p:IsPolicyBranchFinished(id)return self.finished[id]or false end
  function p:Cities()return iterator(self.cities)end
  Players[id]=p
 end
 Players[0].team=7;Players[1].team=7;Players[2].team=0;Players[7].minor=true
 assert(loadfile(arg[1]))()
end
local function value(id,kind,cityIndex)return Players[id].cities[cityIndex or 1]:GetNumRealBuilding(GameInfoTypes[kind])end
local function requireValue(id,kind,n,cityIndex)assert(value(id,kind,cityIndex)==n,kind..' owner'..id..' expected'..n..' actual'..value(id,kind,cityIndex))end
local function tech(team,name)Teams[team].techs[GameInfoTypes[name]]=true;GameEvents.TeamSetHasTech.emit(team,GameInfoTypes[name],true)end
local function adopt(owner)Players[owner].policies[GameInfoTypes.POLICY_ECONOMIC_UNION]=true;GameEvents.PlayerAdoptPolicy.emit(owner,GameInfoTypes.POLICY_ECONOMIC_UNION)end
local n,failed=0,0
local function check(name,fn)setup();n=n+1;local ok,e=pcall(fn);if not ok then failed=failed+1 end;print((ok and'PASS 'or'FAIL ')..name..(ok and''or' '..tostring(e)))end
check('player0-team7-policy-owner',function()adopt(0);requireValue(0,'BUILDING_ECONOMIC_UNION_GOLD',1);requireValue(0,'BUILDING_ECONOMIC_UNION_GOLD',1,2)end)
check('player1-team7-policy-owner',function()adopt(1);requireValue(1,'BUILDING_ECONOMIC_UNION_GOLD',1)end)
check('player2-team0-founding',function()GameEvents.PlayerCityFounded.emit(2,10,10);requireValue(2,'BUILDING_ULUG',1);requireValue(2,'BUILDING_ULUG',0,2)end)
check('player0-does-not-refresh-unrelated-team0',function()adopt(0);requireValue(2,'BUILDING_ULUG',0)end)
check('shared-team-research-civilization-predicates',function()tech(7,'TECH_ANIMAL_HUSBANDRY');tech(7,'TECH_CHIVALRY');requireValue(0,'BUILDING_WALES_TRAIT',1);requireValue(1,'BUILDING_MONGOL_TRAIT',1);requireValue(0,'BUILDING_MONGOL_TRAIT',0);requireValue(1,'BUILDING_WALES_TRAIT',0);requireValue(0,'BUILDING_WALES_TRAIT',0,2)end)
check('all-four-configured-tech-predicates',function()tech(7,'TECH_ANIMAL_HUSBANDRY');tech(7,'TECH_CHIVALRY');tech(3,'TECH_THE_WHEEL');tech(4,'TECH_CHEMISTRY');requireValue(0,'BUILDING_WALES_TRAIT',1);requireValue(1,'BUILDING_MONGOL_TRAIT',1);requireValue(3,'BUILDING_UKRAINE_TRAIT',1);requireValue(4,'BUILDING_COLOMBIA_TRAIT',1)end)
check('missing-technology-no-award',function()GameEvents.TeamSetHasTech.emit(7,0,true);requireValue(0,'BUILDING_WALES_TRAIT',0);requireValue(1,'BUILDING_MONGOL_TRAIT',0)end)
check('foreign-civilization-no-award',function()tech(6,'TECH_CHIVALRY');requireValue(6,'BUILDING_MONGOL_TRAIT',0)end)
check('new-secondary-city-policy-award',function()adopt(0);Players[0].cities[3]=city(false);GameEvents.PlayerCityFounded.emit(0,20,20);requireValue(0,'BUILDING_ECONOMIC_UNION_GOLD',1,3);requireValue(0,'BUILDING_WALES_TRAIT',0,3)end)
for _,excluded in originalIpairs({'dead','minor','barbarian'})do
 check('excluded-'..excluded,function()local p=Players[6];p.civ=GameInfoTypes.CIVILIZATION_TIMURIDS;if excluded=='dead'then p.alive=false else p[excluded]=true end;GameEvents.PlayerCityFounded.emit(6,0,0);requireValue(6,'BUILDING_ULUG',0)end)
end
for _,branch in originalIpairs({'FREEDOM','ORDER','AUTOCRACY'})do
 check('Yugoslav-OR-predicates-'..branch,function()local p=Players[5];p.branches[GameInfoTypes['POLICY_BRANCH_'..branch]]=true;GameEvents.PlayerPolicyBranchUnlocked.emit(5,GameInfoTypes['POLICY_BRANCH_'..branch]);requireValue(5,'BUILDING_YUGO_ORDER',branch=='ORDER'and 0 or 1,2);requireValue(5,'BUILDING_YUGO_AUTOCRACY',branch=='AUTOCRACY'and 0 or 1,2);requireValue(5,'BUILDING_YUGO_FREEDOM',branch=='FREEDOM'and 0 or 1);requireValue(5,'BUILDING_YUGO_FREEDOM',0,2)end)
end
check('branch-switch-removes-stale-OR-buildings',function()local p=Players[5];p.branches[GameInfoTypes.POLICY_BRANCH_FREEDOM]=true;GameEvents.PlayerPolicyBranchUnlocked.emit(5,0);p.branches={[GameInfoTypes.POLICY_BRANCH_ORDER]=true};GameEvents.PlayerPolicyBranchUnlocked.emit(5,0);requireValue(5,'BUILDING_YUGO_ORDER',0);requireValue(5,'BUILDING_YUGO_FREEDOM',1);requireValue(5,'BUILDING_YUGO_AUTOCRACY',1)end)
check('repeat-player-event-idempotent',function()adopt(0);GameEvents.PlayerSetGoldenAge.emit(0,true);GameEvents.PlayerSetGoldenAge.emit(0,false);requireValue(0,'BUILDING_ECONOMIC_UNION_GOLD',1);requireValue(0,'BUILDING_ECONOMIC_UNION_GOLD',1,2)end)
check('capture-refreshes-both-owner-IDs',function()tech(7,'TECH_ANIMAL_HUSBANDRY');local moved=table.remove(Players[0].cities,1);Players[0].cities[1].capital=true;moved.capital=false;Players[2].cities[#Players[2].cities+1]=moved;GameEvents.CityCaptureComplete.emit(0,true,0,0,2,1,true);requireValue(0,'BUILDING_WALES_TRAIT',1);requireValue(2,'BUILDING_WALES_TRAIT',0,3)end)
check('load-repairs-missing-and-stale-derived-markers',function()Players[0].policies[GameInfoTypes.POLICY_ECONOMIC_UNION]=true;Players[6].cities[1].buildings[GameInfoTypes.BUILDING_MONGOL_TRAIT]=1;Events.SequenceGameInitComplete.emit();requireValue(0,'BUILDING_ECONOMIC_UNION_GOLD',1);requireValue(2,'BUILDING_ULUG',1);requireValue(6,'BUILDING_MONGOL_TRAIT',0);Events.SequenceGameInitComplete.emit();requireValue(0,'BUILDING_ECONOMIC_UNION_GOLD',1)end)
print(n..' cases, '..failed..' failures');os.exit(failed==0 and 0 or 1)
'''
with tempfile.TemporaryDirectory(prefix='lekmod-global-events-')as d:
 path=Path(d)/'test.lua';path.write_text(script);raise SystemExit(subprocess.run([str(root/'build/macos/test-deps/lua-5.1.4/src/lua'),str(path),str(a.source)]).returncode)
