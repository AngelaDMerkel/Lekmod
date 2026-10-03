-- Native method surface: GameCore
-- Legal city sites, neutral city terrain and Wheat are fixture inputs. Resource
-- copies and +2 city Gold must come from native founding/acquisition/destruction.
-- Continuation starts from the first phase's verified, reloaded checkpoint.
LekmodScenario={name="indonesia-resources",items={"spice-data-rules","spice-loaded-boundary","spice-founding-sequence","spice-city-gold-and-tile","spice-same-area-control","spice-owner-accounting","spice-foreign-control"}}
local mode=assert(LekmodScenarioParameters.mode)
local owner,foreign=11,1
local resourceNames={"RESOURCE_CLOVES","RESOURCE_NUTMEG","RESOURCE_PEPPER"}
local function audit(point)
 if type(Game.ReadResourceGrantsForTest)~="function"then return end
 local ok,state=pcall(Game.ReadResourceGrantsForTest,owner)
 if ok then
  for _,bad in ipairs({-1,0.5,GameDefines.MAX_MAJOR_CIVS,math.huge,0/0})do assert(not pcall(Game.ReadResourceGrantsForTest,bad),"native diagnostic accepted invalid owner")end
  local before=LekmodScenarioJSON(LekmodScenario.snapshot(Players[0]));assert(LekmodScenarioJSON(Game.ReadResourceGrantsForTest(owner))==LekmodScenarioJSON(state));assert(LekmodScenarioJSON(LekmodScenario.snapshot(Players[0]))==before,"diagnostic changed observed gameplay state")
  LekmodScenarioEvent("native-spice-rule-history",{point=point,state=state})
 elseif not string.find(tostring(state),"requires the explicit test environment",1,true)then error(state)end
end
local names={"Lekmod Spice First","Lekmod Spice Second","Lekmod Spice Third","Lekmod Spice Exhausted"}
local function totals(p)local r={};for _,name in ipairs(resourceNames)do r[name]=p:GetNumResourceTotal(GameInfoTypes[name],false)end;return r end
local function requireTotals(p,a,b,c)local r=totals(p);assert(r.RESOURCE_CLOVES==a and r.RESOURCE_NUTMEG==b and r.RESOURCE_PEPPER==c,"spice counts "..LekmodScenarioJSON(r));return r end
local function cityNamed(p,name)for c in p:Cities()do if c:GetName()==name then return c end end end
local function available(p)
 local areas={}
 for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
  if q:GetOwner()==-1 and q:GetNumUnits()==0 and q:GetResourceType(-1)==-1 and p:CanFound(q:GetX(),q:GetY())then areas[q:GetArea()]=areas[q:GetArea()]or q end
 end
 return areas
end
local function choose(p,exclude)
 local selected
 for area,q in pairs(available(p))do if not exclude[area]and(not selected or q:GetPlotIndex()<selected:GetPlotIndex())then selected=q end end
 assert(selected,"fixture lacks an eligible unused overseas area");return selected
end
local function prepare(q,p)
 assert(not q:IsWater()and not q:IsMountain()and not q:IsCity()and q:GetNumUnits()==0)
 local area=q:GetArea();q:SetFeatureType(-1);q:SetImprovementType(-1);q:SetPlotType(PlotTypes.PLOT_LAND,true,true,false);q:SetTerrainType(GameInfoTypes.TERRAIN_GRASS,true,true);q:SetResourceType(GameInfoTypes.RESOURCE_WHEAT,1);q:SetOwner(p:GetID(),-1,true,true)
 assert(q:GetArea()==area and p:CanFound(q:GetX(),q:GetY()));return area
