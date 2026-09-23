-- Requested civilization owners come from the normal-start matrix. Research,
-- an extra Aksum city, prerequisite Monuments and near-complete hammers are
-- explicit inputs. The two targets must be produced on ordinary owner turns.
LekmodScenario={name="unique-building-pilot",items={"unique-building-replacement-controls","Akkad-library-production","Akkad-library-science","Aksum-epic-production","Aksum-global-monument-yields","Aksum-building-owner-control"}}
local phase,before,orderedAI,started="init",nil,false,nil
local built={}
local library=GameInfoTypes.BUILDING_AKKAD_LIBRARY
local epic=GameInfoTypes.BUILDING_ASKUM_NATIONAL_EPIC
local monument=GameInfoTypes.BUILDING_MONUMENT
local class=GameInfoTypes.BUILDINGCLASS_MONUMENT
local yields={YieldTypes.YIELD_FOOD,YieldTypes.YIELD_PRODUCTION,YieldTypes.YIELD_GOLD,YieldTypes.YIELD_SCIENCE,YieldTypes.YIELD_CULTURE,YieldTypes.YIELD_FAITH}
local function cityState(c)
 local base,policy={},{};local owner=Players[c:GetOwner()]
 for _,y in ipairs(yields)do
  base[y]=c:GetBaseYieldRateFromBuildings(y);policy[y]=0
  for info in GameInfo.Buildings()do
   local count=c:GetNumBuilding(info.ID)
   if count>0 then policy[y]=policy[y]+count*owner:GetPolicyBuildingClassYieldChange(GameInfoTypes[info.BuildingClass],y)end
  end
 end
 return {x=c:GetX(),y=c:GetY(),population=c:GetPopulation(),library=c:GetNumRealBuilding(library),epic=c:GetNumRealBuilding(epic),monument=c:GetNumRealBuilding(monument),base=base,policy_building_yields=policy,science_per_pop100=c:GetYieldPerPopTimes100(YieldTypes.YIELD_SCIENCE)}
end
function LekmodScenario.snapshot(player)
 local owners={}
 for owner=0,1 do local p=Players[owner];local cities,bonus={},{}
  for c in p:Cities()do cities[c:GetID()]=cityState(c)end
  for _,y in ipairs(yields)do bonus[y]=p:GetPlayerBuildingClassYieldChange(class,y)end
  local policies={};for info in GameInfo.Policies()do if p:HasPolicy(info.ID)then policies[info.Type]=true end end
  owners[owner]={civ=p:GetCivilizationType(),cities=cities,monument_bonus=bonus,policies=policies}
 end
 return {turn=Game.GetGameTurn(),owners=owners}
