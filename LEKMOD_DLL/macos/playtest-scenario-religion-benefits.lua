-- Existing founded religion and normal missionary/purchase actions. A legal
-- city, missionary, raw luxury node and exact faith budgets are supplied inputs.
LekmodScenario={name="religion-benefits",items={"religion-purchase-restrictions","first-conversion-gold","faith-building-purchase","mandir-luxury-yields","holy-warriors-purchase"}}
local phase,cityID,missionaryID,unitType,goldBefore,expectedGold,faithBefore,cost,response,luxuryIndex,foodBefore,productionBefore="init"
local purchased={}
local building=GameInfoTypes.BUILDING_MANDIR
LuaEvents.LekmodScenarioCityResponse.Add(function(kind,id) response={kind=kind,id=id} end)
LuaEvents.LekmodScenarioReligionResponse.Add(function(kind,id) response={kind=kind,id=id} end)
GameEvents.CityTrained.Add(function(owner,city,id,gold,faith)
    if owner==Game.GetActivePlayer() and city==cityID and faith and not gold then purchased[id]=true end
end)
local function spread(unit)
    UI.SelectUnit(unit)
    for i=0,#GameInfoActions do if GameInfoActions[i] and GameInfoActions[i].Type=="MISSION_SPREAD_RELIGION" then
        assert(Game.CanHandleAction(i),"normal missionary spread unavailable");Game.HandleAction(i);return
    end end
    error("spread action missing")
end
function LekmodScenario.snapshot(player)
    local cities,units,plots={},{},{}
    for c in player:Cities() do
        cities[c:GetID()]={religion=c:GetReligiousMajority(),mandir=c:GetNumRealBuilding(building),population=c:GetPopulation(),
            pressure=c:GetReligionPressure(player:GetReligionCreatedByPlayer()),followers=c:GetNumFollowers(player:GetReligionCreatedByPlayer())}
        if c:GetNumRealBuilding(building)>0 then
            for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i);local working=p:GetWorkingCity()
                if p:GetOwner()==player:GetID() and working and working:GetID()==c:GetID() and p:GetResourceType(-1)~=-1 then
                    plots[i]={resource=p:GetResourceType(-1),food=p:CalculateYield(YieldTypes.YIELD_FOOD,true),production=p:CalculateYield(YieldTypes.YIELD_PRODUCTION,true)}
                end
            end
        end
    end
    for u in player:Units() do units[u:GetID()]={type=u:GetUnitType(),x=u:GetX(),y=u:GetY(),religion=u:GetReligion(),spreads=u:GetSpreadsLeft()} end
    return {turn=Game.GetGameTurn(),gold=player:GetGold(),faith=player:GetFaith(),cities=cities,units=units,plots=plots}
