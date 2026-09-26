-- Native method surface: GameCore
-- Research, legal mountain-adjacent cities, Barracks, iron and near-complete
-- hammers are inputs. Building rewards/trained promotions must be native.
LekmodScenario={name="swiss-armory",items={"swiss-armory-owner-gate","swiss-armory-production","swiss-armory-free-unit","swiss-armory-trained-promotion","swiss-armory-terrain-at-training","swiss-armory-birth-movement","swiss-armory-trained-movement"}}
local phase,targets,started="init",{},nil
local base,active=GameInfoTypes.PROMOTION_SWISS_MOUNTAINEER,GameInfoTypes.PROMOTION_SWISS_MOUNTAINEER_ACTIVE
local reward=GameInfoTypes.UNIT_SWISS_REISLAUFER
local function near(q)
 if q:IsMountain()or q:GetTerrainType()==GameInfoTypes.TERRAIN_MOUNTAIN then return true end
 for d=0,5 do local n=Map.PlotDirection(q:GetX(),q:GetY(),d);if n and(n:IsMountain()or n:GetTerrainType()==GameInfoTypes.TERRAIN_MOUNTAIN)then return true end end
 return false
end
local function cityFor(p)
 for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
  if q:GetOwner()==-1 and q:GetNumUnits()==0 and not q:IsWater()and not q:IsMountain()and near(q)and p:CanFound(q:GetX(),q:GetY())then
   p:Found(q:GetX(),q:GetY());local c=assert(q:GetPlotCity());LekmodScenarioEvent("fixture-setup",{operation="provided-legal-mountain-city",owner=p:GetID(),city=c:GetID(),x=c:GetX(),y=c:GetY()});return c
  end
 end
 error("no natural legal mountain-adjacent city")
end
GameEvents.CityConstructed.Add(function(owner,city,building,gold,faith)
 local t=targets[owner];if t and t.city==city and t.building==building then assert(t.queued and not gold and not faith);t.built=true;LekmodScenarioEvent("native-armory-built",{owner=owner,city=city,building=building})end
end)
GameEvents.UnitCreated.Add(function(owner,id)
 local t=targets[owner];if not t then return end
 local u=Players[owner]:GetUnitByID(id)
 if u and u:GetUnitType()==reward then assert(owner==3 and not t.reward and phase=="building");t.reward=id;t.rewardState={base=u:IsHasPromotion(base),active=u:IsHasPromotion(active),moves=u:GetMoves(),max_moves=u:MaxMoves()};LekmodScenarioEvent("native-Reislaufer-reward",{owner=owner,id=id,x=u:GetX(),y=u:GetY(),mountaineer=u:IsHasPromotion(base),active=u:IsHasPromotion(active),max_moves=u:MaxMoves(),moves=u:GetMoves()})end
end)
GameEvents.CityTrained.Add(function(owner,city,id,gold,faith)
 local t=targets[owner];if not t or phase~="training"or t.city~=city then return end
 local u=Players[owner]:GetUnitByID(id);if u and u:GetUnitType()==GameInfoTypes.UNIT_LONGSWORDSMAN then assert(t.queued and not gold and not faith and not t.trained);t.trained=id end
end)
local function observe(t)
 if not t.trained or t.observed then return end
 local u=assert(Players[t.owner]:GetUnitByID(t.trained));local nearby=u:IsNearTerrainType(GameInfoTypes.TERRAIN_MOUNTAIN,1,false)
 t.observed={near=nearby,base=u:IsHasPromotion(base),active=u:IsHasPromotion(active),moves=u:GetMoves(),max_moves=u:MaxMoves(),x=u:GetX(),y=u:GetY()}
 LekmodScenarioEvent("armory-trained-settled-state",{owner=t.owner,unit=t.trained,state=t.observed})
end
local function queue(t,human)
 local p=Players[t.owner];local c=p:GetCityByID(t.city);local order,id,cost
 if phase=="building"then order=OrderTypes.ORDER_CONSTRUCT;id=t.building;assert(c:CanConstruct(id));cost=c:GetBuildingProductionNeeded(id)
 else
  order=OrderTypes.ORDER_TRAIN;id=GameInfoTypes.UNIT_LONGSWORDSMAN
  local need=math.max(0,1-p:GetNumResourceAvailable(GameInfoTypes.RESOURCE_IRON,true));if need>0 then p:ChangeNumResourceTotal(GameInfoTypes.RESOURCE_IRON,need);LekmodScenarioEvent("fixture-setup",{operation="provided-training-iron",owner=t.owner,amount=need})end
  assert(c:CanTrain(id));cost=c:GetUnitProductionNeeded(id)
 end
 if human then Game.CityPushOrder(c,order,id,false,true,true);return end
 assert(p:IsTurnActive()and not p:IsHuman());c:PushOrder(order,id,-1,0,true,false,0)
 assert((phase=="building"and c:GetProductionBuilding()or c:GetProductionUnit())==id);assert(cost>1)
 if phase=="building"then c:SetBuildingProduction(id,cost-1)else c:SetUnitProduction(id,cost-1)end
 t.queued=true;LekmodScenarioEvent("fixture-setup",{operation="provided-near-complete-armory-case",owner=t.owner,city=t.city,phase=phase,type=id,cost=cost})
