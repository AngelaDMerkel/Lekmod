-- Full-health units/resources are supplied and logged. Interception, sweeping,
-- rebasing and transport use real missions; no activity/combat flags are set.
LekmodScenario={name="air-operations",items={"air-interception","air-sweep","carrier-rebase","carrier-capacity","carrier-movement"}}
local phase,barbarian,bomber,fighter,interceptor,target,carrier,planes,destination="init",nil,nil,nil,nil,nil,nil,{}
local function input(owner,kind,p)
    local u=assert(Players[owner]:InitUnit(GameInfoTypes[kind],p:GetX(),p:GetY()))
    LekmodScenarioEvent("fixture-setup",{operation="provided-unit",owner=owner,type=kind,id=u:GetID(),x=u:GetX(),y=u:GetY()})
    return u:GetID()
end
local function mission(u,kind,p)
    UI.SelectUnit(u)
    Game.SelectionListGameNetMessage(GameMessageTypes.GAMEMESSAGE_PUSH_MISSION,MissionTypes[kind],p:GetX(),p:GetY(),0,false,false)
end
function LekmodScenario.snapshot(player)
    local units={}
    for owner=0,GameDefines.MAX_CIV_PLAYERS do local p=Players[owner]
        if p then for u in p:Units() do
            local transport=u:GetTransportUnit()
            units[owner..":"..u:GetID()]={type=u:GetUnitType(),x=u:GetX(),y=u:GetY(),moves=u:GetMoves(),damage=u:GetDamage(),xp=u:GetExperience(),
                cargo=u:GetCargo(),transport=transport and transport:GetID() or -1,interceptions_spent=u:isOutOfInterceptions()}
        end end
    end
    return {turn=Game.GetGameTurn(),units=units}
