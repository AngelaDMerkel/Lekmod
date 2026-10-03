-- Native method surface: GameCore
-- Building counts and population are supplied fixture inputs. The tested outputs
-- are native city per-population accumulators and their resulting yield rates.
-- Production eligibility, civilization rewards and unrelated flat yields are separate.
local rows={
 {kind="BUILDING_AKKAD_LIBRARY",values={YIELD_SCIENCE=50}},
 {kind="BUILDING_DUMMY_MUGHALS",values={YIELD_CULTURE=20,YIELD_GOLD=20,YIELD_SCIENCE=20}},
 {kind="BUILDING_LIBRARY",values={YIELD_SCIENCE=50}},
 {kind="BUILDING_PAPER_MAKER",values={YIELD_SCIENCE=50}},
 {kind="BUILDING_PUBLIC_SCHOOL",values={YIELD_SCIENCE=50}},
 {kind="BUILDING_ROYAL_LIBRARY",values={YIELD_SCIENCE=50}},
 {kind="BUILDING_SERAI",values={YIELD_GOLD=33}},
 {kind="BUILDING_UC_HALKEVLERI",values={YIELD_SCIENCE=50}}
}
local items={"perpop-configured-values","perpop-unrelated-yields","perpop-population-rates","perpop-removal","perpop-positive-save"}
for _,r in ipairs(rows)do items[#items+1]="perpop-"..r.kind end
LekmodScenario={name="building-perpop",items=items}
local ys={"YIELD_FOOD","YIELD_PRODUCTION","YIELD_GOLD","YIELD_SCIENCE","YIELD_CULTURE","YIELD_FAITH"}
local populations={1,3,6,7}
local phase,cityID,index,popIndex="init",nil,1,1
local function measures(c)
 local yields,counts={},{}
 for _,name in ipairs(ys)do local y=GameInfoTypes[name]
  yields[name]={perpop100=c:GetYieldPerPopTimes100(y),base=c:GetBaseYieldRate(y),modifier=c:GetBaseYieldRateModifier(y),rate100=c:GetYieldRateTimes100(y)}
 end
 for _,r in ipairs(rows)do counts[r.kind]=c:GetNumRealBuilding(GameInfoTypes[r.kind])end
 return {population=c:GetPopulation(),x=c:GetX(),y=c:GetY(),counts=counts,yields=yields}
end
function LekmodScenario.snapshot(player)
 local cities={};for c in player:Cities()do cities[c:GetID()]=measures(c)end
 return {turn=Game.GetGameTurn(),cities=cities}
end
local function verify(c,wanted,label)
 local state=measures(c)
 for _,name in ipairs(ys)do
  local expected=wanted[name]or 0;local actual=state.yields[name]
  assert(actual.perpop100==expected,label.." "..name..": per-population accumulator differs")
  -- The independently pinned per-population term is added to the observed
  -- background base; this does not assert the correctness of every base source.
  local rate=math.floor((actual.base*100+expected*state.population)*actual.modifier/100)
  assert(actual.rate100==rate,label.." "..name..": native rate differs from expected per-population arithmetic")
 end
 LekmodScenarioEvent("native-perpop-observation",{label=label,expected=wanted,state=state})
end
function LekmodScenario.step(p)
 assert(p:GetID()==0 and p:IsHuman()and p:GetCivilizationType()==GameInfoTypes.CIVILIZATION_ROME)
 if phase=="init"then
  local expected={};for _,r in ipairs(rows)do for y,n in pairs(r.values)do expected[r.kind..":"..y]=n end end
  local count=0;for r in GameInfo.Building_YieldChangesPerPop()do
   local key=r.BuildingType..":"..r.YieldType;assert(expected[key]==r.Yield,"configured per-population row differs: "..key);expected[key]=nil;count=count+1
  end
  assert(count==10 and next(expected)==nil,"configured per-population catalogue changed")
  assert(#p:GetTradeRoutes()==0,"fixture requires no active trade or process income")
  for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
   if q:GetOwner()==-1 and q:GetNumUnits()==0 and p:CanFound(q:GetX(),q:GetY())then
    p:Found(q:GetX(),q:GetY());local c=assert(q:GetPlotCity());assert(not c:IsCapital());cityID=c:GetID();break
   end
  end
  assert(cityID,"no legal noncapital probe city")
  local c=assert(p:GetCityByID(cityID));assert(c:GetProductionProcess()==-1)
  for _,r in ipairs(rows)do assert(c:GetNumBuilding(GameInfoTypes[r.kind])==0)end
  c:SetPopulation(1,true);verify(c,{},"empty-probe")
  LekmodScenarioEvent("fixture-setup",{operation="provided-noncapital-probe-city",city=cityID,population=1})
  LekmodScenarioRecord("perpop-configured-values","PASS","all ten configured entries match independent 20/33/50 hundredths across eight definitions")
  phase="add"
 elseif phase=="add"then
  local c=assert(p:GetCityByID(cityID));local r=rows[index]
  c:SetNumRealBuilding(GameInfoTypes[r.kind],1);assert(c:GetNumBuilding(GameInfoTypes[r.kind])==1)
  LekmodScenarioEvent("fixture-setup",{operation="provided-building-count",building=r.kind,count=1,city=cityID});popIndex=1;phase="population"
 elseif phase=="population"then
  local c=assert(p:GetCityByID(cityID));local r=rows[index];c:SetPopulation(populations[popIndex],true)
  LekmodScenarioEvent("fixture-setup",{operation="provided-population",population=populations[popIndex],city=cityID})
  verify(c,r.values,r.kind.."/population-"..populations[popIndex]);popIndex=popIndex+1
  if popIndex>#populations then
   LekmodScenarioRecord("perpop-"..r.kind,"PASS","native accumulator and yield-rate arithmetic at populations1,3,6,7; no target yield assignment")
   phase="remove"
  end
 elseif phase=="remove"then
  local c=assert(p:GetCityByID(cityID));local r=rows[index];c:SetNumRealBuilding(GameInfoTypes[r.kind],0)
  assert(c:GetNumBuilding(GameInfoTypes[r.kind])==0);verify(c,{},r.kind.."/removed")
  index=index+1;if index<=#rows then phase="add"else phase="positive-save"end
 elseif phase=="positive-save"then
  local c=assert(p:GetCityByID(cityID));c:SetPopulation(7,true)
  c:SetNumRealBuilding(GameInfoTypes.BUILDING_DUMMY_MUGHALS,1);c:SetNumRealBuilding(GameInfoTypes.BUILDING_SERAI,1)
  verify(c,{YIELD_CULTURE=20,YIELD_GOLD=53,YIELD_SCIENCE=20},"positive-composite-save")
  LekmodScenarioRecord("perpop-unrelated-yields","PASS","all untargeted yield accumulators remain zero for every supplied building")
  LekmodScenarioRecord("perpop-population-rates","PASS","all eight definitions at four population boundaries match native resulting yield rates, including fractional33/20/50 values")
  LekmodScenarioRecord("perpop-removal","PASS","removing each supplied building clears its contribution; no residual per-population yield")
  LekmodScenarioRecord("perpop-positive-save","PASS","positive additive gold53/culture20/science20 state at population7 retained for exact replay")
  return true
 end
 return false
end
