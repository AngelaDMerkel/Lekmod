-- Labeled test setup supplies faith and two prophets. Found/enhance/spread
-- missions and the purchase use normal legal actions; no outcome is injected.
LekmodScenario={name="religion",items={"pantheon","religion-found","religion-enhance","faith-purchase","religion-spread"}}
local phase,response,prophetID,missionaryID,faithBefore,cost,oldSpreads,oldFollowers,oldPressure,targetOwner,targetID="init"
local purchased={}
LuaEvents.LekmodScenarioReligionResponse.Add(function(kind,value) response={kind=kind,value=value} end)
GameEvents.CityTrained.Add(function(owner,city,id,gold,faith)
    if owner==Game.GetActivePlayer() and not gold and faith then purchased[id]=true end
end)
local function action(unit,kind)
    UI.SelectUnit(unit)
    for id=0,#GameInfoActions do
        if GameInfoActions[id] and GameInfoActions[id].Type==kind then
            assert(Game.CanHandleAction(id), "religious mission is unavailable: "..kind)
            local unitID=unit:GetID()
            Game.HandleAction(id)
            LekmodScenarioEvent("religious-mission",{unit=unitID,mission=kind,path="normal-action"})
            return
        end
    end
    error("religious mission is missing: "..kind)
end
local function consumed(player,id)
    local unit=player:GetUnitByID(id)
    return not unit or unit:IsDead() or unit:IsDelayedDeath()
end
local function prophet(player,city)
    local unit=player:InitUnit(GameInfoTypes.UNIT_PROPHET,city:GetX(),city:GetY())
    assert(unit, "could not create the scenario's input prophet")
    LekmodScenarioEvent("fixture-setup",{operation="provided-prophet",unit=unit:GetID(),x=city:GetX(),y=city:GetY()})
    return unit:GetID()
end
function LekmodScenario.snapshot(player)
    local religion=player:GetReligionCreatedByPlayer()
    local result={turn=Game.GetGameTurn(),player=player:GetID(),faith=player:GetFaith(),gold=player:GetGold(),
        pantheon=player:GetBeliefInPantheon(),religion=religion,beliefs={},cities={},units={}}
    if religion>0 then
        result.beliefs=Game.GetBeliefsInReligion(religion)
        for owner=0,GameDefines.MAX_CIV_PLAYERS-1 do
            local p=Players[owner]
            if p and p:IsAlive() then
                for city in p:Cities() do
                    local followers=city:GetNumFollowers(religion)
                    if followers>0 then
                        result.cities[owner..":"..city:GetID()]={followers=followers,majority=city:GetReligiousMajority(),holy=city:IsHolyCityForReligion(religion)}
                    end
                end
            end
        end
    end
    for unit in player:Units() do
        if unit:GetReligion()>0 then
            result.units[unit:GetID()]={type=unit:GetUnitType(),religion=unit:GetReligion(),spreads=unit:GetSpreadsLeft(),moves=unit:MovesLeft(),x=unit:GetX(),y=unit:GetY()}
        end
    end
    return result
