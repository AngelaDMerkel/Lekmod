-- Input unit, XP, iron, damage and staging positions are explicit fixtures.
-- Promotion/upgrade/healing and embark/disembark use ordinary game actions.
LekmodScenario={name="unit-actions",items={"unit-promotion","unit-upgrade","unit-healing","unit-embark","unit-disembark","unit-restrictions"}}
local phase,id,newID,promotion,level,xp,target,cost,gold,home,coast,water,healTurn="init"
local xpTurn
GameEvents.UnitUpgraded.Add(function(owner,oldID,upgradedID,ruin)
    if owner==Game.GetActivePlayer() and oldID==id then
        assert(not ruin,"upgrade unexpectedly came from a ruin")
        newID=upgradedID
    end
end)
local function actionID(kind)
    for i=0,#GameInfoActions do
        if GameInfoActions[i] and GameInfoActions[i].Type==kind then return i end
    end
    error("unit action missing: "..kind)
end
local function action(unit,kind)
    UI.SelectUnit(unit)
    local index=actionID(kind)
    assert(Game.CanHandleAction(index),"unit action unavailable: "..kind)
    Game.HandleAction(index)
end
local function stage(unit,plot,purpose)
    unit:SetXY(plot:GetX(),plot:GetY(),false,true,false,false)
    LekmodScenarioEvent("fixture-setup",{operation="position-unit",purpose=purpose,id=unit:GetID(),x=plot:GetX(),y=plot:GetY()})
end
local function move(unit,plot)
    -- General CanMoveOrAttackInto uses the current embark state. Domain
    -- transitions have their own engine eligibility checks.
    local allowed
    if unit:IsEmbarked() and not plot:IsWater() then allowed=unit:CanDisembarkOnto(plot)
    elseif not unit:IsEmbarked() and plot:IsWater() then allowed=unit:CanEmbarkOnto(unit:GetPlot(),plot)
    else allowed=unit:CanMoveOrAttackInto(plot) end
    assert(allowed,"requested unit move is illegal")
    UI.SelectUnit(unit)
    Game.SelectionListGameNetMessage(GameMessageTypes.GAMEMESSAGE_PUSH_MISSION,MissionTypes.MISSION_MOVE_TO,plot:GetX(),plot:GetY(),0,false,false)
end
function LekmodScenario.snapshot(player)
    local units={}
    for unit in player:Units() do
        local promotions={}
        for info in GameInfo.UnitPromotions() do if unit:IsHasPromotion(info.ID) then promotions[info.ID]=true end end
        units[unit:GetID()]={type=unit:GetUnitType(),x=unit:GetX(),y=unit:GetY(),moves=unit:GetMoves(),
            damage=unit:GetDamage(),xp=unit:GetExperience(),level=unit:GetLevel(),embarked=unit:IsEmbarked(),promotions=promotions}
    end
    return {turn=Game.GetGameTurn(),gold=player:GetGold(),iron=player:GetNumResourceAvailable(GameInfoTypes.RESOURCE_IRON,true),units=units}
