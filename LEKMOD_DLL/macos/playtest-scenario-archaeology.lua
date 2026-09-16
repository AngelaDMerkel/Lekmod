-- Supplied technology and archaeologists at natural sites. Digs, artifact and
-- landmark choices and their results use ordinary missions/turns/callbacks.
LekmodScenario={name="archaeology",items={"artifact-dig","archaeology-cancel","artifact-created","landmark-dig","landmark-created","landmark-yield-preview","archaeology-restrictions"}}
local phase,kind,unitID,plotIndex,started,works,known,answered,cultureBefore,scienceBefore,goldBefore="init","artifact",nil,nil,nil,nil,{},nil,nil,nil,nil
local visited={}
local function clearOfEnemies(player,plot)
    for owner=0,GameDefines.MAX_CIV_PLAYERS do local p=Players[owner]
        if p and p:IsAlive() and Teams[player:GetTeam()]:IsAtWar(p:GetTeam()) then
            for u in p:Units() do
                if Map.PlotDistance(plot:GetX(),plot:GetY(),u:GetX(),u:GetY())<=4 then return false end
            end
        end
    end
    return true
end
local completed,recorded={},{}
GameEvents.BuildFinished.Add(function(owner,x,y,improvement)
    if owner==Game.GetActivePlayer() and improvement==GameInfoTypes.IMPROVEMENT_ARCHAEOLOGICAL_DIG then completed[x..":"..y]=Game.GetGameTurn() end
end)
local function recordDig(plot)
    assert(completed[plot:GetX()..":"..plot:GetY()],"real archaeology build-completion event missing")
    if not recorded[kind] then
        recorded[kind]=true
        LekmodScenarioRecord(kind.."-dig","PASS","path=normal-build-and-turns turns="..Game.GetGameTurn()-started)
    end
end
LuaEvents.LekmodArchaeologyAnswered.Add(function(k,x,y) answered={kind=k,x=x,y=y} end)
local function workMap(player)
    local result={}
    for city in player:Cities() do for info in GameInfo.Buildings() do
        if info.GreatWorkCount>0 and city:GetNumBuilding(info.ID)>0 then
            local class=GameInfo.BuildingClasses[info.BuildingClass].ID
            for slot=0,info.GreatWorkCount-1 do local id=city:GetBuildingGreatWork(class,slot)
                if id>=0 then result[id]={city=city:GetID(),class=Game.GetGreatWorkClass(id),building=class,slot=slot,creator=Game.GetGreatWorkCreator(id)} end
            end
        end
    end end
    return result
end
function LekmodScenario.snapshot(player)
    local plots={}
    for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i)
        if p:GetResourceType(-1)==GameInfoTypes.RESOURCE_ARTIFACTS or p:GetImprovementType()==GameInfoTypes.IMPROVEMENT_LANDMARK then
            plots[i]={owner=p:GetOwner(),resource=p:GetResourceType(-1),improvement=p:GetImprovementType(),culture=p:CalculateYield(YieldTypes.YIELD_CULTURE,false),science=p:CalculateYield(YieldTypes.YIELD_SCIENCE,false),gold=p:CalculateYield(YieldTypes.YIELD_GOLD,false),era=p:GetArchaeologyArtifactEra(),origin=p:GetArchaeologyArtifactPlayer1()}
        end
    end
    return {turn=Game.GetGameTurn(),works=workMap(player),count=player:GetNumGreatWorks(),plots=plots}
