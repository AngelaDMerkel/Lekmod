-- Supplied Gerilya/control units and coast positions; embarkation and movement
-- refresh are normal actions. No embark flag or movement budget is assigned.
LekmodScenario={name="philippines-gerilya",items={"gerilya-strength-control","gerilya-normal-embark","gerilya-embarked-refresh"}}
local phase,probes,turn="init",{},nil
local function state(unit)
    return {id=unit:GetID(),type=unit:GetUnitType(),x=unit:GetX(),y=unit:GetY(),moves=unit:GetMoves(),maximum=unit:MaxMoves(),embarked=unit:IsEmbarked(),combat=unit:GetBaseCombatStrength(),marine_promotion=unit:IsHasPromotion(GameInfoTypes.PROMOTION_PHIL_MARINE)}
end
function LekmodScenario.snapshot(player)
    local units={}
    for u in player:Units() do if u:GetUnitType()==GameInfoTypes.UNIT_PHILIPINO_MARINE or u:GetUnitType()==GameInfoTypes.UNIT_EXPEDITIONARY_FORCE then units[u:GetID()]=state(u) end end
    return {turn=Game.GetGameTurn(),units=units}
end
local function move(unit,plot)
    assert(unit:CanEmbarkOnto(unit:GetPlot(),plot),"normal embarkation is unavailable")
    UI.SelectUnit(unit)
    Game.SelectionListGameNetMessage(GameMessageTypes.GAMEMESSAGE_PUSH_MISSION,MissionTypes.MISSION_MOVE_TO,plot:GetX(),plot:GetY(),0,false,false)
end
function LekmodScenario.step(player)
    assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_PHILIPPINES,"requires Philippines")
    if phase=="init" then
        assert(Teams[player:GetTeam()]:GetTeamTechs():HasTech(GameInfoTypes.TECH_OPTICS),"load a fixture with normal embarkation technology")
        player:ChangeGold(1000)
        LekmodScenarioEvent("fixture-setup",{operation="provided-upkeep-budget",gold_added=1000})
        local used={}
        for _,kind in ipairs({"UNIT_PHILIPINO_MARINE","UNIT_EXPEDITIONARY_FORCE"}) do
            local land,water
            for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i)
                if not used[i] and p:GetOwner()==-1 and not p:IsCity() and not p:IsWater() and not p:IsMountain() and not p:IsGoody(-1) and p:GetNumUnits()==0 then
                    for dir=0,5 do local q=Map.PlotDirection(p:GetX(),p:GetY(),dir)
                        if q and q:GetOwner()==-1 and q:GetTerrainType()==GameInfoTypes.TERRAIN_COAST and q:GetFeatureType()~=GameInfoTypes.FEATURE_ICE and q:GetNumUnits()==0 then
                            local key=q:GetX()..":"..q:GetY()
                            if not used[key] then land,water=p,q;used[i]=true;used[key]=true;break end
                        end
                    end
                end
                if land then break end
            end
            assert(land and water,"no distinct neutral coastal staging pair")
            local info=GameInfo.Units[kind];local u=assert(player:InitUnit(info.ID,land:GetX(),land:GetY()))
            assert(u:GetBaseCombatStrength()==info.Combat and not u:IsEmbarked())
            probes[#probes+1]={id=u:GetID(),water=water,land=land}
            LekmodScenarioEvent("fixture-setup",{operation="provided-coastal-unit",type=kind,state=state(u),destination_x=water:GetX(),destination_y=water:GetY()})
        end
        local unique=player:GetUnitByID(probes[1].id);local base=player:GetUnitByID(probes[2].id)
        assert(unique:GetBaseCombatStrength()>base:GetBaseCombatStrength(),"Gerilya is not stronger than its replacement control")
        assert(unique:IsHasPromotion(GameInfoTypes.PROMOTION_PHIL_MARINE) and not base:IsHasPromotion(GameInfoTypes.PROMOTION_PHIL_MARINE))
        assert(unique:MaxMoves()==base:MaxMoves(),"embarked-only bonus affected land movement")
        LekmodScenarioRecord("gerilya-strength-control","PASS","native-created-unit strengths-match-data unique-stronger=true land-movement-equal=true")
        move(unique,probes[1].water);phase="first"
    elseif phase=="first" then
        local u=player:GetUnitByID(probes[1].id);local p=probes[1].water
        if not LekmodScenarioAwait("Gerilya-embark",u:IsEmbarked() and u:GetX()==p:GetX() and u:GetY()==p:GetY()) then return false end
        move(player:GetUnitByID(probes[2].id),probes[2].water);phase="both"
    elseif phase=="both" then
        local u=player:GetUnitByID(probes[2].id);local p=probes[2].water
        if not LekmodScenarioAwait("control-embark",u:IsEmbarked() and u:GetX()==p:GetX() and u:GetY()==p:GetY()) then return false end
        local a=player:GetUnitByID(probes[1].id)
        assert(a:MaxMoves()==u:MaxMoves()+3*GameDefines.MOVE_DENOMINATOR,"embarked Gerilya lacks exactly three extra moves")
        LekmodScenarioEvent("gerilya-embarked",{unique=state(a),control=state(u)})
        LekmodScenarioRecord("gerilya-normal-embark","PASS","path=two-normal-land-to-coast-moves extra-moves=3")
        turn=Game.GetGameTurn();phase="refreshed";return "turn"
    elseif phase=="refreshed" then
        if Game.GetGameTurn()==turn then return "turn" end
        assert(Game.GetGameTurn()==turn+1,"embarked refresh exceeded one ordinary turn")
        local a=player:GetUnitByID(probes[1].id);local b=player:GetUnitByID(probes[2].id)
        assert(a and b and a:IsEmbarked() and b:IsEmbarked() and a:GetMoves()==a:MaxMoves() and b:GetMoves()==b:MaxMoves())
        assert(a:GetMoves()==b:GetMoves()+3*GameDefines.MOVE_DENOMINATOR,"normal refresh did not retain three-move difference")
        LekmodScenarioEvent("gerilya-refreshed",{unique=state(a),control=state(b)})
        LekmodScenarioRecord("gerilya-embarked-refresh","PASS","path=ordinary-turn exact-three-move-budget-difference=true")
        return true
    end
    return false
end
