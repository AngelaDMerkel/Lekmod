-- Native method surface: GameCore
-- Supplied tech, upkeep army, funds and starting garrison. Actual construction,
-- normal movement, treasury settlement and native sale eligibility are tested.
-- Only the matched building-removal/default-building controls use supplied counts.
LekmodScenario={name="mughal-garrison",items={"garrison-default-control","garrison-native-production","garrison-free-count","garrison-defense-and-cost","garrison-leave","garrison-return","garrison-treasury-settlement","garrison-sale-rejection"}}
local building=GameInfoTypes.BUILDING_MUGHALS_CARAVANSARY
local ordinary=GameInfoTypes.BUILDING_CARAVANSARY
local phase,unitID,cityID,dest,constructed,without,with,treasury="init"
local function free(p)return p:GetNumMaintenanceFreeUnits(-1,false)end
local function measure(p,c)return {free=free(p),cost=p:CalculateUnitCost(),strength=c:GetStrengthValue(false),building=c:GetNumRealBuilding(building)}end
function LekmodScenario.snapshot(p)
 local units,cities={},{}
 for u in p:Units()do if not u:IsDead()and not u:IsDelayedDeath()then units[u:GetID()]={type=u:GetUnitType(),x=u:GetX(),y=u:GetY(),moves=u:GetMoves(),garrison=u:IsGarrisoned()}end end
 for c in p:Cities()do cities[c:GetID()]={x=c:GetX(),y=c:GetY(),building=c:GetNumRealBuilding(building),ordinary=c:GetNumRealBuilding(ordinary),strength=c:GetStrengthValue(false)}end
 return {turn=Game.GetGameTurn(),units=units,cities=cities,gold=p:GetGold(),rate100=p:CalculateGoldRateTimes100(),free=free(p),cost=p:CalculateUnitCost()}
end
GameEvents.CityConstructed.Add(function(owner,city,b,gold,faith)
 if owner==0 and city==cityID and b==building then
  assert(not gold and not faith);constructed=true
  LekmodScenarioEvent("native-garrison-building-completion",{owner=owner,city=city,building=b,turn=Game.GetGameTurn()})
 end
end)
local function move(u,q)
 assert(u:GetMoves()>0 and u:CanMoveOrAttackInto(q));UI.SelectUnit(u)
 Game.SelectionListGameNetMessage(GameMessageTypes.GAMEMESSAGE_PUSH_MISSION,MissionTypes.MISSION_MOVE_TO,q:GetX(),q:GetY(),0,false,false)
