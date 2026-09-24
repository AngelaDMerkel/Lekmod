-- Uses an actually purchased College or purchases it normally in the loaded city.
-- Research prerequisites and a Great Engineer are inputs. Improvement completion,
-- unit consumption, and the College's science/faith rewards must be native outcomes.
LekmodScenario={name="israel-college-reward",items={"college-reward-acquisition","college-great-person-build","college-expended-science","college-expended-faith","college-reward-foreign"}}
local phase,before,plotID,unitID,finished,reply,bought="init",nil,nil,nil,false,false,false
local building=GameInfoTypes.BUILDING_ISRAEL_NATIONAL_COLLEGE
local tech=GameInfoTypes.TECH_IRON_WORKING
local build=GameInfoTypes.BUILD_MANUFACTORY
local reward
local function economy(p)
 return {gold=p:GetGold(),faith=p:GetFaith(),culture=p:GetJONSCulture(),research=p:GetCurrentResearch(),progress=Teams[p:GetTeam()]:GetTeamTechs():GetResearchProgress(tech),overflow=p:GetOverflowResearch()}
end
function LekmodScenario.snapshot(player)
 local cities,plots,units={},{},{}
 for c in player:Cities()do cities[c:GetID()]={x=c:GetX(),y=c:GetY(),college=c:GetNumRealBuilding(building),capital=c:IsCapital(),population=c:GetPopulation()}end
 for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
  if q:GetOwner()==0 and q:GetImprovementType()==GameInfoTypes.IMPROVEMENT_MANUFACTORY then plots[i]={owner=q:GetOwner(),improvement=q:GetImprovementType(),pillaged=q:IsImprovementPillaged()}end
 end
 for u in player:Units()do if not u:IsDead()and not u:IsDelayedDeath()then units[u:GetID()]={type=u:GetUnitType(),x=u:GetX(),y=u:GetY()}end end
 return {turn=Game.GetGameTurn(),human=economy(player),foreign=economy(Players[3]),cities=cities,plots=plots,units=units}
end
LuaEvents.LekmodScenarioCityResponse.Add(function(action,id)if action=="purchase"and id==building then reply=true end end)
GameEvents.CityConstructed.Add(function(owner,city,b,gold,faith)if owner==0 and b==building then assert(gold and not faith);bought=true end end)
GameEvents.BuildFinished.Add(function(owner,x,y,improvement)
 if owner==0 and improvement==GameInfoTypes.IMPROVEMENT_MANUFACTORY then finished=true;LekmodScenarioEvent("native-college-great-person-build",{x=x,y=y,improvement=improvement})end
end)
function LekmodScenario.step(p)
 assert(p:GetCivilizationType()==GameInfoTypes.CIVILIZATION_ISRAEL)
 local c=assert(p:GetCapitalCity())
 if phase=="init"then
  local count=0;for owned in p:Cities()do count=count+owned:GetNumRealBuilding(building)end
  assert(count==0 or count==1)
  if count==0 then
   LekmodScenarioGrantTech(p,"TECH_PHILOSOPHY")
   for owned in p:Cities()do owned:SetNumRealBuilding(GameInfoTypes.BUILDING_LIBRARY,1)end
   local cost=c:GetBuildingPurchaseCost(building);assert(cost>0);p:ChangeGold(cost)
   assert(c:IsCanPurchase(true,true,-1,building,-1,YieldTypes.YIELD_GOLD))
   LekmodScenarioEvent("fixture-setup",{operation="provided-Libraries-and-gold",gold_added=cost,city=c:GetID()})
   LuaEvents.LekmodScenarioBuildingPurchase(c:GetID(),building);phase="purchase"
  else phase="research"end
 elseif phase=="purchase"then
  if not reply then return false end
  if not LekmodScenarioAwait("reward-College-purchased",bought and c:GetNumRealBuilding(building)==1)then return false end
  phase="research"
 elseif phase=="research"then
  assert(c:GetNumRealBuilding(building)==1,"College must be in the surviving capital")
  local cities={};for owned in p:Cities()do cities[#cities+1]=owned:GetID()end
  LekmodScenarioEvent("college-reward-city-slots",{ids=cities,count=p:GetNumCities(),slot_zero_present=p:GetCityByID(0)~=nil})
  LekmodScenarioRecord("college-reward-acquisition","PASS","College came from normal purchase in this run or pinned purchase checkpoint; city="..c:GetID())
  for row in GameInfo.Technology_PrereqTechs{TechType="TECH_IRON_WORKING"}do LekmodScenarioGrantTech(p,row.PrereqTech)end
  reward=math.floor(75*GameInfo.GameSpeeds[Game.GetGameSpeedType()].TrainPercent/100)
  assert(reward>0 and p:CanResearch(tech)and not Teams[p:GetTeam()]:GetTeamTechs():HasTech(tech))
  assert(p:GetResearchCost(tech)-Teams[p:GetTeam()]:GetTeamTechs():GetResearchProgress(tech)>reward,"reward would complete chosen research")
  Network.SendResearch(tech,0,-1,false);phase="selected"
 elseif phase=="selected"then
  if not LekmodScenarioAwait("reward-research-selected",p:GetCurrentResearch()==tech)then return false end
  local plot
  for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
   if q:GetOwner()==0 and not q:IsCity()and not q:IsWater()and not q:IsMountain()and q:GetImprovementType()==-1 and q:GetNumUnits()==0 and q:CanBuild(build,0,false,true)then plot=q;break end
  end
  assert(plot,"no legal Manufactory site");plotID=plot:GetPlotIndex()
  local u=assert(p:InitUnit(GameInfoTypes.UNIT_ENGINEER,plot:GetX(),plot:GetY()));unitID=u:GetID()
  LekmodScenarioEvent("fixture-setup",{operation="provided-Great-Engineer",unit=unitID,x=plot:GetX(),y=plot:GetY()})
  assert(u:CanBuild(plot,build));before=LekmodScenario.snapshot(p)
  UI.SelectUnit(u);local action;for id=0,#GameInfoActions do if GameInfoActions[id]and GameInfoActions[id].Type=="BUILD_MANUFACTORY"then action=id;break end end
  assert(action and Game.CanHandleAction(action));Game.HandleAction(action);phase="reward"
 elseif phase=="reward"then
  local plot=Map.GetPlotByIndex(plotID);local u=p:GetUnitByID(unitID)
  if not LekmodScenarioAwait("reward-native-build",finished and plot:GetImprovementType()==GameInfoTypes.IMPROVEMENT_MANUFACTORY and(not u or u:IsDead()or u:IsDelayedDeath()))then return false end
  local after=LekmodScenario.snapshot(p);LekmodScenarioEvent("college-expended-reward",{before=before.human,after=after.human,expected=reward})
  LekmodScenarioRecord("college-great-person-build","PASS","normal Manufactory action; real BuildFinished; supplied Engineer consumed")
  assert(after.human.progress==before.human.progress+reward and after.human.overflow==before.human.overflow,"College science reward differs: expected="..reward.." actual="..(after.human.progress-before.human.progress))
  LekmodScenarioRecord("college-expended-science","PASS","native research delta="..reward.."; overflow unchanged")
  assert(after.human.faith==before.human.faith+reward,"College faith reward differs")
  LekmodScenarioRecord("college-expended-faith","PASS","native faith delta="..reward)
  assert(LekmodScenarioJSON(before.foreign)==LekmodScenarioJSON(after.foreign),"foreign owner received reward")
  LekmodScenarioRecord("college-reward-foreign","PASS","foreign balances and research unchanged")
  return true
 end
 return false
end
