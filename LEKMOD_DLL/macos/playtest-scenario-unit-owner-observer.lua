-- Appended to the actual Lekmod_units context, after its real registrations.
-- Read-only evidence distinguishes registration order from later AI changes.
print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ event=unit-handler-context hover="..tostring(hover_promotion).." embark="..tostring(embark_promotion))
GameEvents.PlayerDoTurn.Add(function(owner)
    local player=Players[owner]
    if not player or not player:IsAlive() then return end
    for unit in player:Units() do
        if unit:IsHasPromotion(GameInfoTypes.PROMOTION_MOVE_ALL_TERRAIN) then
            print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ event=unit-handler-after owner="..owner.." unit="..unit:GetID()..
                " embark="..tostring(unit:IsHasPromotion(GameInfoTypes.PROMOTION_EMBARKATION)))
        end
    end
end)
