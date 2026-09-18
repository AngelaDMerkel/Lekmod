-- Provided AI coastal cities/buildings/reveal/cargo ship and a Qasimi Raider.
-- Trade creation, war and plunder use legal normal missions/commands.
LekmodScenario={name="uae-raider",items={"uae-sea-plunder","uae-raider-experience","uae-raider-movement"}}
local phase,origin,target,inputID,visualID,raiderID,kind,pending,aiError,started,before,eventSeen="init"
local previous={}
local function seaArea(p)
    for d=0,5 do local a=Map.PlotDirection(p:GetX(),p:GetY(),d)
        if a and a:IsWater() and not a:IsLake() then return a:GetArea() end
    end
end
local function provideCity(p,near,area,minimum)
    for i=0,Map.GetNumPlots()-1 do local plot=Map.GetPlotByIndex(i)
        local distance=Map.PlotDistance(near:GetX(),near:GetY(),plot:GetX(),plot:GetY())
        if plot:GetOwner()==-1 and plot:GetNumUnits()==0 and distance>=(minimum or 4) and distance<=12
            and seaArea(plot) and (not area or seaArea(plot)==area) and p:CanFound(plot:GetX(),plot:GetY()) then
            p:Found(plot:GetX(),plot:GetY());local c=assert(plot:GetPlotCity())
            LekmodScenarioEvent("fixture-setup",{operation="provided-AI-coastal-city",owner=p:GetID(),city=c:GetID(),x=c:GetX(),y=c:GetY()})
            return c
        end
    end
    error("no legal coastal city input site")
