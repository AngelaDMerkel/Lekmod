#!/usr/bin/env python3
"""Run the actual scenario body with small independent cached/SQL fixtures."""
from pathlib import Path
import subprocess,tempfile
root=Path(__file__).resolve().parents[2];port=root/'LEKMOD_DLL/macos'
core=(port/'playtest-scenario-core.lua').read_text();jsonfn=core[core.index('function LekmodScenarioJSON'):core.index('function LekmodScenarioRecord')]
body=(port/'array-cache-audit-scenario-body.lua').read_text()
setup=r'''
local descriptors={
 {key="values",table="Owners",relation_table="Relations",index_table="Axes",index_column="AxisType",owner_column="OwnerType",value_column="Value",mode="indexed-value",default=5,length=3,owner_slots=2},
 {key="mask",table="Owners",relation_table="Relations",index_table="Axes",index_column="AxisType",owner_column="OwnerType",mode="membership",default=0,length=3,owner_slots=2},
 {key="list",table="Owners",relation_table="Relations",index_table="Axes",index_column="AxisType",owner_column="OwnerType",mode="compact-ids",default=-1,length=3,owner_slots=2}}
local tables={"Owners"};LekmodScenario={};local verdicts={}
local function info(rows)
 local t={};for _,r in ipairs(rows)do if r.Type then t[r.Type]=r;t[r.ID]=r end end
 return setmetatable(t,{__call=function(_,filter)
  local i=0;return function()while true do i=i+1;local r=rows[i];if not r then return nil end
   local ok=true;for k,v in pairs(filter or {})do if r[k]~=v then ok=false end end
   if ok then return r end
  end end
 end})
end
GameInfo={Owners=info({{ID=0,Type="A"},{ID=1,Type="B"}}),Axes=info({{ID=0,Type="X"},{ID=2,Type="Z"}}),Relations=info({{OwnerType="A",AxisType="X",Value=7},{OwnerType="A",AxisType="Z",Value=-3}})}
GameDefines={MAX_CIV_PLAYERS=0};Players={}
local native={values={{7,5,-3},{5,5,5}},mask={{true,false,true},{false,false,false}},list={{2,-1,0},{-1,-1,-1}}}
local reads=0
Game={GetGameTurn=function()return 1 end,GetElapsedGameTurns=function()return 1 end,ReadInfoArrayForTest=function(key,id)
 assert(id==id and id>=0 and id<2 and id==math.floor(id)and native[key]);reads=reads+1
 local out={};for i,v in ipairs(native[key][id+1])do out[i]=v end;return out
end}
LekmodScenarioRecord=function(item,status)assert(status=="PASS");verdicts[item]=true end
local originalPrint=print;print=function()end
'''
checks=r'''
assert(LekmodScenario.step({})==true and reads==6)
assert(verdicts["arrays-Owners"]and verdicts["arrays-read-only"]and verdicts["arrays-boundary-guards"])
local snapshot=LekmodScenario.snapshot({});assert(snapshot.cells==18 and snapshot.rows==6)
native.mask[1][2]=0;assert(not pcall(LekmodScenario.snapshot,{}));native.mask[1][2]=false
native.values[1][2]=0;assert(not pcall(LekmodScenario.snapshot,{}));native.values[1][2]=5
native.list[1]={0,0,-1};assert(not pcall(LekmodScenario.snapshot,{}));native.list[1]={2,-1,0}
assert(LekmodScenarioJSON(LekmodScenario.snapshot({}))==LekmodScenarioJSON(snapshot))
originalPrint("Actual array scenario: defaults/boolean/compact semantics, guards, read-only snapshot and corruption rejection pass")
'''
with tempfile.TemporaryDirectory(prefix='lekmod-array-scenario-')as d:
 p=Path(d)/'test.lua';p.write_text(jsonfn+setup+body+checks)
 raise SystemExit(subprocess.run([str(root/'build/macos/test-deps/lua-5.1.4/src/lua'),str(p)]).returncode)
