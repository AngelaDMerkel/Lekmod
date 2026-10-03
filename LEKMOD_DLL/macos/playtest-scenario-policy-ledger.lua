-- Native method surface: GameCore
-- Diagnostic observation only. No turn/choice/reward mutation and no claim that
-- a malformed fixture is a correct gameplay state.
LekmodScenario={name="policy-ledger",items={"policy-ledger-read-only"}}
function LekmodScenario.snapshot(player)
 local owners={};for owner=0,2 do local p=Players[owner];local policies={}
  for row in GameInfo.Policies()do if p:HasPolicy(row.ID)then policies[row.Type]=true end end
  owners[owner]={free=p:GetNumFreePolicies(),tenets=p:GetNumFreeTenets(),culture=p:GetJONSCulture(),next_cost=p:GetNextPolicyCost(),owned=p:GetNumPolicies(),policies=policies}
 end
 return {turn=Game.GetGameTurn(),owners=owners}
end
function LekmodScenario.step(player)
 local before=LekmodScenario.snapshot(player);LekmodScenarioEvent("policy-fixture-ledger",before)
 assert(LekmodScenarioJSON(before)==LekmodScenarioJSON(LekmodScenario.snapshot(player)))
 LekmodScenarioRecord("policy-ledger-read-only","PASS","diagnostic fields recorded unchanged; this does not assert valid policy economics")
 return true
end
