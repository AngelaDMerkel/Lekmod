-- Native method surface: GameCore
-- Swiss human fixture. Technology, a legal mountain city, prerequisite Barracks,
-- near-complete Armory hammers, iron and gold are supplied and recorded inputs.
-- Normal production, purchase callback, native promotions and movement are outcomes.
LekmodScenario={name="swiss-purchase",items={"swiss-human-armory","swiss-human-free-reward","swiss-purchase-budget","swiss-purchase-payment","swiss-purchase-mountaineer","swiss-purchase-movement-lock"}}
local phase,cityID,unitID,rewardID,price,before,started="init"
local armory=GameInfoTypes.BUILDING_SWISS_REISLAUFER
local base,active=GameInfoTypes.PROMOTION_SWISS_MOUNTAINEER,GameInfoTypes.PROMOTION_SWISS_MOUNTAINEER_ACTIVE
local function near(q)
 for d=0,5 do local n=Map.PlotDirection(q:GetX(),q:GetY(),d);if n and(n:IsMountain()or n:GetTerrainType()==GameInfoTypes.TERRAIN_MOUNTAIN)then return true end end
 return false
end
GameEvents.UnitCreated.Add(function(owner,id)
 if owner~=0 then return end;local u=Players[0]:GetUnitByID(id)
 if phase=="building"and u and u:GetUnitType()==GameInfoTypes.UNIT_SWISS_REISLAUFER then assert(not rewardID);rewardID=id end
end)
GameEvents.CityTrained.Add(function(owner,city,id,gold,faith)
 if owner==0 and city==cityID and phase=="buying"then assert(gold and not faith and not unitID);unitID=id end
end)
function LekmodScenario.snapshot(player)
 local cities,units={},{}
 for c in player:Cities()do cities[c:GetID()]={x=c:GetX(),y=c:GetY(),armory=c:GetNumRealBuilding(armory),barracks=c:GetNumRealBuilding(GameInfoTypes.BUILDING_BARRACKS)}end
 for u in player:Units()do if u:IsHasPromotion(base)and not u:IsDead()and not u:IsDelayedDeath()then units[u:GetID()]={type=u:GetUnitType(),x=u:GetX(),y=u:GetY(),moves=u:GetMoves(),maximum=u:MaxMoves(),base=u:IsHasPromotion(base),active=u:IsHasPromotion(active)}end end
 return {turn=Game.GetGameTurn(),gold=player:GetGold(),cities=cities,units=units}
end
function LekmodScenario.step(player)
 assert(player:GetID()==0 and player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_SWISS)
 if phase=="init"then
  LekmodScenarioGrantTech(player,"TECH_STEEL");local site
  for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
   if q:GetOwner()==-1 and q:GetNumUnits()==0 and not q:IsWater()and not q:IsMountain()and near(q)and player:CanFound(q:GetX(),q:GetY())then site=q;break end
  end
  assert(site,"no legal natural mountain city");player:Found(site:GetX(),site:GetY());local c=assert(site:GetPlotCity());cityID=c:GetID()
  c:SetNumRealBuilding(GameInfoTypes.BUILDING_BARRACKS,1)
  LekmodScenarioEvent("fixture-setup",{operation="provided-mountain-city-and-Barracks",city=cityID,x=c:GetX(),y=c:GetY()})
  assert(c:CanConstruct(armory));Game.CityPushOrder(c,OrderTypes.ORDER_CONSTRUCT,armory,false,true,true);phase="queue"
 elseif phase=="queue"then
  local c=player:GetCityByID(cityID);if not LekmodScenarioAwait("Swiss-human-armory-queue",c:GetProductionBuilding()==armory)then return false end
  local cost=c:GetBuildingProductionNeeded(armory);assert(cost>1);c:SetBuildingProduction(armory,cost-1)
  LekmodScenarioEvent("fixture-setup",{operation="provided-near-complete-Armory-hammers",cost=cost});phase="building";started=Game.GetGameTurn();return "turn"
 elseif phase=="building"then
  local c=player:GetCityByID(cityID)
  if c:GetNumRealBuilding(armory)~=1 then assert(Game.GetGameTurn()-started<3);return "turn"end
  LekmodScenarioRecord("swiss-human-armory","PASS","human Swiss city completed ordinary Armory production")
  local reward=assert(player:GetUnitByID(rewardID));assert(reward:IsHasPromotion(base))
  LekmodScenarioRecord("swiss-human-free-reward","PASS","normal building production generated exactly one Reislaufer")
  local remote
  for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
   if q:GetOwner()==-1 and q:GetNumUnits()==0 and not q:IsWater()and not q:IsMountain()and Map.PlotDistance(c:GetX(),c:GetY(),q:GetX(),q:GetY())>10 then remote=q;break end
  end
  assert(remote);reward:SetXY(remote:GetX(),remote:GetY(),false,true,false,false)
  local need=math.max(0,1-player:GetNumResourceAvailable(GameInfoTypes.RESOURCE_IRON,true));if need>0 then player:ChangeNumResourceTotal(GameInfoTypes.RESOURCE_IRON,need)end
  LekmodScenarioEvent("fixture-setup",{operation="provided-iron-and-clear-purchase-city",iron_added=need,reward=rewardID,x=reward:GetX(),y=reward:GetY()})
  price=c:GetUnitPurchaseCost(GameInfoTypes.UNIT_LONGSWORDSMAN);assert(price>1)
  local previous=player:GetGold();player:ChangeGold(price-1-previous)
  assert(not c:IsCanPurchase(true,true,GameInfoTypes.UNIT_LONGSWORDSMAN,-1,-1,YieldTypes.YIELD_GOLD))
  player:ChangeGold(1);assert(c:IsCanPurchase(true,true,GameInfoTypes.UNIT_LONGSWORDSMAN,-1,-1,YieldTypes.YIELD_GOLD));before=player:GetGold()
  LekmodScenarioEvent("fixture-setup",{operation="provided-exact-purchase-budget",previous_gold=previous,price=price})
  LekmodScenarioRecord("swiss-purchase-budget","PASS","quoted cost minus one rejects; exact cost permits normal purchase")
  phase="buying";LuaEvents.LekmodScenarioGoldPurchase(cityID,GameInfoTypes.UNIT_LONGSWORDSMAN)
 elseif phase=="buying"then
  if not LekmodScenarioAwait("Swiss-purchase-created",unitID~=nil)then return false end
  local u=assert(player:GetUnitByID(unitID));assert(u:GetUnitType()==GameInfoTypes.UNIT_LONGSWORDSMAN and player:GetGold()==before-price)
  LekmodScenarioRecord("swiss-purchase-payment","PASS","normal ProductionPopup purchase, native CityTrained and exact gold debit")
  assert(u:IsHasPromotion(base)and u:IsHasPromotion(active)and u:IsNearTerrainType(GameInfoTypes.TERRAIN_MOUNTAIN,1,false)and u:MaxMoves()==180)
  LekmodScenarioRecord("swiss-purchase-mountaineer","PASS","purchased Swiss Armory unit receives active mountain promotion")
  assert(u:GetMoves()==0);LekmodScenarioRecord("swiss-purchase-movement-lock","PASS","post-purchase promotion refresh retains required zero movement")
  LekmodScenarioEvent("swiss-purchase-final",LekmodScenario.snapshot(player));return true
 end
 return false
end
