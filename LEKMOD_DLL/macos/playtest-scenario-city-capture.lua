LekmodScenario={name="city-capture",items={"secondary-capture","city-puppet","city-annex","city-raze","city-liberation"}}
local phase,enemy,unitID,x,y,cityID,minorID,reply,beforeCities,issuedTurn="init"
local captures={}
local staged,attacks={},{}
LuaEvents.LekmodCaptureChoiceDone.Add(function(kind,id) reply={kind=kind,id=id} end)
GameEvents.CityCaptureComplete.Add(function(old,capital,cx,cy,new,pop,conquest)
    if new==Game.GetActivePlayer() then captures[cx..":"..cy]={old=old,capital=capital,conquest=conquest} end
end)
local function sendTask(city,kind)
    Network.SendDoTask(city:GetID(),kind,-1,-1,false,false,false,false)
end
local function attack(player,kind)
    local unit=assert(player:GetUnitByID(unitID),"fixture attacker was destroyed")
    local target=assert(Map.GetPlot(x,y):GetPlotCity())
    if unit:IsBusy() or target:Plot():IsFighting() then return false end
    if unit:GetMoves()<=0 or not unit:IsCanAttackWithMoveNow() then return "turn" end
    if not staged[kind] then
        local staging
        for direction=0,5 do
            local plot=Map.PlotDirection(x,y,direction)
            if plot and not plot:IsWater() and not plot:IsMountain() and plot:GetNumUnits()==0 then staging=plot;break end
        end
        assert(staging,"no legal staging tile adjacent to capture target")
        unit:SetXY(staging:GetX(),staging:GetY(),false,true,false,false)
        LekmodScenarioEvent("fixture-setup",{operation="position-attacker",id=unitID,x=unit:GetX(),y=unit:GetY(),target_x=x,target_y=y})
        staged[kind]=true
    end
    assert(Map.PlotDistance(unit:GetX(),unit:GetY(),x,y)==1,"attacker displaced from the capture fixture")
    attacks[kind]=(attacks[kind] or 0)+1;assert(attacks[kind]<=8,"capture needs more than eight attacks")
    assert(unit:CanMoveOrAttackInto(target:Plot()),"capture attack is not legal")
    reply=nil;LuaEvents.LekmodCaptureChoice(kind)
    UI.SelectUnit(unit)
    Game.SelectionListGameNetMessage(GameMessageTypes.GAMEMESSAGE_PUSH_MISSION,MissionTypes.MISSION_MOVE_TO,x,y,0,false,false)
    return true
end
function LekmodScenario.snapshot(player)
    local cities,owners={},{}
    for id=0,GameDefines.MAX_CIV_PLAYERS-1 do
        local p=Players[id]
        if p and p:IsEverAlive() then
            owners[id]={alive=p:IsAlive(),cities=p:GetNumCities()}
            for city in p:Cities() do
                cities[id..":"..city:GetID()]={x=city:GetX(),y=city:GetY(),original=city:GetOriginalOwner(),population=city:GetPopulation(),
                    puppet=city:IsPuppet(),occupied=city:IsOccupied(),razing=city:IsRazing()}
            end
        end
    end
    return {turn=Game.GetGameTurn(),winner=Game.GetWinner(),cities=cities,owners=owners}
