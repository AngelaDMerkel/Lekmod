-- Native method surface: GameCore
-- Technologies, policy prerequisites/choice and Settler staging are supplied.
-- The target policy uses the human command; every tested city uses normal Found.
LekmodScenario={name="policy-founding",items={"policy-found-before-control","policy-found-adoption","policy-found-buildings","policy-found-owner-city-controls","policy-found-repeat-no-stack","policy-found-population","policy-found-territory","policy-found-worker-happiness"}}
local mode=assert(LekmodScenarioParameters.mode)
local policy=mode=="resettlement"and GameInfoTypes.POLICY_RESETTLEMENT or GameInfoTypes.POLICY_MERCHANT_NAVY
local classes=mode=="resettlement"and{"BUILDINGCLASS_WORKSHOP","BUILDINGCLASS_GRANARY","BUILDINGCLASS_AQUEDUCT","BUILDINGCLASS_MONUMENT","BUILDINGCLASS_LIBRARY"}or{"BUILDINGCLASS_GOVERNORS_MANSION"}
local phase,site,settler,ordinal,controls,free="init",nil,nil,0,nil,nil
local kinds={}
local landBefore,workersBefore
local function workers(p)local n=0;for u in p:Units()do if u:GetUnitType()==GameInfoTypes.UNIT_WORKER then n=n+1 end end;return n end
local function classBuilding(p,kind)
 local result=GameInfo.BuildingClasses[kind].DefaultBuilding
 for row in GameInfo.Civilization_BuildingClassOverrides{CivilizationType=GameInfo.Civilizations[p:GetCivilizationType()].Type,BuildingClassType=kind}do if row.BuildingType then result=row.BuildingType end end
 return GameInfoTypes[result]
end
local function counts(c)
 local v={}
 for _,kind in ipairs(classes)do local sum=0;for row in GameInfo.Buildings{BuildingClass=kind}do sum=sum+c:GetNumRealBuilding(row.ID)end;v[kind]=sum end
 return v
end
local function state(p)
 local cities={};for c in p:Cities()do cities[c:GetID()]={x=c:GetX(),y=c:GetY(),buildings=counts(c),population=c:GetPopulation(),happiness=c:GetHappinessFromBuildings()}end
 return {policy=p:HasPolicy(policy),free=p:GetNumFreePolicies(),cities=cities,plots=p:GetNumPlots(),workers=workers(p)}
end
function LekmodScenario.snapshot(p)return {turn=Game.GetGameTurn(),owners={[0]=state(p),[1]=state(Players[1])}}end
local function found(p)
 local ruins={};for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i);if q:IsGoody(-1)then ruins[#ruins+1]=q end end
 local cap=p:GetCapitalCity();local best=999;site=nil
 for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i);local distance=Map.PlotDistance(q:GetX(),q:GetY(),cap:GetX(),cap:GetY())
  if distance<best and q:GetOwner()==-1 and q:GetNumUnits()==0 and q:GetImprovementType()==-1 and p:CanFound(q:GetX(),q:GetY())then
   local safe=true;for _,ruin in ipairs(ruins)do if Map.PlotDistance(q:GetX(),q:GetY(),ruin:GetX(),ruin:GetY())<=2 then safe=false;break end end
   if safe then
    -- A fully unowned radius two leaves space for the base7 plus6 policy plots.
    local ring=0
    for j=0,Map.GetNumPlots()-1 do local t=Map.GetPlotByIndex(j)
     if Map.PlotDistance(q:GetX(),q:GetY(),t:GetX(),t:GetY())<=2 then ring=ring+1;if t:GetOwner()~=-1 then safe=false;break end end
    end
    if ring~=19 then safe=false end
   end
   if safe then site=q;best=distance end
  end
 end
 assert(site,"no legal ruin-free founding site");local u=assert(p:InitUnit(GameInfoTypes.UNIT_SETTLER,site:GetX(),site:GetY()));settler=u:GetID();assert(u:CanFound(site))
 LekmodScenarioEvent("fixture-setup",{operation="provided-policy-test-Settler",id=settler,x=site:GetX(),y=site:GetY(),policy_owned=p:HasPolicy(policy)})
 landBefore=p:GetNumPlots();workersBefore=workers(p)
 UI.SelectUnit(u);for id=0,#GameInfoActions do if GameInfoActions[id]and GameInfoActions[id].Type=="MISSION_FOUND"then assert(Game.CanHandleAction(id));Game.HandleAction(id);return end end
 error("normal Found action missing")
end
local function prerequisites(p,id,seen)
 seen=seen or{};assert(not seen[id]);seen[id]=true
 for row in GameInfo.Policy_PrereqPolicies{PolicyType=GameInfo.Policies[id].Type}do local q=GameInfoTypes[row.PrereqPolicy];prerequisites(p,q,seen);if not p:HasPolicy(q)then p:SetHasPolicy(q,true)end end
 seen[id]=nil
