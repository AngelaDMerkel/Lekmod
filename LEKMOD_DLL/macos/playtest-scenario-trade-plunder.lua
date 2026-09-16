-- Supply an AI internal route through a legal city/unit mission, then use the
-- human's normal plunder action. No route-loss, gold or yield outcome is assigned.
LekmodScenario={name="trade-plunder",items={"plunder-peace-rejection","plunder-own-rejection","plunder-noncombat-rejection","trade-plunder","plunder-yields-cleared"}}
local phase,origin,target,kind,amount,foodBefore,usedBefore,goldBefore,raiderID,workerID,visualID,inputID,eventSeen,routeIssued,pendingAI,aiError="init"
local previous={}
local mission=GameInfoTypes.MISSION_PLUNDER_TRADE_ROUTE
local function food(c) return c:GetYieldRateTimes100(YieldTypes.YIELD_FOOD,false)-c:GetYieldRateTimes100(YieldTypes.YIELD_FOOD,true) end
GameEvents.UnitPlundered.Add(function(owner,id,x,y)
    if owner==Game.GetActivePlayer() and id==raiderID then eventSeen={x=x,y=y} end
end)
GameEvents.PlayerDoTurn.Add(function(owner)
    if owner~=1 or not pendingAI then return end
    pendingAI=false
    local ok,err=pcall(function()
        local other=Players[1];local c=assert(other:GetCityByID(target));local u=assert(other:GetUnitByID(inputID))
        assert(other:IsTurnActive(),"AI route callback is outside its real active turn")
        assert(u:CanMakeTradeRouteAt(u:GetPlot(),c:GetX(),c:GetY(),kind),"AI route became ineligible before its active turn")
        LekmodScenarioEvent("AI-route-command",{mission=GameInfoTypes.MISSION_ESTABLISH_TRADE_ROUTE,target_plot=c:Plot():GetPlotIndex(),kind=kind,moves=u:GetMoves(),owner_active=true})
        u:PushMission(GameInfoTypes.MISSION_ESTABLISH_TRADE_ROUTE,c:Plot():GetPlotIndex(),kind,0,0,1)
    end)
    if not ok then aiError=tostring(err) end
end)
function LekmodScenario.snapshot(player)
    local owners={}
    for id=0,1 do local p=Players[id];local routes,units,cities={},{},{}
        for i,r in ipairs(p:GetTradeRoutes()) do routes[i]={from=r.FromCity:GetID(),to=r.ToCity:GetID(),to_owner=r.ToID,domain=r.Domain,kind=r.ConnectionType,left=r.TurnsLeft,food100=r.ToFood} end
        for u in p:Units() do if u:IsTrade() then units[u:GetID()]={type=u:GetUnitType(),x=u:GetX(),y=u:GetY()} end end
        for c in p:Cities() do cities[c:GetID()]={food100=food(c)} end
        owners[id]={gold=p:GetGold(),routes=routes,units=units,used=p:GetNumInternationalTradeRoutesUsed(),cities=cities}
    end
    return {turn=Game.GetGameTurn(),owners=owners,war=Teams[player:GetTeam()]:IsAtWar(Players[1]:GetTeam())}
