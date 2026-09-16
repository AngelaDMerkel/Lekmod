-- Follow the existing short contracts through ordinary turns. Never alter
-- remaining duration or terminate a route directly.
LekmodScenario={name="trade-expiry",items={"trade-expiry","expired-trade-units-return","expired-trade-yields-cleared"}}
local started,deadline,earliest,count,used,origins,ends,unitCount,lastRecorded
local function key(r) return r.Domain..":"..r.FromCity:GetID()..":"..r.ToCity:GetID() end
local function tradeYield(c,y) return c:GetYieldRateTimes100(y,false)-c:GetYieldRateTimes100(y,true) end
function LekmodScenario.snapshot(player)
    local units,cities={},{}
    for u in player:Units() do if u:IsTrade() then units[u:GetID()]={type=u:GetUnitType(),x=u:GetX(),y=u:GetY(),moves=u:GetMoves()} end end
    for c in player:Cities() do cities[c:GetID()]={food100=tradeYield(c,YieldTypes.YIELD_FOOD),production100=tradeYield(c,YieldTypes.YIELD_PRODUCTION),gold100=tradeYield(c,YieldTypes.YIELD_GOLD)} end
    return {turn=Game.GetGameTurn(),routes=#player:GetTradeRoutes(),used=player:GetNumInternationalTradeRoutesUsed(),units=units,cities=cities}
end
function LekmodScenario.step(player)
    local routes=player:GetTradeRoutes()
    if not started then
        started=Game.GetGameTurn();count=#routes;used=player:GetNumInternationalTradeRoutesUsed();origins={};ends={};deadline=started;earliest=math.huge
        assert(count>=1 and count<=2,"load the internal-route fixture or its late autosave")
        unitCount=0
        for u in player:Units() do if u:IsTrade() then
            unitCount=unitCount+1
            if u:GetPlot():IsCity() then origins[u:GetX()..":"..u:GetY()]=true end
        end end
        for _,r in ipairs(routes) do
            assert(r.FromID==player:GetID() and r.ToID==player:GetID() and r.TurnsLeft>0 and r.TurnsLeft<=26,"fixture route is outside the bounded contract scope")
            deadline=math.max(deadline,started+r.TurnsLeft)
            earliest=math.min(earliest,started+r.TurnsLeft)
            ends[key(r)]=started+r.TurnsLeft
            origins[r.FromCity:GetX()..":"..r.FromCity:GetY()]=true
        end
        LekmodScenarioEvent("existing-route-contracts",{start=started,latest_allowed=deadline,routes=count})
    end
    local active={}
    for _,r in ipairs(routes) do
        local k=key(r);active[k]=true
        assert(r.TurnsLeft>0 and ends[k]==Game.GetGameTurn()+r.TurnsLeft,"countdown no longer matches the route's completion turn")
    end
    for k,finish in pairs(ends) do
        assert(active[k] or Game.GetGameTurn()>=finish,"route disappeared before its quoted completion turn")
    end
    if lastRecorded~=Game.GetGameTurn() then
        lastRecorded=Game.GetGameTurn()
        LekmodScenarioEvent("expiry-progress",{turn=lastRecorded,routes=#routes,ends=ends})
    end
    if #routes>0 then
        assert(Game.GetGameTurn()<=deadline,"trade contracts did not expire within their quoted durations")
        return "turn"
    end
    assert(Game.GetGameTurn()>=earliest,"routes disappeared before their natural contract end")
    LekmodScenarioRecord("trade-expiry","PASS","path=ordinary-turns elapsed="..Game.GetGameTurn()-started)
    local returned=0
    for u in player:Units() do if u:IsTrade() then
        assert(u:GetPlot():IsCity() and origins[u:GetX()..":"..u:GetY()],"expired trade unit did not return to an origin city")
        returned=returned+1
    end end
    assert(returned==unitCount and player:GetNumInternationalTradeRoutesUsed()==used,"expired routes lost/duplicated trade units or capacity")
    LekmodScenarioRecord("expired-trade-units-return","PASS","returned="..returned.." occupied-capacity-retained="..used)
    for c in player:Cities() do
        assert(tradeYield(c,YieldTypes.YIELD_FOOD)==0 and tradeYield(c,YieldTypes.YIELD_PRODUCTION)==0,"expired internal route retained destination yields")
    end
    LekmodScenarioRecord("expired-trade-yields-cleared","PASS","food-and-production=0")
    return true
end