end
function LekmodScenario.step(p)
 assert(p:GetCivilizationType()==GameInfoTypes.CIVILIZATION_MUGHALS)
 local c=assert(p:GetCapitalCity())
 if phase=="init"then
  cityID=c:GetID();assert(c:GetNumRealBuilding(building)==0 and c:GetNumRealBuilding(ordinary)==0)
  LekmodScenarioGrantTech(p,"TECH_CURRENCY");p:SetGold(5000);p:ChangeNumResourceTotal(GameInfoTypes.RESOURCE_URANIUM,1)
  for i=0,c:Plot():GetNumUnits()-1 do assert(not c:Plot():GetUnit(i):IsCombatUnit(),"fixture capital already has a defender")end
  local u=assert(p:InitUnit(GameInfoTypes.UNIT_MECH,c:GetX(),c:GetY()));unitID=u:GetID();assert(u:IsGarrisoned())
  local army=0
  for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
   if army<12 and not q:IsWater()and not q:IsMountain()and not q:IsCity()and q:GetNumUnits()==0 and q:GetArea()==c:Plot():GetArea()and(q:GetOwner()==-1 or q:GetOwner()==0)and Map.PlotDistance(c:GetX(),c:GetY(),q:GetX(),q:GetY())<=6 then
    p:InitUnit(GameInfoTypes.UNIT_WARRIOR,q:GetX(),q:GetY());army=army+1
   end
  end
  assert(army==12 and p:CalculateUnitCost()>0,"positive-upkeep fixture missing")
  LekmodScenarioEvent("fixture-setup",{operation="provided-garrison-and-upkeep-fixture",unit=unitID,army=army,gold=5000,uranium_added=1,city=cityID})
  local n=free(p);c:SetNumRealBuilding(ordinary,1);assert(free(p)==n);c:SetNumRealBuilding(ordinary,0);assert(free(p)==n)
  LekmodScenarioRecord("garrison-default-control","PASS","supplied ordinary Caravansary grants no free-unit count; positive upkeep and actual garrison present")
  assert(c:CanConstruct(building));Game.CityPushOrder(c,OrderTypes.ORDER_CONSTRUCT,building,false,true,true);phase="queued";return false
 elseif phase=="queued"then
  if not LekmodScenarioAwait("garrison-building-order",c:GetProductionBuilding()==building)then return false end
  local needed=c:GetBuildingProductionNeeded(building);assert(needed>1);c:SetBuildingProduction(building,needed-1)
  LekmodScenarioEvent("fixture-setup",{operation="provided-near-complete-hammers",building=building,hammers=needed-1,cost=needed})
  phase="building";return "turn"
 elseif phase=="building"then
  if not constructed then return "turn"end
  local u=assert(p:GetUnitByID(unitID));assert(u:IsGarrisoned()and c:GetNumRealBuilding(building)==1)
  assert(not c:CanConstruct(building));LekmodScenarioRecord("garrison-native-production","PASS","native CityConstructed, count1 and duplicate rejection")
  with=measure(p,c);c:SetNumRealBuilding(building,0);without=measure(p,c);c:SetNumRealBuilding(building,1)
  assert(LekmodScenarioJSON(measure(p,c))==LekmodScenarioJSON(with),"matched control did not restore exact measurements")
  LekmodScenarioEvent("garrison-building-comparison",{with_building=with,without_building=without,expected_free_delta=1,expected_strength_delta=500})
  assert(with.free==without.free+1,"Mughal free-garrison count: expected "..(without.free+1).." actual "..with.free)
  LekmodScenarioRecord("garrison-free-count","PASS","one ordinarily chargeable garrison excluded from maintenance; no extra count on restore")
  assert(with.strength==without.strength+500,"garrison defense differs from +5.00")
  assert(without.cost>0 and with.cost<=without.cost,"free garrison increased upkeep")
  LekmodScenarioRecord("garrison-defense-and-cost","PASS","native defense +500 hundredths; unit cost with="..with.cost.." without="..without.cost.." (integer rounding retained)")
  for d=0,5 do local q=Map.PlotDirection(c:GetX(),c:GetY(),d)
   if q and not q:IsWater()and not q:IsMountain()and not q:IsCity()and q:GetNumUnits()==0 and u:CanMoveOrAttackInto(q)then dest=q;break end
  end
  assert(dest,"no empty legal garrison exit");move(u,dest);phase="left";return false
 elseif phase=="left"then
  local u=assert(p:GetUnitByID(unitID))
  if not LekmodScenarioAwait("garrison-exit",u:GetX()==dest:GetX()and u:GetY()==dest:GetY())then return false end
  assert(not u:IsGarrisoned()and free(p)==without.free)
  LekmodScenarioRecord("garrison-leave","PASS","normal move removes exactly one maintenance exemption")
  move(u,c:Plot());phase="returned";return false
 elseif phase=="returned"then
  local u=assert(p:GetUnitByID(unitID))
  if not LekmodScenarioAwait("garrison-return",u:GetX()==c:GetX()and u:GetY()==c:GetY())then return false end
  assert(u:IsGarrisoned()and free(p)==without.free+1)
  LekmodScenarioRecord("garrison-return","PASS","normal move restores one exemption without duplication")
  treasury={turn=Game.GetGameTurn(),gold=p:GetGold(),rate100=p:CalculateGoldRateTimes100()}
  LekmodScenarioEvent("garrison-before-settlement",treasury);phase="settlement";return "turn"
 elseif phase=="settlement"then
  if Game.GetGameTurn()==treasury.turn then return "turn"end
  assert(Game.GetGameTurn()==treasury.turn+1)
  local expected=math.floor((treasury.gold*100+treasury.rate100)/100)
  assert(p:GetGold()==expected,"ordinary treasury settlement differs from quote")
  assert(p:GetUnitByID(unitID):IsGarrisoned()and free(p)==without.free+1)
  LekmodScenarioRecord("garrison-treasury-settlement","PASS","ordinary gold settlement="..expected.." with active garrison exemption")
  assert(not c:IsBuildingSellable(building),"zero-maintenance Caravansary must reject sale")
  assert(c:GetNumRealBuilding(building)==1 and free(p)==without.free+1)
  LekmodScenarioRecord("garrison-sale-rejection","PASS","native sale eligibility rejects zero-maintenance building; building/exemption unchanged")
  return true
 end
 return false
end
