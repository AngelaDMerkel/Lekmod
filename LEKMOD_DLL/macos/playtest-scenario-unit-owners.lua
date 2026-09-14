-- Native regression of the actual installed PlayerDoTurn handlers. Input units
-- and deliberately conflicting promotions are labeled setup; no handler/event
-- is invoked manually and no turn or synchronization flag is altered.
LekmodScenario={name="unit-owners",items={"minor-defender","minor-hover","barbarian-hover"}}
local initialized=false
local tracked,observed={},{}
local hover=GameInfoTypes.PROMOTION_MOVE_ALL_TERRAIN
local embark=GameInfoTypes.PROMOTION_EMBARKATION
local defender=GameInfoTypes.PROMOTION_JFD_DEFENDER
local active=GameInfoTypes.PROMOTION_JFD_DEFENDER_ACTIVE
GameEvents.PlayerDoTurn.Add(function(owner)
    if not tracked[owner] then return end
    for id,kind in pairs(tracked[owner]) do
        local unit=Players[owner]:GetUnitByID(id)
        if unit then
            observed[kind]={owner=owner,unit=id,hover=unit:IsHasPromotion(hover),embark=unit:IsHasPromotion(embark),
                defender=unit:IsHasPromotion(defender),active=unit:IsHasPromotion(active),in_radius=unit:GetPlot():IsPlayerCityRadius(owner)}
            LekmodScenarioEvent("native-owner-handler",observed[kind])
        end
    end
end)
local function input(owner,plot,kind,unitType)
    local unit=assert(Players[owner]:InitUnit(unitType,plot:GetX(),plot:GetY()), "input unit creation failed")
    if kind~="minor-defender" then
        unit:SetHasPromotion(hover,true)
        unit:SetHasPromotion(embark,true)
    else
        unit:SetHasPromotion(defender,true)
        unit:SetHasPromotion(active,false)
    end
    tracked[owner]=tracked[owner] or {};tracked[owner][unit:GetID()]=kind
    LekmodScenarioEvent("fixture-setup",{operation="provided-owner-test-unit",kind=kind,owner=owner,unit=unit:GetID(),x=unit:GetX(),y=unit:GetY()})
end
function LekmodScenario.snapshot(player)
    local units={}
    for owner=0,GameDefines.MAX_CIV_PLAYERS do
        local p=Players[owner]
        if p and p:IsAlive() then
            for unit in p:Units() do
                if unit:IsHasPromotion(hover) or unit:IsHasPromotion(defender) or unit:IsHasPromotion(active) then
                    units[owner..":"..unit:GetID()]={type=unit:GetUnitType(),hover=unit:IsHasPromotion(hover),embark=unit:IsHasPromotion(embark),
                        defender=unit:IsHasPromotion(defender),active=unit:IsHasPromotion(active)}
                end
            end
        end
    end
    return {turn=Game.GetGameTurn(),units=units}
end
function LekmodScenario.step(player)
    if not initialized then
        local minor,water,land,barbarian,barbarianPlot
        for owner=0,GameDefines.MAX_CIV_PLAYERS do
            local p=Players[owner]
            if p and p:IsAlive() and p:IsMinorCiv() and not minor then
                for city in p:Cities() do
                    for direction=0,5 do
                        local plot=Map.PlotDirection(city:GetX(),city:GetY(),direction)
                        if plot and plot:IsWater() and plot:GetNumUnits()==0 then minor,water,land=owner,plot,city:Plot();break end
                    end
                    if minor then break end
                end
            elseif p and p:IsBarbarian() then
                barbarian=owner
                for unit in p:Units() do
                    if not unit:GetPlot():IsWater() then barbarianPlot=unit:GetPlot();break end
                end
            end
        end
        assert(minor and water and barbarian and barbarianPlot, "fixture lacks coastal minor or barbarian input locations")
        input(minor,water,"minor-defender",GameInfoTypes.UNIT_JFD_DEFENDER)
        -- Use a unit that actually owns the all-terrain ability. A scout with
        -- an injected ability can legitimately receive its scout-class embark
        -- promotion again when moving in friendly territory after this event.
        input(minor,land,"minor-hover",GameInfoTypes.UNIT_HELICOPTER_GUNSHIP)
        input(barbarian,barbarianPlot,"barbarian-hover",GameInfoTypes.UNIT_HELICOPTER_GUNSHIP)
        initialized=true
        return "turn"
    end
    if not (observed["minor-defender"] and observed["minor-hover"] and observed["barbarian-hover"]) then return "turn" end
    -- This UI context registers before the gameplay Lua contexts. The event
    -- observer records the input at PlayerDoTurn; read the result only after
    -- every owner has completed its ordinary turn and control returns here.
    local function result(kind)
        local before=observed[kind]
        local unit=assert(Players[before.owner]:GetUnitByID(before.unit), "fixture unit did not survive: "..kind)
        local after={owner=before.owner,unit=before.unit,hover=unit:IsHasPromotion(hover),embark=unit:IsHasPromotion(embark),
            defender=unit:IsHasPromotion(defender),active=unit:IsHasPromotion(active),input_in_radius=before.in_radius}
        LekmodScenarioEvent("native-owner-handler-result",after)
        return after
    end
    local d=result("minor-defender")
    assert(d.input_in_radius and d.active and not d.defender, "native minor Defender own-city ability failed")
    LekmodScenarioRecord("minor-defender","PASS","path=actual-player-turn-handler owner="..d.owner)
    for _,kind in ipairs({"minor-hover","barbarian-hover"}) do
        local row=result(kind)
        assert(row.hover and not row.embark, "native hover embark correction failed: "..kind)
        LekmodScenarioRecord(kind,"PASS","path=actual-player-turn-handler owner="..row.owner)
    end
    return true
end
