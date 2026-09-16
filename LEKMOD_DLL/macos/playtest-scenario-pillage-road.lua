-- Load the preserved worker fixture with its normally built farm and road.
-- Own pillage must be rejected. An abandoned farm/road and military unit are
-- supplied; their pillage and subsequent neutral-territory repairs are real.
LekmodScenario={name="pillage-road",items={"own-pillage-rejection","farm-pillage","road-pillage","road-repair","road-travel"}}
local phase,plotIndex,raider,worker,food,gold,damage,moves,issuedTurn,abandoned,destination,homeIndex="init"
local function action(u,kind)
    UI.SelectUnit(u)
    for i=0,#GameInfoActions do if GameInfoActions[i] and GameInfoActions[i].Type==kind then
        assert(Game.CanHandleAction(i),"action unavailable: "..kind);Game.HandleAction(i);return
    end end
    error("missing action "..kind)
end
function LekmodScenario.snapshot(player)
    local plots,units={},{}
    for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i)
        if p:GetImprovementType()==GameInfoTypes.IMPROVEMENT_FARM or p:GetRouteType()==GameInfoTypes.ROUTE_ROAD then
            plots[i]={owner=p:GetOwner(),improvement=p:GetImprovementType(),pillaged=p:IsImprovementPillaged(),route=p:GetRouteType(),route_pillaged=p:IsRoutePillaged(),food=p:CalculateYield(YieldTypes.YIELD_FOOD,true)}
        end
    end
    for u in player:Units() do units[u:GetID()]={type=u:GetUnitType(),x=u:GetX(),y=u:GetY(),moves=u:GetMoves(),damage=u:GetDamage()} end
    return {turn=Game.GetGameTurn(),gold=player:GetGold(),plots=plots,units=units}
