-- Units and XP thresholds are supplied. Readiness, promotions and faith are
-- native outcomes; no readiness/faith/turn flag is assigned.
LekmodScenario={name="ottoman-promotions",items={"ottoman-human-first","ottoman-human-second","ottoman-AI-faith","promotion-other-owner-no-faith"}}
local phase,ids,turn,humanBefore,humanLevel,humanEventCount="init",{},nil,nil,nil,0
local events,starts,results={[0]={},[1]={},[2]={}},{},{}
GameEvents.UnitPromoted.Add(function(owner,id,promotion)
    if not ids[owner] then return end
    local player=Players[owner];local u=player:GetUnitByID(id)
    local expected=player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_OTTOMAN and math.ceil(u:ExperienceNeeded()/3) or 0
    local row={unit=id,promotion=promotion,needed=u:ExperienceNeeded(),faith=player:GetFaith(),expected=expected,level=u:GetLevel()}
    events[owner][#events[owner]+1]=row
    LekmodScenarioEvent("ottoman-real-promotion",{owner=owner,values=row})
end)
GameEvents.PlayerDoTurn.Add(function(id)
    if (id==1 or id==2) and ids[id] and not results[id] then
        starts[id]={faith=Players[id]:GetFaith(),events=#events[id]}
    elseif id==GameDefines.BARBARIAN_PLAYER then
        for owner=1,2 do
            local start=starts[owner]
            if start and not results[owner] and #events[owner]>start.events then
                local expected,target=0,false
                for index=start.events+1,#events[owner] do local e=events[owner][index];expected=expected+e.expected;if e.unit==ids[owner] then target=true end end
                local actual=Players[owner]:GetFaith()-start.faith
                results[owner]={before=start.faith,after=Players[owner]:GetFaith(),expected=expected,actual=actual,target=target}
                LekmodScenarioEvent("ottoman-AI-faith-outcome",{owner=owner,values=results[owner]})
            end
        end
    end
end)
local function promote(player)
    local u=assert(player:GetUnitByID(ids[0]));assert(u:IsPromotionReady(),"normal promotion readiness missing")
    humanBefore=player:GetFaith();humanLevel=u:GetLevel();humanEventCount=#events[0]
    UI.SelectUnit(u)
    for index=0,#GameInfoActions do local action=GameInfoActions[index]
        if action and action.SubType==ActionSubTypes.ACTIONSUBTYPE_PROMOTION and Game.CanHandleAction(index) then
            local info=GameInfo.UnitPromotions[action.Type]
            if info and not info.LostWithUpgrade and not u:IsHasPromotion(info.ID) then Game.HandleAction(index);return end
        end
    end
    error("no normal legal promotion")
end
function LekmodScenario.snapshot(player)
    local result={turn=Game.GetGameTurn(),players={}}
    for owner=0,2 do local p=Players[owner];local units={}
        for u in p:Units() do if not u:IsDead() and not u:IsDelayedDeath() then
            local promotions={};for info in GameInfo.UnitPromotions()do if u:IsHasPromotion(info.ID)then promotions[#promotions+1]=info.ID end end
            units[u:GetID()]={type=u:GetUnitType(),level=u:GetLevel(),experience=u:GetExperience(),promotions=promotions}
        end end
        result.players[owner]={civ=p:GetCivilizationType(),faith=p:GetFaith(),units=units}
    end
    return result
end
function LekmodScenario.step(player)
    assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_OTTOMAN and Players[1]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_OTTOMAN and Players[2]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_ROME,"requires normal human/AI Ottomans and Roman control")
    if not player:GetCapitalCity() or not Players[1]:GetCapitalCity() or not Players[2]:GetCapitalCity() then return "turn" end
    if phase=="init" then
        assert(not Game.IsOption("GAMEOPTION_NO_RELIGION") and Game.IsOption("GAMEOPTION_NO_GOODY_HUTS"),"requires enabled faith and normal no-ruins option")
        for owner=0,2 do local p=Players[owner];local plot
            for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
                if q:GetOwner()==owner and not q:IsWater() and not q:IsMountain() and q:GetNumUnits()==0 then plot=q;break end
            end
            assert(plot,"no owned unit staging tile")
            local faith=p:GetFaith();local u=assert(p:InitUnit(GameInfoTypes.UNIT_WARRIOR,plot:GetX(),plot:GetY()));ids[owner]=u:GetID()
            u:SetExperience(u:ExperienceNeeded())
            assert(p:GetFaith()==faith,"unit/XP input itself awarded faith")
            LekmodScenarioEvent("fixture-setup",{operation="provided-promotion-unit-and-XP",owner=owner,unit=u:GetID(),xp=u:GetExperience(),needed=u:ExperienceNeeded()})
        end
        turn=Game.GetGameTurn();phase="first-ready";return "turn"
    elseif phase=="first-ready" then
        local u=player:GetUnitByID(ids[0]);if not u:IsPromotionReady() and Game.GetGameTurn()==turn then return "turn" end
        promote(player);phase="first-done"
    elseif phase=="first-done" or phase=="second-done" then
        local u=player:GetUnitByID(ids[0])
        if not LekmodScenarioAwait("human-promotion-"..phase,#events[0]==humanEventCount+1 and u:GetLevel()==humanLevel+1)then return false end
        local e=events[0][#events[0]];local gained=player:GetFaith()-humanBefore
        assert(gained==e.expected and gained>0,"human promotion faith differs from event-time XP threshold")
        local first=phase=="first-done"
        LekmodScenarioRecord(first and "ottoman-human-first" or "ottoman-human-second","PASS","path=normal-promotion-action faith="..gained.." event-XP-needed="..e.needed)
        if first then
            u:SetExperience(u:ExperienceNeeded());turn=Game.GetGameTurn()
            LekmodScenarioEvent("fixture-setup",{operation="provided-next-promotion-XP",unit=u:GetID(),xp=u:GetExperience()})
            phase="second-ready";return "turn"
        end
        for owner=1,2 do
            local r=assert(results[owner],"AI promotion faith observation missing")
            assert(r.target and r.actual==r.expected,"AI faith change differs from its real promotion events")
            assert((owner==1 and r.actual>0) or (owner==2 and r.actual==0),"AI/other-owner award boundary differs")
        end
        LekmodScenarioRecord("ottoman-AI-faith","PASS","path=normal-AI-promotion events-and-faith-delta-matched=true")
        LekmodScenarioRecord("promotion-other-owner-no-faith","PASS","Roman-AI-promoted faith-added=0")
        return true
    elseif phase=="second-ready" then
        local u=player:GetUnitByID(ids[0]);if not u:IsPromotionReady() and Game.GetGameTurn()==turn then return "turn" end
        promote(player);phase="second-done"
    end
    return false
end
