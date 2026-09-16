-- Supplied units only. Disposal, gifts and great-person benefits must come
-- from normal unit commands; no treasury, influence or research is assigned.
LekmodScenario={name="unit-utility",items={"unit-disband-cancel","unit-disband","unit-gift","gift-restrictions","merchant-mission","scientist-discovery","engineer-hurry"}}
local phase,id,gold,amount,minor,site,count,influence,tech,research,building,production="init"
local confirmation
LuaEvents.LekmodUnitCommandConfirmed.Add(function(kind,unit,choice) confirmation={kind=kind,id=unit,choice=choice} end)
local function action(unit,kind,choice)
    UI.SelectUnit(unit)
    confirmation=nil;LuaEvents.LekmodConfirmUnitAction(kind,unit:GetID(),choice or "yes")
    for i=0,#GameInfoActions do if GameInfoActions[i] and GameInfoActions[i].Type==kind then
        assert(Game.CanHandleAction(i),"normal action unavailable: "..kind);Game.HandleAction(i);return
    end end
    error("missing action "..kind)
end
local function input(player,kind,plot)
    local u=assert(player:InitUnit(GameInfoTypes[kind],plot:GetX(),plot:GetY()))
    LekmodScenarioEvent("fixture-setup",{operation="provided-unit",type=kind,id=u:GetID(),x=u:GetX(),y=u:GetY()})
    return u:GetID()
end
local function consumed(player)
    local u=player:GetUnitByID(id)
    return not u or u:IsDead() or u:IsDelayedDeath()
end
function LekmodScenario.snapshot(player)
    local units,cities,minors,technologies={},{},{},{}
    for owner=0,GameDefines.MAX_CIV_PLAYERS do local p=Players[owner]
        if p then
            for u in p:Units() do units[owner..":"..u:GetID()]={type=u:GetUnitType(),x=u:GetX(),y=u:GetY(),damage=u:GetDamage()} end
            if p:IsMinorCiv() and p:IsAlive() then minors[owner]=p:GetMinorCivFriendshipWithMajor(player:GetID()) end
        end
    end
    for c in player:Cities() do cities[c:GetID()]={building=c:GetProductionBuilding(),production=c:GetProduction(),population=c:GetPopulation()} end
    local t=Teams[player:GetTeam()]:GetTeamTechs()
    for info in GameInfo.Technologies() do technologies[info.ID]={known=t:HasTech(info.ID),progress=t:GetResearchProgress(info.ID)} end
    return {turn=Game.GetGameTurn(),gold=player:GetGold(),units=units,cities=cities,minors=minors,technologies=technologies,overflow=player:GetOverflowResearch()}
