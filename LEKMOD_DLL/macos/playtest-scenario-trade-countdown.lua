-- Read-only comparison of all three route-list APIs on an existing contract.
LekmodScenario={name="trade-countdown",items={"trade-list-countdowns"}}
local function same(a,b)
    return a.FromID==b.FromID and a.ToID==b.ToID and a.FromCity:GetID()==b.FromCity:GetID()
        and a.ToCity:GetID()==b.ToCity:GetID() and a.Domain==b.Domain and a.ConnectionType==b.ConnectionType
end
function LekmodScenario.snapshot(player)
    local routes={}
    for i,r in ipairs(player:GetTradeRoutes()) do
        routes[i]={from=r.FromID,to=r.ToID,from_city=r.FromCity:GetID(),to_city=r.ToCity:GetID(),
            domain=r.Domain,kind=r.ConnectionType,left=r.TurnsLeft,gold100=r.FromGPT,food100=r.ToFood,production100=r.ToProduction}
    end
    return {turn=Game.GetGameTurn(),routes=routes}
end
function LekmodScenario.step(player)
    local routes=player:GetTradeRoutes();assert(#routes>0,"existing contract required")
    local available=player:GetTradeRoutesAvailable();local incoming=0
    for _,r in ipairs(routes) do
        assert(r.TurnsLeft>0,"active contract countdown must be positive")
        local match
        for _,a in ipairs(available) do if same(a,r) then match=a;break end end
        assert(match and match.TurnsLeft==r.TurnsLeft,"available/outgoing countdown mismatch")
        if r.FromID~=r.ToID then
            match=nil
            for _,a in ipairs(Players[r.ToID]:GetTradeRoutesToYou()) do if same(a,r) then match=a;break end end
            assert(match and match.TurnsLeft==r.TurnsLeft,"incoming/outgoing countdown mismatch")
            incoming=incoming+1
        end
    end
    assert(incoming>0,"load an external route to exercise the incoming API")
    LekmodScenarioRecord("trade-list-countdowns","PASS","outgoing="..#routes.." incoming="..incoming.." path=read-only-native-queries")
    return true
end