end
local function founding(p,q,name,expectedBonus,observations)
 local area=prepare(q,p);local base=q:CalculateYield(YieldTypes.YIELD_GOLD,false);local before=totals(p)
 assert(base==0 and GameInfo.Yields.YIELD_GOLD.MinCity==0,"unexpected prepared base city Gold")
 audit("before-found-"..name);p:Found(q:GetX(),q:GetY());audit("after-found-"..name);local c=assert(q:GetPlotCity());assert(c:GetOwner()==p:GetID());c:SetName(name,false)
 assert(q:GetResourceType(-1)==GameInfoTypes.RESOURCE_WHEAT and q:GetNumResource()==1,"City=true grant overwrote provided Wheat")
 assert(q:CalculateYield(YieldTypes.YIELD_GOLD,false)==base+expectedBonus,"wrong free-resource city Gold")
 local r={name=name,city=c:GetID(),x=q:GetX(),y=q:GetY(),area=area,before=before,after=totals(p),gold=q:CalculateYield(YieldTypes.YIELD_GOLD,false),expected_bonus=expectedBonus,resource=q:GetResourceType(-1),quantity=q:GetNumResource()};observations[#observations+1]=r;LekmodScenarioEvent("native-spice-founding",r);return c
end
function LekmodScenario.snapshot(p)
 local owners={}
 for _,id in ipairs({owner,foreign})do local o=Players[id];local cities={}
  for c in o:Cities()do local q=c:Plot();cities[c:GetID()]={name=c:GetName(),x=c:GetX(),y=c:GetY(),owner=c:GetOwner(),capital=c:IsCapital(),area=q:GetArea(),resource=q:GetResourceType(-1),quantity=q:GetNumResource(),gold=q:CalculateYield(YieldTypes.YIELD_GOLD,false)}end
  owners[id]={civilization=o:GetCivilizationType(),resources=totals(o),cities=cities}
 end
 return {mode=mode,turn=Game.GetGameTurn(),owners=owners}
end
function LekmodScenario.step(p)
 assert(not Game.IsGameMultiPlayer()and Players[owner]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_INDONESIA and not Players[owner]:IsHuman()and not Players[foreign]:IsHuman())
 audit("phase-"..mode.."-loaded");local o=Players[owner];local other=Players[foreign];local n=0
 for r in GameInfo.Trait_FreeResourceCities{TraitType="TRAIT_SPICE"}do
  assert(r.ResourceQuantity==2 and r.City and r.Found and not r.Tech and r.UniqueArea and not r.ClaimPlot and r.ResourceGroup==1 and r.CycleGroup and r.NumCities==0 and r.Priority>=0 and r.Priority<=2 and r.ResourceType==resourceNames[r.Priority+1]);n=n+1
 end
 assert(n==3);n=0;for r in GameInfo.Trait_FreeResourceCityYieldChanges{TraitType="TRAIT_SPICE"}do assert(r.YieldType=="YIELD_GOLD"and r.Yield==2);n=n+1 end;assert(n==1)
 LekmodScenarioRecord("spice-data-rules","PASS","three quantity2 City/Found/UniqueArea group1 rules, priorities0/1/2, plus2cityGold; capital area is reserved by native first founding")
 local observations={};local capital=assert(o:GetCapitalCity());local home=capital:Plot():GetArea();local otherBefore=LekmodScenarioJSON(LekmodScenario.snapshot(p).owners[foreign]);local excluded={[home]=true}
 if mode=="first"then
  assert(o:GetNumCities()==1);requireTotals(o,0,0,0);requireTotals(other,0,0,0)
  local choices=available(o);local distinct=0;for area in pairs(choices)do if area~=home then distinct=distinct+1 end end
  assert(choices[home]and distinct>=4,"fixture needs home-area site plus four overseas areas; observed="..distinct)
  LekmodScenarioEvent("fixture-available-areas",{overseas=distinct,home=home})
  LekmodScenarioRecord("spice-loaded-boundary","PASS","ordinary initial-save capital has no spices; saved home area already counts as used")
  founding(o,choices[home],"Lekmod Spice Home",0,observations);requireTotals(o,0,0,0)
  LekmodScenarioRecord("spice-same-area-control","PASS","actual second city on the capital's used area gets no copies or2Gold")
  founding(o,choose(o,excluded),names[1],2,observations);requireTotals(o,2,0,0)
  LekmodScenarioRecord("spice-founding-sequence","PASS","first new landmass grants Cloves2 only, preserving Nutmeg/Pepper for later priorities")
  LekmodScenarioRecord("spice-owner-accounting","PASS","two virtual Cloves copies belong to Indonesia without adding a map resource")
 else
  assert(mode=="continue"and o:GetNumCities()==3);requireTotals(o,2,0,0);requireTotals(other,0,0,0)
  local first=assert(cityNamed(o,names[1]));local q=first:Plot();local firstArea=q:GetArea();excluded[firstArea]=true
  assert(q:GetResourceType(-1)==GameInfoTypes.RESOURCE_WHEAT and q:CalculateYield(YieldTypes.YIELD_GOLD,false)==2)
  LekmodScenarioRecord("spice-loaded-boundary","PASS","separate-process first-grant checkpoint retains Cloves2, cityGold2 and original Wheat")
  local beforeX,beforeY=q:GetX(),q:GetY();other:AcquireCity(first,false,true);local taken=assert(q:GetPlotCity());assert(taken:GetOwner()==foreign);requireTotals(o,0,0,0);requireTotals(other,2,0,0);assert(q:CalculateYield(YieldTypes.YIELD_GOLD,false)==2 and q:GetResourceType(-1)==GameInfoTypes.RESOURCE_WHEAT)
  o:AcquireCity(taken,false,true);local returned=assert(q:GetPlotCity());assert(returned:GetOwner()==owner);requireTotals(o,2,0,0);requireTotals(other,0,0,0);assert(q:CalculateYield(YieldTypes.YIELD_GOLD,false)==2)
  LekmodScenarioEvent("native-spice-owner-transfer",{x=beforeX,y=beforeY,source=owner,recipient=foreign,quantity=2,gold=2,round_trip=true,via="native-AcquireCity-trade-API"})
  returned:Kill();assert(not q:GetPlotCity());requireTotals(o,0,0,0);requireTotals(other,0,0,0)
  assert(o:CanFound(q:GetX(),q:GetY()));founding(o,q,"Lekmod Spice Refounded",0,observations);requireTotals(o,0,0,0)
  LekmodScenarioRecord("spice-same-area-control","PASS","destroyed granted city revokes copies; re-founding its saved used area gives neither new resource nor2Gold")
  LekmodScenarioRecord("spice-owner-accounting","PASS","native acquisition transfers two copies and2Gold once; return restores source, destruction revokes without negative/doubled counters")
  for index=2,4 do
   local site=choose(o,excluded);excluded[site:GetArea()]=true;founding(o,site,names[index],index<=3 and 2 or 0,observations)
   requireTotals(o,0,2,index>=3 and 2 or 0)
  end
  LekmodScenarioRecord("spice-founding-sequence","PASS","saved priority advances to Nutmeg2 then Pepper2; fourth new landmass receives none and cycle does not wrap")
 end
 LekmodScenarioRecord("spice-city-gold-and-tile","PASS","every supplied Wheat city tile is preserved; qualifying native city grant adds exactly2Gold once, excluded/exhausted cities add0")
 assert(LekmodScenarioJSON(LekmodScenario.snapshot(p).owners[foreign])==otherBefore)
 LekmodScenarioRecord("spice-foreign-control","PASS","unrelated foreign cities, resources and tile yields remain exact after this phase and any round-trip transfer")
 LekmodScenarioEvent("native-spice-phase-complete",{mode=mode,owner=owner,resources=totals(o),cities=o:GetNumCities(),founding=observations})
 return true
end
