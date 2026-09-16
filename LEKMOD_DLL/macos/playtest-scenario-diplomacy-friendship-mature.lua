-- The preceding new-game assets fixture establishes contact on turn zero.
-- Wait through the normal contact buffer; do not assign met-time or AI state.
include("LekmodTestFriendship.lua")
LekmodScenario.name="diplomacy-friendship-mature"
local originalStep=LekmodScenario.step
local start,last
function LekmodScenario.step(player)
    if not start then
        start=Game.GetGameTurn()
        assert(start<=2,"load the fresh turn-two diplomatic-assets fixture")
    end
    local turn=Game.GetGameTurn()
    if turn<GameDefines.DOF_TURN_BUFFER then
        if last~=turn then last=turn;LekmodScenarioEvent("friendship-contact-wait",{turn=turn,first_request_turn=GameDefines.DOF_TURN_BUFFER}) end
        return "turn"
    end
    return originalStep(player)
end
