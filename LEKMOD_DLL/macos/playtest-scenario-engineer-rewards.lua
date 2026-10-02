-- Native method surface: GameCore
-- @native-receiver u Unit
-- @native-receiver player Player
-- @native-receiver c City
-- Population, production order/progress and Engineers are explicit inputs.
-- Ordinary hurry actions must consume the unit and add the independent amount.
LekmodScenario={name="engineer-rewards",items={"engineer-data-formula","engineer-population-scaling","engineer-production-cap","engineer-one-turn-rejection","engineer-no-city-rejection","engineer-real-hurry-consumption"}}
local phase,index="init",1
local id,building,before,expected,cityID,neutral
local cases={{population=1,cap=false},{population=5,cap=false},{population=12,cap=false},{population=5,cap=true}}
local function gone(player)local u=player:GetUnitByID(id);return not u or u:IsDead()or u:IsDelayedDeath()end
function LekmodScenario.snapshot(player)
 local cities,units={},{ }
 for c in player:Cities()do cities[c:GetID()]={population=c:GetPopulation(),production=c:GetProduction(),building=c:GetProductionBuilding(),unit=c:GetProductionUnit()}end
 for u in player:Units()do if not u:IsDelayedDeath()then units[u:GetID()]={type=u:GetUnitType(),x=u:GetX(),y=u:GetY()}end end
 return {turn=Game.GetGameTurn(),cities=cities,units=units,gold=player:GetGold(),speed=Game.GetGameSpeedType()}
end
local function maximum(c)
 local info=GameInfo.Units.UNIT_ENGINEER
 assert(info.BaseHurry==75 and info.HurryMultiplier==36,"shipped Engineer parameters changed")
 return math.floor((75+36*c:GetPopulation())*GameInfo.GameSpeeds[Game.GetGameSpeedType()].UnitHurryPercent/100)
end
function LekmodScenario.step(player)
 local c=cityID and player:GetCityByID(cityID)or player:GetCapitalCity();assert(c)
 if phase=="init"then
  cityID=c:GetID()
  -- Ancient-start fixture keeps ordinary build costs. Computers supplies a
  -- legal expensive construction for the unchanged population12 uncapped case.
  assert(Game.GetStartEra()==GameInfoTypes.ERA_ANCIENT,"requires Ancient-start fixture")
  LekmodScenarioGrantTech(player,"TECH_COMPUTERS")
  local cost=0
  for b in GameInfo.Buildings()do if c:CanConstruct(b.ID)and b.Cost>cost then building=b.ID;cost=b.Cost end end
  assert(building,"fixture has no legal construction")
  for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i)
   if not p:IsCity()and not p:IsWater()and not p:IsMountain()then neutral=p;break end
  end
  assert(neutral)
  Game.CityPushOrder(c,OrderTypes.ORDER_CONSTRUCT,building,false,true,true);phase="order"
 elseif phase=="order"then
  if not LekmodScenarioAwait("engineer-order",c:GetProductionBuilding()==building)then return false end
  phase="prepare"
 elseif phase=="prepare"then
  local test=cases[index];c:SetPopulation(test.population,true)
  local amount=maximum(c);local cost=c:GetProductionNeeded()
  local left=test.cap and math.floor(amount/2)or cost
  assert(left>0 and(test.cap or cost>amount),"fixture production is too cheap for uncapped case")
  c:SetBuildingProduction(building,cost-left)
  before=c:GetProduction();expected=math.min(left,amount)
  local u=assert(player:InitUnit(GameInfoTypes.UNIT_ENGINEER,c:GetX(),c:GetY()));id=u:GetID()
  assert(u:GetX()==c:GetX()and u:GetY()==c:GetY()and not gone(player))
  assert(u:GetHurryProduction(neutral)==0 and not u:CanStartMission(MissionTypes.MISSION_HURRY,0,0,neutral,0),"Engineer can hurry a non-city plot")
  assert(c:GetProductionTurnsLeft()>1,"provided cap accidentally entered one-turn exclusion")
  assert(u:CanStartMission(MissionTypes.MISSION_HURRY,0,0,c:Plot(),0)and u:GetHurryProduction(c:Plot())==expected,"native hurry quote disagrees with independent formula")
  LekmodScenarioEvent("fixture-setup",{operation="provided-engineer-population-order-progress",population=c:GetPopulation(),building=building,production=before,cost=cost,maximum=amount,expected=expected,unit=id})
  UI.SelectUnit(u)
  for a=0,#GameInfoActions do if GameInfoActions[a]and GameInfoActions[a].Type=="MISSION_HURRY"then assert(Game.CanHandleAction(a));Game.HandleAction(a);phase="result";return false end end
  error("missing hurry action")
 elseif phase=="result"then
  if not LekmodScenarioAwait("engineer-consumed",gone(player))then return false end
  assert(c:GetProductionBuilding()==building and c:GetProduction()==before+expected,"normal hurry changed wrong target/amount")
  LekmodScenarioEvent("engineer-independent-outcome",{case=index,population=c:GetPopulation(),before=before,after=c:GetProduction(),expected=expected,consumed=true})
  index=index+1
  if index<=#cases then phase="prepare"else phase="one-turn"end
 elseif phase=="one-turn"then
  c:SetBuildingProduction(building,c:GetProductionNeeded()-1)
  local u=assert(player:InitUnit(GameInfoTypes.UNIT_ENGINEER,c:GetX(),c:GetY()));id=u:GetID();before=c:GetProduction()
  assert(c:GetProductionTurnsLeft()==1 and u:GetHurryProduction(c:Plot())==1,"one-turn control not at native boundary")
  assert(not u:CanStartMission(MissionTypes.MISSION_HURRY,0,0,c:Plot(),0),"one-turn construction incorrectly accepts Engineer")
  UI.SelectUnit(u);local found=false
  for a=0,#GameInfoActions do if GameInfoActions[a]and GameInfoActions[a].Type=="MISSION_HURRY"then assert(not Game.CanHandleAction(a));found=true;break end end
  assert(found and not gone(player)and c:GetProduction()==before)
  LekmodScenarioRecord("engineer-data-formula","PASS","75+36*population, then speed truncation, then remaining-production cap independently calculated")
  LekmodScenarioRecord("engineer-population-scaling","PASS","actual hurry outcomes at populations1,5,12 match independent integer amounts")
  LekmodScenarioRecord("engineer-production-cap","PASS","separate capped action adds exactly remaining production with no excess")
  LekmodScenarioRecord("engineer-one-turn-rejection","PASS","one-turn control rejects both unit eligibility and normal action availability; no command sent")
  LekmodScenarioRecord("engineer-no-city-rejection","PASS","non-city query returns0 and ineligible for every supplied Engineer")
  LekmodScenarioRecord("engineer-real-hurry-consumption","PASS","four ordinary hurry actions consume four Engineers; rejected control survives")
  return true
 end
 return false
end