end
function LekmodScenario.step(player)
    local religion=player:GetReligionCreatedByPlayer();local capital=assert(player:GetCapitalCity())
    if phase=="init" then
        local beliefs={}
        for _,id in ipairs(Game.GetBeliefsInReligion(religion)) do beliefs[GameInfo.Beliefs[id].Type]=true end
        assert(beliefs.BELIEF_PROMISED_LAND and beliefs.BELIEF_MANDIRS and beliefs.BELIEF_HOLY_WARRIORS,"load the recorded three-belief fixture")
        local site
        for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i)
            local distance=Map.PlotDistance(capital:GetX(),capital:GetY(),p:GetX(),p:GetY())
            if distance>=4 and distance<=12 and p:GetArea()==capital:Plot():GetArea() and p:GetOwner()==-1
                and p:GetNumUnits()==0 and player:CanFound(p:GetX(),p:GetY()) then site=p;break end
        end
        assert(site,"no legal new conversion city")
        player:Found(site:GetX(),site:GetY());local city=assert(site:GetPlotCity());cityID=city:GetID()
        LekmodScenarioEvent("fixture-setup",{operation="provided-new-conversion-city",city=cityID,x=city:GetX(),y=city:GetY()})
        assert(city:GetReligiousMajority()==-1,"new city already follows a religion")
        for _,name in ipairs({"UNIT_SPEARMAN","UNIT_ARCHER","UNIT_COMPOSITE_BOWMAN","UNIT_CROSSBOWMAN","UNIT_PIKEMAN","UNIT_ROMAN_LEGION","UNIT_LONGSWORDSMAN","UNIT_MUSKETMAN"}) do
            local id=GameInfoTypes[name]
            if id and city:CanTrain(id) and capital:IsCanPurchase(false,true,id,-1,-1,YieldTypes.YIELD_FAITH) then unitType=id;break end
        end
        assert(unitType,"no legal Holy Warriors unit in the current tech/resource state")
        assert(not city:IsCanPurchase(false,true,unitType,-1,-1,YieldTypes.YIELD_FAITH),"unconverted city can use the other city's unit-purchase belief")
        assert(not city:IsCanPurchase(false,true,-1,building,-1,YieldTypes.YIELD_FAITH),"unconverted city can purchase belief-unlocked Mandir")
        LekmodScenarioRecord("religion-purchase-restrictions","PASS","no-majority-city faith-building-and-military-unit=rejected")
        local missionary=assert(player:InitUnit(GameInfoTypes.UNIT_MISSIONARY,capital:GetX(),capital:GetY()));missionaryID=missionary:GetID()
        assert(missionary:GetReligion()==religion,"missionary inherited the wrong source religion")
        local adjacent
        for d=0,5 do local p=Map.PlotDirection(city:GetX(),city:GetY(),d)
            if p and not p:IsWater() and not p:IsMountain() and p:GetNumUnits()==0 then adjacent=p;break end
        end
        assert(adjacent,"no legal missionary staging plot")
        missionary:SetXY(adjacent:GetX(),adjacent:GetY(),false,true,false,false)
        LekmodScenarioEvent("fixture-setup",{operation="provided-positioned-missionary",unit=missionaryID,x=missionary:GetX(),y=missionary:GetY(),religion=religion})
        goldBefore=player:GetGold()
        expectedGold=math.floor(GameInfo.Beliefs.BELIEF_PROMISED_LAND.GoldPerFirstCityConversion*GameInfo.GameSpeeds[Game.GetGameSpeedType()].TrainPercent/100)
        assert(expectedGold>0,"founder bonus is missing")
        spread(missionary);phase="converted"
    elseif phase=="converted" then
        local city=assert(player:GetCityByID(cityID))
        if not LekmodScenarioAwait("own-city-converted",city:GetReligiousMajority()==religion) then return false end
        assert(player:GetGold()==goldBefore+expectedGold,"first conversion did not award the data-defined speed-scaled gold")
        LekmodScenarioRecord("first-conversion-gold","PASS","path=actual-spread gold="..expectedGold)
        assert(city:IsCanPurchase(false,true,-1,building,-1,YieldTypes.YIELD_FAITH),"conversion did not unlock the Mandir")
        assert(city:IsCanPurchase(false,true,unitType,-1,-1,YieldTypes.YIELD_FAITH),"conversion did not unlock the military faith purchase")
        local plot
        for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i);local working=p:GetWorkingCity()
            if p:GetOwner()==player:GetID() and working and working:GetID()==cityID and not p:IsCity()
                and not p:IsWater() and not p:IsMountain() and p:GetResourceType(-1)==-1 and p:GetFeatureType()==-1 and p:GetImprovementType()==-1 then plot=p;break end
        end
        assert(plot,"no bare owned plot assigned to the new city for the luxury-yield boundary")
        plot:SetResourceType(GameInfoTypes.RESOURCE_GEMS,1);luxuryIndex=plot:GetPlotIndex()
        LekmodScenarioEvent("fixture-setup",{operation="provided-raw-luxury-node",resource=GameInfoTypes.RESOURCE_GEMS,plot=luxuryIndex,x=plot:GetX(),y=plot:GetY()})
        foodBefore=plot:CalculateYield(YieldTypes.YIELD_FOOD,true);productionBefore=plot:CalculateYield(YieldTypes.YIELD_PRODUCTION,true)
        cost=city:GetBuildingFaithPurchaseCost(building)
        local old=player:GetFaith();player:ChangeFaith(cost);faithBefore=player:GetFaith()
        LekmodScenarioEvent("fixture-setup",{operation="provided-building-faith-budget",before=old,added=cost})
        response=nil;LuaEvents.LekmodScenarioFaithBuildingPurchase(cityID,building);phase="mandir"
    elseif phase=="mandir" then
        if not response then return false end
        local city=assert(player:GetCityByID(cityID))
        if not LekmodScenarioAwait("mandir-purchased",city:GetNumRealBuilding(building)==1) then return false end
        assert(response.id==building and player:GetFaith()==faithBefore-cost,"Mandir purchase did not spend exact faith")
        LekmodScenarioRecord("faith-building-purchase","PASS","path=actual-production-popup-callback cost="..cost)
        local p=Map.GetPlotByIndex(luxuryIndex)
        local foodAfter=p:CalculateYield(YieldTypes.YIELD_FOOD,true);local productionAfter=p:CalculateYield(YieldTypes.YIELD_PRODUCTION,true)
        LekmodScenarioEvent("mandir-luxury-yields",{plot=luxuryIndex,food_before=foodBefore,food_after=foodAfter,production_before=productionBefore,production_after=productionAfter})
        assert(foodAfter==foodBefore+1 and productionAfter==productionBefore+1,"Mandir did not add one food and production to its luxury tile")
        assert(not city:IsCanPurchase(false,true,-1,building,-1,YieldTypes.YIELD_FAITH),"duplicate Mandir purchase is legal")
        LekmodScenarioRecord("mandir-luxury-yields","PASS","potential-tile-food-and-production=+1 duplicate-building=rejected")
        cost=city:GetUnitFaithPurchaseCost(unitType,true)
        local old=player:GetFaith();player:ChangeFaith(cost);faithBefore=player:GetFaith()
        LekmodScenarioEvent("fixture-setup",{operation="provided-unit-faith-budget",before=old,added=cost,unit_type=unitType})
        assert(city:IsCanPurchase(true,true,unitType,-1,-1,YieldTypes.YIELD_FAITH),"Holy Warriors purchase unavailable with sufficient faith")
        response=nil;LuaEvents.LekmodScenarioFaithPurchase(cityID,unitType);phase="unit"
    elseif phase=="unit" then
        if not response then return false end
        if not LekmodScenarioAwait("holy-warriors-faith-spent",player:GetFaith()==faithBefore-cost) then return false end
        local found
        for u in player:Units() do if purchased[u:GetID()] and u:GetUnitType()==unitType then found=u;break end end
        assert(found and response.id==unitType,"faith-purchased military unit missing from the actual CityTrained event")
        LekmodScenarioRecord("holy-warriors-purchase","PASS","path=actual-production-popup-callback unit="..found:GetID().." type="..unitType.." cost="..cost)
        return true
    end
    return false
end
