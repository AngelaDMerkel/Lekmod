-- Supplied unit positions create one legal exploration boundary. The first
-- meeting uses a normal human move. Later contacts use the engine Meet API
-- explicitly as fixture input; no product callback or random result is assigned.
local researchMode=LekmodNZSelectedResearch==true
local selectedScience=false
LekmodScenario={name=researchMode and "newzealand-research"or"newzealand-meeting",items={"valid-distinct-player-colors","NZ-movement-first-contact","NZ-both-owner-rewards","NZ-native-reward-branches","NZ-meeting-no-repeat","NZ-Roman-no-reward"}}
if researchMode then table.insert(LekmodScenario.items,"NZ-selected-research-science")end
local phase="init"
local unitID,targetPlot,before,eventBefore,contacts,contactIndex= nil,nil,nil,nil,{},1
local events,branches={},{}
local actualContacts=0
local function balance(p)
 local result={gold=p:GetGold(),faith=p:GetFaith(),culture=p:GetJONSCulture(),science=p:GetOverflowResearch(),research=p:GetCurrentResearch()}
 if researchMode then
  result.overflow=p:GetOverflowResearch()
  result.progress=result.research>=0 and Teams[p:GetTeam()]:GetTeamTechs():GetResearchProgress(result.research)or 0
  result.science=result.overflow+result.progress
 end
 return result
end
local function allBalances()
 local result={};for id=0,11 do assert(Players[id]and Players[id]:IsAlive(),"twelve live major slots required");result[id]=balance(Players[id])end;return result
end
local function reward(old,new,owner,expected)
 assert(old.research==new.research and(researchMode or old.research==-1),"meeting unexpectedly changed or completed selected research")
 local changed,kind=0,nil
 for _,key in ipairs({"gold","faith","culture","science"})do
  local delta=new[key]-old[key]
  if delta~=0 then
   assert(expected,"Roman or unrelated owner received a meeting reward")
   local amount=({gold=40,faith=10,culture=6,science=12})[key]
   assert(delta==amount,"native meeting reward amount differs")
   changed=changed+1;kind=key
  end
 end
 assert(changed==(expected and 1 or 0),"meeting awarded the wrong number of reward types")
 if kind=="science"and researchMode then
  if owner==0 then assert(new.progress-old.progress==12 and new.overflow==old.overflow,"selected research did not receive exactly12 science");selectedScience=true
  else assert(new.research==-1 and new.overflow-old.overflow==12,"AI no-research overflow reward differs")end
 end
 if kind then branches[kind]=true;LekmodScenarioEvent("NZ-native-meeting-reward",{owner=owner,kind=kind,before=old,after=new})end
