-- Appended temporarily by automated-playtest.py; never part of the mod payload.
do
    local elapsed = 0
    local started = false
    local function startMatch()
        local loadPath = __TEST_LOAD_PATH__
        if loadPath then
            print("[LEKMOD_TEST] loading saved match: " .. loadPath)
            UIManager:SetUICursor(1)
            Events.PlayerChoseToLoadGame(loadPath)
            return
        end
        print("[LEKMOD_TEST] starting unattended match")
        Controls.VersionNumber:SetText("Lekmod unattended test: starting match")
        PreGame.SetPrivateGame(false)
        PreGame.SetGameType(GameTypes.GAME_SINGLE_PLAYER)
        PreGame.ResetSlots()
        PreGame.ResetGameOptions()
        PreGame.ResetMapOptions()
        PreGame.SetRandomWorldSize(false)
        PreGame.SetWorldSize(GameInfo.Worlds["__TEST_WORLD_SIZE__"].ID)
        PreGame.SetNumMinorCivs(__TEST_MINORS__)
        PreGame.SetRandomMapScript(false)
        PreGame.SetMapScript("Assets\\Maps\\Continents.lua")
        PreGame.SetGameSpeed(GameInfo.GameSpeeds["GAMESPEED_QUICK"].ID)
        PreGame.SetEra(GameInfo.Eras["__TEST_START_ERA__"].ID)
        if __TEST_GAME_TURN_LIMIT__ > 0 then
            PreGame.SetMaxTurns(__TEST_GAME_TURN_LIMIT__)
            PreGame.SetVictory(GameInfo.Victories["VICTORY_TIME"].ID,true)
            print("[LEKMOD_TEST] fixture-setup normal-game-options score-victory=true max-turns="..__TEST_GAME_TURN_LIMIT__)
        end
        for i = 0, 21 do
            PreGame.SetSlotStatus(i, i == 0 and SlotStatus.SS_TAKEN or
                (i < __TEST_MAJORS__ and SlotStatus.SS_COMPUTER or SlotStatus.SS_CLOSED))
            PreGame.SetCivilization(i, -1)
            PreGame.SetHandicap(i, GameInfo.HandicapInfos["HANDICAP_PRINCE"].ID)
        end
        -- Autoplay must move the human to a spare observer slot. Without one,
        -- CivGame::setAIAutoPlay destroys the human's cities and units.
        if __TEST_AUTOPLAY__ then
            PreGame.SetSlotStatus(21, SlotStatus.SS_OBSERVER)
            PreGame.SetSlotClaim(21, SlotClaim.SLOTCLAIM_UNASSIGNED)
        end
        local civilization = assert(GameInfo.Civilizations["__TEST_CIVILIZATION__"], "unknown test civilization")
        assert(civilization.Playable, "test civilization is not playable")
        PreGame.SetCivilization(0, civilization.ID)
        print("[LEKMOD_TEST] fixture-setup normal-civilization=" .. civilization.Type)
        Events.SerialEventStartGame()
        UIManager:SetUICursor(1)
    end
    local function update(dt)
        if started or ContextPtr:IsHidden() then return end
        elapsed = elapsed + dt
        if elapsed < 2 then return end
        started = true
        local ok, err = pcall(startMatch)
        if not ok then
            print("[LEKMOD_TEST] startup failed: " .. tostring(err))
            Controls.VersionNumber:SetText("TEST ERROR: " .. tostring(err))
        end
    end
    -- Lekmod's show handler installs its own version-check update callback.
    local originalShow = ShowHideHandler
    ContextPtr:SetShowHideHandler(function(hidden, initializing)
        if originalShow then originalShow(hidden, initializing) end
        if not hidden then ContextPtr:SetUpdate(update) end
    end)
    ContextPtr:SetUpdate(update)
end
