-- Temporary local manual-save callback check using a unique test-only filename.
do
    local name, elapsed = nil, 0
    LuaEvents.LekmodFunctionalSaveName.Add(function(value)
        name, elapsed = value, 0
    end)
    ContextPtr:SetUpdate(function(dt)
        if not name then return end
        elapsed = elapsed + dt
        if elapsed < 2 then return end
        local ok, err = pcall(function()
            assert(not ContextPtr:IsHidden(), "save menu did not open")
            assert(not Controls.CloudCheck:IsChecked(), "fixture must use local saves")
            assert(g_SelectedEntry == nil, "save menu selected an existing save")
            for _, entry in ipairs(g_SavedGames) do
                assert(entry.DisplayName ~= name, "refusing to overwrite a save")
            end
            Controls.NameBox:SetText(name)
            OnSave()
            assert(Controls.DeleteConfirm:IsHidden(), "unexpected overwrite confirmation")
            print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ event=save-callback-returned")
            -- The save request can return before disk writing ends; the standalone
            -- runner verifies its saved copy after the owned game process exits.
            LuaEvents.LekmodFunctionalExit()
        end)
        name = nil
        if not ok then
            print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=save status=FAIL error=" .. tostring(err))
        end
    end)
end
