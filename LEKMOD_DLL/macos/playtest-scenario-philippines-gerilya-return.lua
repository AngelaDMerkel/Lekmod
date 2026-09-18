-- Resume the actual embarked comparison save. Normal moves must return both
-- units to land and remove only the embarked movement difference.
LekmodScenario={name="philippines-gerilya-return",items={"gerilya-normal-disembark","gerilya-land-move-boundary"}}
local ids,phase,index,destination={},"init",1,nil
local function state(u)
    return {type=u:GetUnitType(),x=u:GetX(),y=u:GetY(),embarked=u:IsEmbarked(),moves=u:GetMoves(),maximum=u:MaxMoves(),combat=u:GetBaseCombatStrength(),marine_promotion=u:IsHasPromotion(GameInfoTypes.PROMOTION_PHIL_MARINE)}
end
function LekmodScenario.snapshot(player)
    local result={turn=Game.GetGameTurn(),units={}}
    for u in player:Units() do if u:GetUnitType()==GameInfoTypes.UNIT_PHILIPINO_MARINE or u:GetUnitType()==GameInfoTypes.UNIT_EXPEDITIONARY_FORCE then result.units[u:GetID()]=state(u) end end
    return result
end
function LekmodScenario.step(player)
    if phase=="init" then
        for u in player:Units() do
            if u:GetUnitType()==GameInfoTypes.UNIT_PHILIPINO_MARINE then ids[1]=u:GetID()
            elseif u:GetUnitType()==GameInfoTypes.UNIT_EXPEDITIONARY_FORCE then ids[2]=u:GetID() end
        end
        assert(ids[1] and ids[2],"comparison units missing")
        for _,id in ipairs(ids)do assert(player:GetUnitByID(id):IsEmbarked(),"load the embarked comparison")end
        phase="move"
    elseif phase=="move" then
        local u=assert(player:GetUnitByID(ids[index]));assert(u:GetMoves()>0,"saved unit has no disembark movement")
        for dir=0,5 do local p=Map.PlotDirection(u:GetX(),u:GetY(),dir)
            if p and p:GetOwner()==-1 and not p:IsCity() and p:GetNumUnits()==0 and not p:IsGoody(-1) and u:CanDisembarkOnto(p) then destination=p;break end
        end
        assert(destination,"no legal empty neutral land destination")
        UI.SelectUnit(u)
        Game.SelectionListGameNetMessage(GameMessageTypes.GAMEMESSAGE_PUSH_MISSION,MissionTypes.MISSION_MOVE_TO,destination:GetX(),destination:GetY(),0,false,false)
        phase="arrived"
    elseif phase=="arrived" then
        local u=assert(player:GetUnitByID(ids[index]))
        if not LekmodScenarioAwait("disembark-"..index,not u:IsEmbarked() and u:GetX()==destination:GetX() and u:GetY()==destination:GetY()) then return false end
        destination=nil
        if index==1 then index=2;phase="move" else
            local a=player:GetUnitByID(ids[1]);local b=player:GetUnitByID(ids[2])
            assert(a:MaxMoves()==b:MaxMoves(),"Gerilya kept an embarked-only movement bonus on land")
            assert(a:IsHasPromotion(GameInfoTypes.PROMOTION_PHIL_MARINE) and a:GetBaseCombatStrength()>b:GetBaseCombatStrength(),"disembark lost the unique promotion/strength")
            LekmodScenarioEvent("gerilya-disembarked",LekmodScenario.snapshot(player))
            LekmodScenarioRecord("gerilya-normal-disembark","PASS","path=two-normal-coast-to-land-moves")
            LekmodScenarioRecord("gerilya-land-move-boundary","PASS","equal-land-maxima=true unique-promotion-and-strength-retained=true")
            return true
        end
    end
    return false
end
