-- Native method surface: GameCore
-- Single player: human0 and AI1 share team7, AI2 belongs to team0.
-- Research/prerequisites/free choices are inputs; native era events and legal
-- policy commands supply every tested delegate change.
LekmodScenario={name="consulates-teams",items={"consulates-team-adoptions","consulates-shared-era","consulates-unrelated-team","consulates-team-repeat","consulates-team-choice"}}
local phase,pending,done,err="init",false,false,nil
local policy=GameInfoTypes.POLICY_CONSULATES
local free={}
local function prerequisites(p,id,seen)
 seen=seen or{};assert(not seen[id]);seen[id]=true
 for row in GameInfo.Policy_PrereqPolicies{PolicyType=GameInfo.Policies[id].Type}do local q=GameInfoTypes[row.PrereqPolicy];prerequisites(p,q,seen);if not p:HasPolicy(q)then p:SetHasPolicy(q,true)end end
 seen[id]=nil
end
local function choice(p)
 assert(not p:HasPolicy(policy));local branch=GameInfoTypes.POLICY_BRANCH_PATRONAGE;p:SetPolicyBranchUnlocked(branch,true,false)
 local opener=GameInfoTypes[GameInfo.PolicyBranchTypes[branch].FreePolicy];if opener and not p:HasPolicy(opener)then p:SetHasPolicy(opener,true)end
 prerequisites(p,policy);free[p:GetID()]=p:GetNumFreePolicies()+1;p:SetNumFreePolicies(free[p:GetID()]);assert(p:CanAdoptPolicy(policy))
 LekmodScenarioEvent("fixture-setup",{operation="provided-Consulates-team-prerequisites",owner=p:GetID(),team=p:GetTeam(),free=free[p:GetID()]})
end
GameEvents.PlayerDoTurn.Add(function(owner)
 if owner~=1 or not pending then return end;pending=false
 local ok,e=pcall(function()local p=Players[1];assert(p:IsTurnActive()and not p:IsHuman());choice(p);p:DoAdoptPolicy(policy);assert(p:HasPolicy(policy)and p:GetNumPolicyLeagueVotes()==2 and p:GetNumFreePolicies()==free[1]-1);done=true end)
 if not ok then err=tostring(e)end
end)
function LekmodScenario.snapshot(player)
 local owners={};for owner=0,2 do local p=Players[owner];owners[owner]={team=p:GetTeam(),era=p:GetCurrentEra(),policy=p:HasPolicy(policy),votes=p:GetNumPolicyLeagueVotes(),free=p:GetNumFreePolicies()}end
 return {turn=Game.GetGameTurn(),owners=owners}
end
function LekmodScenario.step(p)
 assert(not err,err);assert(not Game.IsGameMultiPlayer()and p:GetID()==0 and p:IsHuman()and p:GetTeam()==7 and Players[1]:GetTeam()==7 and Players[2]:GetTeam()==0)
 if phase=="init"then
  for owner=0,2 do assert(not Players[owner]:HasPolicy(policy)and Players[owner]:GetNumPolicyLeagueVotes()==0)end
  LekmodScenarioGrantTech(p,"TECH_SCIENTIFIC_THEORY");assert(p:GetCurrentEra()==GameInfoTypes.ERA_INDUSTRIAL and Players[1]:GetCurrentEra()==GameInfoTypes.ERA_INDUSTRIAL)
  choice(p);Network.SendUpdatePolicies(policy,true,true);phase="human"
 elseif phase=="human"then
  if not LekmodScenarioAwait("team-human-adoption",p:HasPolicy(policy))then return false end
  assert(p:GetNumPolicyLeagueVotes()==2 and p:GetNumFreePolicies()==free[0]-1);pending=true;phase="AI";return "turn"
 elseif phase=="AI"then
  if not done then return "turn"end
  assert(p:GetNumPolicyLeagueVotes()==2 and Players[1]:GetNumPolicyLeagueVotes()==2)
  LekmodScenarioRecord("consulates-team-adoptions","PASS","both legal Industrial adoptions grant2 for owner0/owner1 sharing team7")
  LekmodScenarioGrantTech(p,"TECH_RADIO");phase="shared"
 elseif phase=="shared"then
  assert(p:GetCurrentEra()==GameInfoTypes.ERA_MODERN and Players[1]:GetCurrentEra()==GameInfoTypes.ERA_MODERN)
  assert(p:GetNumPolicyLeagueVotes()==3 and Players[1]:GetNumPolicyLeagueVotes()==3 and Players[2]:GetNumPolicyLeagueVotes()==0)
  LekmodScenarioRecord("consulates-shared-era","PASS","one actual team7 era event awards both eligible members exactly1")
  LekmodScenarioGrantTech(Players[2],"TECH_RADIO");phase="foreign"
 elseif phase=="foreign"then
  assert(Players[2]:GetCurrentEra()==GameInfoTypes.ERA_MODERN and Players[2]:GetNumPolicyLeagueVotes()==0)
  assert(p:GetNumPolicyLeagueVotes()==3 and Players[1]:GetNumPolicyLeagueVotes()==3)
  LekmodScenarioRecord("consulates-unrelated-team","PASS","actual team0 era events do not credit unrelated player0/team7; nonowner2 gets0")
  Teams[7]:SetHasTech(GameInfoTypes.TECH_RADIO,true,0,true,true)
  for owner=0,1 do assert(Players[owner]:GetNumPolicyLeagueVotes()==3 and not Players[owner]:CanAdoptPolicy(policy))end
  LekmodScenarioRecord("consulates-team-repeat","PASS","known research and already-owned policies cannot repeat rewards")
  LekmodScenarioRecord("consulates-team-choice","PASS","human and actual AI adoption each consumed one supplied choice")
  return true
 end
 return false
end
