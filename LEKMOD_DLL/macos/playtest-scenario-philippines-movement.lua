-- Supplied civilian/combat units on distinct legal land plots. No movement
-- counter is assigned; normal turn refresh must supply the owner's bonus.
LekmodScenario={name="philippines-movement",items={"philippines-civilian-move-limits","philippines-move-refresh","philippines-move-controls"}}
local phase,turn="init",nil
local probes={}
local function freePlot(owner,territory,used)
    local player=Players[owner];local capital=assert(player:GetCapitalCity())
    for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i)
        if not used[i] and p:GetNumUnits()==0 and not p:IsWater() and not p:IsMountain() and not p:IsGoody(-1)
            and p:GetArea()==capital:Plot():GetArea() and p:GetOwner()==territory
            and Map.PlotDistance(p:GetX(),p:GetY(),capital:GetX(),capital:GetY())<=8 then used[i]=true;return p,i end
    end
    error("no distinct land placement for movement probe")
end
local function state(unit)
    return {id=unit:GetID(),owner=unit:GetOwner(),type=unit:GetUnitType(),x=unit:GetX(),y=unit:GetY(),territory=unit:GetPlot():GetOwner(),moves=unit:GetMoves(),maximum=unit:MaxMoves(),combat=unit:GetBaseCombatStrength(),embarked=unit:IsEmbarked()}
end
function LekmodScenario.snapshot(player)
    local result={turn=Game.GetGameTurn(),units={}}
    for id=0,1 do result.units[id]={};for u in Players[id]:Units() do if not u:IsDelayedDeath() then result.units[id][u:GetID()]=state(u) end end end
    return result
end
function LekmodScenario.step(player)
    assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_PHILIPPINES and Players[1]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_ROME,"requires Philippines and Roman control")
    if phase=="init" then
        local used={}
        for _,kind in ipairs({"UNIT_WORKER","UNIT_SETTLER","UNIT_SCIENTIST"}) do
            for _,territory in ipairs({player:GetID(),-1}) do
                local plot,index=freePlot(0,territory,used);local info=assert(GameInfo.Units[kind])
                local unit=assert(player:InitUnit(info.ID,plot:GetX(),plot:GetY()))
                local expected=(info.Moves+(territory==player:GetID() and 2 or 0))*GameDefines.MOVE_DENOMINATOR
                probes[#probes+1]={owner=0,id=unit:GetID(),territory=territory,expected=expected,x=plot:GetX(),y=plot:GetY()}
                assert(unit:GetBaseCombatStrength()==0 and unit:MaxMoves()==expected,"civilian movement limit differs by territory")
                LekmodScenarioEvent("fixture-setup",{operation="provided-movement-probe",type=kind,plot=index,state=state(unit),expected=expected})
            end
        end
        for _,row in ipairs({{owner=0,type="UNIT_WARRIOR"},{owner=1,type="UNIT_WORKER"}}) do
            local plot,index=freePlot(row.owner,row.owner,used);local info=GameInfo.Units[row.type]
            local u=assert(Players[row.owner]:InitUnit(info.ID,plot:GetX(),plot:GetY()))
            assert(u:MaxMoves()==info.Moves*GameDefines.MOVE_DENOMINATOR,"combat/other-owner control received civilian bonus")
            LekmodScenarioEvent("fixture-setup",{operation="provided-movement-control",plot=index,state=state(u)})
        end
        LekmodScenarioRecord("philippines-civilian-move-limits","PASS","worker-settler-scientist own=base+2 neutral=base")
        LekmodScenarioRecord("philippines-move-controls","PASS","own-Warrior-and-Roman-Worker base-moves-only=true")
        turn=Game.GetGameTurn();phase="refreshed";return "turn"
    elseif phase=="refreshed" then
        if Game.GetGameTurn()==turn then return "turn" end
        assert(Game.GetGameTurn()==turn+1,"movement refresh exceeded one ordinary turn")
        for _,probe in ipairs(probes) do
            local u=assert(Players[probe.owner]:GetUnitByID(probe.id));local s=state(u)
            LekmodScenarioEvent("philippines-refreshed-movement",s)
            assert(s.x==probe.x and s.y==probe.y and s.territory==probe.territory,"probe placement/ownership changed")
            assert(s.maximum==probe.expected and s.moves==probe.expected,"normal turn did not refresh the quoted movement budget")
        end
        LekmodScenarioRecord("philippines-move-refresh","PASS","path=ordinary-turn own=base-plus-two neutral=base moves-never-assigned=true")
        return true
    end
    return false
end
