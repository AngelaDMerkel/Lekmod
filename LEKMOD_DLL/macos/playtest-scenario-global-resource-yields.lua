-- Native method surface: GameCore
-- Resource probes, extra cities and prerequisite research are fixture inputs.
-- Native technology acquisition and shipped Lua grant the actual global marker.
LekmodScenario={name="global-resource-yields",items={"resource-data-rows","resource-before-tech","resource-both-cities","resource-foreign-and-type-controls","resource-owner-transition","resource-new-city","resource-no-stacking"}}
local mode=assert(LekmodScenarioParameters.mode)
local owner=mode=="wales"and 0 or 10
local foreign=mode=="wales"and 1 or 0
local civ=GameInfoTypes[mode=="wales"and"CIVILIZATION_WALES"or"CIVILIZATION_UKRAINE"]
local marker=GameInfoTypes[mode=="wales"and"BUILDING_WALES_TRAIT"or"BUILDING_UKRAINE_TRAIT"]
local tech=mode=="wales"and"TECH_ANIMAL_HUSBANDRY"or"TECH_THE_WHEEL"
local function measures(q)return {food=q:CalculateYield(YieldTypes.YIELD_FOOD,false),gold=q:CalculateYield(YieldTypes.YIELD_GOLD,false),owner=q:GetOwner(),resource=q:GetResourceType(-1),quantity=q:GetNumResource()}end
local function found(p)
 for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
  if q:GetOwner()==-1 and q:GetNumUnits()==0 and q:GetResourceType(-1)==-1 and p:CanFound(q:GetX(),q:GetY())then
   local c=p:GetCapitalCity()
   if Map.PlotDistance(q:GetX(),q:GetY(),c:GetX(),c:GetY())>8 then p:Found(q:GetX(),q:GetY());return assert(q:GetPlotCity())end
  end
 end
 error("extra city site unavailable")
end
local function probe(c,kind,used,who)
 for i=1,c:GetNumCityPlots()-1 do local q=c:GetCityIndexPlot(i)
  if q and not q:IsCity()and not q:IsWater()and not q:IsMountain()and q:GetNumUnits()==0 and not used[q:GetPlotIndex()]and Map.PlotDistance(q:GetX(),q:GetY(),c:GetX(),c:GetY())<=2 then
   used[q:GetPlotIndex()]=true;q:SetFeatureType(-1);q:SetImprovementType(-1);q:SetPlotType(PlotTypes.PLOT_LAND,true,true,false);q:SetTerrainType(GameInfoTypes.TERRAIN_GRASS,true,true);q:SetResourceType(kind,1);q:SetOwner(who,who==c:GetOwner()and c:GetID()or -1,true,true);return q
  end
 end
 error("empty probe tile unavailable")
end
function LekmodScenario.snapshot(p)
 local owners={}
 for _,id in ipairs({owner,foreign})do local o=Players[id];local cities={}
  for c in o:Cities()do local plots={}
   for i=0,c:GetNumCityPlots()-1 do local q=c:GetCityIndexPlot(i);if q then plots[q:GetPlotIndex()]=measures(q)end end
   cities[c:GetID()]={capital=c:IsCapital(),marker=c:GetNumRealBuilding(marker),plots=plots}
  end
  owners[id]={civilization=o:GetCivilizationType(),cities=cities,technology=Teams[o:GetTeam()]:IsHasTech(GameInfoTypes[tech])}
 end
 return {mode=mode,turn=Game.GetGameTurn(),owners=owners}
