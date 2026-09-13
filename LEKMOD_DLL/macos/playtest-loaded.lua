-- Appended temporarily by automated-playtest.py; normal loading code runs first.
Events.SequenceGameInitComplete.Add(function()
    local majors, minors = 0, 0
    for id = 0, 62 do
        local player = Players[id]
        if player and player:IsAlive() then
            if player:IsMinorCiv() then minors = minors + 1
            else majors = majors + 1 end
        end
    end
    print("[LEKMOD_TEST] loaded-roster majors=" .. majors .. " minors=" .. minors)
    print("[LEKMOD_TEST] loaded game; dismissing loading screen")
    OnActivateButtonClicked()
    if __TEST_AUTOPLAY__ then
        Game.SetAIAutoPlay(__TEST_TURNS__, 0)
    elseif not __TEST_FUNCTIONAL__ then
        -- This is a turn-stability run, not the separate visual popup test.
        -- Informational tech/unit awards otherwise block an unattended match.
        UI.SetDontShowPopups(true)
        print("[LEKMOD_TEST] informational popups disabled for turn-stability run")
    end
end)
