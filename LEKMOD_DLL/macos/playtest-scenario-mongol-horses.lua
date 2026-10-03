-- Native method surface: GameCore
-- Native Trait_FreeResourceCities research grant. Terrain/ownership and extra
-- cities are fixture inputs; the test never places a horse or grants a marker.
LekmodScenario={name="mongol-horses",items={"mongol-active-rule","mongol-no-tech-control","mongol-all-city-grants","mongol-claim-and-food","mongol-protected-plots","mongol-new-city-after-tech","mongol-repeat-tech"}}
local mode=assert(LekmodScenarioParameters.mode)
local horse=GameInfoTypes.RESOURCE_HORSE
local function vicinity(c)
 local plots={}
 for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
  if Map.PlotDistance(q:GetX(),q:GetY(),c:GetX(),c:GetY())<=5 then plots[#plots+1]=q end
 end
 return plots
end
local function row(q)
 return {owner=q:GetOwner(),terrain=q:GetTerrainType(),kind=q:GetPlotType(),feature=q:GetFeatureType(),resource=q:GetResourceType(-1),quantity=q:GetNumResource(),improvement=q:GetImprovementType()}
end
local function allResources()
 local r={};for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i);if q:GetResourceType(-1)~=-1 then r[i]={resource=q:GetResourceType(-1),quantity=q:GetNumResource(),owner=q:GetOwner()}end end;return r
end
local function found(p)
 local site
 for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
  if q:GetOwner()==-1 and q:GetNumUnits()==0 and q:GetResourceType(-1)==-1 and p:CanFound(q:GetX(),q:GetY())then
   local distant=true
   for id=0,GameDefines.MAX_CIV_PLAYERS-1 do local other=Players[id]
    if other and other:IsAlive()then for c in other:Cities()do if Map.PlotDistance(q:GetX(),q:GetY(),c:GetX(),c:GetY())<=11 then distant=false end end end
   end
   if distant then site=q;break end
  end
 end
 assert(site,"separated city site unavailable");p:Found(site:GetX(),site:GetY());local c=assert(site:GetPlotCity());assert(c:GetOwner()==p:GetID());return c
end
function LekmodScenario.snapshot(p)
 local owners={}
 for id=0,2 do local o=Players[id];local cities={}
  for c in o:Cities()do local plots={};for _,q in ipairs(vicinity(c))do plots[q:GetPlotIndex()]=row(q);plots[q:GetPlotIndex()].food=q:CalculateYield(YieldTypes.YIELD_FOOD,false)end
   cities[c:GetID()]={legacy=c:GetNumRealBuilding(GameInfoTypes.BUILDING_TOGTVORTOI),food=c:GetNumRealBuilding(GameInfoTypes.BUILDING_MONGOL_TRAIT),plots=plots}
  end
  owners[id]={team=o:GetTeam(),civilization=o:GetCivilizationType(),chivalry=Teams[o:GetTeam()]:IsHasTech(GameInfoTypes.TECH_CHIVALRY),cities=cities}
 end
 return {mode=mode,turn=Game.GetGameTurn(),owners=owners}
