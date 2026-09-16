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
                if __TEST_EXPECT_HUMAN_VICTORY__ then
                    assert(Game.GetWinner()==Players[Game.GetActivePlayer()]:GetTeam(),"human did not naturally win the score fixture")
                end
                for id=0,GameDefines.MAX_MAJOR_CIVS-1 do
                    local player=Players[id]
                    if player and player:IsAlive() then
                        print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ event=score-outcome player="..id.." score="..player:GetScore().." cities="..player:GetNumCities())
                    end
                end
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
