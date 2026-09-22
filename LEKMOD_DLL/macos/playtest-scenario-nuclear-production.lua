-- Technologies, uranium and near-complete hammers are supplied. Manhattan and
-- the missile must complete by normal city orders and ordinary owner turns.
LekmodScenario={name="nuclear-production",items={"nuclear-project-gate","nuclear-Manhattan-production","nuclear-missile-production"}}
local phase,issued,trained="init",nil,nil
local project=GameInfoTypes.PROJECT_MANHATTAN_PROJECT
local missile=GameInfoTypes.UNIT_NUCLEAR_MISSILE
GameEvents.CityTrained.Add(function(owner,city,id,gold,faith)
 if owner==Game.GetActivePlayer()then local u=Players[owner]:GetUnitByID(id);if u and u:GetUnitType()==missile then trained={id=id,gold=gold,faith=faith}end end
end)
local function stage(city)
 local need=city:GetProductionNeeded();assert(need>1)
 city:SetProduction(need-1);issued=Game.GetGameTurn()
 LekmodScenarioEvent("fixture-setup",{operation="provided-near-complete-production",needed=need,provided=need-1})
end
function LekmodScenario.snapshot(player)
 local cities,units={},{}
 for c in player:Cities()do cities[c:GetID()]={project=c:GetProductionProject(),unit=c:GetProductionUnit(),production=c:GetProduction()}end
 for u in player:Units()do if u:GetUnitType()==missile then units[u:GetID()]={x=u:GetX(),y=u:GetY(),level=u:NukeDamageLevel(),range=u:Range()}end end
 return {turn=Game.GetGameTurn(),Manhattan=Teams[player:GetTeam()]:GetProjectCount(project),uranium=player:GetNumResourceAvailable(GameInfoTypes.RESOURCE_URANIUM,true),cities=cities,missiles=units}
end
function LekmodScenario.step(player)
 local city=assert(player:GetCapitalCity());local team=Teams[player:GetTeam()]
 if phase=="init"then
  assert(team:GetProjectCount(project)==0,"fixture already has Manhattan")
  LekmodScenarioGrantTech(player,GameInfo.Units[missile].PrereqTech)
  local r=GameInfoTypes.RESOURCE_URANIUM;local need=math.max(0,4-player:GetNumResourceAvailable(r,true));player:ChangeNumResourceTotal(r,need)
  LekmodScenarioEvent("fixture-setup",{operation="provided-uranium",amount=need})
  assert(not city:CanTrain(missile),"missile available before own Manhattan")
  assert(city:CanCreate(project),"Manhattan not eligible with supplied prerequisites")
  LekmodScenarioRecord("nuclear-project-gate","PASS","missile production rejected before Manhattan with technologies/uranium supplied")
  Game.CityPushOrder(city,OrderTypes.ORDER_CREATE,project,false,true,true);phase="project-queued"
 elseif phase=="project-queued"then
  if not LekmodScenarioAwait("Manhattan-queued",city:GetProductionProject()==project)then return false end
  stage(city);phase="project-turn";return "turn"
 elseif phase=="project-turn"then
  if Game.GetGameTurn()==issued then return "turn"end
  assert(team:GetProjectCount(project)==1 and not city:CanCreate(project),"Manhattan completion/repeat rejection differs")
  assert(city:CanTrain(missile),"Manhattan did not unlock missile production")
  LekmodScenarioRecord("nuclear-Manhattan-production","PASS","normal project order/turn completed Manhattan; duplicate project rejected; missile unlocked")
  Game.CityPushOrder(city,OrderTypes.ORDER_TRAIN,missile,false,true,true);phase="missile-queued"
 elseif phase=="missile-queued"then
  if not LekmodScenarioAwait("missile-queued",city:GetProductionUnit()==missile)then return false end
  stage(city);phase="missile-turn";return "turn"
 elseif phase=="missile-turn"then
  if Game.GetGameTurn()==issued then return "turn"end
  assert(trained and not trained.gold and not trained.faith,"normal missile CityTrained event missing")
  local u=assert(player:GetUnitByID(trained.id));assert(u:GetUnitType()==missile and u:NukeDamageLevel()==2 and u:Range()==12)
  LekmodScenarioRecord("nuclear-missile-production","PASS","normal city production event; supplied near-complete hammers; level=2 range=12")
  return true
 end
 return false
end
