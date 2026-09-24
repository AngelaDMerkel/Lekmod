-- Baseline with no Vatican religion tests capture followed by a normal Prophet
-- conversion. The pinned St Peter's save tests capture of an already converted
-- city. Provided religion/conversion, cities, units and resources are inputs.
LekmodScenario={name="vatican-courthouse",items={"vatican-foreign-owner-control","vatican-real-capture","vatican-courthouse-gate","vatican-courthouse-award","vatican-annex-preservation"}}
local phase,religion,convertedBefore,x,y,sent,captured,spread,converted,annexed="init",nil,nil,nil,nil,false,false,false,false,false
local court=GameInfoTypes.BUILDING_COURTHOUSE
local function city()return assert(Map.GetPlot(x,y):GetPlotCity())end
function LekmodScenario.snapshot(player)
 local owners={}
 for owner=0,3 do local p=Players[owner];local cities,units={},{}
  for c in p:Cities()do cities[c:GetID()]={x=c:GetX(),y=c:GetY(),original=c:GetOriginalOwner(),population=c:GetPopulation(),majority=c:GetReligiousMajority(),puppet=c:IsPuppet(),occupied=c:IsOccupied(),court=c:GetNumRealBuilding(court),relief=c:IsNoOccupiedUnhappiness(),resistance=c:GetResistanceTurns()}end
  for u in p:Units()do if not u:IsDead()and not u:IsDelayedDeath()and u:GetReligion()>0 then units[u:GetID()]={type=u:GetUnitType(),religion=u:GetReligion(),spreads=u:GetSpreadsLeft(),x=u:GetX(),y=u:GetY()}end end
  owners[owner]={religion=p:GetReligionCreatedByPlayer(),cities=cities,units=units,happiness=p:GetExcessHappiness()}
 end
 return {turn=Game.GetGameTurn(),owners=owners,war=Teams[Players[0]:GetTeam()]:IsAtWar(Players[1]:GetTeam())}
end
GameEvents.CityCaptureComplete.Add(function(old,capital,cx,cy,new,pop,conquest)
 if old==0 and new==1 and cx==x and cy==y then assert(capital and conquest and sent);captured=true;LekmodScenarioEvent("native-Vatican-capture",{x=cx,y=cy,population=pop,majority=city():GetReligiousMajority()})end
end)
GameEvents.CityConvertsReligion.Add(function(owner,r,cx,cy)
 if owner==1 and r==religion and cx==x and cy==y then converted=true;LekmodScenarioEvent("native-Vatican-conversion",{owner=owner,religion=r,x=cx,y=cy})end
end)
local function adjacent()
 for d=0,5 do local q=Map.PlotDirection(x,y,d)
  if q and not q:IsWater()and not q:IsMountain()and not q:IsCity()and q:GetNumUnits()==0 then return q end
 end
 error("no eligible staging tile")
