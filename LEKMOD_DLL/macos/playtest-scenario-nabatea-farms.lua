-- Supply engine-legal bare farm plots; observe owner-specific technology
-- activation/obsolescence and cached versus calculated yields. No yield setters.
LekmodScenario={name="nabatea-farms",items={"nabatea-farm-mathematics","nabatea-roman-mathematics-control","nabatea-civil-service-transition","nabatea-roman-civil-service"}}
local phase="init"
local transitionReads={}
local probes,base={},{ }
local farm=GameInfoTypes.IMPROVEMENT_FARM
local function bare(p)
 if not p or p:IsWater()or p:IsMountain()or p:IsHills()or p:IsCity()or p:GetFeatureType()>=0 or p:GetResourceType()>=0 or p:GetNumUnits()>0 or p:GetOwner()~=-1 then return false end
 return p:GetTerrainType()==GameInfoTypes.TERRAIN_GRASS or p:GetTerrainType()==GameInfoTypes.TERRAIN_PLAINS
end
local function supply(owner)
 local p=Players[owner];local site,fresh,dry
 for i=0,Map.GetNumPlots()-1 do local candidate=Map.GetPlotByIndex(i)
  if candidate:GetOwner()==-1 and candidate:GetNumUnits()==0 and p:CanFound(candidate:GetX(),candidate:GetY())then
   local a,b
   for d=0,5 do local q=Map.PlotDirection(candidate:GetX(),candidate:GetY(),d)
    if bare(q)then if q:IsFreshWater()then a=q else b=q end end
   end
   if a and b then site=candidate;fresh=a;dry=b;break end
  end
 end
 assert(site,"no legal city with bare fresh/dry farm inputs")
 p:Found(site:GetX(),site:GetY());local city=assert(site:GetPlotCity())
 LekmodScenarioEvent("fixture-setup",{operation="provided-farm-test-city",owner=owner,id=city:GetID(),x=site:GetX(),y=site:GetY()})
 for _,entry in ipairs({{plot=fresh,label="fresh"},{plot=dry,label="dry"}})do
  local plot=entry.plot;assert(plot:GetOwner()==owner,"normal founding did not claim farm input")
  local worker=assert(p:InitUnit(GameInfoTypes.UNIT_WORKER,plot:GetX(),plot:GetY()))
  assert(worker:CanBuild(plot,GameInfoTypes.BUILD_FARM),"farm input is not engine-legal")
  plot:SetImprovementType(farm)
  LekmodScenarioEvent("fixture-setup",{operation="provided-legal-farm-and-query-worker",owner=owner,label=entry.label,x=plot:GetX(),y=plot:GetY(),worker=worker:GetID(),fresh=plot:IsFreshWater()})
  probes[owner..":"..entry.label]=plot
 end
end
function LekmodScenario.snapshot(player)
 local plots,techs={},{ }
 for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i)
  if p:GetImprovementType()==farm and(p:GetOwner()==0 or p:GetOwner()==1)then
   plots[p:GetX()..":"..p:GetY()]={owner=p:GetOwner(),fresh=p:IsFreshWater(),terrain=p:GetTerrainType(),cached=p:GetYield(YieldTypes.YIELD_FOOD),calculated=p:CalculateYield(YieldTypes.YIELD_FOOD,false)}
  end
 end
 for owner=0,1 do local t=Teams[Players[owner]:GetTeam()]:GetTeamTechs();techs[owner]={math=t:HasTech(GameInfoTypes.TECH_MATHEMATICS),civil_service=t:HasTech(GameInfoTypes.TECH_CIVIL_SERVICE)}end
 return {turn=Game.GetGameTurn(),plots=plots,techs=techs}
end
local function check(label,deltas)
 local bad={}
 for key,p in pairs(probes)do local expected=base[key]+(deltas[key]or 0);local cached=p:GetYield(YieldTypes.YIELD_FOOD);local calculated=p:CalculateYield(YieldTypes.YIELD_FOOD,false)
  if cached~=expected or calculated~=expected then bad[key]={expected=expected,cached=cached,calculated=calculated}end
 end
 LekmodScenarioEvent(label,{mismatches=bad,state=LekmodScenario.snapshot(Players[0])})
 local ok=next(bad)==nil;LekmodScenarioRecord(label,ok and"PASS"or"FAIL","cached and calculated food checked for fresh/dry Nabatean/Roman farms")
 return ok
end
function LekmodScenario.step(player)
 assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_NABATEA and Players[1]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_ROME,"requires Nabatea0/Rome1")
 if phase=="math"or phase=="roman-math"or phase=="civil"or phase=="roman-civil"then
  transitionReads[phase]=(transitionReads[phase]or 0)+1
  LekmodScenarioEvent("farm-transition-observation",{phase=phase,sample=transitionReads[phase],state=LekmodScenario.snapshot(player)})
  if transitionReads[phase]<3 then return false end
 end
 local city=player:GetCapitalCity()
 if phase=="init"and not city then
  for u in player:Units()do if GameInfo.Units[u:GetUnitType()].Found and u:CanFound(u:GetPlot())then
   UI.SelectUnit(u);for i=0,#GameInfoActions do if GameInfoActions[i]and GameInfoActions[i].Type=="MISSION_FOUND"then assert(Game.CanHandleAction(i));Game.HandleAction(i);phase="founding";return false end end
  end end;error("normal starting Found unavailable")
 end
 if phase=="founding"then if not LekmodScenarioAwait("Nabatean-capital-founded",city~=nil)then return false end;phase="init"end
 if phase=="init"then
  for owner=0,1 do local t=Teams[Players[owner]:GetTeam()]:GetTeamTechs();assert(not t:HasTech(GameInfoTypes.TECH_MATHEMATICS)and not t:HasTech(GameInfoTypes.TECH_CIVIL_SERVICE),"start before the tested technologies");supply(owner)end
  phase="baseline";return false
 elseif phase=="baseline"then
  for key,p in pairs(probes)do base[key]=p:GetYield(YieldTypes.YIELD_FOOD);assert(base[key]==p:CalculateYield(YieldTypes.YIELD_FOOD,false),"initial farm cache differs from calculation")end
  LekmodScenarioEvent("nabatea-farm-baseline",LekmodScenario.snapshot(player));LekmodScenarioGrantTech(player,"TECH_MATHEMATICS");phase="math";return false
 elseif phase=="math"then
  if not check("nabatea-farm-mathematics",{["0:fresh"]=1})then return true end
  LekmodScenarioGrantTech(Players[1],"TECH_MATHEMATICS");phase="roman-math";return false
 elseif phase=="roman-math"then
  if not check("nabatea-roman-mathematics-control",{["0:fresh"]=1})then return true end
  LekmodScenarioGrantTech(player,"TECH_CIVIL_SERVICE");phase="civil";return false
 elseif phase=="civil"then
  if not check("nabatea-civil-service-transition",{["0:fresh"]=1})then return true end
  LekmodScenarioGrantTech(Players[1],"TECH_CIVIL_SERVICE");phase="roman-civil";return false
 elseif phase=="roman-civil"then
  check("nabatea-roman-civil-service",{["0:fresh"]=1,["1:fresh"]=1});return true
 end
end
