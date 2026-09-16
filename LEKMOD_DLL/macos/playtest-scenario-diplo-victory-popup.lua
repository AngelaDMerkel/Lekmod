do
    local shown,elapsed,recorded,exiting,final=false,0,false,false,nil
    local original=OnUpdate
    LuaEvents.LekmodDiploFinal.Add(function(league,proposal,votes) final={league=league,proposal=proposal,votes=votes} end)
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
                assert(Game.GetWinner()==player:GetTeam() and Game.GetVictory()==GameInfoTypes.VICTORY_DIPLOMATIC,"wrong engine victory")
                assert(final and final.votes>=Game.GetVotesNeededForDiploVictory(),"winning ballot missing")
                assert(Game.GetActiveLeague():GetRemainingVotesForMember(player:GetID())==0,"ballot votes not consumed")
                print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=world-leader-vote status=PASS path=normal-ballot votes="..final.votes)
                print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=diplomatic-victory status=PASS path=engine-result winner="..Game.GetWinner())
                print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=victory-panel status=PASS path=actual-endgame-event")
                print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ event=panel-visible name=diplomatic-victory")
            end)
            if not ok then print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=diplomatic-victory status=FAIL error="..tostring(err));exiting=true;return end
        end
        if elapsed>=15 then
            exiting=true
            print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ event=complete scope=diplo-victory-launch")
            LuaEvents.LekmodFunctionalExit()
        end
    end
    ContextPtr:SetUpdate(OnUpdate)
end