end
GameEvents.PlayerAdoptPolicy.Add(function(owner,policy)if owner==0 or owner==1 then LekmodScenarioEvent("observed-natural-policy",{owner=owner,policy=GameInfo.Policies[policy].Type,turn=Game.GetGameTurn()})end end)
GameEvents.CityConstructed.Add(function(owner,city,building,gold,faith)
 if(owner==0 and building==library)or(owner==1 and building==epic)then
  assert(not gold and not faith,"target was purchased rather than produced")
  built[owner]=city;LekmodScenarioEvent("native-unique-building-constructed",{owner=owner,city=city,building=building,turn=Game.GetGameTurn()})
 end
end)
GameEvents.PlayerDoTurn.Add(function(owner)
 if owner==1 and phase=="building"and not orderedAI then
  local p=Players[1];assert(not p:IsHuman()and p:IsTurnActive(),"AI order must use actual owner turn")
  local c=assert(p:GetCapitalCity());assert(c:CanConstruct(epic))
  -- Game.CityPushOrder routes by active-human city ID; use the AI's actual
  -- city queue on its own turn, with bForce=0 and legal eligibility checked.
  c:PushOrder(OrderTypes.ORDER_CONSTRUCT,epic,-1,0,true,false,0)
  assert(c:GetProductionBuilding()==epic,"AI legal production order was not queued")
  local cost=c:GetBuildingProductionNeeded(epic);assert(cost>1);c:SetBuildingProduction(epic,cost-1)
  orderedAI=true
  LekmodScenarioEvent("fixture-setup",{operation="provided-AI-queued-near-complete-production",owner=1,city=c:GetID(),building=epic,cost=cost,hammers=cost-1,force=false})
 end
end)
function LekmodScenario.step(player)
 local human=assert(player:GetCapitalCity());local ai=Players[1];local capital=assert(ai:GetCapitalCity())
 if phase=="init"then
  assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_AKKAD and ai:GetCivilizationType()==GameInfoTypes.CIVILIZATION_AKSUM)
  assert(human:GetNumRealBuilding(library)==0 and capital:GetNumRealBuilding(epic)==0)
  assert(not human:CanConstruct(library),"library unexpectedly eligible before Writing")
  LekmodScenarioGrantTech(player,"TECH_DRAMA");LekmodScenarioGrantTech(ai,"TECH_DRAMA")
  local extra
  for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i);local d=Map.PlotDistance(p:GetX(),p:GetY(),capital:GetX(),capital:GetY())
   if d>=4 and d<=9 and p:GetNumUnits()==0 and p:GetOwner()==-1 and ai:CanFound(p:GetX(),p:GetY())then
    ai:Found(p:GetX(),p:GetY());extra=assert(p:GetPlotCity());break
   end
  end
  assert(extra,"no legal extra-city input for owner-wide yield test")
  LekmodScenarioEvent("fixture-setup",{operation="provided-second-Aksum-city",id=extra:GetID(),x=extra:GetX(),y=extra:GetY()})
  for owner=0,1 do for c in Players[owner]:Cities()do
   assert(c:GetNumRealBuilding(monument)==0,"fixture already contains a Monument")
   c:SetNumRealBuilding(monument,1)
   LekmodScenarioEvent("fixture-setup",{operation="provided-prerequisite-Monument",owner=owner,city=c:GetID()})
  end end
  assert(human:CanConstruct(library)and not human:CanConstruct(GameInfoTypes.BUILDING_LIBRARY))
  assert(capital:CanConstruct(GameInfoTypes.BUILDING_LIBRARY)and not capital:CanConstruct(library))
  assert(capital:CanConstruct(epic)and not capital:CanConstruct(GameInfoTypes.BUILDING_NATIONAL_EPIC))
  assert(human:CanConstruct(GameInfoTypes.BUILDING_NATIONAL_EPIC)and not human:CanConstruct(epic))
  LekmodScenarioRecord("unique-building-replacement-controls","PASS","Writing gate, correct replacements, default-building and foreign-owner controls")
  before=LekmodScenario.snapshot(player);LekmodScenarioEvent("unique-building-before",before)
  Game.CityPushOrder(human,OrderTypes.ORDER_CONSTRUCT,library,false,true,true);phase="human-queued"
 elseif phase=="human-queued"then
  if not LekmodScenarioAwait("Akkad-library-queued",human:GetProductionBuilding()==library)then return false end
  local cost=human:GetBuildingProductionNeeded(library);assert(cost>1);human:SetBuildingProduction(library,cost-1)
  LekmodScenarioEvent("fixture-setup",{operation="provided-human-near-complete-production",cost=cost,hammers=cost-1})
  started=Game.GetGameTurn();phase="building";return "turn"
 elseif phase=="building"then
  if not built[0]or not built[1]then assert(Game.GetGameTurn()-started<3,"building production exceeded three ordinary turns");return "turn"end
  assert(orderedAI and human:GetNumRealBuilding(library)==1 and capital:GetNumRealBuilding(epic)==1)
  assert(not human:CanConstruct(library)and not capital:CanConstruct(epic),"completed building remained constructible")
  local after=LekmodScenario.snapshot(player);LekmodScenarioEvent("unique-building-after",after)
  local h0=before.owners[0].cities[human:GetID()];local h1=after.owners[0].cities[human:GetID()]
  assert(h1.base[YieldTypes.YIELD_SCIENCE]-h1.policy_building_yields[YieldTypes.YIELD_SCIENCE]==h0.base[YieldTypes.YIELD_SCIENCE]-h0.policy_building_yields[YieldTypes.YIELD_SCIENCE]+1 and h1.science_per_pop100==h0.science_per_pop100+50,"Akkad flat/per-population science differs")
  local boosted={[YieldTypes.YIELD_FOOD]=true,[YieldTypes.YIELD_PRODUCTION]=true,[YieldTypes.YIELD_GOLD]=true,[YieldTypes.YIELD_FAITH]=true}
  for _,y in ipairs(yields)do
   local add=boosted[y]and 1 or 0
   assert(after.owners[1].monument_bonus[y]==before.owners[1].monument_bonus[y]+add,"Aksum global Monument bonus differs")
   assert(after.owners[0].monument_bonus[y]==before.owners[0].monument_bonus[y],"Aksum bonus leaked to Akkad")
   if y~=YieldTypes.YIELD_SCIENCE then assert(h1.base[y]-h1.policy_building_yields[y]==h0.base[y]-h0.policy_building_yields[y],"Aksum changed foreign owner's building yields")end
   for id,c in pairs(after.owners[1].cities)do
    local flat=(id==capital:GetID()and(y==YieldTypes.YIELD_FAITH or y==YieldTypes.YIELD_CULTURE))and 4 or 0
    local previous=before.owners[1].cities[id]
    assert(c.base[y]-c.policy_building_yields[y]==previous.base[y]-previous.policy_building_yields[y]+add+flat,"Aksum city contribution differs after accounting for observed policy yields: "..y)
   end
  end
  LekmodScenarioRecord("Akkad-library-production","PASS","normal human city order and native CityConstructed; provided near-complete hammers")
  LekmodScenarioRecord("Akkad-library-science","PASS","building science +1; yield per population +50/100")
  LekmodScenarioRecord("Aksum-epic-production","PASS","eligible unforced AI queue on real owner turn and native CityConstructed")
  LekmodScenarioRecord("Aksum-global-monument-yields","PASS","food/production/gold/faith +1 per Monument in both owner cities; epic culture/faith +4 at capital")
  LekmodScenarioRecord("Aksum-building-owner-control","PASS","Akkad Monument bonuses and nonscience building yields unchanged")
  return true
 end
 return false
end
