-- Build the prerequisite and all six components through real production orders.
-- Technologies and accumulated production are explicit near-completion setup.
include("LekmodTestScience.lua")
LekmodScenario={name="science-prelaunch",items={"apollo-completion","space-parts-production","space-assembly","space-location-rejection","space-prelaunch"}}
LekmodScenario.snapshot=LekmodScienceSnapshot
local phase,index,issuedTurn,before,unitID="init",0
local parts={"UNIT_SS_COCKPIT","UNIT_SS_BOOSTER","UNIT_SS_BOOSTER","UNIT_SS_BOOSTER","UNIT_SS_ENGINE","UNIT_SS_STASIS_CHAMBER"}
local trained={}
GameEvents.CityTrained.Add(function(owner,city,id,gold,faith)
    if owner==Game.GetActivePlayer() then
        local unit=Players[owner]:GetUnitByID(id)
        if unit then
            trained[unit:GetUnitType()]={id=id,gold=gold,faith=faith}
        end
    end
end)
local function stageProduction(city)
    local need=city:GetProductionNeeded()
    assert(need>1,"production requirement is invalid")
    local old=city:GetProduction()
    city:SetProduction(need-1)
    LekmodScenarioEvent("fixture-setup",{operation="provided-accumulated-production",city=city:GetID(),before=old,after=need-1,required=need})
    issuedTurn=Game.GetGameTurn()
end
function LekmodScenario.step(player)
    local city=assert(player:GetCapitalCity(),"science fixture needs a capital")
    local team=Teams[player:GetTeam()]
    local apollo=GameInfoTypes.PROJECT_APOLLO_PROGRAM
    if phase=="init" then
        assert(Game.IsVictoryValid(GameInfoTypes.VICTORY_SPACE_RACE),"science victory disabled in fixture")
        assert(Game.GetWinner()==-1,"fixture already has a winner")
        for _,kind in ipairs(parts) do LekmodScenarioGrantTech(player,GameInfo.Units[kind].PrereqTech) end
        local aluminum=GameInfoTypes.RESOURCE_ALUMINUM
        local available=player:GetNumResourceAvailable(aluminum,true)
        if available<6 then
            player:ChangeNumResourceTotal(aluminum,6-available)
            LekmodScenarioEvent("fixture-setup",{operation="provided-strategic-resource",resource="RESOURCE_ALUMINUM",before=available,added=6-available})
        end
        assert(team:GetProjectCount(apollo)==0,"fixture already has Apollo")
        assert(city:CanCreate(apollo),"Apollo is not a legal production choice")
        Game.CityPushOrder(city,OrderTypes.ORDER_CREATE,apollo,false,true,true)
        phase="apollo-queued"
    elseif phase=="apollo-queued" then
        if not LekmodScenarioAwait("apollo-order",city:GetProductionProject()==apollo) then return false end
        stageProduction(city);phase="apollo-turn";return "turn"
    elseif phase=="apollo-turn" then
        if Game.GetGameTurn()==issuedTurn then return "turn" end
        assert(team:GetProjectCount(apollo)==1,"ordinary production did not complete Apollo")
        LekmodScenarioRecord("apollo-completion","PASS","path=ordinary-project-production setup=near-complete")
        phase="next-part"
    elseif phase=="next-part" then
        index=index+1
        local info=assert(GameInfo.Units[parts[index]])
        assert(city:CanTrain(info.ID),"spaceship part is not a legal production choice: "..info.Type)
        trained[info.ID]=nil
        Game.CityPushOrder(city,OrderTypes.ORDER_TRAIN,info.ID,false,true,true)
        phase="part-queued"
    elseif phase=="part-queued" then
        local info=GameInfo.Units[parts[index]]
        if not LekmodScenarioAwait("component-order-"..index,city:GetProductionUnit()==info.ID) then return false end
        stageProduction(city);phase="part-turn";return "turn"
    elseif phase=="part-turn" then
        if Game.GetGameTurn()==issuedTurn then return "turn" end
        local info=GameInfo.Units[parts[index]]
        local event=assert(trained[info.ID],"component production event missing")
        assert(not event.gold and not event.faith,"component was purchased instead of produced")
        unitID=event.id
        local unit=assert(player:GetUnitByID(unitID),"produced component disappeared")
        LekmodScenarioEvent("component-produced",{index=index,type=info.Type,unit=unitID,x=unit:GetX(),y=unit:GetY()})
        if index==6 then
            assert(team:GetProjectCount(GameInfoTypes.PROJECT_SS_STASIS_CHAMBER)==0 and Game.GetWinner()==-1,"fixture crossed victory before the final action")
            LekmodScenarioRecord("space-parts-production","PASS","parts=6 path=ordinary-production setup=near-complete")
            LekmodScenarioRecord("space-assembly","PASS","components=5 path=normal-unit-actions")
            LekmodScenarioRecord("space-prelaunch","PASS","last-part=unassembled winner=none")
            return true
        end
        phase="assemble"
    elseif phase=="assemble" then
        local unit=assert(player:GetUnitByID(unitID))
        if unit:GetX()~=city:GetX() or unit:GetY()~=city:GetY() then
            assert(unit:CanMoveOrAttackInto(city:Plot()),"component cannot legally return to the capital")
            UI.SelectUnit(unit)
            Game.SelectionListGameNetMessage(GameMessageTypes.GAMEMESSAGE_PUSH_MISSION,MissionTypes.MISSION_MOVE_TO,city:GetX(),city:GetY(),0,false,false)
            phase="arriving";return false
        end
        if index==1 then
            local outside
            for direction=0,5 do
                local plot=Map.PlotDirection(city:GetX(),city:GetY(),direction)
                if plot and not plot:IsCity() then outside=plot;break end
            end
            assert(outside and not unit:CanBuildSpaceship(outside),"spaceship assembly incorrectly allowed outside a city")
            LekmodScenarioRecord("space-location-rejection","PASS","path=engine-eligibility-query")
        end
        local project=GameInfoTypes[GameInfo.Units[parts[index]].SpaceshipProject]
        before=team:GetProjectCount(project)
        if not LekmodScienceAction(unit) then return "turn" end
        phase="assembled"
    elseif phase=="arriving" then
        local unit=assert(player:GetUnitByID(unitID))
        if not LekmodScenarioAwait("component-arrival-"..index,unit:GetX()==city:GetX() and unit:GetY()==city:GetY()) then return false end
        phase="assemble"
    elseif phase=="assembled" then
        local project=GameInfoTypes[GameInfo.Units[parts[index]].SpaceshipProject]
        if not LekmodScenarioAwait("component-assembled-"..index,team:GetProjectCount(project)==before+1 and player:GetUnitByID(unitID)==nil) then return false end
        LekmodScenarioEvent("component-assembled",{index=index,project=project,count=team:GetProjectCount(project)})
        phase="next-part"
    end
    return false
end