end
function LekmodScenario.step(player)
    if phase=="init" then
        assert(Game.GetWinner()==-1,"fixture already has a winner")
        for id=0,GameDefines.MAX_MAJOR_CIVS-1 do
            local p=Players[id]
            if id~=player:GetID() and p and p:IsAlive() then enemy=id;break end
        end
        local other=assert(Players[enemy]);local capital=assert(other:GetCapitalCity())
        local site,best=nil,999
        for i=0,Map.GetNumPlots()-1 do
            local plot=Map.GetPlotByIndex(i)
            local distance=Map.PlotDistance(capital:GetX(),capital:GetY(),plot:GetX(),plot:GetY())
            if distance>=4 and distance<=9 and distance<best and plot:GetArea()==capital:Plot():GetArea() and plot:GetOwner()==-1
                and plot:GetNumUnits()==0 and other:CanFound(plot:GetX(),plot:GetY()) then site,best=plot,distance end
        end
        assert(site,"no legal secondary-city input location")
        x,y=site:GetX(),site:GetY();other:Found(x,y)
        local city=assert(site:GetPlotCity());assert(not city:IsOriginalCapital(),"secondary input became original capital")
        LekmodScenarioEvent("fixture-setup",{operation="provided-opponent-secondary-city",owner=enemy,x=x,y=y,population=city:GetPopulation()})
        local resource=GameInfoTypes.RESOURCE_URANIUM
        if player:GetNumResourceAvailable(resource,true)<1 then
            player:ChangeNumResourceTotal(resource,1)
            LekmodScenarioEvent("fixture-setup",{operation="provided-uranium",added=1})
        end
        local home=player:GetCapitalCity()
        local unit=assert(player:InitUnit(GameInfoTypes.UNIT_MECH,home:GetX(),home:GetY()));unitID=unit:GetID()
        LekmodScenarioEvent("fixture-setup",{operation="provided-unit",type="UNIT_MECH",id=unitID})
        assert(not player:CanRaze(home),"own original capital is razable")
        Network.SendChangeWar(other:GetTeam(),true);phase="war"
    elseif phase=="war" then
        if not LekmodScenarioAwait("capture-war",Teams[player:GetTeam()]:IsAtWar(Players[enemy]:GetTeam())) then return false end
        phase="attack-secondary"
    elseif phase=="attack-secondary" then
        local result=attack(player,"puppet")
        if result==true then phase="puppeted" else return result end
    elseif phase=="puppeted" then
        if not reply then
            local plot=Map.GetPlot(x,y)
            if not plot:IsFighting() and plot:GetPlotCity():GetOwner()==enemy then phase="attack-secondary" end
            return false
        end
        local city=assert(Map.GetPlot(x,y):GetPlotCity());cityID=city:GetID()
        local capture=assert(captures[x..":"..y],"real capture event missing")
        assert(reply.kind=="puppet" and capture.old==enemy and capture.conquest and not capture.capital,"wrong secondary capture")
        if not LekmodScenarioAwait("puppet-created",city:GetOwner()==player:GetID() and city:IsPuppet()) then return false end
        LekmodScenarioRecord("secondary-capture","PASS","path=normal-attack-and-engine-capture")
        LekmodScenarioRecord("city-puppet","PASS","path=actual-capture-popup-choice")
        sendTask(city,TaskTypes.TASK_ANNEX_PUPPET);phase="annexed"
    elseif phase=="annexed" then
        local city=assert(player:GetCityByID(cityID))
        if not LekmodScenarioAwait("annex-created",not city:IsPuppet()) then return false end
        assert(city:IsOccupied() and player:CanRaze(city),"annexed captured secondary city has invalid occupation/raze state")
        LekmodScenarioRecord("city-annex","PASS","path=normal-city-task occupied=true")
        beforeCities=player:GetNumCities();issuedTurn=Game.GetGameTurn()
        sendTask(city,TaskTypes.TASK_RAZE);phase="razing"
    elseif phase=="razing" then
        local city=Map.GetPlot(x,y):GetPlotCity()
        if city then
            if not LekmodScenarioAwait("raze-started",city:IsRazing()) then return false end
            assert(Game.GetGameTurn()-issuedTurn<=8,"raze did not complete within eight turns")
            return "turn"
        end
        assert(player:GetNumCities()==beforeCities-1,"raze did not remove the city")
        LekmodScenarioRecord("city-raze","PASS","path=normal-city-task-and-turns original-capital-raze=rejected")
        phase="liberation-input"
    elseif phase=="liberation-input" then
        for id=GameDefines.MAX_MAJOR_CIVS,GameDefines.MAX_CIV_PLAYERS-1 do
            local minor=Players[id]
            if minor and minor:IsAlive() and minor:IsMinorCiv() and minor:GetCapitalCity() then minorID=id;break end
        end
        local minor=assert(Players[minorID],"no minor capital for liberation input")
        local city=minor:GetCapitalCity();x,y=city:GetX(),city:GetY()
        if not Teams[player:GetTeam()]:IsHasMet(minor:GetTeam()) then Teams[player:GetTeam()]:Meet(minor:GetTeam(),false) end
        Players[enemy]:AcquireCity(city,false,true)
        city=assert(Map.GetPlot(x,y):GetPlotCity())
        assert(city:GetOwner()==enemy and city:GetOriginalOwner()==minorID,"liberation ownership input failed")
        LekmodScenarioEvent("fixture-setup",{operation="provided-foreign-held-minor-city",original_owner=minorID,owner=enemy,x=x,y=y})
        phase="attack-liberation"
    elseif phase=="attack-liberation" then
        local result=attack(player,"liberate")
        if result==true then phase="liberated" else return result end
    elseif phase=="liberated" then
        if not reply then
            local plot=Map.GetPlot(x,y)
            if not plot:IsFighting() and plot:GetPlotCity():GetOwner()==enemy then phase="attack-liberation" end
            return false
        end
        local city=Map.GetPlot(x,y):GetPlotCity()
        if not LekmodScenarioAwait("city-liberated",city~=nil and city:GetOwner()==minorID and Players[minorID]:IsAlive()) then return false end
        assert(reply.kind=="liberate" and captures[x..":"..y].conquest,"liberation did not follow real human capture")
        LekmodScenarioRecord("city-liberation","PASS","path=actual-capture-popup-choice restored-owner="..minorID)
        issuedTurn=Game.GetGameTurn();phase="finish";return "turn"
    elseif phase=="finish" then
        if Game.GetGameTurn()==issuedTurn then return "turn" end
        assert(Game.GetWinner()==-1,"city lifecycle fixture accidentally ended the game")
        return true
    end
    return false
end
