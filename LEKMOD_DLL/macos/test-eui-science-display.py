#!/usr/bin/env python3
"""Execute the actual EUI science HUD block and tooltip rate query in Lua 5.1."""
import argparse
from pathlib import Path
import re
import subprocess
import tempfile

root=Path(__file__).resolve().parents[2]
parser=argparse.ArgumentParser()
parser.add_argument('--source',type=Path,default=root/'LEKMOD/Lua/tmp/eui/TopPanel.lua.ignore')
args=parser.parse_args()
source=args.source.read_text()
start=source.index('\t\tlocal sciencePerTurnTimes100 =',source.index('local function UpdateTopPanelNow()'))
end=source.index('\n\t\tif civ5_mode then',start)
block=source[start:end]
tooltip=source[source.index('g_toolTipHandler.SciencePerTurn = function()'):]
expression=re.search(r'local sciencePerTurnTimes100 = ([^\n]+)',tooltip)[1]
lua='''
S=string.format
YieldTypes={YIELD_SCIENCE=3}
g_scienceTextColor="[COLOR_BLUE]"
local cases={
 {name="deficit-exceeds-science",science=0,generic=-1500,deficit=-3900,text="+0"},
 {name="fractional-negative-floor",science=0,generic=-1,deficit=-1201,text="+0"},
 {name="partial-deficit",science=1100,generic=1100,deficit=-100,text="+11"},
 {name="positive-without-deficit",science=1640,generic=1640,deficit=0,text="+16"},
 {name="zero-without-deficit",science=0,generic=0,deficit=0,text="+0"},
}
local failed=0
for _,case in ipairs(cases) do
 g_activePlayer={GetYieldTimes100=function()return case.generic end,
  GetScienceTimes100=function()return case.science end,
  GetScienceFromBudgetDeficitTimes100=function()return case.deficit end}
 local actual
 Controls={SciencePerTurn={SetText=function(_,text)actual=text end}}
 local function update()
'''+block+'''
 end
 local function tooltipRate() return '''+expression+''' end
 local ok,err=pcall(function()
  update()
  local color=case.deficit==0 and g_scienceTextColor or "[COLOR:255:0:60:255]"
  assert(actual==color..case.text.."[ENDCOLOR][ICON_RESEARCH]", "HUD rate differs: "..tostring(actual))
  assert(tooltipRate()==case.science,"tooltip rate differs from actual science")
 end)
 print((ok and "PASS " or "FAIL ")..case.name..(ok and "" or " "..tostring(err)))
 if not ok then failed=failed+1 end
end
print(#cases.." science display cases; "..failed.." failures")
os.exit(failed==0 and 0 or 1)
'''
with tempfile.TemporaryDirectory(prefix='lekmod-science-display-') as tmp:
    p=Path(tmp)/'test.lua';p.write_text(lua)
    raise SystemExit(subprocess.run([str(root/'build/macos/test-deps/lua-5.1.4/src/lua'),str(p)]).returncode)
