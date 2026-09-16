-- Faith, a legal secondary city and a foreign missionary are supplied inputs.
-- Purchase, spread and removal use normal callbacks/missions; no pressure,
-- followers, unit charges or defense outcome is assigned.
LekmodScenario={name="religion-defense",items={"inquisitor-purchase","inquisitor-defense","foreign-religion-spread","remove-heresy","inquisitor-retention","inquisitor-restrictions"}}
local phase,ownReligion,foreignReligion,foreignOwner,foreignCity,targetID,inqID,missionaryID,cost,faithBefore,response,pendingSpread,spreadError,beforeSpreads,issuedTurn,foreignCenterAllowed,pressureBefore="init"
local purchased={}
local spreadMission=GameInfoTypes.MISSION_SPREAD_RELIGION
local removeMission=GameInfoTypes.MISSION_REMOVE_HERESY
LuaEvents.LekmodScenarioReligionResponse.Add(function(kind,id) response={kind=kind,id=id} end)
GameEvents.CityTrained.Add(function(owner,city,id,gold,faith)
    if owner==Game.GetActivePlayer() and faith and not gold then purchased[id]=true end
end)
GameEvents.PlayerDoTurn.Add(function(owner)
    if owner~=foreignOwner or not pendingSpread then return end
    pendingSpread=false
    local ok,err=pcall(function()
        local p=Players[owner];local u=assert(p:GetUnitByID(missionaryID))
        assert(p:IsTurnActive() and u:CanStartMission(spreadMission,-1,-1,u:GetPlot(),0),"foreign spread is not legal on the real owner turn")
        LekmodScenarioEvent("foreign-spread-command",{owner=owner,unit=missionaryID,spreads=u:GetSpreadsLeft(),strength=u:GetConversionStrength()})
        u:PushMission(spreadMission,-1,-1,0,0,1)
    end)
    if not ok then spreadError=tostring(err) end
end)
local function action(unit,kind)
    UI.SelectUnit(unit)
    for i=0,#GameInfoActions do if GameInfoActions[i] and GameInfoActions[i].Type==kind then
        assert(Game.CanHandleAction(i),"religious action is unavailable: "..kind);Game.HandleAction(i);return
    end end
    error("religious action missing: "..kind)
end
local function stage(unit,plot,reason)
    unit:SetXY(plot:GetX(),plot:GetY(),false,true,false,false)
    LekmodScenarioEvent("fixture-setup",{operation=reason,owner=unit:GetOwner(),unit=unit:GetID(),x=unit:GetX(),y=unit:GetY()})
end
function LekmodScenario.snapshot(player)
    local cities,units={},{}
    for c in player:Cities() do local religions={}
        for r in GameInfo.Religions() do religions[r.ID]={followers=c:GetNumFollowers(r.ID),pressure=c:GetReligionPressure(r.ID)} end
        cities[c:GetID()]={majority=c:GetReligiousMajority(),religions=religions,population=c:GetPopulation()}
    end
    for owner=0,GameDefines.MAX_CIV_PLAYERS-1 do local p=Players[owner]
        if p and p:IsAlive() then for u in p:Units() do if u:GetReligion()>0 then
            units[owner..":"..u:GetID()]={type=u:GetUnitType(),religion=u:GetReligion(),spreads=u:GetSpreadsLeft(),x=u:GetX(),y=u:GetY(),moves=u:GetMoves()}
        end end end
    end
    return {turn=Game.GetGameTurn(),faith=player:GetFaith(),religion=player:GetReligionCreatedByPlayer(),cities=cities,units=units}
