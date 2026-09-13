-- Read-only observer for physical UI tests. Does not choose orders, dismiss
-- popups, alter turn state, or dispatch input. Normal HUD updates are retained.
do
    local ready, elapsed, previous = false, 0, nil
    local originalUpdate = OnSoftPromptUpdate
    Events.SequenceGameInitComplete.Add(function() ready = true end)
    ContextPtr:SetUpdate(function(dt)
        if originalUpdate then originalUpdate(dt) end
        if not ready then return end
        elapsed = elapsed + dt
        if elapsed < 1 then return end
        elapsed = 0
        local player = Players[Game.GetActivePlayer()]
        if not player then return end
        local city = player:GetCapitalCity()
        local order, item = -1, -1
        if city then order, item = city:GetOrderFromQueue(0) end
        local state = table.concat({Game.GetGameTurn(), player:GetID(), tostring(player:IsTurnActive()),
            city and city:GetID() or -1, order or -1, item or -1,
            city and city:GetFocusType() or -1,
            tostring(city and city:IsForcedAvoidGrowth())}, ":")
        if state ~= previous then
            print("[LEKMOD_UI_OBSERVE] run=__TEST_RUN__ state=" .. state)
            previous = state
        end
    end)
end
