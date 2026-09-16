#!/usr/bin/env python3
"""Run only single-player UI guards; multiplayer behavior remains deferred."""
from pathlib import Path
import subprocess
import tempfile

root=Path(__file__).resolve().parents[2]
source=(root/"LEKMOD/Lua/tmp/ui/VotingSystem/VictoryProgress.lua.ignore").read_text()
chunks=[]
for name in ("UpdateMPProposalVisibility","OnProposeIrr","OnProposeCC","OnProposeScrap"):
    start=source.index("function "+name+"(")
    end=source.index("\nend",start)+4
    chunks.append(source[start:end])
test=r'''
Game={IsGameMultiPlayer=function() return false end}
local hidden={}
Controls=setmetatable({}, {__index=function(_,name)
 return {SetHide=function(_,value) hidden[name]=value end,
         SetDisabled=function() error("single-player callback reached proposal UI mutation") end}
end})
Network=setmetatable({}, {__index=function() return function() error("single-player callback sent a proposal") end end})
LuaEvents=Network
'''+"\n".join(chunks)+r'''
assert(UpdateMPProposalVisibility()==false)
for _,name in ipairs({"MPProposeIrrButton","MPProposeCCButton","MPProposeScrapButton"}) do
 assert(hidden[name]==true,name.." is not hidden")
end
OnProposeIrr();OnProposeCC();OnProposeScrap()
print("Single-player: three proposal controls hidden; three callbacks cannot send network proposals")
'''
with tempfile.TemporaryDirectory(prefix="lekmod-sp-victory-ui-") as directory:
    path=Path(directory)/"test.lua";path.write_text(test)
    subprocess.run([str(root/"build/macos/test-deps/lua-5.1.4/src/lua"),str(path)],check=True)
