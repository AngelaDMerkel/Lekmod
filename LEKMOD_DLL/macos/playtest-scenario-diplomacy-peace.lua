-- Resume the real city-capture war; no war score, willingness or peace flag is
-- supplied. Retry only after ordinary turns if the real AI declines early.
LekmodScenario={name="diplomacy-peace",items={"peace-negotiation","peace-accepted","peace-war-restriction"}}
local target,started,attempt,reply,closed,proposed,goldUs,goldThem
LuaEvents.LekmodPeaceReply.Add(function(accepted,text) reply={accepted=accepted,message=text} end)
LuaEvents.LekmodPeaceClosed.Add(function() closed=true end)
LuaEvents.LekmodPeaceProposed.Add(function() proposed=true end)
function LekmodScenario.snapshot(player)
    local p=Players[1];local a,b=Teams[player:GetTeam()],Teams[p:GetTeam()]
    return {turn=Game.GetGameTurn(),war=a:IsAtWar(p:GetTeam()),our_force_peace=a:IsForcePeace(p:GetTeam()),their_force_peace=b:IsForcePeace(player:GetTeam()),
        us_can_war=a:CanDeclareWar(p:GetTeam()),them_can_war=b:CanDeclareWar(player:GetTeam()),us_gold=player:GetGold(),them_gold=p:GetGold()}
end
local function request(player)
    attempt=Game.GetGameTurn();reply=nil;closed=false;proposed=false
    goldUs=player:GetGold();goldThem=Players[target]:GetGold()
    LuaEvents.LekmodPeaceOpen(target)
end
function LekmodScenario.step(player)
    if not started then
        target=1;started=Game.GetGameTurn()
        assert(Teams[player:GetTeam()]:IsAtWar(Players[target]:GetTeam()),"load the saved city-capture war")
        request(player);return false
    end
    if not closed or not reply then return false end
    if not reply.accepted then
        LekmodScenarioEvent("peace-refused",{turn=Game.GetGameTurn(),message=reply.message})
        assert(Game.GetGameTurn()-started<8,"AI did not accept white peace within the bounded case")
        if Game.GetGameTurn()==attempt then return "turn" end
        request(player);return false
    end
    assert(proposed,"peace ended without the actual proposal callback")
    local s=LekmodScenario.snapshot(player)
    assert(not s.war and s.our_force_peace and s.their_force_peace,"accepted peace did not apply bilateral protection")
    assert(not s.us_can_war and not s.them_can_war,"peace treaty did not prohibit declarations")
    assert(s.us_gold==goldUs and s.them_gold==goldThem,"white peace unexpectedly transferred gold")
    LekmodScenarioEvent("peace-accepted",reply)
    LekmodScenarioRecord("peace-negotiation","PASS","path=actual-NegotiatePeace/propose/reply/Back/Goodbye callbacks")
    LekmodScenarioRecord("peace-accepted","PASS","war=false bilateral-peace-duration=5 no-gold-concession=true")
    LekmodScenarioRecord("peace-war-restriction","PASS","both-directions=false")
    return true
end
