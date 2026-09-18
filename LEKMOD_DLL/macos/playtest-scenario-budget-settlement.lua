-- Supplied maintenance buildings and treasury create a deficit; normal turns
-- settle gold/research. The buildings are restored before the recovery turn.
LekmodScenario={name="budget-settlement",items={"deficit-gold-floor","deficit-research-floor","budget-recovery-settlement"}}
local phase,initial,before,recovery,originals="init",nil,nil,nil,{}
local function research(player)
    local techs=Teams[player:GetTeam()]:GetTeamTechs()
    local result={overflow=player:GetOverflowResearch(),total100=0,technologies={}}
    for tech in GameInfo.Technologies() do
        local progress=techs:GetResearchProgressTimes100(tech.ID)
        result.total100=result.total100+progress
        result.technologies[tech.ID]={known=techs:HasTech(tech.ID),count=techs:GetTechCount(tech.ID),progress100=progress}
    end
    return result
end
function LekmodScenario.snapshot(player)
    local buildings={}
    for city in player:Cities() do
        buildings[city:GetID()]={}
        for b in GameInfo.Buildings() do local n=city:GetNumRealBuilding(b.ID);if n>0 then buildings[city:GetID()][b.ID]=n end end
    end
    return {turn=Game.GetGameTurn(),gold=player:GetGold(),gold_rate100=player:CalculateGoldRateTimes100(),science100=player:GetScienceTimes100(),deficit100=player:GetScienceFromBudgetDeficitTimes100(),research=research(player),buildings=buildings}
end
function LekmodScenario.step(player)
    local city=player:GetCapitalCity()
    if not city then return "turn" end
    if phase=="init" then
        assert(not Game.IsOption("GAMEOPTION_NO_SCIENCE") and not player:IsAnarchy(),"requires enabled research without anarchy")
        initial=Game.GetGameTurn();player:SetGold(0)
        LekmodScenarioEvent("fixture-setup",{operation="provided-zero-treasury",turn=initial})
        for _,name in ipairs({"BUILDING_MUSEUM","BUILDING_OPERA_HOUSE","BUILDING_BROADCAST_TOWER","BUILDING_AIRPORT","BUILDING_HOSPITAL","BUILDING_MEDICAL_LAB"}) do
            local info=assert(GameInfo.Buildings[name]);local count=city:GetNumRealBuilding(info.ID)
            originals[info.ID]=count;city:SetNumRealBuilding(info.ID,count+1)
            LekmodScenarioEvent("fixture-setup",{operation="provided-maintenance-building",type=name,original=count,maintenance=info.GoldMaintenance,gold_rate100=player:CalculateGoldRateTimes100(),science100=player:GetScienceTimes100()})
            if player:GetScienceTimes100()==0 and player:GetScienceFromBudgetDeficitTimes100()<0 then break end
        end
        before=LekmodScenario.snapshot(player)
        LekmodScenarioEvent("deficit-before-turn",before)
        assert(before.gold_rate100<0 and before.science100==0,"provided maintenance did not create zero-science deficit")
        phase="deficit";return "turn"
    elseif phase=="deficit" then
        if Game.GetGameTurn()==initial then return "turn" end
        assert(Game.GetGameTurn()==initial+1,"deficit must settle in exactly one ordinary turn")
        local s=LekmodScenario.snapshot(player)
        assert(s.gold==0,"treasury became negative")
        assert(LekmodScenarioJSON(s.research)==LekmodScenarioJSON(before.research),"zero-science turn changed research progress/counts/overflow")
        LekmodScenarioEvent("deficit-after-turn",s)
        LekmodScenarioRecord("deficit-gold-floor","PASS","path=ordinary-turn balance=0")
        LekmodScenarioRecord("deficit-research-floor","PASS","all-tech-progress-counts-overflow-preserved=true")
        for id,count in pairs(originals) do city:SetNumRealBuilding(id,count) end
        player:SetGold(100)
        LekmodScenarioEvent("fixture-setup",{operation="restored-buildings-and-provided-covered-treasury",gold=100})
        recovery=LekmodScenario.snapshot(player)
        assert(recovery.science100>0 and recovery.deficit100==0,"science did not recover with the restored maintenance and covered treasury")
        LekmodScenarioEvent("recovery-before-turn",recovery)
        phase="recovery";return "turn"
    elseif phase=="recovery" then
        if Game.GetGameTurn()==initial+1 then return "turn" end
        assert(Game.GetGameTurn()==initial+2,"recovery must settle in exactly one ordinary turn")
        local s=LekmodScenario.snapshot(player)
        assert(s.gold==math.floor((recovery.gold*100+recovery.gold_rate100)/100),"treasury differs from quoted recovery settlement")
        local actual=s.research.total100+s.research.overflow*100
        local expected=recovery.research.total100+recovery.research.overflow*100+recovery.science100
        assert(actual==expected,"recovery research differs from quoted canonical science")
        for id,row in pairs(s.research.technologies) do
            assert(row.known==recovery.research.technologies[id].known and row.count==recovery.research.technologies[id].count,"fixture completed a technology; progress sum is not a valid oracle")
        end
        for id,count in pairs(originals) do assert(city:GetNumRealBuilding(id)==count,"temporary maintenance building remained") end
        LekmodScenarioEvent("recovery-after-turn",s)
        LekmodScenarioRecord("budget-recovery-settlement","PASS","path=ordinary-turn exact-gold-and-research-deltas=true")
        return true
    end
    return false
end
