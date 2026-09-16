-- Diagnostic outcome check. A recorded refusal is not friendship acceptance.
LekmodScenario={name="friendship-observe",items={"friendship-dialog-result"}}
local target,reply,closed
LuaEvents.LekmodFriendshipReply.Add(function(player,result) assert(player==target);reply=result end)
LuaEvents.LekmodFriendshipClosed.Add(function() closed=true end)
function LekmodScenario.snapshot(player)
    local other=Players[1]
    return {turn=Game.GetGameTurn(),ours=player:IsDoF(1),theirs=other:IsDoF(player:GetID()),counter=other:GetDoFCounter(player:GetID()),
        civilization=GameInfo.Civilizations[other:GetCivilizationType()].Type,approach=other:GetApproachTowardsUsGuess(player:GetID())}
end
function LekmodScenario.step(player)
    if not target then
        target=1
        assert(not Players[target]:IsDoF(player:GetID()) and not Players[target]:IsDoFMessageTooSoon(player:GetID()),"fixture request is unavailable")
        LekmodScenarioEvent("friendship-diagnostic-before",LekmodScenario.snapshot(player))
        LuaEvents.LekmodFriendshipOpen(target);return false
    end
    if not closed or not reply then return false end
    assert(player:IsDoF(target)==reply.accepted and Players[target]:IsDoF(player:GetID())==reply.accepted,"AI reply disagrees with mutual friendship state")
    LekmodScenarioEvent("friendship-diagnostic-reply",reply)
    LekmodScenarioRecord("friendship-dialog-result","PASS","scope=diagnostic-actual-reply accepted="..tostring(reply.accepted).." not-blanket-acceptance-coverage")
    return true
end
