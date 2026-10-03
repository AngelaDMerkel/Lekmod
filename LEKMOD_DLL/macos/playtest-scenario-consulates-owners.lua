-- Native method surface: GameCore
-- @native-receiver player Player
-- @native-receiver p Player
-- Prerequisite research/policies/free choices are supplied. Final adoption,
-- counter changes and subsequent era events are native; delegates are not set.
LekmodScenario={name="consulates-owners",items={"consulates-human-award","consulates-AI-award","consulates-era-increments","consulates-repeat-rejection","consulates-choice-accounting"}}
local order=assert(LekmodScenarioParameters.order)
local phase,pending,aiDone,err="init",nil,nil,nil
local policy=GameInfoTypes.POLICY_CONSULATES
local branch=GameInfoTypes.POLICY_BRANCH_PATRONAGE
local observations={}
local function expected(p)return 1+math.max(0,p:GetCurrentEra()-GameInfoTypes.ERA_RENAISSANCE)end
local function prerequisites(p,id,seen)
 seen=seen or{};assert(not seen[id],"cyclic policy prerequisites");seen[id]=true
 local row=GameInfo.Policies[id]
 for req in GameInfo.Policy_PrereqPolicies{PolicyType=row.Type}do
  local needed=GameInfoTypes[req.PrereqPolicy];prerequisites(p,needed,seen)
  if not p:HasPolicy(needed)then p:SetHasPolicy(needed,true)end
 end
 seen[id]=nil
end
local function prepare(p)
 assert(not p:HasPolicy(policy)and p:GetNumPolicyLeagueVotes()==0,"fixture already has policy delegates")
 LekmodScenarioGrantTech(p,"TECH_SCIENTIFIC_THEORY");assert(p:GetCurrentEra()==GameInfoTypes.ERA_INDUSTRIAL)
 p:SetPolicyBranchUnlocked(branch,true,false)
 local opener=GameInfoTypes[GameInfo.PolicyBranchTypes[branch].FreePolicy];if opener and not p:HasPolicy(opener)then p:SetHasPolicy(opener,true)end
 prerequisites(p,policy);p:SetNumFreePolicies(p:GetNumFreePolicies()+1)
 assert(p:CanAdoptPolicy(policy)and p:GetNumPolicyLeagueVotes()==0)
 observations[p:GetID()]={before=p:GetNumPolicyLeagueVotes(),free=p:GetNumFreePolicies(),expected=expected(p)}
 LekmodScenarioEvent("fixture-setup",{operation="provided-Consulates-prerequisites",owner=p:GetID(),team=p:GetTeam(),era=p:GetCurrentEra(),free=p:GetNumFreePolicies()})
end
local function observe(p)
 local r=observations[p:GetID()];assert(p:HasPolicy(policy)and p:GetNumFreePolicies()==r.free-1,"native adoption/choice accounting differs")
 r.after=p:GetNumPolicyLeagueVotes()
 LekmodScenarioEvent("consulates-adoption-outcome",{owner=p:GetID(),team=p:GetTeam(),era=p:GetCurrentEra(),expected=r.expected,before=r.before,after=r.after})
 LekmodScenarioRecord(p:IsHuman()and"consulates-human-award"or"consulates-AI-award",r.after-r.before==r.expected and"PASS"or"FAIL","base1 plus Industrial-era1 expected="..r.expected.." actual="..(r.after-r.before).." order="..order)
 assert(not p:CanAdoptPolicy(policy),"already owned Consulates remains adoptable")
end
GameEvents.PlayerDoTurn.Add(function(owner)
 if owner~=1 or not pending then return end;pending=nil
 local ok,e=pcall(function()
  local p=Players[owner];assert(p:IsTurnActive()and not p:IsHuman());prepare(p);p:DoAdoptPolicy(policy);observe(p);aiDone=true
 end)
 if not ok then err=tostring(e)end
end)
function LekmodScenario.snapshot(player)
 local owners={}
 for owner=0,1 do local p=Players[owner]
  owners[owner]={team=p:GetTeam(),era=p:GetCurrentEra(),consulates=p:HasPolicy(policy),votes=p:GetNumPolicyLeagueVotes(),free=p:GetNumFreePolicies()}
 end
 return {turn=Game.GetGameTurn(),owners=owners}
end
local function human(player)
 prepare(player);Network.SendUpdatePolicies(policy,true,true);phase="human"
end
function LekmodScenario.step(player)
 assert(not err,err)
 assert(player:GetID()==0 and player:IsHuman()and not Players[1]:IsHuman()and player:GetTeam()~=Players[1]:GetTeam())
 if phase=="init"then
  assert(GameInfo.Policies[policy].NumExtraLeagueVotes==1)
  if not player:GetCapitalCity()or not Players[1]:GetCapitalCity()then return "turn"end
  for owner=0,1 do assert(not Players[owner]:HasPolicy(policy)and Players[owner]:GetCurrentEra()<GameInfoTypes.ERA_INDUSTRIAL)end
  if order=="human-first"then human(player)else pending=true;phase="AI";return "turn"end
 elseif phase=="human"then
  if not LekmodScenarioAwait("Consulates-human-adopted",player:HasPolicy(policy))then return false end
  observe(player)
  if not aiDone then pending=true;phase="AI";return "turn"else phase="advance"end
 elseif phase=="AI"then
  if not aiDone then return "turn"end
  if not player:HasPolicy(policy)then human(player)else phase="advance"end
 elseif phase=="advance"then
  for owner=0,1 do local p=Players[owner];observations[owner].beforeEra=p:GetNumPolicyLeagueVotes();LekmodScenarioGrantTech(p,"TECH_RADIO")end
  phase="advanced"
 elseif phase=="advanced"then
  for owner=0,1 do local p=Players[owner]
   assert(p:GetCurrentEra()==GameInfoTypes.ERA_MODERN and p:GetNumPolicyLeagueVotes()==observations[owner].beforeEra+1,"matching-team Modern event did not add exactly one")
   local before=p:GetNumPolicyLeagueVotes();Teams[p:GetTeam()]:SetHasTech(GameInfoTypes.TECH_RADIO,true,owner,true,true)
   assert(p:GetNumPolicyLeagueVotes()==before and not p:CanAdoptPolicy(policy),"known research/owned policy repeated its award")
  end
  LekmodScenarioRecord("consulates-era-increments","PASS","real research-induced Modern events add1 per matching owner; missing earlier adoption awards remain visible")
  LekmodScenarioRecord("consulates-repeat-rejection","PASS","already-owned policy ineligible and re-sending known technology grants nothing")
  LekmodScenarioRecord("consulates-choice-accounting","PASS","both legal adoptions consume one supplied choice; no delegate counter assigned")
  return true
 end
 return false
end
