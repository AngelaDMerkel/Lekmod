-- Religion founding and conversion are explicit scripted fixture inputs.
-- Real engine conversion events must update/clear both cities' trait benefits.
-- This is a native handler regression, not earned religious gameplay.
LekmodScenario={name="mughals",items={"mughal-conversion","mughal-conversion-cleanup","mughal-reconversion"}}
local phase,foreign,own,otherID,conversions="init",nil,nil,nil,0
local dummy=GameInfoTypes.BUILDING_DUMMY_MUGHALS
GameEvents.CityConvertsReligion.Add(function(owner,religion,x,y)
    if owner==Game.GetActivePlayer() then
        conversions=conversions+1
        LekmodScenarioEvent("engine-conversion",{owner=owner,religion=religion,x=x,y=y})
    end
end)
local function found(player)
    local taken={}
    for id=0,GameDefines.MAX_CIV_PLAYERS-1 do
        local p=Players[id]
        if p and p:IsAlive() and p:HasCreatedReligion() then taken[p:GetReligionCreatedByPlayer()]=true end
    end
    local religion
    for info in GameInfo.Religions() do
        if info.ID>0 and not taken[info.ID] then religion=info.ID;break end
    end
    assert(religion and Game.GetNumReligionsStillToFound()>0,"fixture lacks a free religion")
    local founder=assert(Game.GetAvailableFounderBeliefs()[1])
    local follower=assert(Game.GetAvailableFollowerBeliefs()[1])
    Game.FoundReligion(player:GetID(),religion,nil,founder,follower,-1,-1,assert(player:GetCapitalCity()))
    assert(player:GetReligionCreatedByPlayer()==religion,"scripted religion input did not apply")
    LekmodScenarioEvent("fixture-setup",{operation="provided-religion",owner=player:GetID(),religion=religion,founder=founder,follower=follower})
    return religion
end
local function convert(city,to,from)
    conversions=0
    LekmodScenarioEvent("fixture-setup",{operation="scripted-conversion",city=city:GetID(),from=from,to=to,percent=100})
    city:ConvertPercentFollowers(to,from,100)
end
function LekmodScenario.snapshot(player)
    local cities={}
    for id=0,GameDefines.MAX_CIV_PLAYERS-1 do
        local p=Players[id]
        if p and p:IsAlive() then
            for city in p:Cities() do
                cities[id..":"..city:GetID()]={majority=city:GetReligiousMajority(),benefit=city:GetNumRealBuilding(dummy)}
            end
        end
    end
    return {turn=Game.GetGameTurn(),civ=player:GetCivilizationType(),religion=player:GetReligionCreatedByPlayer(),cities=cities}
end
function LekmodScenario.step(player)
    assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_MUGHALS,"choose Mughals in ordinary setup")
    assert(not Game.IsOption(GameOptionTypes.GAMEOPTION_NO_RELIGION),"fixture requires religion-enabled setup")
    local city=player:GetCapitalCity()
    if not city then return "turn" end
    if phase=="init" then
        for id=0,GameDefines.MAX_MAJOR_CIVS-1 do
            local p=Players[id]
            if id~=player:GetID() and p and p:IsAlive() and p:GetCapitalCity() then otherID=id;break end
        end
        if not otherID then return "turn" end
        foreign=found(Players[otherID]);own=found(player)
        phase="foreign"
    elseif phase=="foreign" then
        assert(city:GetReligiousMajority()==own,"own religion did not become capital majority")
        convert(city,foreign,own);phase="foreign-result"
    elseif phase=="foreign-result" then
        local holy=Players[otherID]:GetCapitalCity()
        if not LekmodScenarioAwait("mughal-foreign-benefit",city:GetNumRealBuilding(dummy)==1 and holy:GetNumRealBuilding(dummy)==1) then return false end
        assert(conversions>0 and city:GetReligiousMajority()==foreign,"real foreign-conversion event missing")
        LekmodScenarioRecord("mughal-conversion","PASS","path=engine-conversion-event setup=scripted-religion-and-conversion")
        convert(city,own,foreign);phase="own-result"
    elseif phase=="own-result" then
        local holy=Players[otherID]:GetCapitalCity()
        if not LekmodScenarioAwait("mughal-old-benefit-cleared",city:GetNumRealBuilding(dummy)==0 and holy:GetNumRealBuilding(dummy)==0) then return false end
        assert(conversions>0 and city:GetReligiousMajority()==own,"real own-conversion event missing")
        LekmodScenarioRecord("mughal-conversion-cleanup","PASS","both-benefits=removed own-religion=excluded")
        convert(city,foreign,own);phase="reconvert-result"
    elseif phase=="reconvert-result" then
        if not LekmodScenarioAwait("mughal-reconversion",city:GetNumRealBuilding(dummy)==1 and Players[otherID]:GetCapitalCity():GetNumRealBuilding(dummy)==1) then return false end
        LekmodScenarioRecord("mughal-reconversion","PASS","both-benefits=restored")
        return true
    end
    return false
end
