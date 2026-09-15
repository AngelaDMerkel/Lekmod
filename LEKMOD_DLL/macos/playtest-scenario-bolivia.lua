-- Ordinary Bolivia setup; units supplied as labeled inputs. Ability changes
-- must come from the real UnitCreated/GreatPersonExpended engine events.
LekmodScenario={name="bolivia",items={"colorado-created","bolivia-artist","bolivia-writer"}}
local phase,unitID,before,createdID,expended,historyTurn="init"
GameEvents.UnitCreated.Add(function(owner,id)
    if owner==Game.GetActivePlayer() then createdID=id end
end)
GameEvents.GreatPersonExpended.Add(function(owner,kind)
    if owner==Game.GetActivePlayer() then expended=kind end
end)
local function action(unit,kind)
    UI.SelectUnit(unit)
    for id=0,#GameInfoActions do
        if GameInfoActions[id] and GameInfoActions[id].Type==kind then
            assert(Game.CanHandleAction(id),"great-person action unavailable: "..kind)
            Game.HandleAction(id);return
        end
    end
    error("great-person action missing: "..kind)
end
local function input(player,kind)
    local city=player:GetCapitalCity()
    local unit=assert(player:InitUnit(GameInfoTypes[kind],city:GetX(),city:GetY()))
    LekmodScenarioEvent("fixture-setup",{operation="provided-unit",type=kind,id=unit:GetID(),x=unit:GetX(),y=unit:GetY()})
    return unit:GetID()
end
function LekmodScenario.snapshot(player)
    local cities,units={},{}
    for city in player:Cities() do
        cities[city:GetID()]={production=city:GetNumRealBuilding(GameInfoTypes.BUILDING_BOLIVIA_TRAIT_PRODUCTION),
            food=city:GetNumRealBuilding(GameInfoTypes.BUILDING_BOLIVIA_TRAIT_FOOD)}
    end
    for unit in player:Units() do
        if unit:GetUnitType()==GameInfoTypes.UNIT_COLORADO then
            units[unit:GetID()]={strength=unit:GetBaseCombatStrength(),x=unit:GetX(),y=unit:GetY()}
        end
    end
    return {turn=Game.GetGameTurn(),civ=player:GetCivilizationType(),cities=cities,units=units,
        golden=player:GetGoldenAgeTurns(),culture=player:GetJONSCulture(),happiness=player:GetExcessHappiness()}
end
function LekmodScenario.step(player)
    assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_BOLIVIA,"choose Bolivia in normal setup")
    local city=player:GetCapitalCity()
    if not city then return "turn" end
    if phase=="init" then
        assert(player:GetExcessHappiness()>=3,"Colorado fixture requires a positive bonus")
        unitID=input(player,"UNIT_COLORADO");phase="colorado"
    elseif phase=="colorado" then
        local unit=assert(player:GetUnitByID(unitID))
        assert(createdID==unitID,"real UnitCreated event missing")
        local expected=GameInfo.Units.UNIT_COLORADO.Combat+2*math.floor(player:GetExcessHappiness()/5+0.5)
        assert(unit:GetBaseCombatStrength()==expected,"Colorado creation bonus differs from current happiness")
        LekmodScenarioRecord("colorado-created","PASS","path=engine-UnitCreated instance="..unitID.." strength="..expected)
        historyTurn=Game.GetGameTurn();phase="history";return "turn"
    elseif phase=="history" then
        if Game.GetGameTurn()==historyTurn then return "turn" end
        unitID=input(player,"UNIT_ARTIST");phase="artist"
    elseif phase=="artist" then
        before=player:GetGoldenAgeTurns();expended=nil
        action(assert(player:GetUnitByID(unitID)),"MISSION_GOLDEN_AGE");phase="artist-result"
    elseif phase=="artist-result" then
        if not LekmodScenarioAwait("artist-benefit",expended==GameInfoTypes.UNIT_ARTIST and city:GetNumRealBuilding(GameInfoTypes.BUILDING_BOLIVIA_TRAIT_PRODUCTION)==1) then return false end
        assert(city:GetNumRealBuilding(GameInfoTypes.BUILDING_BOLIVIA_TRAIT_FOOD)==0 and player:GetGoldenAgeTurns()>before,"artist outcome mismatch")
        LekmodScenarioRecord("bolivia-artist","PASS","path=normal-golden-age-action and engine-GreatPersonExpended")
        unitID=input(player,"UNIT_WRITER");phase="writer"
    elseif phase=="writer" then
        before=player:GetJONSCulture();expended=nil
        local unit=assert(player:GetUnitByID(unitID))
        assert(unit:GetGivePoliciesCulture()>0,"writer has no earned culture history")
        action(unit,"MISSION_GIVE_POLICIES");phase="writer-result"
    elseif phase=="writer-result" then
        if not LekmodScenarioAwait("writer-benefit",expended==GameInfoTypes.UNIT_WRITER and city:GetNumRealBuilding(GameInfoTypes.BUILDING_BOLIVIA_TRAIT_FOOD)==1) then return false end
        assert(city:GetNumRealBuilding(GameInfoTypes.BUILDING_BOLIVIA_TRAIT_PRODUCTION)==0 and player:GetJONSCulture()>before,"writer outcome mismatch")
        LekmodScenarioRecord("bolivia-writer","PASS","path=normal-political-treatise-action and engine-GreatPersonExpended")
        return true
    end
    return false
end