end
GameEvents.PlayerDoTurn.Add(function(owner)
 local t=targets[owner];if not t then return end
 if phase=="training"then observe(t)end
 if owner~=Game.GetActivePlayer()and(phase=="building"or phase=="training")and not t.queued then queue(t,false)end
end)
function LekmodScenario.snapshot(player)
 local owners={}
 for _,owner in ipairs({0,3})do local p=Players[owner];local cities,units={},{}
  for c in p:Cities()do cities[c:GetID()]={x=c:GetX(),y=c:GetY(),population=c:GetPopulation(),armory=c:GetNumRealBuilding(GameInfoTypes.BUILDING_ARMORY),swiss_armory=c:GetNumRealBuilding(GameInfoTypes.BUILDING_SWISS_REISLAUFER),barracks=c:GetNumRealBuilding(GameInfoTypes.BUILDING_BARRACKS)}end
  for u in p:Units()do if not u:IsDead()and not u:IsDelayedDeath()then units[u:GetID()]={type=u:GetUnitType(),x=u:GetX(),y=u:GetY(),moves=u:GetMoves(),max_moves=u:MaxMoves(),experience=u:GetExperience(),mountaineer=u:IsHasPromotion(base),active=u:IsHasPromotion(active)}end end
  owners[owner]={civilization=p:GetCivilizationType(),cities=cities,units=units}
 end
 return {turn=Game.GetGameTurn(),owners=owners}
end
function LekmodScenario.step(player)
 assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_SPAIN and Players[3]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_SWISS)
 if phase=="init"then
  for _,owner in ipairs({0,3})do local p=Players[owner];LekmodScenarioGrantTech(p,"TECH_STEEL");local c=cityFor(p)
   c:SetNumRealBuilding(GameInfoTypes.BUILDING_BARRACKS,1);LekmodScenarioEvent("fixture-setup",{operation="provided-prerequisite-Barracks",owner=owner,city=c:GetID()})
   targets[owner]={owner=owner,city=c:GetID(),building=owner==3 and GameInfoTypes.BUILDING_SWISS_REISLAUFER or GameInfoTypes.BUILDING_ARMORY}
  end
  assert(not player:GetCityByID(targets[0].city):CanConstruct(GameInfoTypes.BUILDING_SWISS_REISLAUFER))
  assert(Players[3]:GetCityByID(targets[3].city):CanConstruct(GameInfoTypes.BUILDING_SWISS_REISLAUFER))
  LekmodScenarioRecord("swiss-armory-owner-gate","PASS","Swiss unique eligible; matching Spanish city rejects it")
  phase="building";started=Game.GetGameTurn();queue(targets[0],true)
 elseif phase=="building"or phase=="training"then
  local t=targets[0];local c=player:GetCityByID(t.city);local id=phase=="building"and t.building or GameInfoTypes.UNIT_LONGSWORDSMAN
  if not t.queued then
   if not LekmodScenarioAwait("human-armory-queue-"..phase,(phase=="building"and c:GetProductionBuilding()or c:GetProductionUnit())==id)then return false end
   local cost=phase=="building"and c:GetBuildingProductionNeeded(id)or c:GetUnitProductionNeeded(id);assert(cost>1)
   if phase=="building"then c:SetBuildingProduction(id,cost-1)else c:SetUnitProduction(id,cost-1)end;t.queued=true
   LekmodScenarioEvent("fixture-setup",{operation="provided-human-near-complete-armory-case",phase=phase,cost=cost})
  end
  if phase=="building"then
   if not targets[0].built or not targets[3].built then assert(Game.GetGameTurn()-started<3);return "turn"end
   assert(targets[3].reward and not targets[0].reward);local u=assert(Players[3]:GetUnitByID(targets[3].reward));assert(u:IsHasPromotion(base))
   LekmodScenarioRecord("swiss-armory-production","PASS","both owners completed unforced native building production")
   LekmodScenarioRecord("swiss-armory-free-unit","PASS","Swiss building generated exactly one native Reislaufer; standard Armory control generated none")
   local birth=targets[3].rewardState
   assert(birth.base and birth.active and birth.moves==birth.max_moves and birth.max_moves==240,"native free Reislaufer lacks full mountain movement at birth")
   LekmodScenarioRecord("swiss-armory-birth-movement","PASS","native free reward begins with all four mountain-adjacent moves")
   -- Keep the reward from occupying the controlled training tile. This is
   -- explicit staging, not travel evidence; its own movement is a separate case.
   local city=Players[3]:GetCityByID(targets[3].city);local remote
   for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
    if q:GetOwner()==-1 and q:GetNumUnits()==0 and not q:IsWater()and not q:IsMountain()and Map.PlotDistance(q:GetX(),q:GetY(),city:GetX(),city:GetY())>20 then remote=q;break end
   end
   assert(remote);u:SetXY(remote:GetX(),remote:GetY(),false,true,false,false)
   LekmodScenarioEvent("fixture-setup",{operation="provided-remote-reward-unit-staging",owner=3,unit=u:GetID(),x=u:GetX(),y=u:GetY()})
   phase="training";started=Game.GetGameTurn();for _,v in pairs(targets)do v.queued=false end;queue(targets[0],true)
  else
   observe(targets[0]);if not targets[0].observed or not targets[3].observed then assert(Game.GetGameTurn()-started<3);return "turn"end
   local own,control=targets[3].observed,targets[0].observed
   assert(own.base and not control.base and not control.active,"city-granted promotion owner control differs")
   LekmodScenarioRecord("swiss-armory-trained-promotion","PASS","ordinary Swiss training grants Mountaineer; standard Armory control does not")
   assert(own.near,"trained Swiss unit was not in the controlled mountain range")
   assert(own.active,"trained Mountaineer lacks active mountain bonus after native production bookkeeping")
   LekmodScenarioRecord("swiss-armory-terrain-at-training","PASS","native training has active terrain benefit before its first movement")
   assert(own.moves==180 and own.max_moves==180 and control.moves==120 and control.max_moves==120,"new training movement differs from full derived allowance")
   LekmodScenarioRecord("swiss-armory-trained-movement","PASS","Swiss training begins with three moves; Spanish control retains two")
   return true
  end
 end
 return false
end
