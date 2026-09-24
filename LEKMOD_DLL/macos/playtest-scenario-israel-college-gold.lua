-- Research, Libraries, an extra legal city and exact purchase budget are inputs.
-- Purchase uses the real ProductionPopup callback; no target building is assigned.
local useFaith=false
local kind="israel-college-gold"
LekmodScenario={name=kind,items={"college-prerequisites","college-purchase-only","college-budget","college-purchased","college-yields","college-repeat-rejected"}}
local phase,before,price,reply,built="init",nil,nil,nil,nil
local building=GameInfoTypes.BUILDING_ISRAEL_NATIONAL_COLLEGE
local currency=useFaith and YieldTypes.YIELD_FAITH or YieldTypes.YIELD_GOLD
local ys={YieldTypes.YIELD_SCIENCE,YieldTypes.YIELD_FAITH,YieldTypes.YIELD_CULTURE}
local function eligible(c,cost)return c:IsCanPurchase(cost,true,-1,building,-1,currency)end
local function state(p)
 local cities={}
 for c in p:Cities()do
  local base,mod={},{}
  for _,y in ipairs(ys)do base[y]=c:GetBaseYieldRateFromBuildings(y);mod[y]=c:GetBaseYieldRateModifier(y)end
  cities[c:GetID()]={x=c:GetX(),y=c:GetY(),population=c:GetPopulation(),library=c:GetNumBuilding(GameInfoTypes.BUILDING_LIBRARY),college=c:GetNumRealBuilding(building),base=base,modifier=mod}
 end
 return {gold=p:GetGold(),faith=p:GetFaith(),cities=cities}
end
function LekmodScenario.snapshot(player)return {turn=Game.GetGameTurn(),human=state(player),foreign=state(Players[3])}end
LuaEvents.LekmodScenarioCityResponse.Add(function(action,id)reply={action=action,id=id}end)
GameEvents.CityConstructed.Add(function(owner,city,b,gold,faith)
 if owner==0 and b==building then built={city=city,gold=gold,faith=faith};LekmodScenarioEvent("native-college-purchase",built)end
end)
function LekmodScenario.step(p)
 assert(p:GetID()==0 and p:GetCivilizationType()==GameInfoTypes.CIVILIZATION_ISRAEL)
 local c=assert(p:GetCapitalCity())
 if phase=="init"then
  assert(c:GetNumBuilding(building)==0 and not eligible(c,false),"baseline purchase should lack prerequisites")
  LekmodScenarioGrantTech(p,"TECH_PHILOSOPHY")
  assert(not eligible(c,false),"missing Library did not block purchase")
  local site
  for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
   if q:GetOwner()==-1 and q:GetNumUnits()==0 and p:CanFound(q:GetX(),q:GetY())then site=q;break end
  end
  assert(site,"no legal extra-city input");p:Found(site:GetX(),site:GetY());local extra=assert(site:GetPlotCity())
  c:SetNumRealBuilding(GameInfoTypes.BUILDING_LIBRARY,1)
  assert(not eligible(c,false),"missing Library in second city did not block national building")
  extra:SetNumRealBuilding(GameInfoTypes.BUILDING_LIBRARY,1)
  LekmodScenarioEvent("fixture-setup",{operation="provided-Libraries-and-legal-second-city",city=extra:GetID(),x=extra:GetX(),y=extra:GetY()})
  assert(eligible(c,false),"legal purchase unavailable after prerequisites")
  LekmodScenarioRecord("college-prerequisites","PASS","research/local Library/empire-wide Libraries tested before legal purchase")
  assert(not c:CanConstruct(building),"purchase-only College is production-eligible")
  assert(not Players[3]:GetCapitalCity():IsCanPurchase(false,true,-1,building,-1,currency),"foreign civilization can purchase Israel replacement")
  LekmodScenarioRecord("college-purchase-only","PASS","normal production rejected; foreign owner rejected")
  price=useFaith and c:GetBuildingFaithPurchaseCost(building)or c:GetBuildingPurchaseCost(building);assert(price>1)
  local old=useFaith and p:GetFaith()or p:GetGold()
  if useFaith then p:ChangeFaith(price-1-old)else p:ChangeGold(price-1-old)end
  assert(not eligible(c,true),"one below quoted cost was sufficient")
  if useFaith then p:ChangeFaith(1)else p:ChangeGold(1)end
  assert(eligible(c,true),"exact quoted cost was insufficient")
  LekmodScenarioEvent("fixture-setup",{operation="provided-exact-purchase-budget",currency=currency,before=old,amount=price})
  LekmodScenarioRecord("college-budget","PASS","cost-1 rejected; exact quoted cost accepted; price="..price)
  before=LekmodScenario.snapshot(p)
  if useFaith then LuaEvents.LekmodScenarioFaithBuildingPurchase(c:GetID(),building)else LuaEvents.LekmodScenarioBuildingPurchase(c:GetID(),building)end
  phase="purchase"
 elseif phase=="purchase"then
  if not reply then return false end
  if not LekmodScenarioAwait("college-purchase",built and c:GetNumRealBuilding(building)==1)then return false end
  assert(reply.action=="purchase"and reply.id==building and built.city==c:GetID())
  assert(built.gold==not useFaith and built.faith==useFaith,"purchase event flags differ")
  local after=LekmodScenario.snapshot(p)
  assert((useFaith and p:GetFaith()or p:GetGold())==0,"exact purchase budget not spent")
  assert((useFaith and p:GetGold()or p:GetFaith())==(useFaith and before.human.gold or before.human.faith),"purchase spent wrong currency")
  LekmodScenarioRecord("college-purchased","PASS","actual ProductionPopup callback/native CityConstructed; exact currency debit="..price)
  local a,b=after.human.cities[c:GetID()],before.human.cities[c:GetID()]
  for _,y in ipairs(ys)do local delta=y==YieldTypes.YIELD_CULTURE and 1 or 3
   assert(a.base[y]==b.base[y]+delta,"College base yield mismatch: "..y)
  end
  assert(a.modifier[YieldTypes.YIELD_SCIENCE]==b.modifier[YieldTypes.YIELD_SCIENCE]+50,"College science modifier mismatch")
  LekmodScenarioRecord("college-yields","PASS","science/faith +3, culture +1, science modifier +50 percentage points")
  for owned in p:Cities()do
   assert(not owned:IsCanPurchase(false,true,-1,building,-1,YieldTypes.YIELD_GOLD)and not owned:IsCanPurchase(false,true,-1,building,-1,YieldTypes.YIELD_FAITH),"duplicate national building purchase allowed")
  end
  assert(LekmodScenarioJSON(after.foreign)==LekmodScenarioJSON(before.foreign),"purchase changed foreign control")
  LekmodScenarioRecord("college-repeat-rejected","PASS","gold/faith duplicates rejected across both cities; foreign control unchanged")
  return true
 end
 return false
end