end
function LekmodScenario.step(player)
    if phase=="init" then
        LekmodScenarioGrantTech(player,"TECH_ARCHAEOLOGY")
        assert(player:HasAvailableGreatWorkSlot(GameInfo.GreatWorkSlots.GREAT_WORK_SLOT_ART_ARTIFACT.ID),"load the two-Museum greatworks fixture with open slots")
        started=Game.GetGameTurn();phase="ready";return "turn"
    elseif phase=="ready" then
        if Game.GetGameTurn()==started then return "turn" end
        phase="site"
    elseif phase=="site" then
        local plot
        for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i)
            if not visited[i] and p:GetResourceType(player:GetTeam())==GameInfoTypes.RESOURCE_ARTIFACTS
                and not p:HasWrittenArtifact() and not p:IsWater() and not p:IsMountain() and p:GetNumUnits()==0
                and p:GetImprovementType()==-1
                and (p:GetOwner()==-1 or p:GetOwner()==player:GetID()) and p:GetArchaeologyArtifactPlayer1()>=0
                and p:CanBuild(GameInfoTypes.BUILD_ARCHAEOLOGY_DIG,player:GetID(),false,true) and clearOfEnemies(player,p) then plot,plotIndex=p,i;break end
        end
        assert(plot,"no natural ordinary dig site available")
        visited[plotIndex]=true
        local u=assert(player:InitUnit(GameInfoTypes.UNIT_ARCHAEOLOGIST,plot:GetX(),plot:GetY()));unitID=u:GetID()
        LekmodScenarioEvent("fixture-setup",{operation="provided-archaeologist-at-natural-site",id=unitID,x=u:GetX(),y=u:GetY(),kind=kind,era=plot:GetArchaeologyArtifactEra(),origin=plot:GetArchaeologyArtifactPlayer1(),enemy_exclusion_radius=4})
        assert(u:CanBuild(plot,GameInfoTypes.BUILD_ARCHAEOLOGY_DIG),"archaeologist cannot legally dig site")
        assert(not u:CanBuild(player:GetCapitalCity():Plot(),GameInfoTypes.BUILD_ARCHAEOLOGY_DIG),"dig allowed on the capital")
        if kind=="artifact" then
            local landmark=GameInfoTypes.IMPROVEMENT_LANDMARK
            local default=plot:CalculateImprovementYieldChange(landmark,YieldTypes.YIELD_CULTURE,player:GetID())
            local explicit=plot:CalculateImprovementYieldChange(landmark,YieldTypes.YIELD_CULTURE,player:GetID(),false)
            local route=plot:CalculateImprovementYieldChange(landmark,YieldTypes.YIELD_CULTURE,player:GetID(),true,GameInfoTypes.ROUTE_ROAD)
            local expected=math.max(0,player:GetCurrentEra()-plot:GetArchaeologyArtifactEra())
            assert(default==explicit and explicit==expected and type(route)=="number","landmark age preview or optional arguments differ")
            LekmodScenarioRecord("landmark-yield-preview","PASS","path=read-only-native-query culture-if-owned="..explicit.." explicit-boolean-and-route=accepted")
        end
        works=player:GetNumGreatWorks();known=workMap(player);cultureBefore=plot:CalculateYield(YieldTypes.YIELD_CULTURE,false)
        scienceBefore=plot:CalculateYield(YieldTypes.YIELD_SCIENCE,false);goldBefore=plot:CalculateYield(YieldTypes.YIELD_GOLD,false)
        answered=nil;LuaEvents.LekmodArchaeologyChoice(kind,unitID,plot:GetX(),plot:GetY())
        UI.SelectUnit(u);local found=false
        for i=0,#GameInfoActions do if GameInfoActions[i] and GameInfoActions[i].Type=="BUILD_ARCHAEOLOGY_DIG" then
            assert(Game.CanHandleAction(i),"normal archaeology build unavailable");Game.HandleAction(i);found=true;break
        end end
        assert(found,"archaeology action missing");started=Game.GetGameTurn();phase="build-ack"
    elseif phase=="build-ack" then
        local plot=Map.GetPlotByIndex(plotIndex);local u=assert(player:GetUnitByID(unitID),"archaeologist disappeared before build acknowledgment")
        if not LekmodScenarioAwait("archaeology-build-ack",u:GetBuildType()==GameInfoTypes.BUILD_ARCHAEOLOGY_DIG or completed[plot:GetX()..":"..plot:GetY()]) then return false end
        LekmodScenarioEvent("dig-build-acknowledged",{id=unitID,kind=kind,build=u:GetBuildType(),progress=plot:GetBuildProgress(GameInfoTypes.BUILD_ARCHAEOLOGY_DIG)})
        phase="digging"
    elseif phase=="digging" then
        local plot=Map.GetPlotByIndex(plotIndex)
        if answered then recordDig(plot);phase="choice-result";return false end
        local u=player:GetUnitByID(unitID)
        assert(u and not u:IsDead() and not u:IsDelayedDeath(),"fixture archaeologist was lost before completing the dig")
        assert(u:GetX()==plot:GetX() and u:GetY()==plot:GetY(),"fixture archaeologist was displaced from its dig")
        local pending=player:GetNextDigCompletePlot()
        if pending then
            assert(pending:GetPlotIndex()==plotIndex and plot:GetImprovementType()==GameInfoTypes.IMPROVEMENT_ARCHAEOLOGICAL_DIG,"wrong completed archaeology site")
            recordDig(plot)
            if player:GetEndTurnBlockingType()==EndTurnBlockingTypes.ENDTURN_BLOCKING_CHOOSE_ARCHAEOLOGY then
                UI.ActivateNotification(player:GetEndTurnBlockingNotificationIndex())
            else return "turn" end
            phase="choosing";return false
        end
        assert(u:GetBuildType()==GameInfoTypes.BUILD_ARCHAEOLOGY_DIG,"archaeology build mission was interrupted before completion")
        assert(Game.GetGameTurn()-started<=10,"dig did not finish within ten ordinary turns")
        return "turn"
    elseif phase=="choosing" then
        if not answered then return false end
        phase="choice-result"
    elseif phase=="choice-result" then
        local plot=Map.GetPlotByIndex(plotIndex);local u=player:GetUnitByID(unitID)
        if not LekmodScenarioAwait("archaeology-unit-consumed",not u or u:IsDead() or u:IsDelayedDeath()) then return false end
        assert(answered.kind==kind and answered.x==plot:GetX() and answered.y==plot:GetY(),"choice response location mismatch")
        assert(plot:GetResourceType(-1)~=GameInfoTypes.RESOURCE_ARTIFACTS,"completed dig retained the antiquity resource")
        if kind=="artifact" then
            assert(player:GetNumGreatWorks()==works+1 and plot:GetImprovementType()==-1,"artifact choice did not add one work and clear the dig")
            local artifact
            for id,row in pairs(workMap(player)) do if not known[id] then artifact=row;break end end
            assert(artifact and artifact.class==GameInfoTypes.GREAT_WORK_ARTIFACT and artifact.creator==plot:GetArchaeologyArtifactPlayer1(),"artifact class/origin does not match its real site")
            LekmodScenarioRecord("artifact-created","PASS","path=actual-archaeology-choice-and-confirmation origin="..artifact.creator)
            kind="landmark";phase="site"
        else
            assert(player:GetNumGreatWorks()==works and plot:GetImprovementType()==GameInfoTypes.IMPROVEMENT_LANDMARK,"landmark choice produced wrong result")
            local science=plot:CalculateYield(YieldTypes.YIELD_SCIENCE,false)-scienceBefore
            local gold=plot:CalculateYield(YieldTypes.YIELD_GOLD,false)-goldBefore
            local culture=plot:CalculateYield(YieldTypes.YIELD_CULTURE,false)-cultureBefore
            local expectedCulture=plot:CalculateImprovementYieldChange(GameInfoTypes.IMPROVEMENT_LANDMARK,YieldTypes.YIELD_CULTURE,plot:GetOwner())
            LekmodScenarioEvent("landmark-yields",{owner=plot:GetOwner(),era=plot:GetArchaeologyArtifactEra(),current_era=player:GetCurrentEra(),science_added=science,gold_added=gold,culture_added=culture,expected_culture=expectedCulture})
            assert(science==2 and gold==2 and culture==expectedCulture,"landmark yields differ from configured base/age benefits")
            LekmodScenarioRecord("landmark-created","PASS","path=actual-archaeology-choice science=2 gold=2 culture="..culture)
            LekmodScenarioRecord("archaeology-restrictions","PASS","city-dig=rejected natural-resource-consumed=true")
            return true
        end
    end
    return false
end