end
function LekmodScenario.step(p)
 assert(not Game.IsGameMultiPlayer()and Players[owner]:GetCivilizationType()==civ)
 local o=Players[owner];local capital=o:GetCapitalCity();assert(o:GetNumCities()==1 and not Teams[o:GetTeam()]:IsHasTech(GameInfoTypes[tech])and capital:GetNumRealBuilding(marker)==0)
 local rules={};local rows=0
 for r in GameInfo.Building_ResourceYieldChangesGlobal{BuildingType=GameInfo.Buildings[marker].Type}do
  assert(r.Yield==1 and(r.YieldType=="YIELD_FOOD"or r.YieldType=="YIELD_GOLD"));local id=GameInfoTypes[r.ResourceType]
  rules[id]=rules[id]or{food=0,gold=0};rules[id][r.YieldType=="YIELD_FOOD"and"food"or"gold"]=1;rows=rows+1
 end
 assert(rows==(mode=="wales"and 2 or 3));LekmodScenarioRecord("resource-data-rows","PASS","all "..rows.." configured "..mode.." resource/yield rows read from active GameInfo")
 local extra=found(o);assert(o:GetNumCities()==2);local used,targets,controls={},{},{}
 for resource,bonus in pairs(rules)do
  for _,c in ipairs({capital,extra})do local q=probe(c,resource,used,owner);targets[#targets+1]={index=q:GetPlotIndex(),city=c:GetID(),before=measures(q),bonus=bonus}end
  local q=probe(capital,resource,used,foreign);controls[#controls+1]={index=q:GetPlotIndex(),before=measures(q),kind="foreign"}
 end
 local q=probe(capital,GameInfoTypes.RESOURCE_STONE,used,owner);controls[#controls+1]={index=q:GetPlotIndex(),before=measures(q),kind="unrelated-resource"}
 assert(capital:GetNumRealBuilding(marker)==0 and extra:GetNumRealBuilding(marker)==0);LekmodScenarioRecord("resource-before-tech","PASS","two actual cities lack target marker before required technology")
 LekmodScenarioEvent("fixture-setup",{operation="owned-and-foreign-resource-probes",owner=owner,foreign=foreign,targets=targets,controls=controls})
 LekmodScenarioGrantTech(o,tech);assert(capital:GetNumRealBuilding(marker)==1 and extra:GetNumRealBuilding(marker)==0)
 for _,r in ipairs(targets)do local after=measures(Map.GetPlotByIndex(r.index));assert(after.food==r.before.food+r.bonus.food and after.gold==r.before.gold+r.bonus.gold);r.after=after end
 LekmodScenarioRecord("resource-both-cities","PASS","every declared Food/Gold increment applies to owned probes near capital and second city although only capital holds the marker")
 for _,r in ipairs(controls)do assert(LekmodScenarioJSON(measures(Map.GetPlotByIndex(r.index)))==LekmodScenarioJSON(r.before))end
 LekmodScenarioRecord("resource-foreign-and-type-controls","PASS","foreign-owned copies and own unrelated Stone retain exact pretech yields/resource/ownership")
 local t=targets[1];q=Map.GetPlotByIndex(t.index);local original=measures(q);q:SetOwner(foreign,-1,true,true)
 local matched
 for _,r in ipairs(controls)do if r.kind=="foreign"and r.before.resource==original.resource then matched=r.before end end
 assert(matched);local changed=measures(q);assert(changed.food==matched.food and changed.gold==matched.gold)
 q:SetOwner(owner,t.city,true,true);assert(LekmodScenarioJSON(measures(q))==LekmodScenarioJSON(original))
 LekmodScenarioRecord("resource-owner-transition","PASS","provided ownership transfer uses recipient yields and returning the tile restores the correct owner bonus")
 local late=found(o);assert(o:GetNumCities()==3 and late:GetNumRealBuilding(marker)==0)
 for resource,bonus in pairs(rules)do local probePlot=probe(late,resource,used,foreign);local before=measures(probePlot);probePlot:SetOwner(owner,late:GetID(),true,true);local after=measures(probePlot);assert(after.food==before.food+bonus.food and after.gold==before.gold+bonus.gold)end
 LekmodScenarioRecord("resource-new-city","PASS","probes in a third city founded after technology inherit the global bonus without another marker")
 local state=LekmodScenarioJSON(LekmodScenario.snapshot(p));Teams[o:GetTeam()]:SetHasTech(GameInfoTypes[tech],true,owner,false,false);assert(state==LekmodScenarioJSON(LekmodScenario.snapshot(p)))
 LekmodScenarioRecord("resource-no-stacking","PASS","already-held technology and three cities do not stack the capital-only global resource modifier")
 LekmodScenarioEvent("native-global-resource-yields",{mode=mode,owner=owner,rows=rows,targets=targets,controls=controls,city_count=o:GetNumCities()})
 return true
end
