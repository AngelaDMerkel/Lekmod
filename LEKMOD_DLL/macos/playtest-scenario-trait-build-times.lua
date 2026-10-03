-- Native method surface: GameCore
-- Owned featureless plots/resources, prerequisite research and workers are inputs.
-- Each worker receives one real build mission on its owner's ordinary turn.
LekmodScenario={name="trait-build-times",items={"build-configured-rows","build-resource-visibility","build-resource-class-controls","build-foreign-control","build-scaled-prices","build-native-orders","build-native-completions"}}
local mode=assert(LekmodScenarioParameters.mode)
local config={
 russia={owner=6,civ="CIVILIZATION_RUSSIA",trait="TRAIT_STRATEGIC_RICHES",rows={{"BUILD_MINE","RESOURCE_IRON","RESOURCECLASS_RUSH",0},{"BUILD_PASTURE","RESOURCE_HORSE","RESOURCECLASS_RUSH",0},{"BUILD_WELL","RESOURCE_OIL","RESOURCECLASS_MODERN",0},{"BUILD_OFFSHORE_PLATFORM_WORKER","RESOURCE_OIL","RESOURCECLASS_MODERN",0},{"BUILD_MINE","RESOURCE_COAL","RESOURCECLASS_MODERN",0}}},
 argentina={owner=4,civ="CIVILIZATION_ARGENTINA",trait="TRAIT_ARGENTINA",rows={{"BUILD_PASTURE","RESOURCE_COW",false,400},{"BUILD_FARM","RESOURCE_WHEAT",false,400}}},
 arabia={owner=3,civ="CIVILIZATION_ARABIA",trait="TRAIT_LAND_TRADE_GOLD",rows={{"BUILD_MINE","RESOURCE_GEMS","RESOURCECLASS_LUXURY",400},{"BUILD_QUARRY","RESOURCE_MARBLE","RESOURCECLASS_LUXURY",400},{"BUILD_CAMP","RESOURCE_FUR","RESOURCECLASS_LUXURY",400},{"BUILD_FISHING_BOATS_WORKER","RESOURCE_WHALE","RESOURCECLASS_LUXURY",400},{"BUILD_PLANTATION","RESOURCE_DYE","RESOURCECLASS_LUXURY",400},{"BUILD_RUBBER_PLANTATION","RESOURCE_RUBBER","RESOURCECLASS_LUXURY",400}}}}
local cfg=assert(config[mode]);local records,events,used={},{},{}
local phase,issued,err,startTurn="init",false,nil,nil
local function scaled(raw,q)
 local n=math.floor(raw*(100+GameInfo.Terrains[q:GetTerrainType()].BuildModifier)/100)
 n=math.floor(n*GameInfo.GameSpeeds[Game.GetGameSpeedType()].BuildPercent/100)
 n=math.floor(n*GameInfo.Eras[Game.GetStartEra()].BuildPercent/100)
 return math.floor(n/10)*10
end
local function site(p,water)
 local best,bestDistance;local cap=p:GetCapitalCity()
 for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
  if not used[i]and not q:IsCity()and not q:IsMountain()and q:GetNumUnits()==0 and(q:GetOwner()==-1 or q:GetOwner()==p:GetID())and q:IsWater()==water and(not water or not q:IsLake())then
   local distance=Map.PlotDistance(q:GetX(),q:GetY(),cap:GetX(),cap:GetY())
   if not best or distance<bestDistance then best,bestDistance=q,distance end
  end
 end
 assert(best);used[best:GetPlotIndex()]=true;best:SetFeatureType(-1);best:SetImprovementType(-1);best:SetResourceType(-1,0)
 if water then best:SetTerrainType(GameInfoTypes.TERRAIN_COAST,true,true)else best:SetPlotType(PlotTypes.PLOT_LAND,true,true,false);best:SetTerrainType(GameInfoTypes.TERRAIN_GRASS,true,true)end
 best:SetOwner(p:GetID(),-1,true,true);return best
