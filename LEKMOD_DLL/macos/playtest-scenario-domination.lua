-- Loaded Duel fixture. Units/resources/positions are labeled inputs; war,
-- attacks, damage, city transfer and victory must use ordinary game actions.
LekmodScenario={name="domination",items={"war-declaration","capital-combat","capital-capture","domination-victory","victory-panel"}}
local phase,owner,x,y,unitID,beforeDamage,issuedTurn,attacks="init",nil,nil,nil,nil,nil,nil,0
local captured=false
GameEvents.CityCaptureComplete.Add(function(old,capital,cx,cy,new,population,conquest)
    if old==owner and new==Game.GetActivePlayer() and cx==x and cy==y then
        assert(capital and conquest and attacks>0,"capital transfer did not follow the legal attack")
        captured=true
        LekmodScenarioRecord("capital-capture","PASS","path=engine-CityCaptureComplete old="..old.." new="..new)
        LuaEvents.LekmodDominationCapture(cx,cy,old,new,attacks)
    end
end)
function LekmodScenario.snapshot(player)
    return {turn=Game.GetGameTurn(),winner=Game.GetWinner(),victory=Game.GetVictory(),cities=player:GetNumCities()}
end
function LekmodScenario.step(player)
    if captured then return false end
    if phase=="init" then
        assert(Game.IsVictoryValid(GameInfoTypes.VICTORY_DOMINATION) and Game.GetWinner()==-1,"domination is unavailable")
        local majors=0
        for id=0,GameDefines.MAX_MAJOR_CIVS-1 do
            local other=Players[id]
            if other and other:IsAlive() then
                majors=majors+1
                if id~=player:GetID() then owner=id end
            end
        end
        assert(majors==2,"domination fixture requires exactly two living majors")
        local target=assert(Players[owner]:GetCapitalCity())
        assert(target:IsOriginalCapital(),"target is not the original capital")
        x,y=target:GetX(),target:GetY()
        local team=Teams[player:GetTeam()]
        assert(not team:IsAtWar(Players[owner]:GetTeam()),"fixture already at war")
        if not team:IsHasMet(Players[owner]:GetTeam()) then
            team:Meet(Players[owner]:GetTeam(),false)
            LekmodScenarioEvent("fixture-setup",{operation="established-contact",other=owner})
        end
        local resource=GameInfoTypes.RESOURCE_URANIUM
        if player:GetNumResourceAvailable(resource,true)<1 then
            player:ChangeNumResourceTotal(resource,1)
            LekmodScenarioEvent("fixture-setup",{operation="provided-uranium",added=1})
        end
        local home=player:GetCapitalCity()
        local unit=assert(player:InitUnit(GameInfoTypes.UNIT_MECH,home:GetX(),home:GetY()))
        unitID=unit:GetID()
        LekmodScenarioEvent("fixture-setup",{operation="provided-unit",type="UNIT_MECH",id=unitID})
        assert(not unit:CanMoveOrAttackInto(target:Plot()),"foreign capital unexpectedly enterable at peace")
        Network.SendChangeWar(Players[owner]:GetTeam(),true);phase="war"
    elseif phase=="war" then
        if not LekmodScenarioAwait("war-declared",Teams[player:GetTeam()]:IsAtWar(Players[owner]:GetTeam())) then return false end
        LekmodScenarioRecord("war-declaration","PASS","path=normal-network-command peace-entry=rejected")
        local unit=assert(player:GetUnitByID(unitID))
        local staging
        for direction=0,5 do
            local plot=Map.PlotDirection(x,y,direction)
            if plot and not plot:IsWater() and not plot:IsMountain() and plot:GetNumUnits()==0 then staging=plot;break end
        end
        assert(staging,"no open land staging plot")
        unit:SetXY(staging:GetX(),staging:GetY(),false,true,false,false)
        LekmodScenarioEvent("fixture-setup",{operation="position-attacker",unit=unitID,x=staging:GetX(),y=staging:GetY()})
        phase="attack"
    elseif phase=="attack" then
        local unit=assert(player:GetUnitByID(unitID),"attacker was destroyed")
        if unit:IsBusy() or Map.GetPlot(x,y):IsFighting() then return false end
        if not unit:IsCanAttackWithMoveNow() or unit:GetMoves()<=0 then return "turn" end
        local city=assert(Map.GetPlot(x,y):GetPlotCity())
        assert(city:GetOwner()==owner and unit:CanMoveOrAttackInto(city:Plot()),"capital attack is not legal")
        beforeDamage=city:GetDamage();issuedTurn=Game.GetGameTurn();attacks=attacks+1
        assert(attacks<=6,"attack fixture exceeded six attacks")
        LekmodScenarioEvent("capital-attack",{attack=attacks,before_damage=beforeDamage,unit_damage=unit:GetDamage(),turn=issuedTurn})
        UI.SelectUnit(unit)
        Game.SelectionListGameNetMessage(GameMessageTypes.GAMEMESSAGE_PUSH_MISSION,MissionTypes.MISSION_MOVE_TO,x,y,0,false,false)
        phase="attack-result"
    elseif phase=="attack-result" then
        local unit=assert(player:GetUnitByID(unitID),"attacker was destroyed")
        local plot=Map.GetPlot(x,y)
        if unit:IsBusy() or plot:IsFighting() then return false end
        local city=assert(plot:GetPlotCity())
        if not LekmodScenarioAwait("capital-damage-"..attacks,city:GetDamage()>beforeDamage or city:GetOwner()==player:GetID()) then return false end
        LekmodScenarioRecord("capital-combat","PASS","path=normal-move-attack attack="..attacks.." damage="..city:GetDamage())
        phase="attack"
    end
    return false
end
