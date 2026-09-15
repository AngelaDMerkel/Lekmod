-- Observe the actual engine victory event and keep the original animation.
do
    local shown,elapsed,recorded,exiting=false,0,false,false
    local original=OnUpdate
    Events.EndGameShow.Add(function(kind,team)
        shown=true
        print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ event=engine-endgame type="..kind.." team="..team)
    end)
    OnUpdate=function(dt)
        if original then original(dt) end
        if not shown or ContextPtr:IsHidden() or exiting then return end
        elapsed=elapsed+dt
        -- The stock space-victory screen intentionally delays its artwork.
        if elapsed>=8 and not recorded then
            recorded=true
            local ok,err=pcall(function()
                local player=Players[Game.GetActivePlayer()]
                local team=Teams[player:GetTeam()]
                assert(not Game.IsGameMultiPlayer(),"not single-player")
                assert(Game.GetWinner()==player:GetTeam() and Game.GetVictory()==GameInfoTypes.VICTORY_SPACE_RACE,"wrong engine victory result")
                for name,count in pairs({PROJECT_SS_COCKPIT=1,PROJECT_SS_BOOSTER=3,PROJECT_SS_ENGINE=1,PROJECT_SS_STASIS_CHAMBER=1}) do
                    assert(team:GetProjectCount(GameInfoTypes[name])==count,"final component count mismatch")
                end
                for unit in player:Units() do
                    if GameInfo.Units[unit:GetUnitType()].SpaceshipProject then
                        -- DoBuildSpaceship uses kill(true). Victory pauses the
                        -- world before delayed deletion can finish; the unit
                        -- must be marked dead, not necessarily absent yet.
                        print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ event=final-component-state id="..unit:GetID().." dead="..tostring(unit:IsDead()).." delayed_death="..tostring(unit:IsDelayedDeath()))
                        assert(unit:IsDead() or unit:IsDelayedDeath(),"assembled component remains alive")
                    end
                end
                print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=science-final-part status=PASS path=normal-spaceship-action")
                print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=science-victory status=PASS path=engine-result winner="..Game.GetWinner())
                print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=victory-panel status=PASS path=actual-endgame-event")
                print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ event=panel-visible name=science-victory")
            end)
            if not ok then
                print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=science-victory status=FAIL error="..tostring(err));exiting=true;return
            end
        end
        if elapsed>=18 then
            exiting=true
            print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ event=complete scope=science-launch")
            LuaEvents.LekmodFunctionalExit()
        end
    end
    ContextPtr:SetUpdate(OnUpdate)
end
