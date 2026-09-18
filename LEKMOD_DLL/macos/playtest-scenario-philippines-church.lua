-- Current shipped Help: Compass, no prerequisite building, +1 culture/+2 faith,
-- +15 production XP. Research and near-complete production are supplied inputs.
LekmodScenario={name="philippines-church",items={"church-prerequisites","church-construction-yields","church-production-XP"}}
local phase,baseCulture,baseFaith,baseXP,unitType,turn,trained,quotedXP="init"
local church=GameInfoTypes.BUILDING_NATIONALCHURCH
local built=false
GameEvents.CityConstructed.Add(function(owner,city,building,gold,faith)
    if owner==Game.GetActivePlayer() and building==church then assert(not gold and not faith);built=true end
end)
GameEvents.CityTrained.Add(function(owner,city,id,gold,faith)
    local unit=Players[owner]:GetUnitByID(id)
    if owner==Game.GetActivePlayer() and unit and unit:GetUnitType()==unitType then
        assert(not gold and not faith);trained=id
        LekmodScenarioEvent("church-native-unit-trained",{unit=id,type=unitType,experience=unit:GetExperience()})
    end
end)
function LekmodScenario.snapshot(player)
    local city=assert(player:GetCapitalCity());local units={}
    for u in player:Units() do if not u:IsDelayedDeath() then units[u:GetID()]={type=u:GetUnitType(),experience=u:GetExperience(),x=u:GetX(),y=u:GetY()} end end
    return {turn=Game.GetGameTurn(),church=city:GetNumRealBuilding(church),temple=city:GetNumRealBuilding(GameInfoTypes.BUILDING_TEMPLE),colosseum=city:GetNumRealBuilding(GameInfoTypes.BUILDING_COLOSSEUM),culture=city:GetBaseYieldRate(YieldTypes.YIELD_CULTURE),faith=city:GetBaseYieldRate(YieldTypes.YIELD_FAITH),units=units}
end
function LekmodScenario.step(player)
    local city=assert(player:GetCapitalCity());local techs=Teams[player:GetTeam()]:GetTeamTechs()
    assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_PHILIPPINES,"requires Philippines")
    if phase=="init" then
        assert(city:GetNumRealBuilding(church)==0 and not techs:HasTech(GameInfoTypes.TECH_COMPASS),"requires pre-Compass city without Church")
        assert(not city:CanConstruct(church),"Church available before Compass")
        assert(city:GetNumRealBuilding(GameInfoTypes.BUILDING_TEMPLE)==0 and city:GetNumRealBuilding(GameInfoTypes.BUILDING_COLOSSEUM)==0,"prerequisite-building control is not empty")
        LekmodScenarioGrantTech(player,"TECH_COMPASS");phase="order"
    elseif phase=="order" then
        assert(city:CanConstruct(church) and not techs:HasTech(GameInfoTypes.TECH_PRINTING_PRESS),"Church unavailable at Compass or fixture reached Printing Press")
        assert(not city:CanConstruct(GameInfoTypes.BUILDING_THEATRE),"Philippines may build the replaced Zoo")
        assert(city:GetBuildingProductionNeeded(church)<city:GetBuildingProductionNeeded(GameInfoTypes.BUILDING_THEATRE),"Church is not cheaper than Zoo")
        for info in GameInfo.Units() do
            local class=GameInfo.UnitClasses[info.Class]
            if info.Combat>0 and info.Domain=="DOMAIN_LAND" and class.MaxPlayerInstances<0 and class.MaxGlobalInstances<0 and class.MaxTeamInstances<0 and city:CanTrain(info.ID) then unitType=info.ID;break end
        end
        assert(unitType,"no ordinary combat unit for XP check")
        baseCulture=city:GetBaseYieldRate(YieldTypes.YIELD_CULTURE);baseFaith=city:GetBaseYieldRate(YieldTypes.YIELD_FAITH);baseXP=city:GetProductionExperience(unitType)
        LekmodScenarioRecord("church-prerequisites","PASS","Compass=true PrintingPress=false Temple=0 Colosseum=0 base-Zoo-rejected=true cheaper-than-Zoo=true")
        Game.CityPushOrder(city,OrderTypes.ORDER_CONSTRUCT,church,false,true,true);phase="queued"
    elseif phase=="queued" then
        if not LekmodScenarioAwait("church-order",city:GetProductionBuilding()==church) then return false end
        local cost=city:GetBuildingProductionNeeded(church);city:SetBuildingProduction(church,cost-1)
        LekmodScenarioEvent("fixture-setup",{operation="provided-near-complete-Church",production=cost-1,needed=cost})
        turn=Game.GetGameTurn();phase="built";return "turn"
    elseif phase=="built" then
        if Game.GetGameTurn()==turn then return "turn" end
        assert(Game.GetGameTurn()==turn+1 and built and city:GetNumRealBuilding(church)==1,"ordinary production did not construct Church")
        local culture=city:GetBaseYieldRate(YieldTypes.YIELD_CULTURE);local faith=city:GetBaseYieldRate(YieldTypes.YIELD_FAITH)
        quotedXP=city:GetProductionExperience(unitType)
        LekmodScenarioEvent("church-yield-XP-change",{culture_before=baseCulture,culture=culture,faith_before=baseFaith,faith=faith,xp_before=baseXP,xp=quotedXP,unit=unitType})
        assert(culture==baseCulture+1 and faith==baseFaith+2 and quotedXP==baseXP+15,"Church yields/production XP differ from current Help")
        LekmodScenarioRecord("church-construction-yields","PASS","normal-CityConstructed culture=+1 faith=+2 production-XP=+15")
        Game.CityPushOrder(city,OrderTypes.ORDER_TRAIN,unitType,false,true,true);phase="unit-queued"
    elseif phase=="unit-queued" then
        if not LekmodScenarioAwait("church-unit-order",city:GetProductionUnit()==unitType) then return false end
        local cost=city:GetUnitProductionNeeded(unitType);city:SetUnitProduction(unitType,cost-1)
        LekmodScenarioEvent("fixture-setup",{operation="provided-near-complete-unit-production",unit=unitType,production=cost-1,needed=cost})
        turn=Game.GetGameTurn();phase="unit-trained";return "turn"
    elseif phase=="unit-trained" then
        if Game.GetGameTurn()==turn then return "turn" end
        local unit=trained and player:GetUnitByID(trained)
        assert(Game.GetGameTurn()==turn+1 and unit and unit:GetExperience()==quotedXP,"normally trained unit lacks quoted Church experience")
        LekmodScenarioRecord("church-production-XP","PASS","path=normal-unit-production experience="..unit:GetExperience())
        return true
    end
    return false
end