end
function LekmodScenario.step(player)
    local plot=plotIndex and Map.GetPlotByIndex(plotIndex)
    if phase=="init" then
        for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i)
            if p:GetOwner()==player:GetID() and p:GetImprovementType()==GameInfoTypes.IMPROVEMENT_FARM
                and p:GetRouteType()==GameInfoTypes.ROUTE_ROAD and not p:IsImprovementPillaged() and not p:IsRoutePillaged() then plot,plotIndex=p,i;break end
        end
        assert(plot,"load the intact worker farm/road fixture")
        local horse=GameInfoTypes.RESOURCE_HORSE;local amount=2-player:GetNumResourceAvailable(horse,true)
        if amount>0 then player:ChangeNumResourceTotal(horse,amount);LekmodScenarioEvent("fixture-setup",{operation="provided-horses",added=amount}) end
        local u=assert(player:InitUnit(GameInfoTypes.UNIT_HORSEMAN,plot:GetX(),plot:GetY()));raider=u:GetID();u:SetDamage(40)
        LekmodScenarioEvent("fixture-setup",{operation="provided-horseman-and-damage",id=raider,x=u:GetX(),y=u:GetY(),damage=40})
        assert(not u:CanPillage(plot),"own farm is unexpectedly pillageable")
        LekmodScenarioRecord("own-pillage-rejection","PASS","path=engine-eligibility-query")
        homeIndex=plotIndex
        for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i)
            local distance=Map.PlotDistance(plot:GetX(),plot:GetY(),p:GetX(),p:GetY())
            if distance<=6 and p:GetOwner()==-1 and not p:IsWater() and not p:IsMountain() and not p:IsHills() and p:GetFeatureType()==-1
                and p:GetImprovementType()==-1 and p:GetResourceType(-1)==-1 and p:GetNumUnits()==0
                and (p:GetTerrainType()==GameInfoTypes.TERRAIN_GRASS or p:GetTerrainType()==GameInfoTypes.TERRAIN_PLAINS) then abandoned=p;break end
        end
        assert(abandoned,"no nearby abandoned farm input location")
        abandoned:SetImprovementType(GameInfoTypes.IMPROVEMENT_FARM);abandoned:SetRouteType(GameInfoTypes.ROUTE_ROAD)
        u:SetXY(abandoned:GetX(),abandoned:GetY(),false,true,false,false)
        LekmodScenarioEvent("fixture-setup",{operation="provided-unowned-farm-road-and-position",unit=raider,x=u:GetX(),y=u:GetY()})
        plot,plotIndex=abandoned,abandoned:GetPlotIndex()
        food=plot:CalculateYield(YieldTypes.YIELD_FOOD,true);gold=player:GetGold();damage=u:GetDamage();moves=u:GetMoves()
        assert(u:CanPillage(plot),"unowned farm cannot be pillaged")
        action(u,"MISSION_PILLAGE");phase="farm"
    elseif phase=="farm" then
        local u=assert(player:GetUnitByID(raider))
        if not LekmodScenarioAwait("farm-pillaged",plot:IsImprovementPillaged()) then return false end
        assert(not plot:IsRoutePillaged() and plot:CalculateYield(YieldTypes.YIELD_FOOD,true)<food,"farm pillage changed route or retained improvement yield")
        local gained=player:GetGold()-gold;local maximum=2*math.max(0,GameInfo.Improvements.IMPROVEMENT_FARM.PillageGold-1)
        assert(gained>=0 and gained<=maximum and u:GetDamage()==math.max(0,damage-GameDefines.PILLAGE_HEAL_AMOUNT) and u:GetMoves()<moves,"farm pillage loot/heal/moves mismatch")
        LekmodScenarioRecord("farm-pillage","PASS","path=normal-pillage gold="..gained.." healed="..damage-u:GetDamage())
        gold=player:GetGold()
        damage=u:GetDamage();moves=u:GetMoves();assert(u:CanPillage(plot),"road is not pillageable after farm")
        action(u,"MISSION_PILLAGE");phase="road"
    elseif phase=="road" then
        local u=assert(player:GetUnitByID(raider))
        if not LekmodScenarioAwait("road-pillaged",plot:IsRoutePillaged()) then return false end
        assert(plot:IsImprovementPillaged() and not u:CanPillage(plot) and u:GetDamage()==damage and player:GetGold()==gold and u:GetMoves()<moves,"road pillage/rejection/heal mismatch")
        LekmodScenarioRecord("road-pillage","PASS","path=normal-pillage heal=0 gold=0 fully-pillaged=rejected")
        local home=Map.GetPlotByIndex(homeIndex)
        for unit in player:Units() do if unit:GetUnitType()==GameInfoTypes.UNIT_WORKER and unit:GetX()==home:GetX() and unit:GetY()==home:GetY() then worker=unit:GetID();break end end
        assert(worker,"the original worker is not on its farm/road")
        local w=player:GetUnitByID(worker);w:SetXY(plot:GetX(),plot:GetY(),false,true,false,false)
        LekmodScenarioEvent("fixture-setup",{operation="position-original-worker",unit=worker,x=w:GetX(),y=w:GetY()})
        assert(w:CanBuild(plot,GameInfoTypes.BUILD_REPAIR),"normal neutral-territory repair is unavailable")
        issuedTurn=Game.GetGameTurn();phase="repair"
    elseif phase=="repair" then
        assert(Game.GetGameTurn()-issuedTurn<=8,"repair exceeded eight ordinary turns")
        local u=assert(player:GetUnitByID(worker))
        if not plot:IsImprovementPillaged() and not plot:IsRoutePillaged() then
            assert(plot:CalculateYield(YieldTypes.YIELD_FOOD,true)==food,"repair failed to restore farm yield")
            LekmodScenarioRecord("road-repair","PASS","path=normal-worker-repair farm-and-road=restored turns="..Game.GetGameTurn()-issuedTurn)
            phase="travel";return false
        end
        if u:GetMoves()<=0 or not u:CanBuild(plot,GameInfoTypes.BUILD_REPAIR) then return "turn" end
        action(u,"BUILD_REPAIR");return "turn"
    elseif phase=="travel" then
        local u=assert(player:GetUnitByID(raider))
        if u:GetMoves()<=0 then return "turn" end
        plot=Map.GetPlotByIndex(homeIndex)
        u:SetXY(plot:GetX(),plot:GetY(),false,true,false,false)
        LekmodScenarioEvent("fixture-setup",{operation="position-road-traveler",unit=raider,x=u:GetX(),y=u:GetY()})
        for d=0,5 do local p=Map.PlotDirection(plot:GetX(),plot:GetY(),d)
            if p and p:GetOwner()==player:GetID() and not p:IsWater() and not p:IsMountain() and not p:IsHills()
                and p:GetFeatureType()==-1 and not p:IsCity() and p:GetNumUnits()==0 and u:CanMoveOrAttackInto(p,0,1) then destination=p;break end
        end
        assert(destination,"no legal adjacent bare owned road destination")
        destination:SetRouteType(GameInfoTypes.ROUTE_ROAD)
        LekmodScenarioEvent("fixture-setup",{operation="provided-adjacent-road",x=destination:GetX(),y=destination:GetY()})
        moves=u:GetMoves();UI.SelectUnit(u)
        Game.SelectionListGameNetMessage(GameMessageTypes.GAMEMESSAGE_PUSH_MISSION,MissionTypes.MISSION_MOVE_TO,destination:GetX(),destination:GetY(),0,false,false)
        phase="moved"
    elseif phase=="moved" then
        local u=assert(player:GetUnitByID(raider))
        if not LekmodScenarioAwait("road-move",u:GetX()==destination:GetX() and u:GetY()==destination:GetY()) then return false end
        local used=moves-u:GetMoves();assert(used>0 and used<GameDefines.MOVE_DENOMINATOR,"road did not reduce movement below one ordinary terrain step")
        LekmodScenarioRecord("road-travel","PASS","path=normal-move move-points="..used.." ordinary-step="..GameDefines.MOVE_DENOMINATOR)
        return true
    end
    return false
end
