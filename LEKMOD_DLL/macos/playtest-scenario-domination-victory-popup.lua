do
    local shown,elapsed,recorded,exiting,capture=false,0,false,false,nil
    local original=OnUpdate
    LuaEvents.LekmodDominationCapture.Add(function(x,y,old,new,attacks)
        capture={x=x,y=y,old=old,new=new,attacks=attacks}
    end)
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
                assert(Game.GetWinner()==player:GetTeam() and Game.GetVictory()==GameInfoTypes.VICTORY_DOMINATION,"wrong engine victory")
                assert(capture and capture.new==player:GetID() and capture.attacks>0,"capture event missing")
                local city=assert(Map.GetPlot(capture.x,capture.y):GetPlotCity())
                assert(city:GetOwner()==player:GetID() and city:IsOriginalCapital(),"captured capital ownership mismatch")
                print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=capital-combat status=PASS path=normal-move-attack capture=true")
                print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=domination-victory status=PASS path=engine-result winner="..Game.GetWinner())
                print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=victory-panel status=PASS path=actual-endgame-event")
                print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ event=panel-visible name=domination-victory")
            end)
            if not ok then
                print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ item=domination-victory status=FAIL error="..tostring(err));exiting=true;return
            end
        end
        if elapsed>=15 then
            exiting=true
            print("[LEKMOD_FUNCTIONAL] run=__TEST_RUN__ event=complete scope=domination")
            LuaEvents.LekmodFunctionalExit()
        end
    end
    ContextPtr:SetUpdate(OnUpdate)
end
