-- Opposing AI ideology, prerequisite technology and a positioned musician are
-- explicit fixture inputs. Influence, public opinion and turns are not assigned.
LekmodScenario={name="ideology-pressure",items={"foreign-concert-pressure","pressure-below-victory"}}
local phase,owner,started,pending,commandError,concert="init"
local function state(player)
    local result={}
    for id=0,GameDefines.MAX_MAJOR_CIVS-1 do local p=Players[id]
        if p and p:IsAlive() then
            local influence={}
            for other=0,GameDefines.MAX_MAJOR_CIVS-1 do if Players[other] and Players[other]:IsAlive() and other~=id then influence[other]={amount=p:GetInfluenceOn(other),level=p:GetInfluenceLevel(other)} end end
            result[id]={ideology=p:GetLateGamePolicyTree(),culture=p:GetJONSCultureEverGenerated(),current_culture=p:GetJONSCulture(),tourism=p:GetTourism(),influence=influence,unhappiness=p:GetPublicOpinionUnhappiness(),preferred=p:GetPublicOpinionPreferredIdeology(),free_tenets=p:GetNumFreeTenets(),population=p:GetTotalPopulation()}
        end
    end
    return {turn=Game.GetGameTurn(),winner=Game.GetWinner(),players=result}
end
LekmodScenario.snapshot=state
GameEvents.PlayerDoTurn.Add(function(id)
    if id~=owner or not pending then return end
    pending=false
    local ok,err=pcall(function()
        local foreign=Players[id];local human=Players[Game.GetActivePlayer()]
        assert(foreign:IsTurnActive(),"concert owner is not active")
        local city=assert(human:GetCapitalCity());local plot
        for d=0,5 do local p=Map.PlotDirection(city:GetX(),city:GetY(),d)
            if p and p:GetOwner()==human:GetID() and not p:IsWater() and not p:IsMountain() then plot=p;break end
        end
        assert(plot,"no human-owned land concert plot")
        local capital=assert(foreign:GetCapitalCity())
        local tours=0
        repeat
        tours=tours+1;assert(tours<=10,"pressure fixture exceeds ten concerts")
        local u=assert(foreign:InitUnit(GameInfoTypes.UNIT_MUSICIAN,capital:GetX(),capital:GetY()))
        u:SetXY(plot:GetX(),plot:GetY(),false,true,false,false)
        local before=foreign:GetInfluenceOn(human:GetID());local strength=u:GetBlastTourism()
        assert(before+strength<human:GetJONSCultureEverGenerated(),"concert would reach cultural victory threshold")
        assert(u:CanStartMission(GameInfoTypes.MISSION_ONE_SHOT_TOURISM,-1,-1,u:GetPlot(),0),"normal concert mission unavailable")
        LekmodScenarioEvent("fixture-setup",{operation="provided-positioned-foreign-musician",owner=id,unit=u:GetID(),x=u:GetX(),y=u:GetY(),strength=strength})
        u:PushMission(GameInfoTypes.MISSION_ONE_SHOT_TOURISM,-1,-1,0,0,1)
        assert(foreign:GetInfluenceOn(human:GetID())==before+strength,"concert influence increment differs")
        assert(u:IsDead() or u:IsDelayedDeath(),"concert musician not consumed")
        concert={before=before,after=foreign:GetInfluenceOn(human:GetID()),strength=strength,owner=id,turn=Game.GetGameTurn()}
        LekmodScenarioEvent("concert-outcome",concert)
        until foreign:GetInfluenceOn(human:GetID())>=human:GetJONSCultureEverGenerated()*0.7
    end)
    if not ok then commandError=tostring(err) end
end)
function LekmodScenario.step(player)
    assert(not commandError,commandError)
    assert(Game.GetWinner()==-1,"unexpected victory")
    if phase=="init" then
        assert(player:GetLateGamePolicyTree()~=-1 and player:GetPublicOpinionUnhappiness()==0,"requires content human ideology")
        for id=0,GameDefines.MAX_MAJOR_CIVS-1 do local p=Players[id]
            if p and p:IsAlive() and id~=player:GetID() then assert(not owner,"requires duel fixture");owner=id end
        end
        assert(owner and Players[owner]:GetLateGamePolicyTree()==-1,"AI already has ideology")
        local city=assert(player:GetCapitalCity());local population=city:GetPopulation();city:SetPopulation(25,true)
        LekmodScenarioEvent("fixture-setup",{operation="provided-city-population-for-nonzero-rounded-pressure",before=population,after=25})
        LekmodScenarioGrantTech(Players[owner],"TECH_RADIO")
        local opposite=GameInfoTypes.POLICY_BRANCH_ORDER
        assert(player:GetLateGamePolicyTree()~=opposite,"human fixture already follows Order")
        Players[owner]:SetPolicyBranchUnlocked(opposite,true,false)
        LekmodScenarioEvent("fixture-setup",{operation="provided-opposing-AI-ideology",owner=owner,ideology=opposite})
        started=Game.GetGameTurn();pending=true;phase="pressure";return "turn"
    elseif phase=="pressure" then
        LekmodScenarioEvent("pressure-progress",state(player))
        if not concert or player:GetPublicOpinionUnhappiness()==0 then assert(Game.GetGameTurn()-started<5,"concert did not produce public pressure");return "turn" end
        assert(player:GetPublicOpinionPreferredIdeology()==Players[owner]:GetLateGamePolicyTree(),"preferred ideology differs from concert owner")
        LekmodScenarioEvent("public-pressure-outcome",state(player))
        LekmodScenarioRecord("foreign-concert-pressure","PASS","path=actual-owner-turn-concert-and-normal-turn-public-opinion")
        LekmodScenarioRecord("pressure-below-victory","PASS","winner=-1 influence-below-lifetime-culture=true")
        return true
    end
    return false
end
