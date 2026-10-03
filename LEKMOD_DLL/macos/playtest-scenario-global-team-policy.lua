-- Native method surface: GameCore
-- Actual research events, human/AI policy adoption and normal Found; research,
-- branch prerequisites, one choice, Settler and staging are explicitly supplied.
LekmodScenario={name="global-team-policy",items={"global-team-tech-awards","global-team-capital-only","global-human-policy-award","global-AI-policy-award","global-new-city-award","global-policy-foreign-control","global-policy-choice-accounting"}}
local phase,pending,done,err="init",false,false,nil
local union=GameInfoTypes.BUILDING_ECONOMIC_UNION_GOLD
local policy=GameInfoTypes.POLICY_ECONOMIC_UNION
local free,foreign,site,settler={}
local function markers(p)
 local cities={};for c in p:Cities()do cities[c:GetID()]={ulug=c:GetNumRealBuilding(GameInfoTypes.BUILDING_ULUG),wales=c:GetNumRealBuilding(GameInfoTypes.BUILDING_WALES_TRAIT),mongol=c:GetNumRealBuilding(GameInfoTypes.BUILDING_MONGOL_TRAIT),union=c:GetNumRealBuilding(union)}end;return cities
end
local function choice(p)
 assert(not p:HasPolicy(policy));p:SetPolicyBranchUnlocked(GameInfoTypes.POLICY_BRANCH_FREEDOM,true,false);p:SetNumFreeTenets(0)
 free[p:GetID()]=p:GetNumFreePolicies()+1;p:SetNumFreePolicies(free[p:GetID()]);assert(p:CanAdoptPolicy(policy))
 LekmodScenarioEvent("fixture-setup",{operation="provided-Economic-Union-prerequisites-and-choice",owner=p:GetID(),team=p:GetTeam(),free=free[p:GetID()]})
end
local function adopted(p,item)
 assert(p:HasPolicy(policy)and p:GetNumFreePolicies()==free[p:GetID()]-1 and p:GetNumFreeTenets()==0 and not p:CanAdoptPolicy(policy))
 local n=p:GetCapitalCity():GetNumRealBuilding(union)
 LekmodScenarioRecord(item,n==1 and"PASS"or"FAIL","owner="..p:GetID().." team="..p:GetTeam().." native adoption requires capital marker1; actual="..n)
end
GameEvents.PlayerDoTurn.Add(function(owner)
 if owner~=1 or not pending then return end;pending=false
 local ok,e=pcall(function()local p=Players[1];assert(p:IsTurnActive()and not p:IsHuman());choice(p);p:DoAdoptPolicy(policy);adopted(p,"global-AI-policy-award");done=true end)
 if not ok then err=tostring(e)end
end)
function LekmodScenario.snapshot(player)
 local owners={}
 for owner=0,2 do local p=Players[owner];owners[owner]={team=p:GetTeam(),civilization=p:GetCivilizationType(),cities=markers(p),union=p:HasPolicy(policy),free=p:GetNumFreePolicies(),era=p:GetCurrentEra()}end
 return {turn=Game.GetGameTurn(),owners=owners}
end
local function found(p)
 for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
  if q:GetOwner()==-1 and q:GetNumUnits()==0 and not q:IsGoody(-1)and p:CanFound(q:GetX(),q:GetY())then site=q;break end
 end
 assert(site);local u=assert(p:InitUnit(GameInfoTypes.UNIT_SETTLER,site:GetX(),site:GetY()));settler=u:GetID();assert(u:CanFound(site))
 LekmodScenarioEvent("fixture-setup",{operation="provided-Settler-and-legal-site",unit=settler,x=site:GetX(),y=site:GetY()})
 UI.SelectUnit(u);for id=0,#GameInfoActions do if GameInfoActions[id]and GameInfoActions[id].Type=="MISSION_FOUND"then assert(Game.CanHandleAction(id));Game.HandleAction(id);return end end
 error("normal Found missing")
end
function LekmodScenario.step(p)
 assert(not err,err);assert(not Game.IsGameMultiPlayer()and p:GetID()==0 and p:GetTeam()==7 and Players[1]:GetTeam()==7 and Players[2]:GetTeam()==0)
 if phase=="init"then
  assert(p:GetCivilizationType()==GameInfoTypes.CIVILIZATION_WALES and Players[1]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_MONGOL)
  foreign=LekmodScenarioJSON(markers(Players[2]))
  LekmodScenarioGrantTech(p,"TECH_ANIMAL_HUSBANDRY");LekmodScenarioGrantTech(p,"TECH_CHIVALRY");LekmodScenarioGrantTech(p,"TECH_RADIO")
  assert(p:GetCapitalCity():GetNumRealBuilding(GameInfoTypes.BUILDING_WALES_TRAIT)==1 and Players[1]:GetCapitalCity():GetNumRealBuilding(GameInfoTypes.BUILDING_MONGOL_TRAIT)==1)
  assert(p:GetCapitalCity():GetNumRealBuilding(GameInfoTypes.BUILDING_MONGOL_TRAIT)==0 and Players[1]:GetCapitalCity():GetNumRealBuilding(GameInfoTypes.BUILDING_WALES_TRAIT)==0)
  LekmodScenarioRecord("global-team-tech-awards","PASS","team7 research updates both proper civilization capitals without cross-awarding the other trait")
  choice(p);Network.SendUpdatePolicies(policy,true,true);phase="human"
 elseif phase=="human"then
  if not LekmodScenarioAwait("global-union-human",p:HasPolicy(policy))then return false end
  adopted(p,"global-human-policy-award")
  local same=LekmodScenarioJSON(markers(Players[2]))==foreign
  LekmodScenarioRecord("global-policy-foreign-control",same and"PASS"or"FAIL","player0 policy must not refresh unrelated owner2/team0 markers")
  found(p);phase="found"
 elseif phase=="found"then
  local c=site:GetPlotCity();if not LekmodScenarioAwait("global-union-new-city",c and c:GetOwner()==0)then return false end
  local u=p:GetUnitByID(settler);assert(not u or u:IsDead()or u:IsDelayedDeath())
  local n=c:GetNumRealBuilding(union);LekmodScenarioRecord("global-new-city-award",n==1 and"PASS"or"FAIL","normal Found requires Economic Union marker1; actual="..n)
  assert(c:GetNumRealBuilding(GameInfoTypes.BUILDING_WALES_TRAIT)==0 and c:GetNumRealBuilding(GameInfoTypes.BUILDING_MONGOL_TRAIT)==0 and p:GetCapitalCity():GetNumRealBuilding(GameInfoTypes.BUILDING_WALES_TRAIT)==1)
  LekmodScenarioRecord("global-team-capital-only","PASS","new secondary city has no capital-only trait while the original capital keeps its marker")
  pending=true;phase="AI";return "turn"
 elseif phase=="AI"then
  if not done then return "turn"end
  assert(not Players[2]:HasPolicy(policy)and Players[2]:CountNumBuildings(union)==0)
  LekmodScenarioRecord("global-policy-choice-accounting","PASS","human and actual AI owner-turn adoption consume one supplied choice; foreign nonowner unmarked")
  return true
 end
 return false
end
