-- Human/AI Mexico selected normally. Pottery is an explicit technology input;
-- free Workers must come from the native trait award, never InitUnit.
LekmodScenario={name="mexico-pottery",items={"mexico-human-worker","mexico-AI-worker","mexico-worker-no-repeat"}}
local phase,before="init",{}
local function workers(player)
    local list={}
    for unit in player:Units() do
        if unit:GetUnitType()==GameInfoTypes.UNIT_WORKER and not unit:IsDelayedDeath() then
            list[#list+1]={id=unit:GetID(),owner=unit:GetOwner(),type=unit:GetUnitType(),x=unit:GetX(),y=unit:GetY(),moves=unit:GetMoves()}
        end
    end
    table.sort(list,function(a,b)return a.id<b.id end)
    return list
end
function LekmodScenario.snapshot(player)
    local result={turn=Game.GetGameTurn(),players={}}
    for id=0,1 do local p=Players[id]
        result.players[id]={civ=p:GetCivilizationType(),team=p:GetTeam(),pottery=Teams[p:GetTeam()]:GetTeamTechs():HasTech(GameInfoTypes.TECH_POTTERY),workers=workers(p)}
    end
    return result
end
function LekmodScenario.step(player)
    assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_MEXICO and Players[1]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_MEXICO,"requires normally selected human/AI Mexico")
    assert(player:GetTeam()~=Players[1]:GetTeam() and player:GetCapitalCity() and Players[1]:GetCapitalCity(),"requires separate teams and existing capitals")
    if phase=="init" then
        for id=0,1 do local p=Players[id]
            assert(not Teams[p:GetTeam()]:GetTeamTechs():HasTech(GameInfoTypes.TECH_POTTERY),"Pottery already known")
            before[id]=#workers(p)
        end
        LekmodScenarioEvent("mexico-before-pottery",LekmodScenario.snapshot(player))
        LekmodScenarioGrantTech(player,"TECH_POTTERY");phase="human"
    elseif phase=="human" then
        assert(#workers(player)==before[0]+1 and #workers(Players[1])==before[1],"human Pottery worker/other-owner boundary differs")
        LekmodScenarioRecord("mexico-human-worker","PASS","path=native-tech-award workers-added=1 AI-unchanged=true")
        LekmodScenarioGrantTech(Players[1],"TECH_POTTERY");phase="ai"
    elseif phase=="ai" then
        assert(#workers(player)==before[0]+1 and #workers(Players[1])==before[1]+1,"AI Pottery worker/other-owner boundary differs")
        LekmodScenarioRecord("mexico-AI-worker","PASS","path=native-tech-award workers-added=1 human-unchanged=true")
        for id=0,1 do Teams[Players[id]:GetTeam()]:SetHasTech(GameInfoTypes.TECH_POTTERY,true,id,true,true) end
        phase="repeat"
    elseif phase=="repeat" then
        assert(#workers(player)==before[0]+1 and #workers(Players[1])==before[1]+1,"known Pottery repeated a Worker award")
        LekmodScenarioEvent("mexico-pottery-outcome",LekmodScenario.snapshot(player))
        LekmodScenarioRecord("mexico-worker-no-repeat","PASS","path=repeated-native-known-tech-command no-additional-workers=true")
        return true
    end
    return false
end
