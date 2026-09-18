#!/usr/bin/env python3
"""Execute Italy's product policy handler across player and bonus boundaries."""
import argparse
from pathlib import Path
import subprocess,tempfile
root=Path(__file__).resolve().parents[2]
parser=argparse.ArgumentParser();parser.add_argument('--source-root',type=Path,default=root);args=parser.parse_args()
script=r'''
include=function()end
GameInfoTypes={CIVILIZATION_ITALY=1}
GameInfo={Policies={[1]={PolicyBranchType='TRADITION'},[2]={}},PolicyBranchTypes={TRADITION={ID=3}},GameSpeeds={[0]={GoldenAgePercent=67}}}
LekmodUtilities={is_civilization_active=function()return true end}
Game={GetActivePlayer=function()return 0 end,GetGameSpeedType=function()return 0 end}
local callback,alerts
GameEvents={PlayerAdoptPolicy={Add=function(fn)callback=fn end}}
Locale={ConvertTextKey=function(...)return 'alert' end}
Events={GameplayAlertMessage=function()alerts=alerts+1 end}
local function player(id,civ,human)
 local p={alive=true,owned=true,finished=true,golden=false,points=0,turns=0}
 function p:IsEverAlive()return true end
 function p:IsAlive()return self.alive end
 function p:GetCivilizationType()return civ end
 function p:IsHuman()return human end
 function p:GetID()return id end
 function p:HasPolicy()return self.owned end
 function p:IsPolicyBranchFinished()return self.finished end
 function p:IsGoldenAge()return self.golden end
 function p:ChangeGoldenAgeTurns(n)self.turns=self.turns+math.floor(n)end
 function p:ChangeGoldenAgeProgressMeter(n)self.points=self.points+math.floor(n)end
 return p
end
assert(loadfile(arg[1]))()
local count,failed=0,0
local function check(name,fn)
 GameInfo.GameSpeeds[0].GoldenAgePercent=67;Players={[0]=player(0,1,true),[1]=player(1,1,false),[2]=player(2,2,false)};alerts=0
 count=count+1;local ok,err=pcall(fn);if not ok then failed=failed+1 end
 print((ok and 'PASS ' or 'FAIL ')..name..(ok and '' or ' '..tostring(err)))
end
check('human-completion-points',function()callback(0,1);assert(Players[0].points==209 and alerts==1)end)
check('AI-completion-points-without-human-alert',function()callback(1,1);assert(Players[1].points==209 and alerts==0)end)
check('human-golden-extension',function()Players[0].golden=true;callback(0,1);assert(Players[0].turns==3 and Players[0].points==0 and alerts==1)end)
check('AI-golden-extension-without-human-alert',function()Players[1].golden=true;callback(1,1);assert(Players[1].turns==3 and Players[1].points==0 and alerts==0)end)
check('unfinished-branch-no-reward',function()Players[0].finished=false;callback(0,1);assert(Players[0].points==0 and alerts==0)end)
check('unowned-policy-no-reward',function()Players[0].owned=false;callback(0,1);assert(Players[0].points==0 and alerts==0)end)
check('branchless-policy-no-reward',function()callback(0,2);assert(Players[0].points==0 and alerts==0)end)
check('other-civilization-no-reward',function()callback(2,1);assert(Players[2].points==0 and alerts==0)end)
check('shipped-Quick-80-percent-points',function()GameInfo.GameSpeeds[0].GoldenAgePercent=80;callback(1,1);assert(Players[1].points==250 and alerts==0)end)
check('shipped-Quick-80-percent-extension',function()GameInfo.GameSpeeds[0].GoldenAgePercent=80;Players[1].golden=true;callback(1,1);assert(Players[1].turns==4 and alerts==0)end)
print(count..' cases, '..failed..' failures');os.exit(failed==0 and 0 or 1)
'''
with tempfile.TemporaryDirectory(prefix='lekmod-italy-events-') as d:
 p=Path(d)/'test.lua';p.write_text(script)
 raise SystemExit(subprocess.run([str(root/'build/macos/test-deps/lua-5.1.4/src/lua'),str(p),str(args.source_root/'LEKMOD/Lua/Civilizations/Lekmod_italy.lua')]).returncode)
