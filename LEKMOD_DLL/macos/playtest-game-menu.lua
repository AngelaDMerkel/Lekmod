-- Temporary normal game-menu save dispatch. Never invokes cloud-save controls.
LuaEvents.LekmodFunctionalSave.Add(function(name)
    UIManager:QueuePopup(ContextPtr, PopupPriority.InGameMenu)
    OnSave()
    LuaEvents.LekmodFunctionalSaveName(name)
end)
