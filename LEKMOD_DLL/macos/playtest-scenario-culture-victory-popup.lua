do
    local shown,elapsed,recorded,exiting,final=false,0,false,false,nil
    local original=OnUpdate
    LuaEvents.LekmodCultureFinal.Add(function(target,before,strength,id) final={target=target,before=before,strength=strength,id=id} end)
    Events.EndGameShow.Add(function(kind,team)
        shown=true
        print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ event=engine-endgame type="..kind.." team="..team)
    end)
    OnUpdate=function(dt)
        if original then original(dt) end
        if not shown or ContextPtr:IsHidden() or exiting then return end
        elapsed=elapsed+dt
        if elapsed>=5 and not recorded then
            recorded=true
            local ok,err=pcall(function()
                local player=Players[Game.GetActivePlayer()]
                assert(Game.GetWinner()==player:GetTeam() and Game.GetVictory()==GameInfoTypes.VICTORY_CULTURAL,"wrong engine victory")
                assert(final and player:GetInfluenceOn(final.target)>=final.before+final.strength,"final concert influence missing")
                assert(player:GetNumCivsInfluentialOn()>=player:GetNumCivsToBeInfluentialOn(),"influence threshold not met")
                local unit=player:GetUnitByID(final.id)
                assert(not unit or unit:IsDead() or unit:IsDelayedDeath(),"final musician remains alive")
                print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=culture-threshold status=PASS path=normal-concert-action")
                print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=cultural-victory status=PASS path=engine-result winner="..Game.GetWinner())
                print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=victory-panel status=PASS path=actual-endgame-event")
                print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ event=panel-visible name=cultural-victory")
            end)
            if not ok then print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=cultural-victory status=FAIL error="..tostring(err));exiting=true;return end
        end
        if elapsed>=15 then
            exiting=true
            print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ event=complete scope=culture-launch")
            LuaEvents.LekmodFunctionalExit()
        end
    end
    ContextPtr:SetUpdate(OnUpdate)
end
