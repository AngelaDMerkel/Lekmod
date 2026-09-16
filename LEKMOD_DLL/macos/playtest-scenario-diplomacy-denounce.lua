LekmodScenario={name="diplomacy-denounce",items={"denounce-cancel","denounce-confirm","denounce-state"}}
local target,cancelled,confirmed,closed
LuaEvents.LekmodDenounceCancelled.Add(function() cancelled=true end)
LuaEvents.LekmodDenounceConfirmed.Add(function(reply) confirmed=reply end)
LuaEvents.LekmodFriendshipClosed.Add(function() closed=true end)
function LekmodScenario.snapshot(player)
    local relations={}
    for id=0,GameDefines.MAX_MAJOR_CIVS-1 do local p=Players[id]
        if p and p:IsAlive() and id~=player:GetID() then relations[id]={ours=player:IsDenouncedPlayer(id),theirs=p:IsDenouncedPlayer(player:GetID()),friendship=player:IsDoF(id),their_friendship=p:IsDoF(player:GetID()),war=Teams[player:GetTeam()]:IsAtWar(p:GetTeam()),our_embassy=Teams[player:GetTeam()]:HasEmbassyAtTeam(p:GetTeam()),their_embassy=Teams[p:GetTeam()]:HasEmbassyAtTeam(player:GetTeam())} end
    end
    return {turn=Game.GetGameTurn(),relations=relations}
end
function LekmodScenario.step(player)
    if not target then
        for id=0,GameDefines.MAX_MAJOR_CIVS-1 do local p=Players[id]
            if p and p:IsAlive() and not p:IsHuman() and p:GetTeam()~=player:GetTeam() and Teams[player:GetTeam()]:IsHasMet(p:GetTeam())
                and not Teams[player:GetTeam()]:IsAtWar(p:GetTeam()) and not player:IsDenouncedPlayer(id) then target=id;break end
        end
        assert(target,"no eligible peaceful denouncement target")
        assert(player:IsDoF(target) and Players[target]:IsDoF(player:GetID()),"load the accepted-friendship fixture")
        assert(Teams[player:GetTeam()]:HasEmbassyAtTeam(Players[target]:GetTeam()) and Teams[Players[target]:GetTeam()]:HasEmbassyAtTeam(player:GetTeam()),"fixture lacks mutual embassies")
        LuaEvents.LekmodFriendshipOpen(target);return false
    end
    if not closed or not confirmed then return false end
    assert(cancelled,"denouncement No branch was not exercised")
    LekmodScenarioRecord("denounce-cancel","PASS","path=actual-confirmation-No state-preserved=true")
    LekmodScenarioRecord("denounce-confirm","PASS","path=actual-confirmation-Yes-and-AI-reply")
    assert(player:IsDenouncedPlayer(target) and not Teams[player:GetTeam()]:IsAtWar(Players[target]:GetTeam()),"denouncement did not persist independently of war")
    assert(not player:IsDoF(target) and not Players[target]:IsDoF(player:GetID()),"denouncement did not end mutual friendship")
    assert(not Teams[player:GetTeam()]:HasEmbassyAtTeam(Players[target]:GetTeam()) and not Teams[Players[target]:GetTeam()]:HasEmbassyAtTeam(player:GetTeam()),"denouncement did not close both embassies")
    LekmodScenarioEvent("denouncement-reply",confirmed)
    LekmodScenarioRecord("denounce-state","PASS","human-denounced=true war=false friendship-ended-and-embassies-closed=true")
    return true
end
