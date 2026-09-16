-- Supplied city/museums/Artists; creation and movement use normal actions and
-- the same move command as CultureOverview. No work or theming value is set.
LekmodScenario={name="greatworks",items={"art-created","museum-themed","great-work-swap","great-work-cross-city","theming-removed","theming-restored"}}
local phase,otherCity,artist,known,before,panelWait,panelClosed,pending,placed,themedTourism="init",nil,nil,{},nil,0,false,nil,1
local created={}
local museum=GameInfoTypes.BUILDINGCLASS_MUSEUM
LuaEvents.LekmodCultureGreatWorkClosed.Add(function() panelClosed=true end)
local function slots(player)
    local result={}
    for city in player:Cities() do
        for info in GameInfo.Buildings() do
            if info.GreatWorkCount>0 and city:GetNumBuilding(info.ID)>0 then
                local class=GameInfo.BuildingClasses[info.BuildingClass].ID
                for slot=0,info.GreatWorkCount-1 do
                    result[#result+1]={city=city:GetID(),class=class,slot=slot,work=city:GetBuildingGreatWork(class,slot),kind=info.GreatWorkSlotType}
                end
            end
        end
    end
    return result
end
local function location(player,id)
    for _,row in ipairs(slots(player)) do if row.work==id then return row end end
    error("created work no longer belongs to the player: "..id)
end
local function move(player,id,city,class,slot)
    local from=location(player,id)
    assert(GameInfo.Buildings.BUILDING_MUSEUM.GreatWorkSlotType=="GREAT_WORK_SLOT_ART_ARTIFACT")
    assert(from.kind=="GREAT_WORK_SLOT_ART_ARTIFACT","art is in an incompatible slot")
    if from.city==city and from.class==class and from.slot==slot then return true end
    pending={id=id,city=city,class=class,slot=slot}
    Network.SendMoveGreatWorks(player:GetID(),from.city,from.class,from.slot,city,class,slot)
    return false
end
local function moved(player)
    if not pending then return true end
    local row=location(player,pending.id)
    if not LekmodScenarioAwait("great-work-move",row.city==pending.city and row.class==pending.class and row.slot==pending.slot) then return false end
    pending=nil;return true
end
function LekmodScenario.snapshot(player)
    local works,holdings,cities={},{},{}
    for _,row in ipairs(slots(player)) do
        holdings[row.city..":"..row.class..":"..row.slot]=row.work
        if row.work>=0 then works[row.work]={class=Game.GetGreatWorkClass(row.work),era=Game.GetGreatWorkEra(row.work),creator=Game.GetGreatWorkCreator(row.work),controller=Game.GetGreatWorkController(row.work)} end
    end
    for city in player:Cities() do cities[city:GetID()]={works=city:GetNumGreatWorks(),museum_theme=city:GetThemingBonus(museum),tourism=city:GetBaseTourism()} end
    return {turn=Game.GetGameTurn(),works=works,holdings=holdings,cities=cities,total=player:GetNumGreatWorks()}
end
function LekmodScenario.step(player)
    local city=assert(player:GetCapitalCity())
    if phase=="init" then
        assert(player:GetNumGreatWorks()==0,"fixture must begin without existing works")
        local site
        for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i)
            local distance=Map.PlotDistance(city:GetX(),city:GetY(),p:GetX(),p:GetY())
            if distance>=4 and distance<=8 and p:GetArea()==city:Plot():GetArea() and p:GetOwner()==-1 and p:GetNumUnits()==0 and player:CanFound(p:GetX(),p:GetY()) then site=p;break end
        end
        assert(site,"no legal second-city input location")
        player:Found(site:GetX(),site:GetY());otherCity=assert(site:GetPlotCity()):GetID()
        LekmodScenarioEvent("fixture-setup",{operation="provided-legal-second-city",city=otherCity,x=site:GetX(),y=site:GetY()})
        for _,c in ipairs({city,player:GetCityByID(otherCity)}) do
            c:SetNumRealBuilding(GameInfoTypes.BUILDING_MUSEUM,1)
            LekmodScenarioEvent("fixture-setup",{operation="provided-museum",city=c:GetID()})
        end
        phase="provide"
    elseif phase=="provide" then
        known={};for _,row in ipairs(slots(player)) do if row.work>=0 then known[row.work]=true end end
        before=player:GetNumGreatWorks()
        local u=assert(player:InitUnit(GameInfoTypes.UNIT_ARTIST,city:GetX(),city:GetY()));artist=u:GetID()
        LekmodScenarioEvent("fixture-setup",{operation="provided-artist",id=artist})
        phase="create"
    elseif phase=="create" then
        UI.SelectUnit(assert(player:GetUnitByID(artist)))
        local found=false
        for i=0,#GameInfoActions do if GameInfoActions[i] and GameInfoActions[i].Type=="MISSION_CREATE_GREAT_WORK" then
            assert(Game.CanHandleAction(i),"normal art creation unavailable");Game.HandleAction(i);found=true;break
        end end
        assert(found,"great-work action missing");panelWait,panelClosed=0,false;phase="created"
    elseif phase=="created" then
        if not LekmodScenarioAwait("created-art",player:GetNumGreatWorks()==before+1) then return false end
        local u=player:GetUnitByID(artist);assert(not u or u:IsDead() or u:IsDelayedDeath(),"art creation did not consume Artist")
        local id
        for _,row in ipairs(slots(player)) do if row.work>=0 and not known[row.work] then assert(not id,"creation added multiple works");id=row.work end end
        assert(id and Game.GetGreatWorkClass(id)==GameInfoTypes.GREAT_WORK_ART,"created object is not art")
        created[#created+1]=id;phase="panel"
    elseif phase=="panel" then
        panelWait=panelWait+1;if panelWait<8 then return false end
        if not panelClosed then LuaEvents.LekmodCultureCloseGreatWork();return false end
        if #created<2 then phase="provide" else
            LekmodScenarioRecord("art-created","PASS","path=two-normal-Artist-actions-and-real-popup-Close")
            phase="place"
        end
    elseif phase=="place" then
        if not moved(player) then return false end
        if placed<=2 then
            local id=created[placed];placed=placed+1
            move(player,id,city:GetID(),museum,placed-2);return false
        end
        assert(city:GetBuildingGreatWork(museum,0)==created[1] and city:GetBuildingGreatWork(museum,1)==created[2],"museum placement differs")
        assert(city:GetThemingBonus(museum)==2,"same-era own artwork pair did not theme the museum")
        themedTourism=city:GetBaseTourism()
        LekmodScenarioRecord("museum-themed","PASS","normal-slot-placement theme=2 tourism="..themedTourism)
        move(player,created[1],city:GetID(),museum,1);phase="swap"
    elseif phase=="swap" then
        if not moved(player) then return false end
        assert(city:GetBuildingGreatWork(museum,0)==created[2] and city:GetThemingBonus(museum)==2,"swap lost second work or theme")
        LekmodScenarioRecord("great-work-swap","PASS","path=CultureOverview-network-command theme-retained=2")
        move(player,created[1],otherCity,museum,0);phase="cross-city"
    elseif phase=="cross-city" then
        if not moved(player) then return false end
        assert(player:GetNumGreatWorks()==2 and city:GetNumGreatWorks()==1 and player:GetCityByID(otherCity):GetNumGreatWorks()==1,"cross-city move duplicated or lost a work")
        LekmodScenarioRecord("great-work-cross-city","PASS","path=CultureOverview-network-command total-retained=2")
        assert(city:GetThemingBonus(museum)==0 and player:GetCityByID(otherCity):GetThemingBonus(museum)==0 and city:GetBaseTourism()<themedTourism,"incomplete museums retain a theme")
        local otherTourism=player:GetCityByID(otherCity):GetBaseTourism()
        LekmodScenarioEvent("split-work-yields",{capital_tourism=city:GetBaseTourism(),other_tourism=otherTourism,themed_tourism=themedTourism})
        assert(city:GetBaseTourism()==2 and otherTourism==2,"split museums do not each yield two tourism for their one artwork")
        LekmodScenarioRecord("theming-removed","PASS","incomplete-museums theme=0")
        move(player,created[1],city:GetID(),museum,1);phase="restore"
    elseif phase=="restore" then
        if not moved(player) then return false end
        assert(city:GetThemingBonus(museum)==2 and city:GetBaseTourism()==themedTourism and player:GetNumGreatWorks()==2,"restoring art did not restore theme/tourism")
        LekmodScenarioRecord("theming-restored","PASS","theme=2 tourism="..themedTourism)
        return true
    end
    return false
end
