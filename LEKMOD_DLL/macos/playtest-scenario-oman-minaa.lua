-- Supplied legal coastal city, Minaa, units, health/embark states and upkeep.
-- A real owner turn must apply the product's periodic damage; no damage result
-- or game wait flag is assigned by the test.
LekmodScenario={name="oman-minaa",items={"minaa-enemy-sea","minaa-embarked","minaa-lethal-stack","minaa-own-land-distance-controls"}}
local phase,cityID,water,land,distant,ids,turn="init",nil,{},nil,nil,{},nil
local minaa=GameInfoTypes.BUILDING_MC_OMANI_MINAA
local function neighbors(plot)
    local seas,ground={},nil
    for dir=0,5 do local p=Map.PlotDirection(plot:GetX(),plot:GetY(),dir)
        if p and not p:IsCity() and p:GetNumUnits()==0 then
            if p:GetTerrainType()==GameInfoTypes.TERRAIN_COAST and p:GetFeatureType()~=GameInfoTypes.FEATURE_ICE then seas[#seas+1]=p
            elseif not p:IsWater() and not p:IsMountain() then ground=ground or p end
        end
    end
    return seas,ground
end
local function unitState(u)
    return {type=u:GetUnitType(),owner=u:GetOwner(),x=u:GetX(),y=u:GetY(),damage=u:GetDamage(),maximum_hp=u:GetMaxHitPoints(),domain=u:GetDomainType(),embarked=u:IsEmbarked()}
end
GameEvents.PlayerDoTurn.Add(function(id)
    if id~=GameDefines.BARBARIAN_PLAYER or phase~="pulse" or ids.sea then return end
    local enemy=Players[1];assert(not enemy:IsTurnActive(),"place probes only after the Roman AI turn")
    enemy:ChangeGold(1000)
    local function provide(kind,plot,key,damage,embarked)
        local u=assert(enemy:InitUnit(GameInfoTypes[kind],plot:GetX(),plot:GetY()));ids[key]=u:GetID()
        if embarked then u:SetEmbarked(true);assert(u:IsEmbarked()) end
        if damage then u:SetDamage(u:GetMaxHitPoints()-20) end
        LekmodScenarioEvent("fixture-setup",{operation="provided-probe-after-AI-turn",key=key,state=unitState(u)})
        return u
    end
    provide("UNIT_TRIREME",water[1],"sea")
    local doomed=provide("UNIT_TRIREME",water[2],"lethal",true)
    local embarked=provide("UNIT_WORKER",water[2],"embarked",false,true)
    assert(water[2]:GetNumUnits()==2 and water[2]:GetUnit(0):GetID()==doomed:GetID() and water[2]:GetUnit(1):GetID()==embarked:GetID(),"lethal-first stack ordering was not established")
    provide("UNIT_WARRIOR",land,"land")
    provide("UNIT_TRIREME",distant,"distant")
end)
function LekmodScenario.snapshot(player)
    local result={turn=Game.GetGameTurn(),war=Teams[player:GetTeam()]:IsAtWar(Players[1]:GetTeam()),cities={},units={}}
    for c in player:Cities() do result.cities[c:GetID()]={x=c:GetX(),y=c:GetY(),minaa=c:GetNumRealBuilding(minaa)} end
    for id=0,1 do result.units[id]={};for u in Players[id]:Units() do if not u:IsDead() and not u:IsDelayedDeath() then result.units[id][u:GetID()]=unitState(u) end end end
    return result
end
function LekmodScenario.step(player)
    local capital=player:GetCapitalCity();if not capital then return "turn" end
    assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_OMAN,"requires Oman")
    if phase=="init" then
        local site
        for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i)
            local distance=Map.PlotDistance(capital:GetX(),capital:GetY(),p:GetX(),p:GetY())
            local otherStart=Players[1]:GetStartingPlot()
            local otherDistance=Map.PlotDistance(otherStart:GetX(),otherStart:GetY(),p:GetX(),p:GetY())
            if distance>=8 and otherDistance>=8 and p:GetOwner()==-1 and p:GetNumUnits()==0 and player:CanFound(p:GetX(),p:GetY()) then
                local seas,ground=neighbors(p)
                if #seas>=3 and ground then site=p;water,land=seas,ground;break end
            end
        end
        assert(site,"no legal distant coastal input city with three water probes")
        player:Found(site:GetX(),site:GetY());local city=assert(site:GetPlotCity());cityID=city:GetID()
        city:SetNumRealBuilding(minaa,1);player:ChangeGold(1000)
        LekmodScenarioEvent("fixture-setup",{operation="provided-legal-coastal-city-Minaa-and-upkeep",city=cityID,x=site:GetX(),y=site:GetY(),gold_added=1000})
        for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i)
            if p:GetTerrainType()==GameInfoTypes.TERRAIN_COAST and p:GetFeatureType()~=GameInfoTypes.FEATURE_ICE and p:GetNumUnits()==0
                and Map.PlotDistance(site:GetX(),site:GetY(),p:GetX(),p:GetY())==2 then distant=p;break end
        end
        assert(distant,"no distance-two water control")
        local own=assert(player:InitUnit(GameInfoTypes.UNIT_TRIREME,water[3]:GetX(),water[3]:GetY()));ids.own=own:GetID()
        LekmodScenarioEvent("fixture-setup",{operation="provided-own-sea-control",state=unitState(own)})
        Teams[player:GetTeam()]:Meet(Players[1]:GetTeam(),true)
        Network.SendChangeWar(Players[1]:GetTeam(),true);phase="war"
    elseif phase=="war" then
        if not LekmodScenarioAwait("minaa-war",Teams[player:GetTeam()]:IsAtWar(Players[1]:GetTeam())) then return false end
        turn=Game.GetGameTurn();phase="pulse";return "turn"
    elseif phase=="pulse" then
        if Game.GetGameTurn()==turn then return "turn" end
        assert(Game.GetGameTurn()==turn+1 and ids.sea,"pulse did not follow one real owner turn")
        local enemy=Players[1]
        local function damage(key,expected)
            local u=assert(enemy:GetUnitByID(ids[key]),"surviving probe missing: "..key)
            LekmodScenarioEvent("minaa-after-pulse",{key=key,state=unitState(u)})
            assert(u:GetDamage()==expected,"unexpected damage for "..key)
        end
        damage("sea",30);damage("embarked",30);damage("land",0);damage("distant",0)
        local doomed=enemy:GetUnitByID(ids.lethal)
        assert(not doomed or doomed:IsDead() or doomed:IsDelayedDeath(),"lethal pulse did not kill its target")
        assert(player:GetUnitByID(ids.own):GetDamage()==0,"Minaa damaged its owner's ship")
        LekmodScenarioRecord("minaa-enemy-sea","PASS","ordinary-owner-turn damage=30")
        LekmodScenarioRecord("minaa-embarked","PASS","ordinary-owner-turn provided-embarked-worker damage=30")
        LekmodScenarioRecord("minaa-lethal-stack","PASS","first-stacked-ship-killed second-embarked-unit-damaged=true")
        LekmodScenarioRecord("minaa-own-land-distance-controls","PASS","owned-ship enemy-unembarked-land distance-two-ship damage=0")
        return true
    end
    return false
end
