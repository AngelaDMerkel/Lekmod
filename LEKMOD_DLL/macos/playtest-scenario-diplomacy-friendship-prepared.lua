include("LekmodTestFriendship.lua")
LekmodScenario.name="diplomacy-friendship-prepared"
local originalStep=LekmodScenario.step
local inputTurn
function LekmodScenario.step(player)
    if not inputTurn then
        local uranium=GameInfoTypes.RESOURCE_URANIUM
        local needed=math.max(0,2-player:GetNumResourceAvailable(uranium,true))
        if needed>0 then player:ChangeNumResourceTotal(uranium,needed) end
        local gold=player:GetGold();player:ChangeGold(2000)
        LekmodScenarioEvent("fixture-setup",{operation="provided-military-maintenance-and-resource-inputs",gold_before=gold,gold_added=2000,uranium_added=needed})
        for count=1,2 do
            local site
            for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i)
                if p:GetOwner()==player:GetID() and not p:IsWater() and not p:IsMountain() and not p:IsCity() and p:GetNumUnits()==0 then site=p;break end
            end
            assert(site,"no empty owned land for the military input")
            local u=assert(player:InitUnit(GameInfoTypes.UNIT_MECH,site:GetX(),site:GetY()))
            LekmodScenarioEvent("fixture-setup",{operation="provided-military-unit",type="UNIT_MECH",id=u:GetID(),x=u:GetX(),y=u:GetY()})
        end
        inputTurn=Game.GetGameTurn();return "turn"
    end
    if Game.GetGameTurn()==inputTurn then return "turn" end
    return originalStep(player)
end
