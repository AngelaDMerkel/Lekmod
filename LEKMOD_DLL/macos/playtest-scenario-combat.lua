-- Supplied full-health units/resources at recorded natural map locations.
-- Damage, death, XP and captures must result from ordinary network missions.
LekmodScenario={name="combat",items={"land-ranged","land-melee","combat-unit-death","civilian-capture","city-ranged","naval-ranged","air-strike","combat-restrictions"}}
local cases={
    {item="land-ranged",attacker="UNIT_ARCHER",defender="UNIT_SPEARMAN",ranged=true},
    {item="land-melee",attacker="UNIT_WARRIOR",defender="UNIT_WARRIOR"},
    {item="combat-unit-death",attacker="UNIT_MECH",defender="UNIT_WARRIOR",death=true},
    {item="civilian-capture",attacker="UNIT_WARRIOR",defender="UNIT_WORKER",capture=true},
    {item="city-ranged",defender="UNIT_INFANTRY",city=true,ranged=true},
    {item="naval-ranged",attacker="UNIT_FRIGATE",defender="UNIT_CARAVEL",sea=true,ranged=true},
    {item="air-strike",attacker="UNIT_BOMBER",defender="UNIT_INFANTRY",air=true,ranged=true},
}
local index,phase,barbarian,attackerID,defenderID,source,target,issued,initialCount=1,"init"
local function available(p,sea)
    return p and p:IsWater()==(sea==true) and not p:IsMountain() and not p:IsCity() and p:GetNumUnits()==0
        and p:GetFeatureType()~=GameInfoTypes.FEATURE_ICE and (p:GetOwner()==-1 or p:GetOwner()==Game.GetActivePlayer())
end
local function input(owner,kind,p)
    local u=assert(Players[owner]:InitUnit(GameInfoTypes[kind],p:GetX(),p:GetY()),"cannot create input "..kind)
    assert(u:GetDamage()==0,"input unit is not at full health")
    LekmodScenarioEvent("fixture-setup",{operation="provided-combat-unit",owner=owner,type=kind,id=u:GetID(),x=u:GetX(),y=u:GetY()})
    return u:GetID()
end
function LekmodScenario.snapshot(player)
    local units,cities={},{}
    for id=0,GameDefines.MAX_CIV_PLAYERS do local p=Players[id]
        if p then
            for u in p:Units() do units[id..":"..u:GetID()]={type=u:GetUnitType(),x=u:GetX(),y=u:GetY(),damage=u:GetDamage(),moves=u:GetMoves(),xp=u:GetExperience()} end
            for c in p:Cities() do cities[id..":"..c:GetID()]={x=c:GetX(),y=c:GetY(),damage=c:GetDamage(),population=c:GetPopulation()} end
        end
    end
    return {turn=Game.GetGameTurn(),gold=player:GetGold(),units=units,cities=cities}
end
function LekmodScenario.step(player)
    local case=cases[index]
    if not case then LekmodScenarioRecord("combat-restrictions","PASS","friendly-fire-and-second-ranged-attack=rejected");return true end
    local city=assert(player:GetCapitalCity())
    if phase=="init" then
        for id=0,GameDefines.MAX_CIV_PLAYERS do if Players[id] and Players[id]:IsBarbarian() then barbarian=id;break end end
        assert(barbarian and Teams[player:GetTeam()]:IsAtWar(Players[barbarian]:GetTeam()),"barbarian enemy unavailable")
        for _,kind in ipairs({"RESOURCE_IRON","RESOURCE_URANIUM","RESOURCE_OIL"}) do
            local id=GameInfoTypes[kind];local amount=4-player:GetNumResourceAvailable(id,true)
            if amount>0 then player:ChangeNumResourceTotal(id,amount);LekmodScenarioEvent("fixture-setup",{operation="provided-resource",type=kind,added=amount}) end
        end
        phase="setup"
    elseif phase=="setup" then
        source,target=nil,nil
        for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i)
            local distance=Map.PlotDistance(city:GetX(),city:GetY(),p:GetX(),p:GetY())
            if available(p,case.sea) and (not (case.city or case.air) or (distance>=1 and distance<=2)) then
                if case.city or case.air then source,target=city:Plot(),p;break end
                for d=0,5 do local q=Map.PlotDirection(p:GetX(),p:GetY(),d)
                    if available(q,case.sea) then source,target=p,q;break end
                end
                if source then break end
            end
        end
        assert(source and target,"no natural empty combat staging pair for "..case.item)
        defenderID=input(barbarian,case.defender,target)
        attackerID=nil
        if not case.city then attackerID=input(player:GetID(),case.attacker,source) end
        initialCount=player:GetNumUnits();issued=false;phase="issue"
    elseif phase=="issue" then
        local defender=assert(Players[barbarian]:GetUnitByID(defenderID))
        assert(defender:GetX()==target:GetX() and defender:GetY()==target:GetY(),"input defender moved before the test")
        if case.city then
            assert(city:CanRangeStrikeAt(target:GetX(),target:GetY()),"city strike unavailable")
            Network.SendDoTask(city:GetID(),TaskTypes.TASK_RANGED_ATTACK,target:GetX(),target:GetY(),false,false,false,false)
        else
            local u=assert(player:GetUnitByID(attackerID));UI.SelectUnit(u)
            if case.ranged then
                assert(not u:CanRangeStrikeAt(source:GetX(),source:GetY()),"friendly-fire target allowed")
                assert(u:CanRangeStrikeAt(target:GetX(),target:GetY()),"normal ranged strike unavailable: "..case.item)
            else assert(u:CanMoveOrAttackInto(target,0,1),"normal melee/capture destination unavailable") end
            Game.SelectionListGameNetMessage(GameMessageTypes.GAMEMESSAGE_PUSH_MISSION,
                case.ranged and MissionTypes.MISSION_RANGE_ATTACK or MissionTypes.MISSION_MOVE_TO,target:GetX(),target:GetY(),0,false,false)
        end
        issued=true;phase="result"
    elseif phase=="result" then
        local u=attackerID and player:GetUnitByID(attackerID)
        if (u and u:IsBusy()) or target:IsFighting() then return false end
        local defender=Players[barbarian]:GetUnitByID(defenderID)
        local gone=not defender or defender:IsDead() or defender:IsDelayedDeath()
        local damage=gone and 100 or defender:GetDamage()
        if not LekmodScenarioAwait(case.item,issued and (damage>0 or (case.capture and player:GetNumUnits()>initialCount))) then return false end
        if case.capture then
            local captured=false
            for own in player:Units() do if own:GetUnitType()==GameInfoTypes.UNIT_WORKER and own:GetX()==target:GetX() and own:GetY()==target:GetY() then captured=true end end
            assert(gone and captured and player:GetNumUnits()==initialCount+1,"civilian capture did not transfer a worker")
        elseif case.death then assert(gone,"overwhelming legal attack did not destroy defender")
        elseif case.item=="land-melee" then assert(u and u:GetDamage()>0,"melee exchange did not damage attacker") end
        if u and not case.capture then assert(u:GetExperience()>0,"combat did not award attacker XP") end
        if case.ranged and u then assert(not u:CanRangeStrikeAt(target:GetX(),target:GetY()),"second ranged attack remained legal") end
        LekmodScenarioRecord(case.item,"PASS","path=normal-network-mission target-damage="..damage.." dead="..tostring(gone).." attacker-damage="..(u and u:GetDamage() or 0))
        index=index+1;phase="setup"
    end
    return false
end
