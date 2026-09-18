-- Normal human/AI Mexico setup on separate single-player teams. Read-only
-- observation of starting locations and actual PlayerDoTurn discovery outcomes.
LekmodScenario={name="mexico-discovery",items={"mexico-starting-locations","mexico-start-human","mexico-start-ai","mexico-distance-control"}}
local initial
local function visibility(player)
    local start=player:GetStartingPlot();local cities,starts={},{}
    if not start then return {starting_plot=false,cities=cities} end
    for id,minor in pairs(Players) do
        if minor:IsAlive() and minor:IsMinorCiv() then
            local minorStart=minor:GetStartingPlot()
            if minorStart then starts[#starts+1]={owner=id,x=minorStart:GetX(),y=minorStart:GetY(),distance=Map.PlotDistance(start:GetX(),start:GetY(),minorStart:GetX(),minorStart:GetY()),revealed=minorStart:IsRevealed(player:GetTeam())} end
            for city in minor:Cities() do
                local plot=city:Plot()
                cities[#cities+1]={owner=id,city=city:GetID(),x=plot:GetX(),y=plot:GetY(),
                    distance=Map.PlotDistance(start:GetX(),start:GetY(),plot:GetX(),plot:GetY()),
                    plot_revealed=plot:IsRevealed(player:GetTeam()),city_revealed=city:IsRevealed(player:GetTeam())}
            end
        end
    end
    table.sort(cities,function(a,b)return a.owner<b.owner end)
    table.sort(starts,function(a,b)return a.owner<b.owner end)
    return {team=player:GetTeam(),start_x=start:GetX(),start_y=start:GetY(),cities=cities,starts=starts}
end
function LekmodScenario.snapshot(player)
    return {turn=Game.GetGameTurn(),human=visibility(player),ai=visibility(Players[1])}
end
GameEvents.PlayerDoTurn.Add(function(id)
    if id==0 or id==1 then
        LekmodScenarioEvent("mexico-real-player-turn",{player=id,turn=Game.GetGameTurn(),visibility=visibility(Players[id])})
    end
end)
function LekmodScenario.step(player)
    assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_MEXICO and Players[1]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_MEXICO,"requires normally selected human and AI Mexico")
    assert(player:GetTeam()~=Players[1]:GetTeam() and not Game.IsGameMultiPlayer(),"requires separate single-player teams")
    if not initial then
        initial=Game.GetGameTurn()
        local opening=LekmodScenario.snapshot(player)
        LekmodScenarioEvent("mexico-starting-visibility",opening)
        for _,key in ipairs({"human","ai"}) do
            local near=0
            for _,plot in ipairs(opening[key].starts) do
                if plot.distance>0 and plot.distance<=10 then near=near+1;assert(plot.revealed,"opening minor location was not revealed for "..key) end
            end
            assert(near>0,"no nearby minor starting location for "..key)
        end
        LekmodScenarioRecord("mexico-starting-locations","PASS","path=normal-game-initialization human-and-AI-before-minor-foundations=true")
    end
    if Game.GetGameTurn()==initial then return "turn" end
    assert(Game.GetGameTurn()==initial+1,"discovery observation exceeded one ordinary turn")
    local s=LekmodScenario.snapshot(player)
    LekmodScenarioEvent("mexico-after-first-turn",s)
    local farControls=0
    for _,entry in ipairs({{key="human",item="mexico-start-human"},{key="ai",item="mexico-start-ai"}}) do
        local near,missing,distant=0,0,0
        for _,city in ipairs(s[entry.key].cities) do
            if city.distance<=10 then
                near=near+1
                if not city.plot_revealed or not city.city_revealed then missing=missing+1 end
            elseif city.distance>=16 then
                distant=distant+1
                assert(not city.plot_revealed,"far control city was unexpectedly discovered")
            end
        end
        assert(near>0,"setup has no nearby minor city for "..entry.key)
        farControls=farControls+distant
        LekmodScenarioRecord(entry.item,missing==0 and "PASS" or "FAIL","path=normal-first-turn nearby="..near.." undiscovered="..missing)
    end
    assert(farControls>0,"setup has no distant control city")
    LekmodScenarioRecord("mexico-distance-control","PASS","distant-city-plots-unrevealed="..farControls)
    return true
end
