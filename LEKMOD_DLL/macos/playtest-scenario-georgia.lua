-- Ordinary Georgia setup; supplied units use real creation/expended events.
-- Golden-age start uses an Artist action and expiration uses ordinary turns.
LekmodScenario={name="georgia",items={"georgia-before-golden-age","georgia-existing-golden-age","georgia-new-golden-age","georgia-golden-age-expired"}}
local phase,existing,new,control,artist,before,started,duration="init"
local promotion=GameInfoTypes.PROMOTION_GEORGIA_KHEVSUR_GA
local function input(player,kind)
    local city=player:GetCapitalCity();local plot=city:Plot()
    if kind~="UNIT_ARTIST" then
        plot=nil
        for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i)
            local distance=Map.PlotDistance(city:GetX(),city:GetY(),p:GetX(),p:GetY())
            if distance>=2 and distance<=3 and not p:IsWater() and not p:IsMountain() and p:GetNumUnits()==0
                and (p:GetOwner()==-1 or p:GetOwner()==player:GetID()) then plot=p;break end
        end
        assert(plot,"no empty local military staging plot")
    end
    local u=assert(player:InitUnit(GameInfoTypes[kind],plot:GetX(),plot:GetY()))
    LekmodScenarioEvent("fixture-setup",{operation="provided-unit",type=kind,id=u:GetID(),x=u:GetX(),y=u:GetY()})
    return u:GetID()
end
function LekmodScenario.snapshot(player)
    local units={}
    for u in player:Units() do if u:GetUnitType()==GameInfoTypes.UNIT_GEORGIA_KHEVSUR then
        units[u:GetID()]={golden=u:IsHasPromotion(promotion),combat=u:GetExtraCombatPercent()}
    end end
    return {turn=Game.GetGameTurn(),civ=player:GetCivilizationType(),golden_turns=player:GetGoldenAgeTurns(),units=units}
end
function LekmodScenario.step(player)
    assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_GEORGIA,"choose Georgia in normal setup")
    if not player:GetCapitalCity() then return "turn" end
    if phase=="init" then
        assert(not player:IsGoldenAge(),"initial fixture is already in a golden age")
        local city=player:GetCapitalCity();local wealth=GameInfoTypes.PROCESS_WEALTH
        if wealth and city:CanMaintain(wealth) then Game.CityPushOrder(city,OrderTypes.ORDER_MAINTAIN,wealth,false,true,true) end
        existing=input(player,"UNIT_GEORGIA_KHEVSUR");control=input(player,"UNIT_WARRIOR")
        local u=player:GetUnitByID(existing);before=u:GetExtraCombatPercent()
        assert(not u:IsHasPromotion(promotion) and not player:GetUnitByID(control):IsHasPromotion(promotion),"pre-golden-age promotion unexpectedly set")
        LekmodScenarioRecord("georgia-before-golden-age","PASS","native-created-unit promotion=false")
        artist=input(player,"UNIT_ARTIST");phase="artist"
    elseif phase=="artist" then
        UI.SelectUnit(assert(player:GetUnitByID(artist)))
        local found=false
        for i=0,#GameInfoActions do if GameInfoActions[i] and GameInfoActions[i].Type=="MISSION_GOLDEN_AGE" then
            assert(Game.CanHandleAction(i),"artist golden-age action unavailable");Game.HandleAction(i);found=true;break
        end end
        assert(found,"artist action missing");phase="golden"
    elseif phase=="golden" then
        if not LekmodScenarioAwait("georgia-golden-age",player:IsGoldenAge()) then return false end
        local u=assert(player:GetUnitByID(existing))
        assert(u:IsHasPromotion(promotion) and u:GetExtraCombatPercent()==before+33,"existing Khevsur did not receive golden-age strength")
        assert(not player:GetUnitByID(control):IsHasPromotion(promotion),"ordinary Warrior received Khevsur benefit")
        LekmodScenarioRecord("georgia-existing-golden-age","PASS","path=normal-artist-and-real-expended-event combat-added=33")
        new=input(player,"UNIT_GEORGIA_KHEVSUR");phase="new"
    elseif phase=="new" then
        local u=assert(player:GetUnitByID(new))
        LekmodScenarioEvent("georgia-new-unit",{golden=player:IsGoldenAge(),golden_turns=player:GetGoldenAgeTurns(),promotion=u:IsHasPromotion(promotion),combat=u:GetExtraCombatPercent()})
        assert(u:IsHasPromotion(promotion) and u:GetExtraCombatPercent()==before+33,"Khevsur created during golden age lacks its immediate combat bonus")
        LekmodScenarioRecord("georgia-new-golden-age","PASS","path=real-UnitCreated combat-added=33")
        started=Game.GetGameTurn();duration=player:GetGoldenAgeTurns();phase="expire";return "turn"
    elseif phase=="expire" then
        if player:IsGoldenAge() then
            assert(Game.GetGameTurn()-started<=duration+2,"golden age did not naturally expire within its duration")
            return "turn"
        end
        for _,id in ipairs({existing,new}) do local u=assert(player:GetUnitByID(id))
            assert(not u:IsHasPromotion(promotion) and u:GetExtraCombatPercent()==before,"expired golden-age combat bonus remains")
        end
        assert(not player:GetUnitByID(control):IsHasPromotion(promotion),"control Warrior gained the benefit")
        LekmodScenarioRecord("georgia-golden-age-expired","PASS","path=ordinary-turns turns="..Game.GetGameTurn()-started)
        return true
    end
    return false
end
