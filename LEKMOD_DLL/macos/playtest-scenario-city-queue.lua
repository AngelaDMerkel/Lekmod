-- Prepare a reusable UI fixture with normal orders, without ending a turn.
LekmodScenario={name="city-queue",items={"city-queue-ready"}}
local phase="init"
function LekmodScenario.snapshot(player)
    local city=player:GetCapitalCity()
    local queue={}
    for index=0,city:GetOrderQueueLength()-1 do
        local kind,id=city:GetOrderFromQueue(index);queue[index]={kind=kind,id=id}
    end
    return {turn=Game.GetGameTurn(),city=city:GetID(),focus=city:GetFocusType(),queue=queue,gold=player:GetGold()}
end
function LekmodScenario.step(player)
    local city=assert(player:GetCapitalCity())
    if phase=="init" then
        assert(city:CanTrain(GameInfoTypes.UNIT_WORKER) and city:CanConstruct(GameInfoTypes.BUILDING_WATERMILL), "queue fixture items unavailable")
        Game.CityPushOrder(city,OrderTypes.ORDER_TRAIN,GameInfoTypes.UNIT_WORKER,false,true,true)
        phase="worker"
    elseif phase=="worker" then
        local kind,id=city:GetOrderFromQueue(0)
        if not LekmodScenarioAwait("queue-worker",kind==OrderTypes.ORDER_TRAIN and id==GameInfoTypes.UNIT_WORKER) then return false end
        Game.CityPushOrder(city,OrderTypes.ORDER_CONSTRUCT,GameInfoTypes.BUILDING_WATERMILL,false,false,true)
        phase="mill"
    elseif phase=="mill" then
        local kind,id=city:GetOrderFromQueue(1)
        if not LekmodScenarioAwait("queue-mill",city:GetOrderQueueLength()==2 and kind==OrderTypes.ORDER_CONSTRUCT and id==GameInfoTypes.BUILDING_WATERMILL) then return false end
        LekmodScenarioRecord("city-queue-ready","PASS","scope=fixture-preparation path=normal-orders turns=0")
        return true
    end
    return false
end
