-- Native engine first contact awards an unchanged random reward. Prerequisites
-- and all but six research points are supplied; completion/overflow are outcomes.
LekmodScenario={name="newzealand-science-completion",items={"NZ-science-completion","NZ-completion-overflow","NZ-completed-contact-no-repeat"}}
local phase="init"
local tech=GameInfoTypes.TECH_ASTRONOMY
local cost,completedPartner,completedBefore,eventCount=0,nil,nil,0
local contacts=0
local function state(player)
 local t=Teams[player:GetTeam()]:GetTeamTechs();local known={}
 for id=0,11 do known[id]=Teams[player:GetTeam()]:IsHasMet(Players[id]:GetTeam())end
 return {progress=t:GetResearchProgress(tech),known=t:HasTech(tech),current=player:GetCurrentResearch(),overflow=player:GetOverflowResearch(),gold=player:GetGold(),faith=player:GetFaith(),culture=player:GetJONSCulture(),contacts=known}
end
function LekmodScenario.snapshot(player)return {turn=Game.GetGameTurn(),human=state(player),AI=state(Players[1])}end
GameEvents.TeamTechResearched.Add(function(team,id,change)
 if team==Players[Game.GetActivePlayer()]:GetTeam()and id==tech and change>0 then
  eventCount=eventCount+1;LekmodScenarioEvent("native-NZ-reward-tech-completion",{team=team,tech=id,change=change,turn=Game.GetGameTurn()})
 end
end)
function LekmodScenario.step(player)
 assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_NEW_ZEALAND)
 if phase=="init"and not player:GetCapitalCity()then
  for u in player:Units()do if GameInfo.Units[u:GetUnitType()].Found and u:CanFound(u:GetPlot())then
   UI.SelectUnit(u);for i=0,#GameInfoActions do if GameInfoActions[i]and GameInfoActions[i].Type=="MISSION_FOUND"then assert(Game.CanHandleAction(i));Game.HandleAction(i);phase="founding";return false end end
  end end;error("normal Found action required")
 end
 if phase=="founding"then if not LekmodScenarioAwait("NZ-completion-capital",player:GetCapitalCity()~=nil)then return false end;phase="init"end
 local team=Teams[player:GetTeam()];local techs=team:GetTeamTechs()
 if phase=="init"then
  assert(not techs:HasTech(tech)and player:GetCurrentResearch()==-1)
  for row in GameInfo.Technology_PrereqTechs{TechType="TECH_ASTRONOMY"}do LekmodScenarioGrantTech(player,row.PrereqTech)end
  assert(player:CanResearch(tech));cost=player:GetResearchCost(tech);assert(cost>12)
  techs:SetResearchProgress(tech,cost-6,player:GetID())
  LekmodScenarioEvent("fixture-setup",{operation="provided-six-points-short-of-Astronomy",cost=cost,progress=cost-6})
  assert(not techs:HasTech(tech)and eventCount==0,"setup completed target technology")
  Network.SendResearch(tech,0,-1,false);phase="selected";return false
 elseif phase=="selected"then
  if not LekmodScenarioAwait("NZ-completion-research-selected",player:GetCurrentResearch()==tech)then return false end
  phase="contact";return false
 elseif phase=="contact"then
  local other
  for id=2,11 do assert(Players[id]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_ROME)
   if not team:IsHasMet(Players[id]:GetTeam())then other=id;break end
  end
  assert(other,"this fixture exhausted unmet Roman contacts without drawing science")
  local before=state(player);local AIbefore=state(Players[1]);local roman=Players[other]
  local romanBefore={gold=roman:GetGold(),faith=roman:GetFaith(),culture=roman:GetJONSCulture(),overflow=roman:GetOverflowResearch()}
  LekmodScenarioEvent("fixture-setup",{operation="provided-native-engine-contact",human=player:GetID(),other=other})
  team:Meet(roman:GetTeam(),true);contacts=contacts+1
  local after=state(player)
  assert(LekmodScenarioJSON(state(Players[1]))==LekmodScenarioJSON(AIbefore),"unrelated New Zealand owner changed")
  assert(roman:GetGold()==romanBefore.gold and roman:GetFaith()==romanBefore.faith and roman:GetJONSCulture()==romanBefore.culture and roman:GetOverflowResearch()==romanBefore.overflow,"Roman recipient got a reward")
  LekmodScenarioEvent("NZ-completion-contact-result",{contact=contacts,other=other,before=before,after=after,tech_events=eventCount})
  if after.known then
   assert(eventCount==1 and after.progress==before.progress+12,"science reward did not complete through the normal technology path")
   assert(after.gold==before.gold and after.faith==before.faith and after.culture==before.culture,"completion contact also granted another reward")
   assert(after.overflow==before.overflow+6 and after.current==-1,"six excess research points did not enter overflow or completed research remained selected")
   LekmodScenarioRecord("NZ-science-completion","PASS","naturally drawn12science completed Astronomy from supplied cost-minus6; native TeamTechResearched observed")
   LekmodScenarioRecord("NZ-completion-overflow","PASS","exact6science carried to overflow; no gold/faith/culture or other-owner award")
   completedPartner=other;completedBefore=LekmodScenario.snapshot(player);phase="repeat";return false
  end
  assert(after.progress==before.progress and after.overflow==before.overflow and after.current==tech and eventCount==0,"non-science reward changed research")
  local rewards=0
  for key,amount in pairs({gold=40,faith=10,culture=6})do local delta=after[key]-before[key];assert(delta==0 or delta==amount);if delta~=0 then rewards=rewards+1 end end
  assert(rewards==1,"contact granted no valid reward")
  return false
 elseif phase=="repeat"then
  team:Meet(Players[completedPartner]:GetTeam(),true)
  assert(eventCount==1 and LekmodScenarioJSON(LekmodScenario.snapshot(player))==LekmodScenarioJSON(completedBefore),"known contact repeated the completion/reward")
  LekmodScenarioRecord("NZ-completed-contact-no-repeat","PASS","known contact leaves completed technology, progress, overflow and balances unchanged")
  return true
 end
 return false
end
