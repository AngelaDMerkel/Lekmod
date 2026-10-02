-- Native method surface: GameCore
-- @native-receiver u Unit
-- @native-receiver c City
-- @native-receiver player Player
-- Research/resources/policy/population/progress are inputs. Apollo completion,
-- five hurry rewards, Engineer consumption and final booster birth are outcomes.
LekmodScenario={name="engineer-space-hurry",items={"space-hurry-apollo-gate","space-hurry-policy-rejection","space-hurry-double-all-parts","space-hurry-normal-unit-rejection","space-hurry-cap","space-hurry-production","space-hurry-consumption"}}
local phase,index,id,before,expected,cost,started,normalUnit="init",1
local types={"UNIT_SS_COCKPIT","UNIT_SS_ENGINE","UNIT_SS_STASIS_CHAMBER","UNIT_SS_BOOSTER"}
local policy=GameInfoTypes.POLICY_SPACEFLIGHT_PIONEERS
local produced
GameEvents.CityTrained.Add(function(owner,city,unit,gold,faith)
 if owner==0 and phase=="production"then local u=Players[owner]:GetUnitByID(unit)
  if u and u:GetUnitType()==GameInfoTypes.UNIT_SS_BOOSTER then assert(not gold and not faith);produced=unit end
 end
end)
local function alive(u)return u and not u:IsDead()and not u:IsDelayedDeath()end
local function amount(c)return 2*math.floor((75+36*c:GetPopulation())*GameInfo.GameSpeeds[Game.GetGameSpeedType()].UnitHurryPercent/100)end
local function order(c,unit)Game.CityPushOrder(c,OrderTypes.ORDER_TRAIN,unit,false,true,true)end
local function act(u)
 UI.SelectUnit(u)
 for a=0,#GameInfoActions do if GameInfoActions[a]and GameInfoActions[a].Type=="MISSION_HURRY"then assert(Game.CanHandleAction(a));Game.HandleAction(a);return end end
 error("missing ordinary hurry action")
end
function LekmodScenario.snapshot(player)
 local c=assert(player:GetCapitalCity());local production,projects,units={},{},{}
 for _,kind in ipairs(types)do local row=GameInfo.Units[kind];production[kind]=c:GetUnitProduction(row.ID);projects[kind]=Teams[player:GetTeam()]:GetProjectCount(GameInfoTypes[row.SpaceshipProject])end
 for u in player:Units()do if alive(u)then units[u:GetID()]={type=u:GetUnitType(),x=u:GetX(),y=u:GetY(),moves=u:GetMoves()}end end
 return {turn=Game.GetGameTurn(),population=c:GetPopulation(),apollo=Teams[player:GetTeam()]:GetProjectCount(GameInfoTypes.PROJECT_APOLLO_PROGRAM),production=production,projects=projects,policy=player:HasPolicy(policy),units=units,winner=Game.GetWinner()}
