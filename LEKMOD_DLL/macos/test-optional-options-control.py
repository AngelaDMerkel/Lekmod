#!/usr/bin/env python3
"""Execute the actual optional AI-deals UI statements with present/missing controls."""
from pathlib import Path
import argparse,re,subprocess,tempfile
root=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser(description=__doc__);p.add_argument('--source',type=Path,default=root/'LEKMOD/Lua/tmp/ui/Lobby/MPGameOptions.lua.ignore');a=p.parse_args()
s=a.source.read_text();name='AICannotHaveWealsWithHumans'
functions=[]
for fn in ['Set'+name+'Option','On'+name+'Checked']:
 m=re.search(r'function '+fn+r'\(\)\n.*?\nend',s,re.S);assert m,fn;functions.append(m.group())
lines=[l.strip()for l in s.splitlines()if 'Controls.'+name in l and any(x in l for x in [':SetHide(',':SetDisabled(',':SetCheck(',':RegisterCallback('])]
assert len(lines)==7,len(lines)
code='''local cases,failed=0,0
local function run(name,fn)cases=cases+1;local ok,err=pcall(fn);if not ok then failed=failed+1;print('FAIL '..name..': '..tostring(err))end end
'''
chunks=lines+[ '\n'.join(functions)+'\n'+lines[-1]+'\nOn'+name+'Checked()']
for index,chunk in enumerate(chunks):
 for has_check in (False,True):
  for has_box in (False,True):
   for checked in (False,True):
    q=lambda v:'true'if v else'false'
    code+=f'''run('fragment{index} check{has_check} box{has_box} checked{checked}',function()
local e=setmetatable({{}},{{__index=_G}});e.Controls={{}};e.Mouse={{eLClick=1}};e.isChecked={q(checked)};e.bCanEdit=true
local control={{writes=0}};function control:SetHide(v)self.hidden=v;self.writes=self.writes+1 end
function control:SetDisabled(v)self.disabled=v;self.writes=self.writes+1 end
function control:SetCheck(v)self.checked=v;self.writes=self.writes+1 end
function control:IsChecked()return {q(checked)} end
function control:RegisterCallback(event,fn)assert(event==1);self.callback=fn end
if {q(has_check)} then e.Controls.{name}Check=control end
if {q(has_box)} then e.Controls.{name}Box=control end
local value='unchanged';local updates,broadcasts=0,0
e.PreGame={{SetGameOption=function(key,v)assert(key=='GAMEOPTION_AI_GIMP_NO_DEALS');value=v end}}
e.UpdateGameOptionsDisplay=function()updates=updates+1 end;e.SendGameOptionChanged=function()broadcasts=broadcasts+1 end
local chunk=assert(loadstring([==[{chunk}]==]));setfenv(chunk,e);chunk()
'''
    if index==len(chunks)-1:
     code+=f"assert(value=={q(checked)} and updates==1 and broadcasts==1 and control.callback)\n"if has_check else "assert(value=='unchanged'and updates==0 and broadcasts==0 and not control.callback)\n"
    if ':SetHide( not Controls.' in chunk and has_box and not has_check:code+='assert(control.hidden==true)\n'
    code+='end)\n'
code+="print(cases..' optional-control cases; '..failed..' failures');os.exit(failed==0 and 0 or 1)\n"
with tempfile.TemporaryDirectory(prefix='lekmod-optional-control-')as d:
 script=Path(d)/'test.lua';script.write_text(code)
 raise SystemExit(subprocess.run([str(root/'build/macos/test-deps/lua-5.1.4/src/lua'),str(script)]).returncode)