end
GameEvents.BuildFinished.Add(function(owner,x,y,improvement)
 if owner~=cfg.owner then return end
 for _,r in ipairs(records)do local q=Map.GetPlotByIndex(r.plot)
  if q:GetX()==x and q:GetY()==y then assert(improvement==r.improvement and not events[r.plot]);events[r.plot]=Game.GetGameTurn();LekmodScenarioEvent("native-trait-build-finished",{mode=mode,plot=r.plot,build=r.build,improvement=improvement,turn=Game.GetGameTurn()})end
 end
end)
GameEvents.PlayerDoTurn.Add(function(owner)
 if owner~=cfg.owner or phase~="building"or issued then return end;issued=true
 local ok,e=pcall(function()
  local p=Players[owner];assert(p:IsTurnActive()and not p:IsHuman())
  for _,r in ipairs(records)do local q=Map.GetPlotByIndex(r.plot);local u=assert(p:InitUnit(GameInfoTypes.UNIT_WORKER,q:GetX(),q:GetY()));r.unit=u:GetID()
   if q:IsWater()then u:SetEmbarked(true)end
   assert(u:CanBuild(q,r.build)and u:CanStartMission(MissionTypes.MISSION_BUILD,r.build,-1,q,0),"provided worker lacks legal build "..r.kind)
   r.work_rate=u:WorkRate(true);assert(r.work_rate>0);r.turns_quote=q:GetBuildTurnsLeft(r.build,owner,0,r.work_rate);assert(r.turns_quote==math.ceil(r.expected/r.work_rate))
   LekmodScenarioEvent("fixture-setup",{operation="provided-owner-turn-worker",owner=owner,unit=r.unit,plot=r.plot,embarked=u:IsEmbarked(),work_rate=r.work_rate,turns_quote=r.turns_quote})
   u:PushMission(MissionTypes.MISSION_BUILD,r.build,-1,0,0,1)
   if not events[r.plot]then assert(u:GetBuildType()==r.build,"native build order not accepted")end
  end
  LekmodScenarioRecord("build-native-orders","PASS","all workers started legal native build missions on the actual AI owner turn; no build progress/improvement supplied")
 end)
 if not ok then err=tostring(e)end
end)
function LekmodScenario.snapshot(player)
 local p=Players[cfg.owner];local plots,units={},{}
 for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
  if q:GetOwner()==cfg.owner and q:GetResourceType(-1)~=-1 then local times={}
   for _,r in ipairs(cfg.rows)do times[r[1]]=q:GetBuildTime(GameInfoTypes[r[1]],cfg.owner)end
   plots[i]={resource=q:GetResourceType(-1),quantity=q:GetNumResource(),improvement=q:GetImprovementType(),pillaged=q:IsImprovementPillaged(),times=times}
  end
 end
 for u in p:Units()do if u:GetUnitType()==GameInfoTypes.UNIT_WORKER then units[u:GetID()]={x=u:GetX(),y=u:GetY(),build=u:GetBuildType(),embarked=u:IsEmbarked(),moves=u:GetMoves(),work_rate=u:WorkRate(true)}end end
 return {mode=mode,turn=Game.GetGameTurn(),plots=plots,workers=units}
