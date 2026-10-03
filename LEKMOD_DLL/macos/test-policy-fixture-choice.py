#!/usr/bin/env python3
"""Exercise the real fixture choice helper with native free-choice precedence."""
from pathlib import Path
import subprocess,tempfile
root=Path(__file__).resolve().parents[2]
core=(root/'LEKMOD_DLL/macos/playtest-scenario-core.lua').read_text().split('function LekmodScenarioStart()')[0]
test=r'''
GameInfo={Policies={[1]={Level=1},[2]={Level=0}}}
local function player(free,tenets,owned,ever)
 local p={free=free,tenets=tenets,owned=owned,ever=ever,culture=2,has={}}
 function p:GetID()return 0 end
 function p:GetNumFreePolicies()return self.free end
 function p:GetNumFreeTenets()return self.tenets end
 function p:GetJONSCulture()return self.culture end
 function p:GetNextPolicyCost()return self.owned-(self.ever-self.free-self.tenets)<0 and -1 or 15 end
 function p:SetNumFreePolicies(n)assert(n>=self.free,'fixture discarded choices');self.ever=self.ever+n-self.free;self.free=n end
 function p:HasPolicy(id)return self.has[id]or false end
 function p:CanAdoptPolicy(id)return not self:HasPolicy(id)and(self.free>0 or(id==1 and self.tenets>0))end
 return p
end
local total=0
for _,id in ipairs({1,2})do
 for _,free in ipairs({0,1,3})do for _,tenets in ipairs({0,1,2})do
  local p=player(free,tenets,0,free+tenets);local oldTenets=p.tenets
  local before=LekmodScenarioPolicyChoice(p,id);assert(p.tenets==oldTenets,'native tenets discarded')
  if id==1 and p.tenets>0 then p.tenets=p.tenets-1 else p.free=p.free-1 end
  p.has[id]=true;p.owned=p.owned+1
  LekmodScenarioVerifyPolicyChoice(p,id,before);assert(p:GetNextPolicyCost()>0);total=total+1
 end end
end
local p=player(0,0,1,3);local ok=pcall(LekmodScenarioPolicyChoice,p,1);assert(not ok and p.free==0 and p.ever==3);total=total+1
for _,bad in ipairs({'free','tenets','culture','cost','ownership'})do
 local p=player(1,2,0,3);local before=LekmodScenarioPolicyChoice(p,1);p.tenets=1;p.has[1]=true;p.owned=1
 if bad=='free'then p.free=0 elseif bad=='tenets'then p.tenets=0 elseif bad=='culture'then p.culture=99 elseif bad=='cost'then p.ever=99 else p.has[1]=false end
 assert(not pcall(LekmodScenarioVerifyPolicyChoice,p,1,before),'bad debit accepted:'..bad);total=total+1
end
print(total..' policy fixture choice cases passed')
'''
with tempfile.TemporaryDirectory(prefix='lekmod-policy-fixture-')as d:
 p=Path(d)/'test.lua';p.write_text(core+'\n'+test);raise SystemExit(subprocess.run([str(root/'build/macos/test-deps/lua-5.1.4/src/lua'),str(p)]).returncode)
