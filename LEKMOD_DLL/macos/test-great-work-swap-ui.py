#!/usr/bin/env python3
"""Execute actual swap-selection and dropdown functions with varied database IDs."""
import argparse
from pathlib import Path
import subprocess
import tempfile

root=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--source',type=Path,default=root/'LEKMOD/Lua/tmp/ui/CultureOverview/CultureOverview.lua.ignore')
p.add_argument('--lua',type=Path,default=root/'build/macos/test-deps/lua-5.1.4/src/lua')
a=p.parse_args();source=a.source.read_text()
selection=source[source.index('local g_iTheirItem = -1;'):source.index('Controls.SwapButton:RegisterCallback')]
refresh=source[source.index('function RefreshSwappingItems()'):source.index('function DisplayOthersWorks ()')]
product=selection+'\n'+refresh+'\nreturn {select=SelectOthersWork,selectOwn=SelectYourWork,refresh=RefreshSwappingItems,state=function()return g_iYourItem,g_iTheirItem,g_iTradingPartner end}'
harness=r'''
local product=assert(arg[1]);local failed,total=0,0
local layouts={{1,2,3,4},{0,1,2,3},{17,4,0,9}}
local labels={"ART","ARTIFACT","LITERATURE","MUSIC"}
local textures={"GreatWorks.dds","GreatWorks.dds","GreatWorks_Book.dds","GreatWorks_Music.dds"}
local function fixture(ids)
 local e=setmetatable({},{__index=_G});e._G=e
 local function control()
  local c={entries={},emptyTexture=false}
  function c:SetDisabled(v)self.disabled=v end;function c:SetTexture(v)self.texture=v;if v==""then self.emptyTexture=true end end
  function c:SetHide(v)self.hidden=v end;function c:SetToolTipString(v)self.tooltip=v end
  function c:SetVoids(a,b)self.voids={a,b}end;function c:GetButton()return self end
  function c:ClearEntries()self.entries={}end
  function c:BuildEntry(_,instance)
   for _,name in ipairs({"Name","CivIcon","CivIconBG","CivIconShadow","CivIconHighlight","Era","Theming","Button"})do instance[name]=control()end
   self.entries[#self.entries+1]=instance.Button
  end
  function c:RegisterSelectionCallback(fn)self.selection=fn end
  return setmetatable(c,{__index=function()return function()end end})
 end
 e.Controls=setmetatable({},{__index=function(t,k)local c=control();rawset(t,k,c);return c end})
 e.Controls.SwapButton:SetDisabled(true)
 e.Locale={Lookup=function(s)return s end};e.IconHookup=function()end;e.CivIconHookup=function()end
 e.GameInfoTypes={};for i,label in ipairs(labels)do e.GameInfoTypes['GREAT_WORK_'..label]=ids[i]end
 e.GameInfo={Leaders={[0]={PortraitIndex=0,IconAtlas='test'}}}
 local offered={};for i=1,4 do offered[i]=10+i end
 local function player(owner)
  local p={}
  function p:GetLeaderType()return 0 end;function p:GetCivilizationShortDescription()return 'civilization'..owner end
  function p:GetSwappableGreatArt()return offered[1]end;function p:GetSwappableGreatArtifact()return offered[2]end
  function p:GetSwappableGreatWriting()return offered[3]end;function p:GetSwappableGreatMusic()return offered[4]end
  function p:GetGreatWorks(class)
   for i,id in ipairs(ids)do if id==class then return {{Index=10+i,Creator=0}}end end;return {}
  end
  return p
 end
 e.Players={[0]=player(0),[1]=player(1)}
 e.Game={GetActivePlayer=function()return 0 end,GetGreatWorkClass=function(id)return ids[id%10]end,
  GetGreatWorkCreator=function(id)return id>20 and 1 or 0 end,GetGreatWorkController=function(id)return id>20 and 1 or 0 end,
  GetGreatWorkEraShort=function()return 'era'end,GetGreatWorkTooltip=function()return 'tooltip'end,
  GetGreatWorkName=function(id)return 'work'..id end,GetGreatWorkCurrentThemingBonus=function()return 0 end}
 e.Network={SendSetSwappableGreatWork=function(owner,class,id)e.last_offer={owner,class,id}end,SendSwapGreatWorks=function(...)e.swap={...}end}
 local chunk=assert(loadfile(product));setfenv(chunk,e);local api=chunk()
 return e,api
end
local function test(name,fn)
 total=total+1;local ok,err=pcall(fn);if not ok then failed=failed+1;print('FAIL '..name..': '..tostring(err))end
end
for layout,ids in ipairs(layouts)do
 for kind=1,4 do test('selection layout'..layout..' '..labels[kind],function()
  local e,api=fixture(ids);api.select(20+kind);local ours,theirs,partner=api.state()
  assert(ours==10+kind and theirs==20+kind and partner==1,'wrong offered class selected')
  assert(e.Controls.SwapButton.disabled==false,'eligible swap stayed disabled')
  assert(e.Controls.SwapOursIcon.texture==textures[kind]and e.Controls.SwapTheirsIcon.texture==textures[kind],'wrong or empty work icon texture')
 end)end
 test('no matching offer layout'..layout,function()
  local e,api=fixture(ids);e.Players[0].GetSwappableGreatArt=function()return -1 end
  api.select(21);local ours=api.state();assert(ours==-1 and e.Controls.SwapButton.disabled==true,'no matching offer enabled swap')
 end)
 test('unknown class texture guard layout'..layout,function()
  local e,api=fixture(ids);e.Game.GetGreatWorkClass=function()return 99 end
  api.select(29);api.selectOwn(19)
  assert(not e.Controls.SwapTheirsIcon.emptyTexture and not e.Controls.SwapOursIcon.emptyTexture,'unknown class submitted empty texture name')
  assert(e.Controls.SwapButton.disabled==true,'unknown class enabled swap')
 end)
 for _,choice in ipairs({{'YourArtPullDown',1},{'YourArtifactPullDown',2},{'YourWritingPullDown',3}})do
  test('dropdown layout'..layout..' '..choice[1],function()
   local e,api=fixture(ids);api.refresh();local c=e.Controls[choice[1]]
   assert(#c.entries==2,'expected clear entry and owned work')
   assert(c.entries[1].voids[1]==ids[choice[2]]and c.entries[1].voids[2]==-1,'clear uses wrong class')
   local args=c.entries[2].voids;assert(args[1]==ids[choice[2]]and args[2]==10+choice[2],'dropdown shows wrong class')
   c.selection(args[1],args[2]);assert(e.last_offer[1]==0 and e.last_offer[2]==ids[choice[2]]and e.last_offer[3]==10+choice[2],'offer command has wrong class')
  end)
 end
end
print(total..' actual swap UI class/texture/offer cases; '..failed..' failures')
os.exit(failed==0 and 0 or 1)
'''
with tempfile.TemporaryDirectory(prefix='lekmod-swap-ui-') as d:
    actual=Path(d)/'actual.lua';test=Path(d)/'test.lua';actual.write_text(product);test.write_text(harness)
    raise SystemExit(subprocess.run([str(a.lua),str(test),str(actual)]).returncode)