end
function LekmodScenario.step(player)
    if phase=="init" then
        LekmodScenarioGrantTech(player,"TECH_OPTICS")
        for i=0,Map.GetNumPlots()-1 do
            local plot=Map.GetPlotByIndex(i)
            if plot:GetOwner()==player:GetID() and not plot:IsCity() and not plot:IsWater() and not plot:IsMountain() and plot:GetNumUnits()==0 then home=plot;break end
        end
        assert(home,"no free friendly staging tile")
        local unit=assert(player:InitUnit(GameInfoTypes.UNIT_WARRIOR,home:GetX(),home:GetY()))
        id=unit:GetID()
        local before=unit:GetExperience();unit:SetExperience(unit:ExperienceNeeded())
        xpTurn=Game.GetGameTurn()
        LekmodScenarioEvent("fixture-setup",{operation="provided-unit-and-xp",id=id,type="UNIT_WARRIOR",before_xp=before,after_xp=unit:GetExperience()})
        local resource=GameInfoTypes.RESOURCE_IRON
        local available=player:GetNumResourceAvailable(resource,true)
        if available<2 then
            player:ChangeNumResourceTotal(resource,2-available)
            LekmodScenarioEvent("fixture-setup",{operation="provided-iron",added=2-available})
        end
        phase="promotion"
    elseif phase=="promotion" then
        local unit=assert(player:GetUnitByID(id))
        -- This build refreshes promotion readiness in the ordinary unit turn,
        -- not in SetExperience. Let that normal refresh occur; do not set it.
        if not unit:IsPromotionReady() and Game.GetGameTurn()==xpTurn then return "turn" end
        assert(unit:IsPromotionReady(),"provided XP did not trigger normal promotion eligibility")
        level,xp=unit:GetLevel(),unit:GetExperience()
        UI.SelectUnit(unit)
        for i=0,#GameInfoActions do
            local entry=GameInfoActions[i]
            if entry and entry.SubType==ActionSubTypes.ACTIONSUBTYPE_PROMOTION and Game.CanHandleAction(i) then
                local info=GameInfo.UnitPromotions[entry.Type]
                if info and not info.LostWithUpgrade and not unit:IsHasPromotion(info.ID) then
                    promotion=info.ID;Game.HandleAction(i);break
                end
            end
        end
        assert(promotion,"no transferable legal promotion")
        phase="promoted"
    elseif phase=="promoted" then
        local unit=assert(player:GetUnitByID(id))
        if not LekmodScenarioAwait("promotion",unit:IsHasPromotion(promotion) and unit:GetLevel()==level+1) then return false end
        assert(unit:GetExperience()==xp,"promotion changed stored XP unexpectedly")
        level=unit:GetLevel()
        LekmodScenarioRecord("unit-promotion","PASS","path=normal-action promotion="..promotion.." level="..level)
        target=unit:GetUpgradeUnitType();assert(target>=0,"fixture has no available upgrade type")
        cost=unit:UpgradePrice(target);gold=player:GetGold()
        assert(gold>=cost and unit:CanUpgradeRightNow(),"friendly upgrade is not legal")
        local neutral,mountain
        for i=0,Map.GetNumPlots()-1 do
            local plot=Map.GetPlotByIndex(i)
            if not neutral and plot:GetOwner()==-1 and not plot:IsWater() and not plot:IsMountain() and plot:GetNumUnits()==0 then neutral=plot end
            if not mountain and plot:IsMountain() then mountain=plot end
            if neutral and mountain then break end
        end
        assert(neutral and mountain,"fixture lacks neutral and mountain boundary tiles")
        assert(not unit:CanMoveOrAttackInto(mountain),"ordinary land unit can enter a mountain")
        stage(unit,neutral,"upgrade-territory-rejection")
        assert(not unit:CanUpgradeRightNow(),"upgrade allowed outside friendly territory")
        stage(unit,home,"restore-friendly-upgrade-input")
        assert(unit:CanUpgradeRightNow(),"restored friendly upgrade is not legal")
        LekmodScenarioRecord("unit-restrictions","PASS","mountain-entry=rejected neutral-territory-upgrade=rejected friendly-upgrade=allowed")
        action(unit,"COMMAND_UPGRADE");phase="upgraded"
    elseif phase=="upgraded" then
        if not LekmodScenarioAwait("upgrade-event",newID~=nil) then return false end
        local old=player:GetUnitByID(id)
        local unit=assert(player:GetUnitByID(newID))
        assert(unit:GetUnitType()==target and player:GetGold()==gold-cost,"upgrade type or gold charge differs")
        assert(unit:IsHasPromotion(promotion) and unit:GetExperience()==xp and unit:GetLevel()==level,"upgrade lost promotion/XP/level")
        assert(not old or old:IsDead() or old:IsDelayedDeath(),"old unit remains alive after upgrade")
        LekmodScenarioRecord("unit-upgrade","PASS","path=normal-action-and-UnitUpgraded old="..id.." new="..newID.." gold="..cost)
        id=newID;newID=nil
        assert(not unit:CanHeal(unit:GetPlot()),"healthy unit can heal")
        unit:SetDamage(50)
        LekmodScenarioEvent("fixture-setup",{operation="provided-unit-damage",id=id,damage=50})
        phase="heal-order"
    elseif phase=="heal-order" then
        local unit=assert(player:GetUnitByID(id))
        if unit:GetMoves()<=0 then return "turn" end
        assert(unit:CanHeal(unit:GetPlot()),"damaged unit cannot heal")
        healTurn=Game.GetGameTurn();action(unit,"MISSION_HEAL");phase="healing";return "turn"
    elseif phase=="healing" then
        local unit=assert(player:GetUnitByID(id))
        if Game.GetGameTurn()==healTurn then return "turn" end
        assert(unit:GetDamage()<50,"ordinary healing turn restored no HP")
        if unit:GetDamage()>0 then return "turn" end
        LekmodScenarioRecord("unit-healing","PASS","path=normal-heal-mission-and-turns damage=0 turns="..Game.GetGameTurn()-healTurn)
        UI.SelectUnit(unit)
        local wake=actionID("COMMAND_WAKE")
        if Game.CanHandleAction(wake) then Game.HandleAction(wake) end
        for i=0,Map.GetNumPlots()-1 do
            local plot=Map.GetPlotByIndex(i)
            if not plot:IsWater() and not plot:IsMountain() and plot:GetNumUnits()==0 and (plot:GetOwner()==-1 or plot:GetOwner()==player:GetID()) then
                for direction=0,5 do
                    local candidate=Map.PlotDirection(plot:GetX(),plot:GetY(),direction)
                    if candidate and candidate:GetTerrainType()==GameInfoTypes.TERRAIN_COAST and candidate:GetFeatureType()~=GameInfoTypes.FEATURE_ICE and candidate:GetNumUnits()==0 and (candidate:GetOwner()==-1 or candidate:GetOwner()==player:GetID()) then coast,water=plot,candidate;break end
                end
            end
            if coast then break end
        end
        assert(coast and water,"no safe coast staging pair")
        stage(unit,coast,"embark-input");phase="embark"
    elseif phase=="embark" then
        local unit=assert(player:GetUnitByID(id))
        if unit:GetMoves()<=0 then return "turn" end
        assert(unit:CanEmbarkOnto(unit:GetPlot(),water),"coast embark is not eligible")
        move(unit,water);phase="embarked"
    elseif phase=="embarked" then
        local unit=assert(player:GetUnitByID(id))
        if not LekmodScenarioAwait("embark-move",unit:IsEmbarked() and unit:GetX()==water:GetX() and unit:GetY()==water:GetY()) then return false end
        LekmodScenarioRecord("unit-embark","PASS","path=normal-move-to-coast")
        phase="disembark"
    elseif phase=="disembark" then
        local unit=assert(player:GetUnitByID(id))
        if unit:GetMoves()<=0 then return "turn" end
        assert(unit:CanDisembarkOnto(coast),"return to land is not eligible")
        move(unit,coast);phase="disembarked"
    elseif phase=="disembarked" then
        local unit=assert(player:GetUnitByID(id))
        if not LekmodScenarioAwait("disembark-move",not unit:IsEmbarked() and unit:GetX()==coast:GetX() and unit:GetY()==coast:GetY()) then return false end
        assert(unit:IsHasPromotion(promotion),"embark/disembark lost the selected promotion")
        LekmodScenarioRecord("unit-disembark","PASS","path=normal-move-to-land")
        return true
    end
    return false
end