end
function LekmodScenario.step(player)
    local city=player:GetCapitalCity()
    assert(city and not Game.IsOption(GameOptionTypes.GAMEOPTION_NO_RELIGION), "scenario requires a religion-enabled capital")
    if phase=="init" then
        assert(not player:HasCreatedPantheon() and not player:HasCreatedReligion(), "fixture already has a pantheon/religion")
        assert(Game.GetNumReligionsStillToFound()>0, "no religion slots remain")
        local before=player:GetFaith()
        local budget=Game.GetMinimumFaithNextPantheon()+city:GetUnitFaithPurchaseCost(GameInfoTypes.UNIT_MISSIONARY,true)+20
        player:ChangeFaith(budget)
        LekmodScenarioEvent("fixture-setup",{operation="provided-faith",before=before,added=budget,after=player:GetFaith()})
        assert(player:CanCreatePantheon(true), "faith-funded pantheon is not legal")
        response=nil; LuaEvents.LekmodScenarioPantheon(); phase="pantheon"
    elseif phase=="pantheon" then
        if not response then return false end
        if not LekmodScenarioAwait("pantheon",player:HasCreatedPantheon()) then return false end
        assert(response.kind=="pantheon" and player:HasCreatedPantheon() and player:GetBeliefInPantheon()==response.value, "pantheon did not apply")
        LekmodScenarioRecord("pantheon","PASS","path=real-popup-callback belief="..response.value)
        prophetID=prophet(player,city); phase="found-mission"
    elseif phase=="found-mission" or phase=="enhance-mission" then
        local kind=phase=="found-mission" and "found" or "enhance"
        action(assert(player:GetUnitByID(prophetID)),kind=="found" and "MISSION_FOUND_RELIGION" or "MISSION_ENHANCE_RELIGION")
        phase=kind.."-consumed"
    elseif phase=="found-consumed" or phase=="enhance-consumed" then
        if not consumed(player,prophetID) then return false end
        local kind=phase=="found-consumed" and "found" or "enhance"
        response=nil; LuaEvents.LekmodScenarioReligionChoice(kind,city:GetX(),city:GetY()); phase=kind
    elseif phase=="found" then
        if not response then return false end
        if not LekmodScenarioAwait("religion-founded",player:HasCreatedReligion()) then return false end
        local religion=player:GetReligionCreatedByPlayer()
        assert(response.kind=="found" and religion==response.value and city:IsHolyCityForReligion(religion), "religion/holy city did not apply")
        assert(city:GetNumFollowers(religion)>0 and #Game.GetBeliefsInReligion(religion)>=3, "religion beliefs/followers missing")
        LekmodScenarioRecord("religion-found","PASS","path=prophet-mission-and-popup religion="..religion.." prophet-consumed=true")
        prophetID=prophet(player,city); phase="enhance-mission"
    elseif phase=="enhance" then
        if not response then return false end
        if not LekmodScenarioAwait("religion-enhanced",#Game.GetBeliefsInReligion(player:GetReligionCreatedByPlayer())>=5) then return false end
        assert(response.kind=="enhance" and #Game.GetBeliefsInReligion(player:GetReligionCreatedByPlayer())>=5, "enhancement beliefs missing")
        LekmodScenarioRecord("religion-enhance","PASS","path=prophet-mission-and-popup prophet-consumed=true")
        assert(city:IsCanPurchase(true,true,GameInfoTypes.UNIT_MISSIONARY,-1,-1,YieldTypes.YIELD_FAITH), "missionary purchase is not legal")
        faithBefore,cost=player:GetFaith(),city:GetUnitFaithPurchaseCost(GameInfoTypes.UNIT_MISSIONARY,true)
        response=nil; LuaEvents.LekmodScenarioFaithPurchase(city:GetID(),GameInfoTypes.UNIT_MISSIONARY); phase="purchase"
    elseif phase=="purchase" then
        if not response then return false end
        if not LekmodScenarioAwait("faith-spent",player:GetFaith()==faithBefore-cost) then return false end
        assert(response.kind=="purchase" and player:GetFaith()==faithBefore-cost, "faith purchase cost mismatch")
        for unit in player:Units() do
            if purchased[unit:GetID()] and unit:GetUnitType()==GameInfoTypes.UNIT_MISSIONARY then missionaryID=unit:GetID(); break end
        end
        local unit=assert(missionaryID and player:GetUnitByID(missionaryID), "purchased missionary missing")
        assert(unit:GetReligion()==player:GetReligionCreatedByPlayer() and unit:GetSpreadsLeft()>0, "missionary religion/spreads missing")
        LekmodScenarioRecord("faith-purchase","PASS","path=production-popup-callback unit="..missionaryID.." faith-spent="..cost)
        -- Position this purchased unit for the spread test; travel itself is
        -- explicitly not under test. Choose a known non-religious foreign city.
        local destination
        for owner=0,GameDefines.MAX_CIV_PLAYERS-1 do
            local other=Players[owner]
            if other and other:IsAlive() and owner~=player:GetID() and Teams[player:GetTeam()]:IsHasMet(other:GetTeam())
                and not Teams[player:GetTeam()]:IsAtWar(other:GetTeam()) then
                for candidate in other:Cities() do
                    if candidate:GetReligiousMajority()==-1 then destination=candidate; break end
                end
            end
            if destination then break end
        end
        assert(destination, "fixture has no known non-religious foreign city")
        local plot
        for direction=0,5 do
            local candidate=Map.PlotDirection(destination:GetX(),destination:GetY(),direction)
            if candidate and not candidate:IsWater() and not candidate:IsMountain() and candidate:GetNumUnits()==0 then plot=candidate; break end
        end
        assert(plot, "no staging plot beside spread target")
        targetOwner,targetID=destination:GetOwner(),destination:GetID()
        unit:SetXY(plot:GetX(),plot:GetY(),false,true,false,false)
        assert(unit:GetX()==plot:GetX() and unit:GetY()==plot:GetY(), "missionary staging position did not apply")
        LekmodScenarioEvent("fixture-setup",{operation="position-purchased-missionary",unit=missionaryID,x=unit:GetX(),y=unit:GetY(),moves=unit:MovesLeft(),target_owner=targetOwner,target_city=targetID})
        phase="spread-mission"
    elseif phase=="spread-mission" then
        local unit=assert(player:GetUnitByID(missionaryID))
        if unit:MovesLeft()==0 then return "turn" end
        local target=Players[targetOwner]:GetCityByID(targetID)
        oldFollowers=target:GetNumFollowers(player:GetReligionCreatedByPlayer())
        oldPressure=target:GetReligionPressure(player:GetReligionCreatedByPlayer())
        oldSpreads=unit:GetSpreadsLeft()
        LekmodScenarioEvent("spread-before",{moves=unit:MovesLeft(),spreads=oldSpreads,pressure=oldPressure,followers=oldFollowers,strength=unit:GetConversionStrength()})
        action(unit,"MISSION_SPREAD_RELIGION"); phase="spread-verify"
    elseif phase=="spread-verify" then
        local target=Players[targetOwner]:GetCityByID(targetID)
        local followers=target:GetNumFollowers(player:GetReligionCreatedByPlayer())
        local unit=player:GetUnitByID(missionaryID)
        local pressure=target:GetReligionPressure(player:GetReligionCreatedByPlayer())
        LekmodScenarioEvent("spread-after",{followers=followers,pressure=pressure,spreads=unit and unit:GetSpreadsLeft() or -1})
        assert(pressure>oldPressure, "spread did not increase religious pressure")
        assert(followers>oldFollowers, "spread did not increase followers in this fixture")
        assert((unit and unit:GetSpreadsLeft()==oldSpreads-1) or (not unit and oldSpreads==1), "spread charge was not consumed")
        LekmodScenarioRecord("religion-spread","PASS","path=normal-mission followers-before="..oldFollowers.." followers-after="..followers.." charges-consumed=1")
        return true
    end
    return false
end
