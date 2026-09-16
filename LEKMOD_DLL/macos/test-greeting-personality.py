#!/usr/bin/env python3
"""Render the actual greeting personality block for every shipped personality."""
import argparse
import json
from pathlib import Path
import subprocess
import tempfile
import xml.etree.ElementTree as ET

root=Path(__file__).resolve().parents[2]
parser=argparse.ArgumentParser()
parser.add_argument("--greeting",type=Path,default=root/"LEKMOD/Lua/tmp/ui/CityStatePopup/CityStateGreetingPopup.lua.ignore")
args=parser.parse_args()
source=args.greeting.read_text()
start=source.find("\t-- Personality")
if start<0:start=source.index("\t-- Shared data-driven personality text")
end=source.index("\t-- Ally Status",start)
block=source[start:end]
rows=ET.parse(root/"LEKMOD/Override/CIV5Units.xml").getroot().findall("Minor_Civ_Personalities/Row")
entries=[]
for index,row in enumerate(rows):
    values={field:row.findtext(field) for field in ("Type","Description","Help")}
    assert all(values.values())
    entries.append("{"+",".join(key+"="+json.dumps(value) for key,value in values.items())+",ordinal="+str(index)+"}")
lua='''
local rows={'''+",".join(entries)+'''}
GameInfo={Minor_Civ_Personalities={}}
for _,row in ipairs(rows) do GameInfo.Minor_Civ_Personalities[row.Type]=row end
Locale={ConvertTextKey=function(key) return key end}
MinorCivPersonalityTypes={MINOR_CIV_PERSONALITY_FRIENDLY=0,MINOR_CIV_PERSONALITY_NEUTRAL=1,MINOR_CIV_PERSONALITY_HOSTILE=2,MINOR_CIV_PERSONALITY_IRRATIONAL=3}
assert(loadfile(arg[1]))()
local failures=0
for _,row in ipairs(rows) do
 local text,tip,labelTip
 local pPlayer={IsMinorCiv=function()return true end,GetMinorCivPersonalityType=function()return row.Type end,GetPersonality=function()return row.ordinal end}
 Controls={PersonalityInfo={SetText=function(_,v)text=v end,SetToolTipString=function(_,v)tip=v end},PersonalityLabel={SetToolTipString=function(_,v)labelTip=v end}}
 local function render()
'''+block+'''
 end
 local ok,err=pcall(function()
  render()
  assert(text and string.find(text,row.Description,1,true),"personality name is blank/wrong")
  assert(tip and tip~="" and labelTip==tip,"personality tooltip is blank/inconsistent")
 end)
 print((ok and "PASS " or "FAIL ")..row.Type..(ok and "" or " "..tostring(err)))
 if not ok then failures=failures+1 end
end
print(#rows.." greeting personality cases; "..failures.." failures")
os.exit(failures==0 and 0 or 1)
'''
with tempfile.TemporaryDirectory(prefix="lekmod-greeting-test-") as directory:
    path=Path(directory)/"test.lua";path.write_text(lua)
    raise SystemExit(subprocess.run([str(root/"build/macos/test-deps/lua-5.1.4/src/lua"),str(path),str(root/"LEKMOD/Lua/UI/CityStatePersonalityHelper.lua")]).returncode)