end
function LekmodScenario.step(player)
    local city=assert(player:GetCapitalCity())
    if phase=="init" then
        for id=0,GameDefines.MAX_CIV_PLAYERS do if Players[id] and Players[id]:IsBarbarian() then barbarian=id;break end end
        assert(barbarian,"missing barbarian opponent")
        for _,kind in ipairs({"RESOURCE_OIL","RESOURCE_ALUMINUM"}) do
            local id=GameInfoTypes[kind];local amount=10-player:GetNumResourceAvailable(id,true)
            if amount>0 then player:ChangeNumResourceTotal(id,amount);LekmodScenarioEvent("fixture-setup",{operation="provided-resource",type=kind,added=amount}) end
        end
        local aa
        for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i)
            local distance=Map.PlotDistance(city:GetX(),city:GetY(),p:GetX(),p:GetY())
            if distance<=2 and not p:IsWater() and not p:IsMountain() and not p:IsCity() and p:GetNumUnits()==0 then
                for d=0,5 do local q=Map.PlotDirection(p:GetX(),p:GetY(),d)
                    if q and not q:IsWater() and not q:IsMountain() and not q:IsCity() and q:GetNumUnits()==0 then target,aa=p,q;break end
                end
                if target then break end
            end
        end
        assert(aa,"no open land interception pair near the capital")
        local defender=input(barbarian,"UNIT_INFANTRY",target)
        interceptor=input(barbarian,"UNIT_ANTI_AIRCRAFT_GUN",aa)
        bomber=input(player:GetID(),"UNIT_BOMBER",city:Plot())
        local u=player:GetUnitByID(bomber);local best=u:GetBestInterceptor(target,Players[barbarian]:GetUnitByID(defender),false,false,false)
        assert(best and best:GetID()==interceptor and best:CurrInterceptionProbability()==100,"expected full-health 100-percent interceptor unavailable")
        assert(u:CanRangeStrikeAt(target:GetX(),target:GetY()),"intercepted strike unavailable")
        -- WorldView's AIRSTRIKE handler submits MOVE_TO for air units.
        mission(u,"MISSION_MOVE_TO",target);phase="intercepted"
    elseif phase=="intercepted" then
        local u=assert(player:GetUnitByID(bomber),"bomber was destroyed")
        local aa=assert(Players[barbarian]:GetUnitByID(interceptor))
        if u:IsBusy() or target:IsFighting() then return false end
        LekmodScenarioEvent("interception-state",{bomber_damage=u:GetDamage(),bomber_moves=u:GetMoves(),interceptions_spent=aa:isOutOfInterceptions(),interceptor_xp=aa:GetExperience()})
        if not LekmodScenarioAwait("interception",aa:isOutOfInterceptions() and u:GetDamage()>0) then return false end
        LekmodScenarioRecord("air-interception","PASS","path=normal-air-strike bomber-damage="..u:GetDamage())
        local plot
        for d=0,5 do local p=Map.PlotDirection(target:GetX(),target:GetY(),d)
            if p and not p:IsWater() and not p:IsMountain() and not p:IsCity() and p:GetNumUnits()==0 then plot=p;break end
        end
        assert(plot,"no second interceptor position")
        interceptor=input(barbarian,"UNIT_ANTI_AIRCRAFT_GUN",plot)
        fighter=input(player:GetID(),"UNIT_FIGHTER",city:Plot())
        local f=player:GetUnitByID(fighter);assert(f:IsHasPromotion(GameInfoTypes.PROMOTION_AIR_SWEEP),"fighter lacks sweep ability")
        local best=f:GetBestInterceptor(target,nil,false,false,false)
        assert(best and best:GetID()==interceptor,"new sweep interceptor unavailable")
        mission(f,"MISSION_AIR_SWEEP",target);phase="swept"
    elseif phase=="swept" then
        local f=assert(player:GetUnitByID(fighter));local aa=assert(Players[barbarian]:GetUnitByID(interceptor))
        if f:IsBusy() or target:IsFighting() then return false end
        LekmodScenarioEvent("sweep-state",{fighter_damage=f:GetDamage(),fighter_moves=f:GetMoves(),fighter_xp=f:GetExperience(),interceptions_spent=aa:isOutOfInterceptions(),interceptor_damage=aa:GetDamage()})
        if not LekmodScenarioAwait("air-sweep",aa:isOutOfInterceptions() and f:GetMoves()==0) then return false end
        -- Lekmod deliberately gives no attacker XP for sweeping ground AA,
        -- and its ground-sweep damage multiplier is zero for both sides.
        assert(GameDefines.AIR_SWEEP_INTERCEPTION_DAMAGE_MOD==0 and f:GetDamage()==0 and aa:GetDamage()==0 and f:GetExperience()==0,"ground air-sweep result differs from the configured rules")
        LekmodScenarioRecord("air-sweep","PASS","path=normal-air-sweep ground-interception=spent both-damage=0 attacker-xp=0-as-designed")
        local water
        for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i)
            if p:IsWater() and p:GetFeatureType()~=GameInfoTypes.FEATURE_ICE and p:GetNumUnits()==0
                and p:GetOwner()==-1 and Map.PlotDistance(city:GetX(),city:GetY(),p:GetX(),p:GetY())<=8 then water=p;break end
        end
        assert(water,"no carrier position within rebase range")
        carrier=input(player:GetID(),"UNIT_CARRIER",water)
        assert(player:GetUnitByID(carrier):CargoSpace()==3,"fixture expects ordinary capacity three")
        phase="load"
    elseif phase=="load" then
        local c=assert(player:GetUnitByID(carrier))
        local id=input(player:GetID(),"UNIT_FIGHTER",city:Plot());local u=player:GetUnitByID(id)
        assert(u:CanRebaseAt(u:GetPlot(),c:GetX(),c:GetY()),"legal carrier rebase unavailable")
        planes[#planes+1]=id;mission(u,"MISSION_REBASE",c:GetPlot());phase="loaded"
    elseif phase=="loaded" then
        local c=assert(player:GetUnitByID(carrier));local u=assert(player:GetUnitByID(planes[#planes]))
        local transport=u:GetTransportUnit()
        if not LekmodScenarioAwait("carrier-load-"..#planes,transport~=nil and transport:GetID()==carrier and c:GetCargo()==#planes) then return false end
        assert(u:GetX()==c:GetX() and u:GetY()==c:GetY() and u:IsCargo(),"rebased plane not on carrier")
        if #planes<3 then phase="load";return false end
        LekmodScenarioRecord("carrier-rebase","PASS","path=normal-rebase-missions planes=3")
        local id=input(player:GetID(),"UNIT_FIGHTER",city:Plot());local extra=player:GetUnitByID(id)
        assert(not extra:CanRebaseAt(extra:GetPlot(),c:GetX(),c:GetY()),"full carrier accepts a fourth plane")
        LekmodScenarioRecord("carrier-capacity","PASS","capacity=3 fourth-plane=rejected")
        for d=0,5 do local p=Map.PlotDirection(c:GetX(),c:GetY(),d)
            if p and p:IsWater() and p:GetNumUnits()==0 and c:CanMoveOrAttackInto(p,0,1) then destination=p;break end
        end
        assert(destination,"carrier has no legal adjacent sea move")
        mission(c,"MISSION_MOVE_TO",destination);phase="moved"
    elseif phase=="moved" then
        local c=assert(player:GetUnitByID(carrier))
        if not LekmodScenarioAwait("carrier-moved",c:GetX()==destination:GetX() and c:GetY()==destination:GetY()) then return false end
        for _,id in ipairs(planes) do local u=assert(player:GetUnitByID(id))
            assert(u:IsCargo() and u:GetTransportUnit():GetID()==carrier and u:GetX()==c:GetX() and u:GetY()==c:GetY(),"carrier left a plane behind")
        end
        LekmodScenarioRecord("carrier-movement","PASS","path=normal-sea-move transported-planes=3")
        return true
    end
    return false
end
