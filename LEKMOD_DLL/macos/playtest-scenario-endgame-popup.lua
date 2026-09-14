-- Observe the real game-over event and preserve the original animation update.
do
    local shown,elapsed,recorded,exiting=false,0,false,false
    local original=OnUpdate
    Events.EndGameShow.Add(function(kind,team)
        shown=true
        print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ event=engine-endgame type="..kind.." team="..team)
    end)
    -- ShowHideHandler installs OnUpdate again when this panel appears.
    -- Wrap that function so the original animation and the observer both run.
    OnUpdate=function(dt)
        if original then original(dt) end
        if not shown or ContextPtr:IsHidden() or exiting then return end
        elapsed=elapsed+dt
        if not recorded then
            recorded=true
            local ok,err=pcall(function()
                assert(not Game.IsGameMultiPlayer(), "not single-player")
                assert(Game.GetWinner()>=0 and Game.GetVictory()==GameInfoTypes.VICTORY_TIME, "engine did not resolve a score victory")
                print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=score-victory status=PASS path=normal-two-turn-score-resolution winner="..Game.GetWinner())
                print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=endgame-panel status=PASS path=actual-game-over-event")
                print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ event=panel-visible name=endgame")
            end)
            if not ok then
                print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=score-victory status=FAIL error="..tostring(err))
                exiting=true;return
            end
        end
        if elapsed>=12 then
            exiting=true
            print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ event=complete scope=endgame")
            LuaEvents.LekmodFunctionalExit()
        end
    end
    ContextPtr:SetUpdate(OnUpdate)
end