end
function LekmodScenario.step(player)
    local city=assert(player:GetCapitalCity())
    if phase=="init" then
        id=input(player,"UNIT_SCOUT",city:Plot())
        local u=player:GetUnitByID(id);assert(u:CanScrap() and not u:CanGift(),"own-territory disposal/gift eligibility wrong")
        gold=player:GetGold();amount=u:GetScrapGold()
        action(u,"COMMAND_DELETE","no");phase="cancelled"
    elseif phase=="cancelled" then
        if not confirmation then return false end
        assert(confirmation.kind=="COMMAND_DELETE" and confirmation.id==id and confirmation.choice=="no","wrong cancel response")
        assert(not consumed(player) and player:GetGold()==gold,"cancelled disband changed unit or gold")
        LekmodScenarioRecord("unit-disband-cancel","PASS","path=actual-confirmation-No")
        action(player:GetUnitByID(id),"COMMAND_DELETE");phase="disband"
    elseif phase=="disband" then
        if not LekmodScenarioAwait("unit-disband",consumed(player) and player:GetGold()==gold+amount) then return false end
        assert(confirmation and confirmation.choice=="yes" and confirmation.id==id,"missing actual disband confirmation")
        LekmodScenarioRecord("unit-disband","PASS","path=actual-confirmation-Yes refund="..amount)
        for owner=GameDefines.MAX_MAJOR_CIVS,GameDefines.MAX_CIV_PLAYERS-1 do local p=Players[owner]
            if p and p:IsMinorCiv() and p:IsAlive() and not Teams[player:GetTeam()]:IsAtWar(p:GetTeam()) then
                for i=0,Map.GetNumPlots()-1 do local plot=Map.GetPlotByIndex(i)
                    if plot:GetOwner()==owner and not plot:IsWater() and not plot:IsMountain() and not plot:IsCity() and plot:GetNumUnits()==0 then minor,site=owner,plot;break end
                end
                if site then break end
            end
        end
        assert(site,"no peaceful minor staging tile")
        if not Teams[player:GetTeam()]:IsHasMet(Players[minor]:GetTeam()) then
            Teams[player:GetTeam()]:Meet(Players[minor]:GetTeam(),false)
            LekmodScenarioEvent("fixture-setup",{operation="established-contact",minor=minor})
        end
        local scout=input(player,"UNIT_SCOUT",site)
        assert(not player:GetUnitByID(scout):CanGift(),"city-state accepts a scout")
        LekmodScenarioRecord("gift-restrictions","PASS","own-territory-and-scout-to-minor=rejected")
        id=input(player,"UNIT_WARRIOR",site);count=Players[minor]:GetNumUnits();influence=Players[minor]:GetMinorCivFriendshipWithMajor(player:GetID())
        local u=player:GetUnitByID(id);assert(u:CanGift(),"military gift unavailable")
        action(u,"COMMAND_GIFT");phase="gift"
    elseif phase=="gift" then
        if not LekmodScenarioAwait("unit-gift",consumed(player) and Players[minor]:GetNumUnits()==count+1) then return false end
        assert(Players[minor]:GetMinorCivFriendshipWithMajor(player:GetID())>influence,"gift did not add influence")
        LekmodScenarioRecord("unit-gift","PASS","path=normal-unit-command recipient="..minor.." influence-gain="..Players[minor]:GetMinorCivFriendshipWithMajor(player:GetID())-influence)
        id=input(player,"UNIT_MERCHANT",city:Plot())
        local u=player:GetUnitByID(id);assert(not u:CanTrade(city:Plot()),"merchant mission allowed in own city")
        u:SetXY(site:GetX(),site:GetY(),false,true,false,false)
        LekmodScenarioEvent("fixture-setup",{operation="position-merchant",id=id,x=site:GetX(),y=site:GetY()})
        gold=player:GetGold();influence=Players[minor]:GetMinorCivFriendshipWithMajor(player:GetID())
        amount={gold=u:GetTradeGold(site),influence=u:GetTradeInfluence(site)}
        assert(amount.gold>0 and amount.influence>0 and u:CanTrade(site),"merchant has no legal benefit")
        action(u,"MISSION_TRADE");phase="merchant"
    elseif phase=="merchant" then
        if not LekmodScenarioAwait("merchant",consumed(player) and player:GetGold()==gold+amount.gold) then return false end
        assert(Players[minor]:GetMinorCivFriendshipWithMajor(player:GetID())==influence+amount.influence,"merchant influence mismatch")
        LekmodScenarioRecord("merchant-mission","PASS","path=normal-unit-action gold="..amount.gold.." influence="..amount.influence)
        id=input(player,"UNIT_SCIENTIST",city:Plot());amount=player:GetUnitByID(id):GetDiscoverAmount()
        assert(amount>0,"scientist fixture has no science history")
        local techs=Teams[player:GetTeam()]:GetTeamTechs();local largest=0
        for info in GameInfo.Technologies() do if player:CanResearch(info.ID) then
            local remaining=player:GetResearchCost(info.ID)-techs:GetResearchProgress(info.ID)
            if remaining>amount and remaining>largest then tech,largest=info.ID,remaining end
        end end
        assert(tech,"no legal technology with enough room for the discovery assertion")
        research=techs:GetResearchProgress(tech);Network.SendResearch(tech,0,-1,false);phase="research"
    elseif phase=="research" then
        if not LekmodScenarioAwait("research-selected",player:GetCurrentResearch()==tech) then return false end
        action(player:GetUnitByID(id),"MISSION_DISCOVER");phase="scientist"
    elseif phase=="scientist" then
        if not LekmodScenarioAwait("scientist",consumed(player) and Teams[player:GetTeam()]:GetTeamTechs():GetResearchProgress(tech)==research+amount) then return false end
        LekmodScenarioRecord("scientist-discovery","PASS","path=normal-unit-action science="..amount)
        local largest=0
        for info in GameInfo.Buildings() do if city:CanConstruct(info.ID) and info.Cost>largest then building,largest=info.ID,info.Cost end end
        assert(building,"no legal building for engineer")
        Game.CityPushOrder(city,OrderTypes.ORDER_CONSTRUCT,building,false,true,true);phase="building-order"
    elseif phase=="building-order" then
        if not LekmodScenarioAwait("engineer-order",city:GetProductionBuilding()==building) then return false end
        id=input(player,"UNIT_ENGINEER",city:Plot())
        local u=player:GetUnitByID(id);production=city:GetProduction();amount=u:GetHurryProduction(city:Plot())
        assert(amount>0,"engineer would add no production")
        action(u,"MISSION_HURRY");phase="engineer"
    elseif phase=="engineer" then
        if not LekmodScenarioAwait("engineer",consumed(player) and city:GetProduction()==production+amount) then return false end
        LekmodScenarioRecord("engineer-hurry","PASS","path=normal-unit-action production="..amount.." building="..building)
        return true
    end
    return false
end