end
GameEvents.TeamMeet.Add(function(a,b)
 events[#events+1]={a=a,b=b};LekmodScenarioEvent("native-TeamMeet",{a=a,b=b,number=#events})
end)
local function verifyPair(a,b,old,count)
 assert(#events==count+1,"expected exactly one native TeamMeet event")
 local e=events[#events];local ta=Players[a]:GetTeam();local tb=Players[b]:GetTeam()
 assert((e.a==ta and e.b==tb)or(e.a==tb and e.b==ta),"native meeting team IDs differ")
 local after=allBalances()
 for id=0,11 do reward(old[id],after[id],id,(id==a or id==b)and Players[id]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_NEW_ZEALAND)end
 assert(Teams[ta]:IsHasMet(tb)and Teams[tb]:IsHasMet(ta),"engine did not persist mutual contact")
 actualContacts=actualContacts+1
 return after
end
function LekmodScenario.snapshot(player)
 local owners={}
 for id=0,11 do local p=Players[id];local known={}
  for other=0,11 do known[other]=Teams[p:GetTeam()]:IsHasMet(Players[other]:GetTeam())end
  owners[id]={civilization=p:GetCivilizationType(),color=p:GetPlayerColor(),balance=balance(p),contacts=known}
 end
 return {turn=Game.GetGameTurn(),owners=owners}
end
local function bare(p)return p and p:GetOwner()==-1 and p:GetNumUnits()==0 and not p:IsWater()and not p:IsMountain()and not p:IsHills()and p:GetFeatureType()<0 end
local function isolated(p)
 for owner=0,11 do for u in Players[owner]:Units()do
  if Map.PlotDistance(p:GetX(),p:GetY(),u:GetX(),u:GetY())<=6 then return false end
 end end
 return true
end
function LekmodScenario.step(player)
 assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_NEW_ZEALAND and Players[1]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_NEW_ZEALAND)
 for id=2,11 do assert(Players[id]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_ROME)end
 if researchMode and phase=="init"and not player:GetCapitalCity()then
  for u in player:Units()do if GameInfo.Units[u:GetUnitType()].Found and u:CanFound(u:GetPlot())then
   UI.SelectUnit(u);for i=0,#GameInfoActions do if GameInfoActions[i]and GameInfoActions[i].Type=="MISSION_FOUND"then
    assert(Game.CanHandleAction(i));Game.HandleAction(i);phase="founding";return false
   end end
  end end
  error("normal Found action unavailable for research prerequisite")
 end
 if phase=="founding"then if not LekmodScenarioAwait("NZ-capital-founded",player:GetCapitalCity()~=nil)then return false end;phase="init"end
 if phase=="init"then
  local colors,seen={},{}
  for id=0,11 do local color=Players[id]:GetPlayerColor();local entry=GameInfo.PlayerColors[color]
   assert(entry and GameInfo.Colors[entry.PrimaryColor]and GameInfo.Colors[entry.SecondaryColor]and GameInfo.Colors[entry.TextColor],"invalid native player color")
   assert(not seen[color],"duplicate resolved player color");seen[color]=true;colors[id]={id=color,type=entry.Type}
  end
  LekmodScenarioEvent("native-player-colors",colors)
  LekmodScenarioRecord("valid-distinct-player-colors","PASS","twelve duplicate-civilization players use distinct existing color rows and valid components")
  assert(not Teams[player:GetTeam()]:IsHasMet(Players[1]:GetTeam()),"NZ players already met before movement fixture")
  for owner=0,11 do assert(Players[owner]:GetCurrentResearch()==-1,"fresh pre-research opening required")end
  local start,foreign
  for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i)
   if bare(p)and isolated(p)then
    for d=0,5 do local q=Map.PlotDirection(p:GetX(),p:GetY(),d);local r=q and Map.PlotDirection(q:GetX(),q:GetY(),d);local s=r and Map.PlotDirection(r:GetX(),r:GetY(),d)
     if bare(q)and bare(r)and bare(s)and not s:IsVisible(player:GetTeam())and not p:IsVisible(Players[1]:GetTeam())then start=p;targetPlot=q;foreign=s;break end
    end
   end
   if start then break end
  end
  assert(start and foreign,"no isolated legal three-to-two sight boundary")
  local foreignUnit=assert(Players[1]:InitUnit(GameInfoTypes.UNIT_WARRIOR,foreign:GetX(),foreign:GetY()))
  local u=assert(player:InitUnit(GameInfoTypes.UNIT_SCOUT,start:GetX(),start:GetY()));unitID=u:GetID()
  LekmodScenarioEvent("fixture-setup",{operation="provided-isolated-meeting-units",human_unit=unitID,AI_unit=foreignUnit:GetID(),human_x=start:GetX(),human_y=start:GetY(),AI_x=foreign:GetX(),AI_y=foreign:GetY()})
  assert(not Teams[player:GetTeam()]:IsHasMet(Players[1]:GetTeam()),"unit setup already caused first contact")
  if researchMode then
   for row in GameInfo.Technology_PrereqTechs{TechType="TECH_ASTRONOMY"}do LekmodScenarioGrantTech(player,row.PrereqTech)end
   local tech=GameInfoTypes.TECH_ASTRONOMY
   LekmodScenarioEvent("NZ-research-gates",{cities=player:GetNumCities(),can_research=player:CanResearch(tech),cost=player:GetResearchCost(tech),progress=Teams[player:GetTeam()]:GetTeamTechs():GetResearchProgress(tech)})
   assert(player:CanResearch(tech)and player:GetResearchCost(tech)-Teams[player:GetTeam()]:GetTeamTechs():GetResearchProgress(tech)>132,"research target must fit every possible meeting reward without completing")
   LekmodScenarioEvent("fixture-setup",{operation="provided-research-prerequisites-and-selected-target",target=tech,cost=player:GetResearchCost(tech)})
   Network.SendResearch(tech,0,-1,false);phase="research-selected"
  else phase="move"end
  return false
 elseif phase=="research-selected"then
  if not LekmodScenarioAwait("NZ-Astronomy-selected",player:GetCurrentResearch()==GameInfoTypes.TECH_ASTRONOMY)then return false end
  phase="move";return false
 elseif phase=="move"then
  local u=assert(player:GetUnitByID(unitID));assert(u:GetMoves()>0 and u:CanMoveOrAttackInto(targetPlot))
  before=allBalances();eventBefore=#events
  UI.SelectUnit(u);Game.SelectionListGameNetMessage(GameMessageTypes.GAMEMESSAGE_PUSH_MISSION,MissionTypes.MISSION_MOVE_TO,targetPlot:GetX(),targetPlot:GetY(),0,false,false)
  phase="moved";return false
 elseif phase=="moved"then
  local u=assert(player:GetUnitByID(unitID))
  if not LekmodScenarioAwait("NZ-first-contact-movement",u:GetX()==targetPlot:GetX()and u:GetY()==targetPlot:GetY())then return false end
  verifyPair(0,1,before,eventBefore)
  LekmodScenarioRecord("NZ-movement-first-contact","PASS","normal synchronized Scout movement produced mutual contact and native TeamMeet")
  LekmodScenarioRecord("NZ-both-owner-rewards","PASS","human and AI New Zealand each received exactly one valid reward; unrelated Romans unchanged")
  for owner=0,1 do for other=2,11 do if not Teams[Players[owner]:GetTeam()]:IsHasMet(Players[other]:GetTeam())then contacts[#contacts+1]={owner,other}end end end
  assert(#contacts>=8,"insufficient distinct unmet controls for reward sampling")
  phase="contacts";return false
 elseif phase=="contacts"then
  local pair=contacts[contactIndex]
  if pair then
   local a,b=pair[1],pair[2];local old=allBalances();local count=#events
   assert(not Teams[Players[a]:GetTeam()]:IsHasMet(Players[b]:GetTeam()))
   LekmodScenarioEvent("fixture-setup",{operation="provided-native-engine-contact",a=a,b=b})
   Teams[Players[a]:GetTeam()]:Meet(Players[b]:GetTeam(),true)
   verifyPair(a,b,old,count)
   contactIndex=contactIndex+1;return false
  end
  LekmodScenarioEvent("NZ-observed-reward-branches",{branches=branches,contacts=actualContacts})
  assert(branches.gold and branches.faith and branches.culture and branches.science,"this deterministic fixture did not observe all four random reward branches")
  LekmodScenarioRecord("NZ-native-reward-branches","PASS","four naturally drawn reward branches observed; contacts supplied; no RNG or reward setter")
  if researchMode then assert(selectedScience,"selected-research reward not drawn");LekmodScenarioRecord("NZ-selected-research-science","PASS","naturally drawn science rewards add12 to selected research and preserve overflow; AI no-research control uses overflow")end
  before=allBalances();eventBefore=#events
  Teams[player:GetTeam()]:Meet(Players[1]:GetTeam(),true);phase="repeat";return false
 elseif phase=="repeat"then
  assert(#events==eventBefore and LekmodScenarioJSON(allBalances())==LekmodScenarioJSON(before),"known contact emitted another event/reward")
  LekmodScenarioRecord("NZ-meeting-no-repeat","PASS","native Meet on known pair emits no event and no further award")
  local a,b
  for first=2,10 do for second=first+1,11 do if not Teams[Players[first]:GetTeam()]:IsHasMet(Players[second]:GetTeam())then a=first;b=second;break end end;if a then break end end
  assert(a,"no unmet Roman pair for negative control")
  local old=allBalances();local count=#events;Teams[Players[a]:GetTeam()]:Meet(Players[b]:GetTeam(),true);verifyPair(a,b,old,count)
  LekmodScenarioRecord("NZ-Roman-no-reward","PASS","new native Roman/Roman meeting awards nothing to either or unrelated NZ players")
  LekmodScenarioEvent("NZ-meeting-final",LekmodScenario.snapshot(player));return true
 end
 return false
end