end
function LekmodScenario.step(player)
 assert(not err,err);local p=Players[cfg.owner];assert(not Game.IsGameMultiPlayer()and p:GetCivilizationType()==GameInfoTypes[cfg.civ]and not p:IsHuman())
 if phase=="init"then
  local count=0;for row in GameInfo.Trait_BuildImprovementBuildTimeOverride{TraitType=cfg.trait}do count=count+1 end;assert(count==#cfg.rows)
  local timeChanges=0;for r in GameInfo.Build_TechTimeChanges()do timeChanges=timeChanges+1 end;assert(timeChanges==0,"review nonempty team build-time modifiers")
  for _,input in ipairs(cfg.rows)do
   local build=assert(GameInfo.Builds[input[1]]);local resource=assert(GameInfo.Resources[input[2]]);local matches=0
   for r in GameInfo.Trait_BuildImprovementBuildTimeOverride{TraitType=cfg.trait,BuildType=input[1]}do if(r.ResourceClassRequired or false)==input[3]then assert(r.Time==input[4]);matches=matches+1 end end;assert(matches==1)
   assert(not input[3]or resource.ResourceClassType==input[3]);local q=site(p,build.Water);q:SetResourceType(resource.ID,1)
   local hidden=resource.TechReveal and not Teams[p:GetTeam()]:IsHasTech(GameInfoTypes[resource.TechReveal])or false
   local raw=(not input[3]or not hidden)and input[4]or build.Time
   assert(q:GetBuildTime(build.ID,cfg.owner)==scaled(raw,q),"pre-research resource-class quote differs")
   records[#records+1]={kind=input[1],build=build.ID,resource=resource.ID,resource_name=input[2],required_class=input[3],raw=input[4],plot=q:GetPlotIndex(),improvement=GameInfoTypes[build.ImprovementType],hidden_before=hidden,initial_quote=q:GetBuildTime(build.ID,cfg.owner)}
  end
  LekmodScenarioRecord("build-configured-rows","PASS","all "..#records.." active "..mode.." rows have unique matching build/class/time data")
  LekmodScenarioRecord("build-resource-visibility","PASS","unrevealed resources do not activate class-restricted override; generic rows work without a class")
  for _,r in ipairs(records)do local info=GameInfo.Builds[r.build];local res=GameInfo.Resources[r.resource]
   LekmodScenarioGrantTech(p,info.PrereqTech);if res.TechReveal then LekmodScenarioGrantTech(p,res.TechReveal)end
   if info.Water then LekmodScenarioGrantTech(p,"TECH_OPTICS")end
  end
  p:ChangeGold(5000);LekmodScenarioEvent("fixture-setup",{operation="provided-worker-upkeep",owner=cfg.owner,gold_added=5000})
  for _,r in ipairs(records)do local q=Map.GetPlotByIndex(r.plot);local info=GameInfo.Builds[r.build];r.expected=scaled(r.raw,q);r.base=scaled(info.Time,q)
   assert(q:GetBuildTime(r.build,cfg.owner)==r.expected and q:GetBuildTime(r.build,0)==r.base)
   q:SetResourceType(-1,0);local fallback=r.required_class and r.base or r.expected;assert(q:GetBuildTime(r.build,cfg.owner)==fallback)
   q:SetResourceType(GameInfoTypes.RESOURCE_STONE,1);assert(q:GetBuildTime(r.build,cfg.owner)==fallback)
   q:SetResourceType(r.resource,1);assert(q:GetBuildTime(r.build,cfg.owner)==r.expected and q:CanBuild(r.build,cfg.owner,false,false),"positive probe is not a legal build")
  end
  LekmodScenarioRecord("build-resource-class-controls","PASS","missing and wrong resource class use ordinary time; generic Argentina entries still apply; restoring matching resource restores the override")
  LekmodScenarioRecord("build-foreign-control","PASS","unmodified human civilization quotes ordinary build time on the same plots")
  LekmodScenarioRecord("build-scaled-prices","PASS","native times equal declared0/400 overrides after actual terrain/speed/start-era scaling and tens rounding")
  LekmodScenarioEvent("native-trait-build-quotes",{mode=mode,owner=cfg.owner,speed=Game.GetGameSpeedType(),start_era=Game.GetStartEra(),records=records})
  phase="building";startTurn=Game.GetGameTurn();return "turn"
 end
 local complete=issued
 for _,r in ipairs(records)do local q=Map.GetPlotByIndex(r.plot)
  if not events[r.plot]then complete=false end
  if events[r.plot]then assert(q:GetImprovementType()==r.improvement and not q:IsImprovementPillaged()and q:GetResourceType(-1)==r.resource)end
 end
 if not complete then assert(Game.GetGameTurn()-startTurn<8,"parallel worker builds did not finish within eight ordinary rounds");return "turn"end
 LekmodScenarioRecord("build-native-completions","PASS","all "..#records.." original native worker orders emitted BuildFinished and produced the matching intact improvements/resources")
 return true
end
