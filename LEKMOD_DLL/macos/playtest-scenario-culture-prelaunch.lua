include("LekmodTestCulture.lua")
LekmodScenario={name="culture-prelaunch",items={"great-work","passive-tourism","concert-tourism","concert-location-rejection","culture-prelaunch"}}
LekmodScenario.snapshot=LekmodCultureSnapshot
local phase,target,unitID,before,strength,startTurn,works,tours="init",nil,nil,nil,nil,nil,nil,0
local panelWait,panelClosed=0,false
LuaEvents.LekmodCultureGreatWorkClosed.Add(function() panelClosed=true end)
local function provide(player,kind)
    local city=player:GetCapitalCity()
    local unit=assert(player:InitUnit(GameInfoTypes[kind],city:GetX(),city:GetY()))
    LekmodScenarioEvent("fixture-setup",{operation="provided-unit",type=kind,id=unit:GetID()})
    return unit
end
function LekmodScenario.step(player)
    if phase=="init" then
        assert(Game.IsVictoryValid(GameInfoTypes.VICTORY_CULTURAL) and Game.GetWinner()==-1,"cultural victory unavailable")
        local count=0
        for id=0,GameDefines.MAX_MAJOR_CIVS-1 do
            local other=Players[id]
            if other and other:IsAlive() and id~=player:GetID() then count=count+1;target=id end
        end
        assert(count==1 and player:GetNumCivsInfluentialOn()==0,"fixture requires one uninfluenced major")
        assert(Teams[player:GetTeam()]:IsHasMet(Players[target]:GetTeam()),"fixture target not met")
        works=player:GetNumGreatWorks()
        unitID=provide(player,"UNIT_WRITER"):GetID();phase="work"
    elseif phase=="work" then
        LekmodCultureAction(assert(player:GetUnitByID(unitID)),"MISSION_CREATE_GREAT_WORK");phase="work-result"
    elseif phase=="work-result" then
        if not LekmodScenarioAwait("great-work-created",player:GetNumGreatWorks()==works+1) then return false end
        assert(player:GetTourism()>0,"created great work yields no tourism")
        LekmodScenarioRecord("great-work","PASS","path=normal-create-great-work-action total="..player:GetNumGreatWorks())
        phase="work-panel"
    elseif phase=="work-panel" then
        panelWait=panelWait+1
        if panelWait<8 then return false end
        if not panelClosed then LuaEvents.LekmodCultureCloseGreatWork();return false end
        before=player:GetInfluenceOn(target);startTurn=Game.GetGameTurn();phase="tourism-turn";return "turn"
    elseif phase=="tourism-turn" then
        if Game.GetGameTurn()==startTurn then return "turn" end
        assert(player:GetInfluenceOn(target)>before,"normal tourism turn did not add influence")
        LekmodScenarioRecord("passive-tourism","PASS","path=ordinary-turn before="..before.." after="..player:GetInfluenceOn(target))
        phase="provide"
    elseif phase=="provide" then
        local unit=provide(player,"UNIT_MUSICIAN");unitID=unit:GetID()
        UI.SelectUnit(unit)
        assert(not Game.CanHandleAction(LekmodCultureActionID("MISSION_ONE_SHOT_TOURISM")),"concert allowed on own territory")
        local city=assert(Players[target]:GetCapitalCity())
        local staging
        for direction=0,5 do
            local plot=Map.PlotDirection(city:GetX(),city:GetY(),direction)
            if plot and plot:GetOwner()==target and not plot:IsWater() and not plot:IsMountain() and plot:GetNumUnits()==0 then staging=plot;break end
        end
        assert(staging,"no free target-owned concert plot")
        unit:SetXY(staging:GetX(),staging:GetY(),false,true,false,false)
        LekmodScenarioEvent("fixture-setup",{operation="position-musician",id=unitID,x=staging:GetX(),y=staging:GetY(),target=target})
        phase="concert"
    elseif phase=="concert" then
        local unit=assert(player:GetUnitByID(unitID))
        before=player:GetInfluenceOn(target);strength=unit:GetBlastTourism()
        assert(strength>0,"musician has no tourism strength")
        local threshold=Players[target]:GetJONSCultureEverGenerated()
        if before+strength>=threshold then
            assert(tours>0 and before<threshold and Game.GetWinner()==-1,"fixture must remain below victory after real concert progress")
            LekmodScenarioRecord("concert-tourism","PASS","path=normal-concert-actions tours="..tours)
            LekmodScenarioRecord("concert-location-rejection","PASS","path=normal-action-eligibility own-territory=rejected")
            LekmodScenarioRecord("culture-prelaunch","PASS","influence="..before.." threshold="..threshold.." next-blast="..strength)
            return true
        end
        assert(tours<40,"fixture needs more than forty concerts")
        tours=tours+1
        LekmodCultureAction(unit,"MISSION_ONE_SHOT_TOURISM");phase="concert-result"
    elseif phase=="concert-result" then
        if not LekmodScenarioAwait("concert-"..tours,player:GetInfluenceOn(target)==before+strength) then return false end
        local unit=player:GetUnitByID(unitID)
        assert(not unit or unit:IsDead() or unit:IsDelayedDeath(),"concert musician remains alive")
        LekmodScenarioEvent("concert-outcome",{tour=tours,before=before,after=player:GetInfluenceOn(target),strength=strength})
        phase="provide"
    end
    return false
end