end
GameEvents.PlayerDoTurn.Add(function(owner)
 if owner~=1 then return end
 local p=Players[1]
 if phase=="capture"and not sent then
  assert(p:IsTurnActive()and not p:IsHuman());local q=adjacent();p:ChangeGold(1000);p:ChangeNumResourceTotal(GameInfoTypes.RESOURCE_URANIUM,1)
  local u=assert(p:InitUnit(GameInfoTypes.UNIT_MECH,q:GetX(),q:GetY()))
  LekmodScenarioEvent("fixture-setup",{operation="provided-Vatican-attacker",unit=u:GetID(),gold_added=1000,uranium_added=1,x=q:GetX(),y=q:GetY()})
  assert(u:CanMoveOrAttackInto(city():Plot()));sent=true;u:PushMission(MissionTypes.MISSION_MOVE_TO,x,y,0,0,1)
 elseif phase=="convert"and not spread then
  assert(p:IsTurnActive());local holy=p:GetCapitalCity();local u=assert(p:InitUnit(GameInfoTypes.UNIT_PROPHET,holy:GetX(),holy:GetY()))
  assert(u:GetReligion()==religion);local q=adjacent();u:SetXY(q:GetX(),q:GetY(),false,true,false,false)
  LekmodScenarioEvent("fixture-setup",{operation="provided-staged-Vatican-Prophet",unit=u:GetID(),religion=religion,x=q:GetX(),y=q:GetY()})
  assert(u:CanStartMission(GameInfoTypes.MISSION_SPREAD_RELIGION,-1,-1,u:GetPlot(),0),"normal AI Prophet spread unavailable")
  spread=true;u:PushMission(GameInfoTypes.MISSION_SPREAD_RELIGION,-1,-1,0,0,1)
 elseif phase=="annex"and not annexed then
  assert(p:IsTurnActive());local c=city();assert(c:GetOwner()==1 and c:GetNumRealBuilding(court)==1)
  if c:IsPuppet()then c:DoTask(TaskTypes.TASK_ANNEX_PUPPET,-1,-1,0)end
  assert(c:IsOccupied()and not c:IsPuppet());annexed=true
  LekmodScenarioEvent("normal-city-task",{operation="Vatican-annex",city=c:GetID(),court=c:GetNumRealBuilding(court)})
 end
end)
function LekmodScenario.step(player)
 local p=Players[1];assert(p:GetCivilizationType()==GameInfoTypes.CIVILIZATION_VATICAN)
 if phase=="init"then
  convertedBefore=p:HasCreatedReligion();local holy=p:GetCapitalCity()
  if not convertedBefore then
   for info in GameInfo.Religions()do if info.ID>0 then religion=info.ID;break end end
   Game.FoundReligion(1,religion,nil,GameInfoTypes.BELIEF_CHURCH_PROPERTY,GameInfoTypes.BELIEF_FEED_WORLD,-1,-1,holy)
   LekmodScenarioEvent("fixture-setup",{operation="provided-Vatican-religion",religion=religion})
  else religion=p:GetReligionCreatedByPlayer()end
  assert(religion>0 and holy:GetNumRealBuilding(court)==0,"nonoccupied holy-city control already has Courthouse")
  local site;for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
   if q:GetOwner()==-1 and q:GetNumUnits()==0 and player:CanFound(q:GetX(),q:GetY())then site=q;break end
  end
  assert(site);player:Found(site:GetX(),site:GetY());local c=player:GetCapitalCity();x,y=c:GetX(),c:GetY()
  if convertedBefore then c:ConvertPercentFollowers(religion,-1,100);assert(c:GetReligiousMajority()==religion)end
  assert(c:GetNumRealBuilding(court)==0 and not c:IsNoOccupiedUnhappiness())
  LekmodScenarioEvent("fixture-setup",{operation="provided-survival-city-and-religion-input",survival_city=site:GetPlotCity():GetID(),converted_before_capture=convertedBefore,religion=religion,target_x=x,target_y=y})
  LekmodScenarioRecord("vatican-foreign-owner-control","PASS","human target receives no Vatican Courthouse; peaceful Vatican holy city also excluded")
  Teams[player:GetTeam()]:Meet(p:GetTeam(),true);Network.SendChangeWar(p:GetTeam(),true);phase="war"
 elseif phase=="war"then
  if not LekmodScenarioAwait("Vatican-war",Teams[player:GetTeam()]:IsAtWar(p:GetTeam()))then return false end
  phase="capture";return "turn"
 elseif phase=="capture"then
  if not captured then return "turn"end
  local c=city();assert(c:GetOwner()==1 and c:GetOriginalOwner()==0 and(c:IsPuppet()or c:IsOccupied())and player:IsAlive())
  LekmodScenarioRecord("vatican-real-capture","PASS","real AI owner-turn move/attack and native capital capture; human survives")
  if convertedBefore then
   assert(c:GetReligiousMajority()==religion and c:GetNumRealBuilding(court)==1)
   LekmodScenarioRecord("vatican-courthouse-gate","PASS","already-own-religion capture grants one Courthouse")
   phase="awarded"
  else
   assert(c:GetReligiousMajority()~=religion and c:GetNumRealBuilding(court)==0)
   LekmodScenarioRecord("vatican-courthouse-gate","PASS","captured city without Vatican religion gets no Courthouse")
   phase="convert";return "turn"
  end
 elseif phase=="convert"then
  if not converted then return "turn"end
  assert(spread and city():GetReligiousMajority()==religion);phase="awarded"
 elseif phase=="awarded"then
  local c=city();assert(c:GetNumRealBuilding(court)==1 and c:IsNoOccupiedUnhappiness())
  assert(p:GetCapitalCity():GetNumRealBuilding(court)==0)
  LekmodScenarioRecord("vatican-courthouse-award","PASS",convertedBefore and"native capture callback grants exactly one Courthouse"or"normal Prophet spread/native conversion grants exactly one Courthouse")
  phase="annex";return "turn"
 elseif phase=="annex"then
  if not annexed then return "turn"end
  local c=city();assert(c:IsOccupied()and not c:IsPuppet()and c:GetNumRealBuilding(court)==1 and c:IsNoOccupiedUnhappiness())
  LekmodScenarioRecord("vatican-annex-preservation","PASS","normal annex preserves one Courthouse and occupation-unhappiness exemption")
  return true
 end
 return false
end