end
GameEvents.PlayerDoTurn.Add(function(owner)
    if owner~=1 or not pending then return end;pending=false
    local ok,err=pcall(function()
        local p=Players[owner];local u=assert(p:GetUnitByID(inputID));local c=assert(p:GetCityByID(target))
        assert(p:IsTurnActive() and u:CanMakeTradeRouteAt(u:GetPlot(),c:GetX(),c:GetY(),kind),"AI sea route not legal on actual owner turn")
        u:PushMission(GameInfoTypes.MISSION_ESTABLISH_TRADE_ROUTE,c:Plot():GetPlotIndex(),kind,0,0,1)
    end)
    if not ok then aiError=tostring(err) end
end)
GameEvents.UnitPlundered.Add(function(owner,id,x,y)
    if owner==Game.GetActivePlayer() and id==raiderID then eventSeen={x=x,y=y} end
end)
function LekmodScenario.snapshot(player)
    local raiders,routes={},{}
    for u in player:Units() do if u:GetUnitType()==GameInfoTypes.UNIT_QASIMI_RAIDER then raiders[u:GetID()]={moves=u:GetMoves(),xp=u:GetExperience(),x=u:GetX(),y=u:GetY()} end end
    for _,r in ipairs(Players[1]:GetTradeRoutes()) do routes[#routes+1]={from=r.FromCity:GetID(),to=r.ToCity:GetID(),domain=r.Domain,kind=r.ConnectionType} end
    return {turn=Game.GetGameTurn(),gold=player:GetGold(),raiders=raiders,enemy_routes=routes,war=Teams[player:GetTeam()]:IsAtWar(Players[1]:GetTeam())}
end
function LekmodScenario.step(player)
    if aiError then LekmodScenarioRecord("uae-route-command","FAIL",aiError);return true end
    assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_UAE,"select UAE normally")
    local other=Players[1]
    if not player:GetCapitalCity() or not other:GetCapitalCity() then return "turn" end
    if phase=="init" then
        assert(not Teams[player:GetTeam()]:IsAtWar(other:GetTeam()),"start at peace")
        local destination=other:GetCapitalCity()
        if not destination:IsCoastal(10) then destination=provideCity(other,destination:Plot()) end
        local home=provideCity(other,destination:Plot(),seaArea(destination:Plot()),7)
        origin,target=home:GetID(),destination:GetID()
        for _,name in ipairs({"BUILDING_GRANARY","BUILDING_HARBOR"}) do
            home:SetNumRealBuilding(GameInfoTypes[name],1)
            LekmodScenarioEvent("fixture-setup",{operation="provided-origin-building",city=origin,building=name})
        end
        local revealed=0
        for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i)
            if Map.PlotDistance(home:GetX(),home:GetY(),p:GetX(),p:GetY())<=other:GetTradeRouteRange(DomainTypes.DOMAIN_SEA,home) and not p:IsRevealed(other:GetTeam()) then p:SetRevealed(other:GetTeam(),true);revealed=revealed+1 end
        end
        LekmodScenarioEvent("fixture-setup",{operation="provided-AI-sea-trade-reveal",plots=revealed})
        assert(other:GetNumInternationalTradeRoutesAvailable()>other:GetNumInternationalTradeRoutesUsed(),"no spare AI trade capacity")
        for u in other:Units() do previous[u:GetID()]=true end
        local u=assert(other:InitUnit(other:GetTradeUnitType(DomainTypes.DOMAIN_SEA),home:GetX(),home:GetY()));inputID=u:GetID()
        LekmodScenarioEvent("fixture-setup",{operation="provided-AI-cargo-ship",unit=inputID})
        for _,r in ipairs(other:GetPotentialInternationalTradeRouteDestinations(u)) do
            if r.X==destination:GetX() and r.Y==destination:GetY() and r.Yields[YieldTypes.YIELD_FOOD+1].Theirs>0 then kind=r.TradeConnectionType;break end
        end
        assert(kind~=nil,"no legal internal food sea route to target")
        started=Game.GetGameTurn();pending=true;phase="route";return "turn"
    elseif phase=="route" then
        local route
        for _,r in ipairs(other:GetTradeRoutes()) do if r.FromCity:GetID()==origin and r.ToCity:GetID()==target and r.Domain==DomainTypes.DOMAIN_SEA then route=r;break end end
        if not route then assert(Game.GetGameTurn()-started<3,"sea route not created");return "turn" end
        for u in other:Units() do if u:IsTrade() and u:GetID()~=inputID and not previous[u:GetID()] then visualID=u:GetID();break end end
        assert(visualID,"no new trade visualization unit")
        local plot=other:GetUnitByID(visualID):GetPlot()
        assert(plot:IsWater() and plot:GetNumUnits()==0,"trade visual must be on an empty sea tile")
        local u=assert(player:InitUnit(GameInfoTypes.UNIT_QASIMI_RAIDER,plot:GetX(),plot:GetY()));raiderID=u:GetID()
        LekmodScenarioEvent("fixture-setup",{operation="provided-positioned-Qasimi-Raider",unit=raiderID,x=u:GetX(),y=u:GetY()})
        Network.SendChangeWar(other:GetTeam(),true);phase="war"
    elseif phase=="war" then
        if not LekmodScenarioAwait("uae-war",Teams[player:GetTeam()]:IsAtWar(other:GetTeam())) then return false end
        local u=assert(player:GetUnitByID(raiderID));before={moves=u:GetMoves(),xp=u:GetExperience(),gold=player:GetGold()}
        assert(u:CanStartMission(GameInfoTypes.MISSION_PLUNDER_TRADE_ROUTE,-1,-1,u:GetPlot(),0),"Qasimi plunder mission unavailable")
        UI.SelectUnit(u);local action
        for i=0,#GameInfoActions do if GameInfoActions[i] and GameInfoActions[i].Type=="MISSION_PLUNDER_TRADE_ROUTE" then action=i;break end end
        assert(action and Game.CanHandleAction(action),"normal plunder action not enabled")
        Game.HandleAction(action);phase="plundered"
    elseif phase=="plundered" then
        if not LekmodScenarioAwait("uae-route-plundered",eventSeen and other:GetUnitByID(visualID)==nil) then return false end
        local u=assert(player:GetUnitByID(raiderID));local after={moves=u:GetMoves(),xp=u:GetExperience(),gold=player:GetGold()}
        LekmodScenarioEvent("uae-plunder-outcome",{before=before,after=after,move_denominator=GameDefines.MOVE_DENOMINATOR,expected_move_reward=2*GameDefines.MOVE_DENOMINATOR})
        for _,r in ipairs(other:GetTradeRoutes()) do assert(r.FromCity:GetID()~=origin or r.ToCity:GetID()~=target,"plundered route remains active") end
        LekmodScenarioRecord("uae-sea-plunder","PASS","path=normal-plunder-action sea-route-and-visual-removed=true")
        LekmodScenarioRecord("uae-raider-experience",after.xp-before.xp==15 and "PASS" or "FAIL","actual="..(after.xp-before.xp).." expected=15")
        LekmodScenarioRecord("uae-raider-movement",after.moves-before.moves==2*GameDefines.MOVE_DENOMINATOR and "PASS" or "FAIL","actual="..(after.moves-before.moves).." expected="..(2*GameDefines.MOVE_DENOMINATOR))
        return true
    end
    return false
end
