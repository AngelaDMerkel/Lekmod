LekmodScenario={name="diplomacy-friendship",items={"friendship-request","friendship-agreement","duplicate-friendship-rejected"}}
local target,reply,closed
local attempted={}
local incomingTarget
LuaEvents.LekmodFriendshipIncoming.Add(function(player,result)
    assert(result.accepted,"normal acceptance of the AI offer did not establish friendship")
    incomingTarget=player
    LekmodScenarioEvent("AI-friendship-offer-accepted",{target=player,reply=result})
end)
LuaEvents.LekmodFriendshipReply.Add(function(player,result) assert(player==target);reply=result end)
LuaEvents.LekmodFriendshipClosed.Add(function() closed=true end)
function LekmodScenario.snapshot(player)
    local relations={}
    for id=0,GameDefines.MAX_MAJOR_CIVS-1 do local p=Players[id]
        if p and p:IsAlive() and id~=player:GetID() then relations[id]={ours=player:IsDoF(id),theirs=p:IsDoF(player:GetID()),counter=p:GetDoFCounter(player:GetID()),denounced=player:IsDenouncedPlayer(id)} end
    end
    return {turn=Game.GetGameTurn(),relations=relations}
end
function LekmodScenario.step(player)
    if incomingTarget then
        target=incomingTarget;incomingTarget=nil;reply=nil;closed=false
        LuaEvents.LekmodFriendshipOpen(target,true);return false
    end
    if not target then
        local best=-1
        for id=0,GameDefines.MAX_MAJOR_CIVS-1 do local p=Players[id]
            if p and p:IsAlive() and not p:IsHuman() and not attempted[id] and p:GetTeam()~=player:GetTeam() and Teams[player:GetTeam()]:IsHasMet(p:GetTeam())
                and not Teams[player:GetTeam()]:IsAtWar(p:GetTeam()) and not p:IsDoF(player:GetID())
                and not p:IsDoFMessageTooSoon(player:GetID()) and not player:IsDenouncedPlayer(id) and not p:IsDenouncedPlayer(player:GetID()) then
                local approach=p:GetApproachTowardsUsGuess(player:GetID());local types=MajorCivApproachTypes or {}
                local score=approach==types.MAJOR_CIV_APPROACH_FRIENDLY and 2 or (approach==types.MAJOR_CIV_APPROACH_AFRAID and 1 or 0)
                if score>best then target,best=id,score end
            end
        end
        assert(target,"fixture has no currently eligible friendship request")
        LekmodScenarioEvent("friendship-before",{target=target,relations=LekmodScenario.snapshot(player)})
        LuaEvents.LekmodFriendshipOpen(target);return false
    end
    if not closed or not reply then return false end
    LekmodScenarioEvent("friendship-reply",reply)
    LekmodScenarioRecord("friendship-request","PASS","path="..(reply.path or "actual-dialog-callbacks").." accepted="..tostring(reply.accepted))
    if not reply.accepted then
        attempted[target]=true;target=nil;reply=nil;closed=false
        return false
    end
    assert(player:IsDoF(target) and Players[target]:IsDoF(player:GetID()),"accepted friendship did not persist through normal dialog closure")
    LekmodScenarioRecord("friendship-agreement","PASS","both-directions=true")
    assert(reply.duplicate_blocked,"actual duplicate friendship request remained available")
    LekmodScenarioRecord("duplicate-friendship-rejected","PASS","actual-button=hidden-or-disabled")
    return true
end