end
function LekmodScenario.step(player)
    assert(not spreadError,spreadError)
    local capital=assert(player:GetCapitalCity())
    if phase=="init" then
        ownReligion=player:GetReligionCreatedByPlayer();assert(ownReligion>0,"load the founded/enhanced religion fixture")
        for owner=0,GameDefines.MAX_MAJOR_CIVS-1 do local p=Players[owner]
            if p and p:IsAlive() and owner~=player:GetID() and not Teams[player:GetTeam()]:IsAtWar(p:GetTeam()) then
                for c in p:Cities() do local r=c:GetReligiousMajority()
                    if r>0 and r~=ownReligion then
                        local retention=0
                        for _,belief in ipairs(Game.GetBeliefsInReligion(r)) do retention=retention+(GameInfo.Beliefs[belief].InquisitorPressureRetention or 0) end
                        if retention==0 then foreignOwner,foreignCity,foreignReligion=owner,c:GetID(),r;break end
                    end
                end
            end
            if foreignOwner then break end
        end
        assert(foreignOwner,"fixture has no other major's religion without a pressure-retention belief")
        local site
        for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i)
            local distance=Map.PlotDistance(capital:GetX(),capital:GetY(),p:GetX(),p:GetY())
            if distance>=4 and distance<=8 and p:GetArea()==capital:Plot():GetArea() and p:GetOwner()==-1
                and p:GetNumUnits()==0 and player:CanFound(p:GetX(),p:GetY()) then site=p;break end
        end
        assert(site,"no legal secondary religion target city")
        player:Found(site:GetX(),site:GetY());targetID=site:GetPlotCity():GetID()
        LekmodScenarioEvent("fixture-setup",{operation="provided-own-secondary-city",city=targetID,x=site:GetX(),y=site:GetY()})
        cost=capital:GetUnitFaithPurchaseCost(GameInfoTypes.UNIT_INQUISITOR,true)
        local old=player:GetFaith();player:ChangeFaith(cost);faithBefore=player:GetFaith()
        LekmodScenarioEvent("fixture-setup",{operation="provided-faith",before=old,added=cost})
        assert(capital:IsCanPurchase(true,true,GameInfoTypes.UNIT_INQUISITOR,-1,-1,YieldTypes.YIELD_FAITH),"inquisitor purchase unavailable")
        response=nil;LuaEvents.LekmodScenarioFaithPurchase(capital:GetID(),GameInfoTypes.UNIT_INQUISITOR);phase="purchase"
    elseif phase=="purchase" then
        if not response then return false end
        if not LekmodScenarioAwait("inquisitor-faith-spent",player:GetFaith()==faithBefore-cost) then return false end
        for u in player:Units() do if purchased[u:GetID()] and u:GetUnitType()==GameInfoTypes.UNIT_INQUISITOR then inqID=u:GetID();break end end
        local inq=assert(inqID and player:GetUnitByID(inqID),"purchased inquisitor missing")
        if not LekmodScenarioAwait("inquisitor-ready",not inq:IsBusy()) then return false end
        assert(inq:GetReligion()==ownReligion,"purchased inquisitor inherited the wrong religion")
        LekmodScenarioRecord("inquisitor-purchase","PASS","path=actual-faith-purchase-callback cost="..cost)
        local target=player:GetCityByID(targetID);local source=Players[foreignOwner]:GetCityByID(foreignCity)
        assert(not inq:CanStartMission(removeMission,-1,-1,target:Plot(),0),"inquisitor can purge a city without foreign religion")
        foreignCenterAllowed=inq:CanStartMission(removeMission,-1,-1,source:Plot(),0)
        local foreignAdjacent=Map.PlotDirection(source:GetX(),source:GetY(),0)
        assert(not inq:CanStartMission(removeMission,-1,-1,foreignAdjacent,0),"inquisitor can purge an adjacent foreign city")
        LekmodScenarioEvent("inquisitor-location-queries",{foreign_center=foreignCenterAllowed,foreign_adjacent=false,own_clean=false})
        local other=Players[foreignOwner]
        if not Teams[player:GetTeam()]:IsHasMet(other:GetTeam()) then
            Teams[player:GetTeam()]:Meet(other:GetTeam(),false)
            LekmodScenarioEvent("fixture-setup",{operation="provided-contact",owner=foreignOwner})
        end
        local missionary=assert(other:InitUnit(GameInfoTypes.UNIT_MISSIONARY,source:GetX(),source:GetY()));missionaryID=missionary:GetID()
        assert(missionary:GetReligion()==foreignReligion and missionary:GetSpreadsLeft()>0,"foreign missionary did not inherit its source religion")
        LekmodScenarioEvent("fixture-setup",{operation="provided-foreign-missionary",owner=foreignOwner,unit=missionaryID,religion=foreignReligion,source_city=foreignCity})
        local site
        for d=0,5 do local p=Map.PlotDirection(target:GetX(),target:GetY(),d)
            if p and not p:IsWater() and not p:IsMountain() and p:GetNumUnits()==0 then site=p;break end
        end
        assert(site,"no missionary staging tile beside own target")
        stage(missionary,site,"position-foreign-missionary")
        stage(inq,target:Plot(),"position-defending-inquisitor")
        assert(not missionary:CanStartMission(spreadMission,-1,-1,missionary:GetPlot(),0),"inquisitor failed to prevent foreign spread")
        local same=assert(player:InitUnit(GameInfoTypes.UNIT_MISSIONARY,capital:GetX(),capital:GetY()))
        LekmodScenarioEvent("fixture-setup",{operation="provided-own-religion-query-control",unit=same:GetID(),religion=same:GetReligion()})
        assert(same:GetReligion()==ownReligion and same:CanStartMission(spreadMission,-1,-1,missionary:GetPlot(),0),"inquisitor blocked its own religion")
        stage(inq,capital:Plot(),"position-inquisitor-away-from-target")
        assert(Map.PlotDistance(inq:GetX(),inq:GetY(),target:GetX(),target:GetY())>1,"inquisitor remains in defense range")
        assert(missionary:CanStartMission(spreadMission,-1,-1,missionary:GetPlot(),0),"removing defense did not enable foreign spread")
        LekmodScenarioRecord("inquisitor-defense","PASS","foreign-blocked same-religion-allowed away-enables-spread=true")
        beforeSpreads=missionary:GetSpreadsLeft();issuedTurn=Game.GetGameTurn();pendingSpread=true;phase="spread";return "turn"
    elseif phase=="spread" then
        local target=assert(player:GetCityByID(targetID));local missionary=Players[foreignOwner]:GetUnitByID(missionaryID)
        if pendingSpread or target:GetReligionPressure(foreignReligion)<=0 then
            assert(Game.GetGameTurn()-issuedTurn<3,"foreign missionary did not spread during its ordinary owner turn");return "turn"
        end
        assert((missionary and missionary:GetSpreadsLeft()==beforeSpreads-1) or (not missionary and beforeSpreads==1),"foreign spread did not consume one charge")
        LekmodScenarioEvent("foreign-spread-result",{pressure=target:GetReligionPressure(foreignReligion),followers=target:GetNumFollowers(foreignReligion),majority=target:GetReligiousMajority()})
        assert(target:GetNumFollowers(foreignReligion)>0,"foreign missionary did not establish any followers")
        LekmodScenarioRecord("foreign-religion-spread","PASS","path=actual-owner-turn-mission charges-consumed=1")
        local inq=assert(player:GetUnitByID(inqID));if inq:GetMoves()<=0 then return "turn" end
        stage(inq,target:Plot(),"position-inquisitor-for-owned-city-removal")
        assert(inq:CanStartMission(removeMission,-1,-1,inq:GetPlot(),0),"inquisitor cannot remove foreign religion in own city")
        pressureBefore={}
        for r in GameInfo.Religions() do
            local pressure=target:GetReligionPressure(r.ID)
            if pressure>0 then
                local retention=0
                if r.ID==ownReligion then retention=100
                elseif r.ID>0 then
                    for _,belief in ipairs(Game.GetBeliefsInReligion(r.ID)) do retention=retention+(GameInfo.Beliefs[belief].InquisitorPressureRetention or 0) end
                end
                pressureBefore[r.ID]={before=pressure,retention=retention,expected=math.floor(pressure*retention/100)}
            end
        end
        LekmodScenarioEvent("inquisitor-pressure-before",pressureBefore)
        action(inq,"MISSION_REMOVE_HERESY");phase="removed"
    elseif phase=="removed" then
        local target=assert(player:GetCityByID(targetID));local inq=player:GetUnitByID(inqID)
        if not LekmodScenarioAwait("inquisitor-consumed",not inq or inq:IsDead() or inq:IsDelayedDeath()) then return false end
        assert(target:GetReligionPressure(foreignReligion)==0 and target:GetNumFollowers(foreignReligion)==0,"inquisitor retained foreign religion without a retention belief")
        LekmodScenarioRecord("remove-heresy","PASS","path=actual-unit-action foreign-pressure-followers=0 unit-consumed=true")
        local retained=0
        for religion,expected in pairs(pressureBefore) do
            local actual=target:GetReligionPressure(religion)
            assert(actual==expected.expected,"inquisitor pressure differs from the religion's retention rule")
            if religion~=ownReligion and expected.retention>0 then retained=retained+1 end
        end
        assert(retained>0,"fixture had no positive foreign-pressure retention case")
        LekmodScenarioRecord("inquisitor-retention","PASS","path=actual-removal foreign-retention-cases="..retained)
        assert(not foreignCenterAllowed,"inquisitor's mission eligibility incorrectly permits purging a foreign city center")
        LekmodScenarioRecord("inquisitor-restrictions","PASS","foreign-center-foreign-adjacent-clean-own-city=rejected")
        return true
    end
    return false
end
