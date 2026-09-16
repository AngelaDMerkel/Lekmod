-- Load an actually paid first-conversion bonus. Supplied prophets use normal
-- spreads; test that save/reload and conversion away/back cannot repeat gold.
LekmodScenario={name="religion-reconversion",items={"prophet-foreign-conversion","conversion-bonus-no-repeat","religious-building-retained"}}
local phase,cityID,foreignOwner,foreignReligion,foreignUnit,ownUnit,pending,commandError,started,goldBefore,plots="init"
local building=GameInfoTypes.BUILDING_MANDIR
local function luxuryState(player,city)
    local result={}
    for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i);local c=p:GetWorkingCity()
        if p:GetOwner()==player:GetID() and c and c:GetID()==city:GetID() and p:GetResourceType(-1)~=-1 then
            result[i]={food=p:CalculateYield(YieldTypes.YIELD_FOOD,true),production=p:CalculateYield(YieldTypes.YIELD_PRODUCTION,true)}
        end
    end
    return result
end
GameEvents.PlayerDoTurn.Add(function(owner)
    if owner~=foreignOwner or not pending then return end
    pending=false
    local ok,err=pcall(function()
        local p=Players[owner];local u=assert(p:GetUnitByID(foreignUnit))
        assert(p:IsTurnActive() and u:CanStartMission(GameInfoTypes.MISSION_SPREAD_RELIGION,-1,-1,u:GetPlot(),0),"foreign prophet spread is not legal on its active turn")
        u:PushMission(GameInfoTypes.MISSION_SPREAD_RELIGION,-1,-1,0,0,1)
    end)
    if not ok then commandError=tostring(err) end
end)
function LekmodScenario.snapshot(player)
    local cities,units={},{}
    for c in player:Cities() do cities[c:GetID()]={majority=c:GetReligiousMajority(),mandir=c:GetNumRealBuilding(building),plots=luxuryState(player,c)} end
    for u in player:Units() do if u:GetReligion()>0 then units[u:GetID()]={type=u:GetUnitType(),religion=u:GetReligion(),spreads=u:GetSpreadsLeft(),x=u:GetX(),y=u:GetY()} end end
    return {turn=Game.GetGameTurn(),gold=player:GetGold(),faith=player:GetFaith(),cities=cities,units=units}
end
local function verifyBuilding(player)
    local c=assert(player:GetCityByID(cityID));assert(c:GetNumRealBuilding(building)==1,"conversion removed the purchased Mandir")
    local current=luxuryState(player,c)
    for index,before in pairs(plots) do
        assert(current[index] and current[index].food==before.food and current[index].production==before.production,"religion change altered the Mandir's intrinsic tile yields")
    end
end
function LekmodScenario.step(player)
    assert(not commandError,commandError)
    local religion=player:GetReligionCreatedByPlayer()
    if phase=="init" then
        for c in player:Cities() do if c:GetNumRealBuilding(building)==1 then assert(not cityID,"fixture has multiple Mandirs");cityID=c:GetID() end end
        local city=assert(cityID and player:GetCityByID(cityID),"load the first-conversion/Mandir fixture")
        assert(city:GetReligiousMajority()==religion,"Mandir city no longer follows the founder religion")
        local source
        for owner=0,GameDefines.MAX_MAJOR_CIVS-1 do local p=Players[owner]
            if p and p:IsAlive() and owner~=player:GetID() and not Teams[player:GetTeam()]:IsAtWar(p:GetTeam()) then
                for c in p:Cities() do if c:GetReligiousMajority()>0 and c:GetReligiousMajority()~=religion then foreignOwner,foreignReligion,source=owner,c:GetReligiousMajority(),c;break end end
            end
            if source then break end
        end
        assert(source,"no other religion's source city")
        local enemy=assert(Players[foreignOwner]:InitUnit(GameInfoTypes.UNIT_PROPHET,source:GetX(),source:GetY()));foreignUnit=enemy:GetID()
        local capital=player:GetCapitalCity();local own=assert(player:InitUnit(GameInfoTypes.UNIT_PROPHET,capital:GetX(),capital:GetY()));ownUnit=own:GetID()
        assert(enemy:GetReligion()==foreignReligion and own:GetReligion()==religion,"provided prophets inherited incorrect religions")
        local staging
        for d=0,5 do local p=Map.PlotDirection(city:GetX(),city:GetY(),d)
            if p and not p:IsWater() and not p:IsMountain() and p:GetNumUnits()==0 then staging=p;break end
        end
        assert(staging,"no foreign-prophet staging plot")
        enemy:SetXY(staging:GetX(),staging:GetY(),false,true,false,false)
        own:SetXY(city:GetX(),city:GetY(),false,true,false,false)
        LekmodScenarioEvent("fixture-setup",{operation="provided-positioned-prophets",foreign_owner=foreignOwner,foreign_unit=foreignUnit,foreign_religion=foreignReligion,own_unit=ownUnit,city=cityID})
        plots=luxuryState(player,city);started=Game.GetGameTurn();pending=true;phase="foreign";return "turn"
    elseif phase=="foreign" then
        local city=assert(player:GetCityByID(cityID))
        if city:GetReligiousMajority()~=foreignReligion then assert(Game.GetGameTurn()-started<3,"foreign prophet did not convert the city");return "turn" end
        local enemy=assert(Players[foreignOwner]:GetUnitByID(foreignUnit))
        assert(enemy:GetSpreadsLeft()==GameInfo.Units.UNIT_PROPHET.ReligionSpreads-1,"foreign prophet did not spend one charge")
        verifyBuilding(player)
        LekmodScenarioRecord("prophet-foreign-conversion","PASS","path=actual-owner-turn-spread majority="..foreignReligion)
        local own=assert(player:GetUnitByID(ownUnit));assert(own:GetX()==city:GetX() and own:GetY()==city:GetY(),"own prophet moved from its supplied city position")
        if own:GetMoves()<=0 then return "turn" end
        goldBefore=player:GetGold();UI.SelectUnit(own)
        local action
        for i=0,#GameInfoActions do if GameInfoActions[i] and GameInfoActions[i].Type=="MISSION_SPREAD_RELIGION" then action=i;break end end
        assert(action and Game.CanHandleAction(action),"normal reconversion action unavailable")
        Game.HandleAction(action);phase="restored"
    elseif phase=="restored" then
        local city=assert(player:GetCityByID(cityID))
        if not LekmodScenarioAwait("religion-restored",city:GetReligiousMajority()==religion) then return false end
        assert(player:GetGold()==goldBefore,"reconversion repeated a first-city adoption reward after save/reload")
        local own=assert(player:GetUnitByID(ownUnit));assert(own:GetSpreadsLeft()==GameInfo.Units.UNIT_PROPHET.ReligionSpreads-1,"own prophet did not spend one charge")
        verifyBuilding(player)
        LekmodScenarioRecord("conversion-bonus-no-repeat","PASS","path=actual-reconversion-after-reload gold-delta=0")
        LekmodScenarioRecord("religious-building-retained","PASS","mandir-and-tile-yields unchanged-through-both-conversions=true")
        return true
    end
    return false
end
