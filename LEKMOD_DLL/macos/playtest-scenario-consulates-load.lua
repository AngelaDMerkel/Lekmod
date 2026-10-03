-- Native method surface: GameCore
-- Authentic affected save; no setup mutation or direct policy-vote assignment.
LekmodScenario={name="consulates-load",items={"consulates-load-repair","consulates-load-protected-state","consulates-load-next-turn"}}
local phase,turn="init",nil
local policy=GameInfoTypes.POLICY_CONSULATES
function LekmodScenario.snapshot(player)
 local owners={}
 for owner=0,1 do local p=Players[owner]
  owners[owner]={team=p:GetTeam(),era=p:GetCurrentEra(),consulates=p:HasPolicy(policy),votes=p:GetNumPolicyLeagueVotes(),free=p:GetNumFreePolicies()}
 end
 return {turn=Game.GetGameTurn(),owners=owners}
end
function LekmodScenario.step(player)
 if phase=="init"then
  assert(LekmodScenarioJSON(LekmodScenario.snapshot(player))==LekmodScenarioParameters.expected_state,"native load repair differs from the declared counter-only correction")
  for owner=0,1 do local p=Players[owner]
   assert(p:GetCurrentEra()==GameInfoTypes.ERA_MODERN and p:HasPolicy(policy)and p:GetNumPolicyLeagueVotes()==3)
   assert(not p:CanAdoptPolicy(policy),"loaded policy became adoptable again")
  end
  LekmodScenarioRecord("consulates-load-repair","PASS","authentic affected save repaired by product load handler before test mutation; both Modern policy counters are3")
  LekmodScenarioRecord("consulates-load-protected-state","PASS","saved owner/team/era/policy/free-choice/turn fields unchanged; first adopter's correct counter preserved")
  turn=Game.GetGameTurn();phase="turn";return "turn"
 end
 if Game.GetGameTurn()==turn then return "turn"end
 assert(Game.GetGameTurn()==turn+1)
 for owner=0,1 do local p=Players[owner]
  assert(p:GetCurrentEra()==GameInfoTypes.ERA_MODERN and p:GetNumPolicyLeagueVotes()==3 and not p:CanAdoptPolicy(policy))
 end
 LekmodScenarioRecord("consulates-load-next-turn","PASS","one ordinary round preserves both rewards without stacking or reopening adoption")
 return true
end
