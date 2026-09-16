-- Resume an actually killed spy, then wait for the normal five-turn replacement.
LekmodScenario={name="spy-replacement",items={"dead-spy-wait","spy-replacement"}}
local agent,start,count,oldName
function LekmodScenario.snapshot(player)
    return {turn=Game.GetGameTurn(),spies=player:GetEspionageSpies()}
end
function LekmodScenario.step(player)
    local spies=player:GetEspionageSpies()
    if not agent then
        for _,s in ipairs(spies) do if s.State=="TXT_KEY_SPY_STATE_DEAD" then agent=s.AgentID;oldName=s.Name;break end end
        assert(agent~=nil,"load the newly failed-coup save")
        start=Game.GetGameTurn();count=#spies
    end
    local current
    for _,s in ipairs(spies) do if s.AgentID==agent then current=s;break end end
    assert(current and #spies==count,"spy replacement changed the agent-slot count")
    local elapsed=Game.GetGameTurn()-start
    if elapsed<5 then
        assert(current.State=="TXT_KEY_SPY_STATE_DEAD","dead spy returned before the five-turn replacement delay")
        assert(not player:CanSpyStageCoup(agent) and #player:GetAvailableSpyRelocationCities(agent)==0,"dead spy can act during replacement delay")
        LekmodScenarioEvent("dead-spy-wait",{turn=Game.GetGameTurn(),elapsed=elapsed,state=current.State})
        return "turn"
    end
    assert(elapsed==5,"replacement did not resolve at the expected ordinary turn")
    assert(current.State=="TXT_KEY_SPY_STATE_UNASSIGNED" and current.CityX==-1 and current.CityY==-1 and not current.EstablishedSurveillance,"replacement did not return to HQ without surveillance")
    assert(#player:GetAvailableSpyRelocationCities(agent)>0,"replacement spy has no legal destinations")
    LekmodScenarioRecord("dead-spy-wait","PASS","path=ordinary-turns delay=5")
    LekmodScenarioEvent("spy-replacement",{before_name=oldName,spy=current})
    LekmodScenarioRecord("spy-replacement","PASS","state=unassigned slot-count-preserved=true")
    return true
end
