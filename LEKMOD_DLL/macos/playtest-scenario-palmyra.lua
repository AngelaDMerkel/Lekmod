-- Duplicate Palmyra is a normal single-player setup with an AI opponent.
-- Founding inputs, uranium, attacker and staging are supplied explicitly.
-- Freshwater, city damage and the capture outcome are never assigned.
LekmodScenario={name="palmyra",items={"palmyra-founded-water","palmyra-capture-water"}}
local phase,enemy,unitID,x,y,reply,captured,staged,attacks="init",nil,nil,nil,nil,nil,nil,false,0
local dry={}
LuaEvents.LekmodCaptureChoiceDone.Add(function(kind,id) reply={kind=kind,id=id} end)
GameEvents.CityCaptureComplete.Add(function(old,capital,cx,cy,new,pop,conquest)
    if cx==x and cy==y then captured={old=old,new=new,capital=capital,conquest=conquest} end
end)
function LekmodScenario.snapshot(player)
    local cities,plots={},{}
    for id=0,GameDefines.MAX_MAJOR_CIVS-1 do
        local p=Players[id]
        if p and p:IsAlive() then for c in p:Cities() do
            cities[id..":"..c:GetID()]={owner=id,x=c:GetX(),y=c:GetY(),puppet=c:IsPuppet()}
            for d=0,5 do local a=Map.PlotDirection(c:GetX(),c:GetY(),d)
                if a then plots[a:GetPlotIndex()]={x=a:GetX(),y=a:GetY(),water=a:IsWater(),fresh=a:IsFreshWater()} end
            end
        end end
    end
    return {turn=Game.GetGameTurn(),cities=cities,plots=plots,winner=Game.GetWinner()}
end
function LekmodScenario.step(player)
    assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_PALMYRA,"human must use normal Palmyra setup")
    if not player:GetCapitalCity() or not Players[1]:GetCapitalCity() then return "turn" end
    local other=Players[1]
    assert(other:GetCivilizationType()==GameInfoTypes.CIVILIZATION_PALMYRA,"AI must use normal Palmyra setup")
    if phase=="init" then
        enemy=other:GetID();local capital=other:GetCapitalCity();local site
        for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i)
            local dist=Map.PlotDistance(capital:GetX(),capital:GetY(),p:GetX(),p:GetY())
            if dist>=4 and dist<=9 and p:GetOwner()==-1 and p:GetArea()==capital:Plot():GetArea()
                and p:GetNumUnits()==0 and other:CanFound(p:GetX(),p:GetY()) then
                local candidates={}
                for d=0,5 do local a=Map.PlotDirection(p:GetX(),p:GetY(),d)
                    if a and not a:IsWater() and not a:IsMountain() and not a:IsFreshWater() then
                        candidates[#candidates+1]={x=a:GetX(),y=a:GetY()}
                    end
                end
                if #candidates>0 then site,dry=p,candidates;break end
            end
        end
        assert(site,"no legal Palmyra secondary site with naturally dry neighbors")
        x,y=site:GetX(),site:GetY();other:Found(x,y)
        assert(site:GetPlotCity() and not site:GetPlotCity():IsOriginalCapital(),"secondary city not founded")
        LekmodScenarioEvent("fixture-setup",{operation="provided-AI-secondary-city",x=x,y=y,dry_neighbors=dry,owner=enemy})
        for _,p in ipairs(dry) do assert(Map.GetPlot(p.x,p.y):IsFreshWater(),"Palmyra founding did not add freshwater") end
        LekmodScenarioRecord("palmyra-founded-water","PASS","path=actual-founded-event dry-neighbors="..#dry)
        local r=GameInfoTypes.RESOURCE_URANIUM
        if player:GetNumResourceAvailable(r,true)<1 then player:ChangeNumResourceTotal(r,1)
            LekmodScenarioEvent("fixture-setup",{operation="provided-uranium",added=1}) end
        local home=player:GetCapitalCity();local u=assert(player:InitUnit(GameInfoTypes.UNIT_MECH,home:GetX(),home:GetY()));unitID=u:GetID()
        LekmodScenarioEvent("fixture-setup",{operation="provided-attacker",id=unitID,type="UNIT_MECH"})
        Network.SendChangeWar(other:GetTeam(),true);phase="war"
    elseif phase=="war" then
        if not LekmodScenarioAwait("palmyra-war",Teams[player:GetTeam()]:IsAtWar(other:GetTeam())) then return false end
        phase="attack"
    elseif phase=="attack" then
        local u=assert(player:GetUnitByID(unitID));local target=Map.GetPlot(x,y)
        if u:IsBusy() or target:IsFighting() then return false end
        if u:GetMoves()<=0 or not u:IsCanAttackWithMoveNow() then return "turn" end
        if not staged then
            local site
            for d=0,5 do local p=Map.PlotDirection(x,y,d)
                if p and not p:IsWater() and not p:IsMountain() and p:GetNumUnits()==0 then site=p;break end
            end
            assert(site,"no legal adjacent attacker staging tile")
            u:SetXY(site:GetX(),site:GetY(),false,true,false,false);staged=true
            LekmodScenarioEvent("fixture-setup",{operation="position-attacker",x=u:GetX(),y=u:GetY(),id=unitID})
        end
        attacks=attacks+1;assert(attacks<=4,"capture exceeds four attacks")
        assert(u:CanMoveOrAttackInto(target),"capture attack is illegal")
        reply=nil;LuaEvents.LekmodCaptureChoice("puppet");UI.SelectUnit(u)
        Game.SelectionListGameNetMessage(GameMessageTypes.GAMEMESSAGE_PUSH_MISSION,MissionTypes.MISSION_MOVE_TO,x,y,0,false,false)
        phase="captured"
    elseif phase=="captured" then
        local p=Map.GetPlot(x,y);local city=assert(p:GetPlotCity())
        if not reply then
            if not p:IsFighting() and city:GetOwner()==enemy then phase="attack" end
            return false
        end
        if not LekmodScenarioAwait("palmyra-puppet",city:GetOwner()==player:GetID() and city:IsPuppet()) then return false end
        assert(captured and captured.old==enemy and captured.new==player:GetID() and captured.conquest and not captured.capital,"actual capture event mismatch")
        LekmodScenarioEvent("palmyra-after-capture",LekmodScenario.snapshot(player))
        for _,p in ipairs(dry) do assert(Map.GetPlot(p.x,p.y):IsFreshWater(),"capture from another Palmyra removed the current owner's freshwater") end
        assert(other:IsAlive() and Game.GetWinner()==-1,"fixture ended opponent/game")
        LekmodScenarioRecord("palmyra-capture-water","PASS","path=normal-attack-actual-puppet-callback Palmyra-to-Palmyra=true")
        return true
    end
    return false
end