end
function LekmodScenario.step(p)
 assert(not Game.IsGameMultiPlayer()and p:GetID()==0 and p:IsHuman())
 local mongol=Players[1];local team=Teams[mongol:GetTeam()]
 assert(mongol:GetCivilizationType()==GameInfoTypes.CIVILIZATION_MONGOL and not mongol:IsHuman()and mongol:GetNumCities()==1 and p:GetTeam()==mongol:GetTeam())
 assert(not team:IsHasTech(GameInfoTypes.TECH_CHIVALRY))
 local rules=0
 for r in GameInfo.Trait_FreeResourceCities{TraitType="TRAIT_TERROR"}do
  assert(r.ResourceType=="RESOURCE_HORSE"and r.ResourceQuantity==1 and r.TechType=="TECH_CHIVALRY"and r.Tech and not r.Found and not r.City and r.ClaimPlot and not r.UniqueArea and not r.CycleGroup and r.ResourceGroup==0 and r.NumCities==0);rules=rules+1
 end
 assert(rules==1)
 LekmodScenarioRecord("mongol-active-rule","PASS","active native data row grants one Horse per existing city on Chivalry with ClaimPlot; legacy Lua/Togtvortoi is inactive")
 local extra=found(mongol);assert(mongol:GetNumCities()==2)
 local targets,protected={},{}
 for c in mongol:Cities()do
  local target
  for _,q in ipairs(vicinity(c))do
   assert(not q:IsCity()or q:GetPlotCity():GetID()==c:GetID())
   if q:IsCity()then q:SetResourceType(GameInfoTypes.RESOURCE_WHEAT,1)
   else
    if not target and not q:IsWater()and not q:IsMountain()and q:GetNumUnits()==0 and Map.PlotDistance(q:GetX(),q:GetY(),c:GetX(),c:GetY())==1 then target=q end
    q:SetOwner(0,-1,true,true)
   end
  end
  if mode=="center"then target=c:Plot()end
  assert(target);target:SetFeatureType(-1);target:SetImprovementType(-1);target:SetResourceType(-1,0)
  target:SetPlotType(PlotTypes.PLOT_LAND,true,true,false);target:SetTerrainType(GameInfoTypes.TERRAIN_GRASS,true,true)
  target:SetOwner(1,c:GetID(),true,true)
  if mode=="unowned"then target:SetOwner(-1,-1,true,true)end
  if mode=="blocked-foreign"then target:SetOwner(0,-1,true,true)end
  if mode=="blocked-resource"then target:SetResourceType(GameInfoTypes.RESOURCE_WHEAT,1)end
  if mode=="blocked-mountain"then target:SetPlotType(PlotTypes.PLOT_MOUNTAIN,true,true,false)end
  targets[#targets+1]={city=c:GetID(),index=target:GetPlotIndex()}
 end
 LekmodScenarioGrantTech(p,"TECH_ANIMAL_HUSBANDRY")
 for _,r in ipairs(targets)do r.before=row(Map.GetPlotByIndex(r.index));r.food=Map.GetPlotByIndex(r.index):CalculateYield(YieldTypes.YIELD_FOOD,false)end
 for c in mongol:Cities()do assert(c:GetNumRealBuilding(GameInfoTypes.BUILDING_TOGTVORTOI)==0);for _,q in ipairs(vicinity(c))do protected[q:GetPlotIndex()]=row(q)end end
 local terrainFood,resourceFood,bonus=0,0,0
 for r in GameInfo.Terrain_Yields{TerrainType="TERRAIN_GRASS",YieldType="YIELD_FOOD"}do terrainFood=terrainFood+r.Yield end
 for r in GameInfo.Resource_YieldChanges{ResourceType="RESOURCE_HORSE",YieldType="YIELD_FOOD"}do resourceFood=resourceFood+r.Yield end
 for r in GameInfo.Building_ResourceYieldChangesGlobal{BuildingType="BUILDING_MONGOL_TRAIT",ResourceType="RESOURCE_HORSE",YieldType="YIELD_FOOD"}do bonus=bonus+r.Yield end
 local minimum=GameInfo.Yields.YIELD_FOOD.MinCity
 assert(terrainFood==2 and resourceFood==0 and bonus==1 and minimum==3)
 local before=allResources();local initial=LekmodScenarioJSON(before)
 assert(not team:IsHasTech(GameInfoTypes.TECH_CHIVALRY))
 LekmodScenarioGrantTech(p,"TECH_MASONRY");assert(LekmodScenarioJSON(allResources())==initial)
 LekmodScenarioRecord("mongol-no-tech-control","PASS","new city and unrelated Masonry do not grant Horses before Chivalry")
 LekmodScenarioEvent("fixture-setup",{operation="two-separated-cities-and-controlled-radius-five",mode=mode,targets=targets})
 LekmodScenarioGrantTech(p,"TECH_CHIVALRY");assert(team:IsHasTech(GameInfoTypes.TECH_CHIVALRY))
 local expected=mode=="owned"or mode=="unowned"or mode=="center";local grantOK,claimOK=true,true
 local expectedMap={};for i,r in pairs(before)do expectedMap[i]=r end
 for _,r in ipairs(targets)do local q=Map.GetPlotByIndex(r.index)
  if expected then
   grantOK=grantOK and q:GetResourceType(-1)==horse and q:GetNumResource()==1
   r.expected_food=q:IsCity()and math.max(terrainFood+resourceFood+bonus,minimum)or terrainFood+resourceFood+bonus
   claimOK=claimOK and q:GetOwner()==1 and q:CalculateYield(YieldTypes.YIELD_FOOD,false)==r.expected_food
   expectedMap[r.index]={resource=horse,quantity=1,owner=1}
  else grantOK=grantOK and LekmodScenarioJSON(row(q))==LekmodScenarioJSON(r.before)end
  r.after=row(q);r.food_after=q:CalculateYield(YieldTypes.YIELD_FOOD,false)
 end
 LekmodScenarioRecord("mongol-all-city-grants",grantOK and"PASS"or"FAIL","mode="..mode.." requires "..(expected and"one quantity1 Horse per existing city"or"no placement on either blocked candidate"))
 LekmodScenarioRecord("mongol-claim-and-food",claimOK and"PASS"or"FAIL","positive grants stay/become owned by Mongol; Food uses grass2 + Horse0 + trait1, with city minimum3; blocked cases add none")
 local ok=LekmodScenarioJSON(expectedMap)==LekmodScenarioJSON(allResources())
 local targetSet={};for _,r in ipairs(targets)do targetSet[r.index]=true end
 for i,v in pairs(protected)do local q=Map.GetPlotByIndex(i);local after=row(q)
  for key,value in pairs(v)do if not(expected and targetSet[i]and(key=="resource"or key=="quantity"or key=="owner"))and after[key]~=value then ok=false end end
 end
 for id=0,2 do for c in Players[id]:Cities()do assert(c:GetNumRealBuilding(GameInfoTypes.BUILDING_TOGTVORTOI)==0);assert(c:GetNumRealBuilding(GameInfoTypes.BUILDING_MONGOL_TRAIT)==(id==1 and c:IsCapital()and 1 or 0))end end
 LekmodScenarioRecord("mongol-protected-plots",ok and"PASS"or"FAIL","world resource map changes only at the expected two candidates; old resources, foreign territory, other plot attributes and owner-specific markers retained")
 local beforeFound=LekmodScenarioJSON(allResources());local late=found(mongol);assert(mongol:GetNumCities()==3 and beforeFound==LekmodScenarioJSON(allResources()))
 LekmodScenarioRecord("mongol-new-city-after-tech","PASS","Found=false: actual third city founded after Chivalry receives no retrospective Horse")
 local same=LekmodScenarioJSON(LekmodScenario.snapshot(p));team:SetHasTech(GameInfoTypes.TECH_CHIVALRY,true,p:GetID(),false,false)
 LekmodScenarioRecord("mongol-repeat-tech",same==LekmodScenarioJSON(LekmodScenario.snapshot(p))and"PASS"or"FAIL","already-known Chivalry cannot repeat the grant")
 LekmodScenarioEvent("native-Mongol-horse-outcome",{mode=mode,expected_horse=expected,targets=targets,new_city=late:GetID(),num_cities=mongol:GetNumCities()})
 return true
end