end
function LekmodScenario.step(player)
 local c=assert(player:GetCapitalCity());local team=Teams[player:GetTeam()]
 if phase=="init"then
  assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_ROME and Game.GetStartEra()==GameInfoTypes.ERA_ANCIENT and Game.GetWinner()==-1)
  assert(Game.IsVictoryValid(GameInfoTypes.VICTORY_SPACE_RACE)and team:GetProjectCount(GameInfoTypes.PROJECT_APOLLO_PROGRAM)==0 and not player:HasPolicy(policy))
  for _,kind in ipairs(types)do LekmodScenarioGrantTech(player,GameInfo.Units[kind].PrereqTech)end
  local resource=GameInfoTypes.RESOURCE_ALUMINUM;local added=math.max(0,6-player:GetNumResourceAvailable(resource,true));player:ChangeNumResourceTotal(resource,added)
  LekmodScenarioEvent("fixture-setup",{operation="provided-space-prerequisites",aluminum=added})
  assert(not c:CanTrain(GameInfoTypes.UNIT_SS_BOOSTER)and c:CanCreate(GameInfoTypes.PROJECT_APOLLO_PROGRAM))
  Game.CityPushOrder(c,OrderTypes.ORDER_CREATE,GameInfoTypes.PROJECT_APOLLO_PROGRAM,false,true,true);phase="apollo-queue"
 elseif phase=="apollo-queue"then
  if not LekmodScenarioAwait("Apollo-queued",c:GetProductionProject()==GameInfoTypes.PROJECT_APOLLO_PROGRAM)then return false end
  local need=c:GetProductionNeeded();c:SetProduction(need-1);started=Game.GetGameTurn()
  LekmodScenarioEvent("fixture-setup",{operation="provided-Apollo-progress",production=need-1});phase="apollo";return "turn"
 elseif phase=="apollo"then
  if Game.GetGameTurn()==started then return "turn"end
  assert(team:GetProjectCount(GameInfoTypes.PROJECT_APOLLO_PROGRAM)==1 and c:CanTrain(GameInfoTypes.UNIT_SS_BOOSTER))
  LekmodScenarioRecord("space-hurry-apollo-gate","PASS","normal prerequisite project completion unlocks spaceship-unit production")
  c:SetPopulation(5,true);LekmodScenarioEvent("fixture-setup",{operation="provided-population",population=5});phase="queue"
 elseif phase=="queue"then
  local unit=GameInfoTypes[types[index]];assert(c:CanTrain(unit));order(c,unit);phase="queued"
 elseif phase=="queued"then
  local unit=GameInfoTypes[types[index]]
  if not LekmodScenarioAwait("space-part-queued",c:GetProductionUnit()==unit)then return false end
  c:SetUnitProduction(unit,0);cost=c:GetProductionNeeded();expected=amount(c);assert(cost>expected and c:GetProductionTurnsLeft()>1)
  local u=assert(player:InitUnit(GameInfoTypes.UNIT_ENGINEER,c:GetX(),c:GetY()));id=u:GetID();assert(u:GetX()==c:GetX()and u:GetY()==c:GetY())
  assert(u:GetHurryProduction(c:Plot())==expected)
  if index==1 then
   assert(not u:CanStartMission(MissionTypes.MISSION_HURRY,0,0,c:Plot(),0))
   UI.SelectUnit(u);for a=0,#GameInfoActions do if GameInfoActions[a]and GameInfoActions[a].Type=="MISSION_HURRY"then assert(not Game.CanHandleAction(a))end end
   assert(alive(u)and c:GetProduction()==0)
   LekmodScenarioRecord("space-hurry-policy-rejection","PASS","no Spaceflight Pioneers: unit mission and action availability reject despite positive quote")
   player:SetHasPolicy(policy,true);LekmodScenarioEvent("fixture-setup",{operation="provided-Spaceflight-Pioneers-policy"})
  end
  assert(player:HasPolicy(policy)and u:CanStartMission(MissionTypes.MISSION_HURRY,0,0,c:Plot(),0))
  before=c:GetProduction();LekmodScenarioEvent("space-hurry-independent-quote",{unit=types[index],population=c:GetPopulation(),cost=cost,expected=expected});act(u);phase="result"
 elseif phase=="result"then
  if not LekmodScenarioAwait("space-engineer-consumed",not alive(player:GetUnitByID(id)))then return false end
  assert(c:GetProduction()==before+expected)
  LekmodScenarioEvent("space-hurry-native-outcome",{unit=types[index],before=before,after=c:GetProduction(),expected=expected})
  index=index+1
  if index<=#types then phase="queue"else
   LekmodScenarioRecord("space-hurry-double-all-parts","PASS","all four real component orders receive exact2x ordinary Engineer amount and consume their Engineer")
   for row in GameInfo.Units()do if row.Combat>0 and not row.SpaceshipProject and c:CanTrain(row.ID)then normalUnit=row.ID;break end end
   assert(normalUnit);order(c,normalUnit);phase="normal"
  end
 elseif phase=="normal"then
  if not LekmodScenarioAwait("normal-unit-queued",c:GetProductionUnit()==normalUnit)then return false end
  c:SetUnitProduction(normalUnit,0)
  local u=assert(player:InitUnit(GameInfoTypes.UNIT_ENGINEER,c:GetX(),c:GetY()));id=u:GetID()
  assert(player:HasPolicy(policy)and not u:CanStartMission(MissionTypes.MISSION_HURRY,0,0,c:Plot(),0))
  LekmodScenarioRecord("space-hurry-normal-unit-rejection","PASS","policy does not permit hurrying an ordinary combat unit")
  order(c,GameInfoTypes.UNIT_SS_BOOSTER);phase="cap"
 elseif phase=="cap"then
  if not LekmodScenarioAwait("booster-restored",c:GetProductionUnit()==GameInfoTypes.UNIT_SS_BOOSTER)then return false end
  cost=c:GetProductionNeeded();expected=math.floor(amount(c)/4);c:SetUnitProduction(GameInfoTypes.UNIT_SS_BOOSTER,cost-expected)
  assert(c:GetProductionTurnsLeft()>1);local u=assert(player:GetUnitByID(id));before=c:GetProduction()
  assert(u:GetHurryProduction(c:Plot())==expected and u:CanStartMission(MissionTypes.MISSION_HURRY,0,0,c:Plot(),0));act(u);phase="capped"
 elseif phase=="capped"then
  if not LekmodScenarioAwait("capped-engineer-consumed",not alive(player:GetUnitByID(id)))then return false end
  assert(c:GetProduction()==cost and c:GetProduction()==before+expected)
  LekmodScenarioRecord("space-hurry-cap","PASS","remaining production caps doubled Engineer amount without overflow")
  started=Game.GetGameTurn();phase="production";return "turn"
 elseif phase=="production"then
  if not produced then assert(Game.GetGameTurn()-started<3);return "turn"end
  local u=assert(player:GetUnitByID(produced));assert(u:GetUnitType()==GameInfoTypes.UNIT_SS_BOOSTER and team:GetProjectCount(GameInfoTypes.PROJECT_SS_BOOSTER)==0 and Game.GetWinner()==-1)
  LekmodScenarioRecord("space-hurry-production","PASS","ordinary next-turn CityTrained creates unassembled booster; no victory/project assembly manufactured")
  LekmodScenarioRecord("space-hurry-consumption","PASS","five real hurry missions consume five Engineers; rejection control retained until reused legally")
  return true
 end
 return false
end
