-- Population, belief/religion definitions and pressure transfers are explicit
-- inputs. Native follower counts and local/empire happiness must respond.
LekmodScenario={name="ottoman-diversity",items={"ottoman-pantheon-excluded","ottoman-one-religion","ottoman-minority-happiness","ottoman-three-religions","ottoman-diversity-removal","diversity-other-owner-control"}}
local phase,religions,baseline,empire,majorityFollowers="init",{},nil,nil,nil
local conversionEvents,minorityEvents=0,0
GameEvents.CityConvertsReligion.Add(function(owner,religion,x,y)
    if owner==0 then conversionEvents=conversionEvents+1;LekmodScenarioEvent("observed-city-religion-event",{owner=owner,religion=religion,x=x,y=y})end
end)
local founders={"BELIEF_CHURCH_PROPERTY","BELIEF_DAWAHH","BELIEF_MESSIAH"}
local followers={"BELIEF_CHORAL_MUSIQ","BELIEF_DIVINE_INSPIRATION","BELIEF_FEED_WORLD"}
local function belief(available,names)
    local allowed={};for _,id in ipairs(available)do allowed[id]=true end
    for _,name in ipairs(names)do local info=GameInfo.Beliefs[name];if info and allowed[info.ID]then return info.ID end end
    error("no configured non-happiness belief is available")
end
local function found(player)
    local used={};for _,p in pairs(Players)do if p:IsAlive() and p:HasCreatedReligion()then used[p:GetReligionCreatedByPlayer()]=true end end
    local id;for info in GameInfo.Religions()do if info.ID>0 and not used[info.ID]then id=info.ID;break end end
    assert(id and Game.GetNumReligionsStillToFound()>0)
    local a=belief(Game.GetAvailableFounderBeliefs(),founders);local b=belief(Game.GetAvailableFollowerBeliefs(),followers)
    Game.FoundReligion(player:GetID(),id,nil,a,b,-1,-1,player:GetCapitalCity())
    assert(player:GetReligionCreatedByPlayer()==id)
    LekmodScenarioEvent("fixture-setup",{operation="provided-world-religion-without-happiness-beliefs",owner=player:GetID(),religion=id,founder=a,follower=b})
    return id
end
local function convert(city,to,from,percent)
    city:ConvertPercentFollowers(to,from,percent)
    LekmodScenarioEvent("fixture-setup",{operation="provided-pressure-transfer",city=city:GetID(),to=to,from=from,percent=percent})
end
local function state(player)
    local city=assert(player:GetCapitalCity());local counts={};local present=0
    for info in GameInfo.Religions()do local n=city:GetNumFollowers(info.ID);counts[info.ID]=n;if info.ID>0 and n>0 then present=present+1 end end
    counts[-1]=city:GetNumFollowers(-1)
    return {population=city:GetPopulation(),followers=counts,world_religions=present,majority=city:GetReligiousMajority(),local_happiness=city:GetLocalHappiness(),empire_happiness=player:GetExcessHappiness(),faith=player:GetFaith()}
end
function LekmodScenario.snapshot(player)
    return {turn=Game.GetGameTurn(),players={[0]=state(Players[0]),[1]=state(Players[1]),[2]=state(Players[2])}}
end
function LekmodScenario.step(player)
    local city=assert(player:GetCapitalCity())
    assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_OTTOMAN and Players[1]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_OTTOMAN and Players[2]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_ROME)
    if phase=="init" then
        for id=0,2 do local p=Players[id];assert(not p:HasCreatedReligion());p:GetCapitalCity():SetPopulation(20,true) end
        baseline={};for id=0,2 do baseline[id]=Players[id]:GetCapitalCity():GetLocalHappiness() end
        local pantheon=GameInfoTypes.BELIEF_ANCESTOR_WORSHIP
        assert(not player:HasCreatedPantheon())
        Game.FoundPantheon(0,pantheon)
        LekmodScenarioEvent("fixture-setup",{operation="provided-population-and-pantheon",population=20,pantheon=pantheon})
        phase="pantheon"
    elseif phase=="pantheon" then
        local s=state(player);LekmodScenarioEvent("ottoman-pantheon-state",s)
        assert(player:HasCreatedPantheon() and s.world_religions==0 and s.local_happiness==baseline[0],"pantheon incorrectly counted as world-religion happiness")
        LekmodScenarioRecord("ottoman-pantheon-excluded","PASS","native-pantheon followers-do-not-add-trait-happiness=true")
        for id=0,2 do religions[id]=found(Players[id]) end
        phase="single"
    elseif phase=="single" then
        for id=0,2 do local s=state(Players[id]);assert(s.world_religions==1 and s.local_happiness==baseline[id]+(id<2 and 1 or 0),"one-religion owner happiness differs")end
        LekmodScenarioRecord("ottoman-one-religion","PASS","human-and-AI-Ottoman local=base+1 Roman=base")
        for info in GameInfo.Religions()do if info.ID~=religions[0]then convert(city,religions[0],info.ID,100)end end
        convert(city,religions[0],-1,100)
        convert(city,-1,religions[0],40)
        phase="minority-input"
    elseif phase=="minority-input" then
        local s=state(player);assert(s.majority==religions[0] and s.followers[religions[0]]>10 and s.followers[-1]>=2)
        majorityFollowers=s.followers[religions[0]];empire=s.empire_happiness;minorityEvents=conversionEvents
        LekmodScenarioEvent("ottoman-before-minority",s)
        convert(city,religions[1],-1,50);phase="two"
    elseif phase=="two" then
        local s=state(player);LekmodScenarioEvent("ottoman-two-religions",s)
        assert(s.world_religions==2 and s.majority==religions[0] and s.followers[religions[0]]==majorityFollowers,"minority fixture changed the majority's followers")
        assert(conversionEvents==minorityEvents,"minority-only addition emitted a majority conversion event")
        assert(s.local_happiness==baseline[0]+2 and s.empire_happiness==empire+1,"minority-only addition did not update local and empire happiness")
        LekmodScenarioRecord("ottoman-minority-happiness","PASS","majority-and-majority-followers-unchanged local-and-empire=+1 conversion-events=0")
        empire=s.empire_happiness;convert(city,religions[2],-1,100);phase="three"
    elseif phase=="three" then
        local s=state(player);LekmodScenarioEvent("ottoman-three-religions",s)
        assert(s.world_religions==3 and s.local_happiness==baseline[0]+3 and s.empire_happiness==empire+1,"third religion did not add one happiness")
        LekmodScenarioRecord("ottoman-three-religions","PASS","three-world-religions local=base+3 empire-added=1")
        local other=Players[2]:GetCapitalCity()
        convert(other,religions[0],religions[2],35);convert(other,religions[1],religions[2],50)
        convert(city,religions[0],religions[1],100);convert(city,religions[0],religions[2],100)
        phase="removed"
    elseif phase=="removed" then
        local s=state(player);local other=state(Players[2]);LekmodScenarioEvent("ottoman-diversity-final",LekmodScenario.snapshot(player))
        assert(s.world_religions==1 and s.local_happiness==baseline[0]+1 and s.empire_happiness==empire-1,"removing two religions did not clear two happiness")
        assert(other.world_religions==3 and other.local_happiness==baseline[2],"Roman diversity control received Ottoman happiness")
        LekmodScenarioRecord("ottoman-diversity-removal","PASS","three-to-one religions removes-two-happiness=true")
        LekmodScenarioRecord("diversity-other-owner-control","PASS","Roman-three-world-religions local-happiness-unchanged=true")
        return true
    end
    return false
end