end
function LekmodScenario.step(p)
 assert(p:GetID()==0 and p:IsHuman())
 if phase=="init"then
  if not p:GetCapitalCity()or not Players[1]:GetCapitalCity()then return "turn"end
  assert(not p:HasPolicy(policy)and not Players[1]:HasPolicy(policy))
  for _,kind in ipairs(classes)do kinds[kind]=classBuilding(p,kind)end
  LekmodScenarioGrantTech(p,"TECH_RADIO");p:ChangeGold(10000);found(p);phase="before"
 elseif phase=="before"then
  local c=site:GetPlotCity();if not LekmodScenarioAwait("no-policy-city",c and c:GetOwner()==0)then return false end
  for _,n in pairs(counts(c))do assert(n==0,"new city received policy building without the policy")end
  assert(c:GetPopulation()==1 and p:GetNumPlots()-landBefore==7 and workers(p)==workersBefore,"pre-policy founding baseline differs")
  LekmodScenarioRecord("policy-found-before-control","PASS","normal pre-policy Found receives none of the selected policy's buildings")
  controls=LekmodScenario.snapshot(p)
  local branch=GameInfoTypes[GameInfo.Policies[policy].PolicyBranchType];p:SetPolicyBranchUnlocked(branch,true,false)
  local opener=GameInfo.PolicyBranchTypes[branch].FreePolicy;if opener then p:SetHasPolicy(GameInfoTypes[opener],true)end
  prerequisites(p,policy);p:SetNumFreeTenets(0);free=p:GetNumFreePolicies()+1;p:SetNumFreePolicies(free)
  assert(p:CanAdoptPolicy(policy));LekmodScenarioEvent("fixture-setup",{operation="provided-policy-founding-prerequisites",policy=policy,free=free})
  Network.SendUpdatePolicies(policy,true,true);phase="adopted"
 elseif phase=="adopted"then
  if not LekmodScenarioAwait("founding-policy-adopted",p:HasPolicy(policy))then return false end
  assert(p:GetNumFreePolicies()==free-1 and p:GetNumFreeTenets()==0 and not p:CanAdoptPolicy(policy))
  LekmodScenarioRecord("policy-found-adoption","PASS","legal human adoption consumes one supplied choice and rejects duplicate adoption")
  found(p);ordinal=1;phase="after"
 elseif phase=="after"then
  local c=site:GetPlotCity();if not LekmodScenarioAwait("policy-city-"..ordinal,c and c:GetOwner()==0)then return false end
  local u=p:GetUnitByID(settler);assert(not u or u:IsDead()or u:IsDelayedDeath(),"normal Found failed to consume Settler")
  assert(c:GetPopulation()==(mode=="resettlement"and 5 or 3),"new city extra population differs from4/2")
  assert(p:GetNumPlots()-landBefore==13,"new city must claim base7 plus6 additional plots")
  assert(workers(p)-workersBefore==(mode=="colonialism"and 1 or 0),"founding Worker reward differs")
  if mode=="colonialism"then assert(c:GetHappinessFromBuildings()==2,"Governor mansion happiness differs")end
  for kind,id in pairs(kinds)do assert(c:GetNumRealBuilding(id)==1 and counts(c)[kind]==1,"founding policy gave wrong class, replacement or count")end
  for id,r in pairs(controls.owners[0].cities)do assert(LekmodScenarioJSON(counts(p:GetCityByID(id)))==LekmodScenarioJSON(r.buildings),"preexisting human city was retroactively granted policy buildings")end
  assert(LekmodScenarioJSON(state(Players[1]))==LekmodScenarioJSON(controls.owners[1]),"foreign owner changed during human founding")
  LekmodScenarioEvent("native-policy-founding",{ordinal=ordinal,city=c:GetID(),counts=counts(c),resolved_buildings=kinds})
  if ordinal==1 then LekmodScenarioRecord("policy-found-buildings","PASS","normal Found grants exactly one per declared class, resolving civilization replacements");found(p);ordinal=2;return false end
  LekmodScenarioRecord("policy-found-owner-city-controls","PASS","pre-policy human cities and foreign owner remain unchanged")
  LekmodScenarioRecord("policy-found-repeat-no-stack","PASS","second distinct normal Found grants one per class and consumes its Settler")
  LekmodScenarioRecord("policy-found-population","PASS","both normal new cities have4/2 extra population over the pre-policy1 control")
  LekmodScenarioRecord("policy-found-territory","PASS","pre-policy normal founding claims7; both policy foundings claim13 with clear radius-two input")
  LekmodScenarioRecord("policy-found-worker-happiness","PASS",mode=="colonialism"and"one native Worker grant and2 building happiness per new city"or"no unconfigured Worker reward")
  return true
 end
 return false
end
