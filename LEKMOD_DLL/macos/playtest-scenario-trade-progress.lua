-- Diagnostic continuation of a preserved late-contract save. No durations,
-- circuit counters or waiting flags are assigned.
LekmodScenario={name="trade-progress",items={"trade-progress-observed"}}
local start,last
function LekmodScenario.snapshot(player)
    local routes,units={},{}
    for i,r in ipairs(player:GetTradeRoutes()) do routes[i]={domain=r.Domain,type=r.ConnectionType,from=r.FromCity:GetID(),to=r.ToCity:GetID(),left=r.TurnsLeft} end
    for u in player:Units() do if u:IsTrade() then units[u:GetID()]={type=u:GetUnitType(),x=u:GetX(),y=u:GetY(),moves=u:GetMoves()} end end
    return {turn=Game.GetGameTurn(),routes=routes,units=units}
end
function LekmodScenario.step(player)
    start=start or Game.GetGameTurn()
    if last~=Game.GetGameTurn() then last=Game.GetGameTurn();LekmodScenarioEvent("trade-progress-observed",LekmodScenario.snapshot(player)) end
    if Game.GetGameTurn()-start<3 then return "turn" end
    LekmodScenarioRecord("trade-progress-observed","PASS","scope=read-only-progress-and-three-normal-turns not-expiry-certification")
    return true
end