end
function LekmodScenario.step(player)
    assert(not aiError,aiError)
    local other=Players[1]
    assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_ROME,"Rome fixture required for the unmodified 100-gold land plunder reward")
    if phase=="init" then
        assert(not Teams[player:GetTeam()]:IsAtWar(other:GetTeam()),"fixture must start at peace")
        local capital=other:GetCapitalCity();local site
        for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i)
            local distance=Map.PlotDistance(capital:GetX(),capital:GetY(),p:GetX(),p:GetY())
            if distance>=4 and distance<=7 and p:GetOwner()==-1 and p:GetNumUnits()==0 and p:GetArea()==capital:Plot():GetArea()
                and other:CanFound(p:GetX(),p:GetY()) then site=p;break end
        end
        assert(site,"no legal AI secondary city for internal route")
        other:Found(site:GetX(),site:GetY());origin=site:GetPlotCity():GetID();target=capital:GetID()
        local c=other:GetCityByID(origin)
        LekmodScenarioEvent("fixture-setup",{operation="provided-AI-secondary-city",owner=1,city=origin,x=c:GetX(),y=c:GetY()})
        for _,name in ipairs({"BUILDING_GRANARY","BUILDING_CARAVANSARY"}) do
            c:SetNumRealBuilding(GameInfoTypes[name],1)
            LekmodScenarioEvent("fixture-setup",{operation="provided-origin-building",building=name,city=origin})
        end
        local revealed=0
        for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i)
            if Map.PlotDistance(c:GetX(),c:GetY(),p:GetX(),p:GetY())<=other:GetTradeRouteRange(DomainTypes.DOMAIN_LAND,c)
                and not p:IsRevealed(other:GetTeam()) then p:SetRevealed(other:GetTeam(),true);revealed=revealed+1 end
        end
        LekmodScenarioEvent("fixture-setup",{operation="revealed-AI-trade-range",plots=revealed})
        assert(other:GetNumInternationalTradeRoutesAvailable()>other:GetNumInternationalTradeRoutesUsed(),"AI has no spare trade capacity")
        for u in other:Units() do previous[u:GetID()]=true end
        local caravan=assert(other:InitUnit(other:GetTradeUnitType(DomainTypes.DOMAIN_LAND),c:GetX(),c:GetY()));inputID=caravan:GetID()
        LekmodScenarioEvent("fixture-setup",{operation="provided-AI-caravan",id=inputID})
        for _,r in ipairs(other:GetPotentialInternationalTradeRouteDestinations(caravan)) do
            if r.X==capital:GetX() and r.Y==capital:GetY() and r.Yields[YieldTypes.YIELD_FOOD+1].Theirs>0 then
                kind=r.TradeConnectionType;amount=r.Yields[YieldTypes.YIELD_FOOD+1].Theirs;break
            end
        end
        assert(kind and caravan:CanMakeTradeRouteAt(c:Plot(),capital:GetX(),capital:GetY(),kind),"legal AI internal food route unavailable")
        foodBefore=food(capital);usedBefore=other:GetNumInternationalTradeRoutesUsed()
        routeIssued=Game.GetGameTurn()
        pendingAI=true
        LekmodScenarioEvent("AI-route-pending",{owner=1,unit=inputID,dispatch="actual-PlayerDoTurn-callback"})
        phase="route";return false
    elseif phase=="route" then
        local route
        for _,r in ipairs(other:GetTradeRoutes()) do if r.FromCity:GetID()==origin and r.ToCity:GetID()==target and r.ToID==1 and r.ConnectionType==kind then route=r;break end end
        if not route then
            -- An AI unit's queued mission starts only on that owner's active
            -- turn. Let the ordinary turn cycle run; never clear waiting flags.
            assert(Game.GetGameTurn()-routeIssued<2,"AI route mission did not complete during its ordinary owner turn")
            return "turn"
        end
        assert(food(other:GetCityByID(target))==foodBefore+amount,"AI route did not apply food contribution")
        for u in other:Units() do if u:IsTrade() and u:GetID()~=inputID and not previous[u:GetID()] then visualID=u:GetID();break end end
        assert(visualID,"new active trade unit missing")
        local capital=player:GetCapitalCity()
        if player:GetNumResourceAvailable(GameInfoTypes.RESOURCE_HORSE,true)<1 then player:ChangeNumResourceTotal(GameInfoTypes.RESOURCE_HORSE,1)
            LekmodScenarioEvent("fixture-setup",{operation="provided-horse",added=1}) end
        local raider=player:InitUnit(GameInfoTypes.UNIT_HORSEMAN,capital:GetX(),capital:GetY());raiderID=raider:GetID()
        local worker=player:InitUnit(GameInfoTypes.UNIT_WORKER,capital:GetX(),capital:GetY());workerID=worker:GetID()
        LekmodScenarioEvent("fixture-setup",{operation="provided-query-and-raiding-units",raider=raiderID,worker=workerID})
        local plot=other:GetUnitByID(visualID):GetPlot()
        assert(not raider:CanStartMission(mission,-1,-1,plot,0),"peaceful foreign route can be plundered")
        LekmodScenarioRecord("plunder-peace-rejection","PASS","path=normal-mission-eligibility")
        local own
        for u in player:Units() do if u:IsTrade() and u:GetDomainType()==DomainTypes.DOMAIN_LAND then own=u:GetPlot();break end end
        assert(own and not raider:CanStartMission(mission,-1,-1,own,0),"own route is missing or plunderable")
        LekmodScenarioRecord("plunder-own-rejection","PASS","path=normal-mission-eligibility")
        Network.SendChangeWar(other:GetTeam(),true);phase="war";return false
    elseif phase=="war" then
        if not LekmodScenarioAwait("plunder-war",Teams[player:GetTeam()]:IsAtWar(other:GetTeam())) then return false end
        local visual=assert(other:GetUnitByID(visualID),"internal AI route disappeared on war declaration")
        local plot=visual:GetPlot();local raider=assert(player:GetUnitByID(raiderID));local worker=assert(player:GetUnitByID(workerID))
        assert(not worker:CanStartMission(mission,-1,-1,plot,0),"noncombat worker can plunder trade")
        LekmodScenarioRecord("plunder-noncombat-rejection","PASS","path=normal-mission-eligibility")
        assert(raider:CanStartMission(mission,-1,-1,plot,0),"wartime route not plunderable")
        assert(not plot:IsCity() and plot:GetNumUnits()==0,"route visualization is not on an empty staging plot")
        raider:SetXY(plot:GetX(),plot:GetY(),false,true,false,false)
        LekmodScenarioEvent("fixture-setup",{operation="position-raider",x=plot:GetX(),y=plot:GetY(),id=raiderID})
        goldBefore=player:GetGold();UI.SelectUnit(raider)
        local action
        for i=0,#GameInfoActions do if GameInfoActions[i] and GameInfoActions[i].Type=="MISSION_PLUNDER_TRADE_ROUTE" then action=i;break end end
        assert(action and Game.CanHandleAction(action),"actual plunder action not enabled")
        Game.HandleAction(action);phase="plundered";return false
    elseif phase=="plundered" then
        if not LekmodScenarioAwait("trade-plundered",eventSeen~=nil and other:GetUnitByID(visualID)==nil) then return false end
        assert(player:GetGold()==goldBefore+100,"normal land plunder did not award exactly 100 gold")
        assert(other:GetNumInternationalTradeRoutesUsed()==usedBefore-1,"plunder did not remove one occupied trade slot")
        for _,r in ipairs(other:GetTradeRoutes()) do assert(r.FromCity:GetID()~=origin or r.ToCity:GetID()~=target,"plundered route remains active") end
        assert(not player:GetUnitByID(raiderID):CanStartMission(mission,-1,-1,player:GetUnitByID(raiderID):GetPlot(),0),"empty route tile can be plundered again")
        LekmodScenarioRecord("trade-plunder","PASS","path=actual-unit-action gold=100 route-and-unit-removed=true")
        assert(food(other:GetCityByID(target))==foodBefore,"plundered internal route retained food yield")
        LekmodScenarioRecord("plunder-yields-cleared","PASS","food-contribution-returned-to-baseline=true")
        return true
    end
    return false
end
