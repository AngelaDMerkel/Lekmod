-- Treasury balances are supplied inputs, restored before saving. No turn,
-- research progress, income rate, science yield or synchronization flag is set.
LekmodScenario={name="budget-science",items={"budget-science-boundaries","treasury-restored"}}
function LekmodScenario.snapshot(player)
    return {turn=Game.GetGameTurn(),gold=player:GetGold(),gold_rate100=player:CalculateGoldRateTimes100(),
        science100=player:GetScienceTimes100(),generic_science100=player:GetYieldTimes100(YieldTypes.YIELD_SCIENCE),
        deficit100=player:GetScienceFromBudgetDeficitTimes100(),anarchy=player:IsAnarchy()}
end
local function research(player)
    local techs=Teams[player:GetTeam()]:GetTeamTechs()
    local result={overflow=player:GetOverflowResearch(),technologies={}}
    for tech in GameInfo.Technologies() do
        result.technologies[tech.ID]={known=techs:HasTech(tech.ID),count=techs:GetTechCount(tech.ID),progress100=techs:GetResearchProgressTimes100(tech.ID)}
    end
    return LekmodScenarioJSON(result)
end
function LekmodScenario.step(player)
    local initial=LekmodScenario.snapshot(player)
    assert(initial.gold_rate100<0 and not initial.anarchy,"requires an ordinary negative-income fixture")
    local before=research(player)
    local cover=math.ceil(-initial.gold_rate100/100)
    player:SetGold(cover+100)
    local base=player:GetScienceTimes100()
    assert(base>0 and player:GetScienceFromBudgetDeficitTimes100()==0,"covered treasury must retain positive science")
    LekmodScenarioEvent("fixture-setup",{operation="provided-temporary-treasury-balances",original=initial.gold,covered=cover,unpenalized_science100=base})
    local seen={}
    for _,balance in ipairs({cover+100,0,1,math.max(0,cover-1),cover}) do
        if not seen[balance] then
            seen[balance]=true;player:SetGold(balance)
            local s=LekmodScenario.snapshot(player)
            local deficit=math.min(0,balance*100+initial.gold_rate100)
            assert(s.gold_rate100==initial.gold_rate100,"changing treasury changed the income rate")
            assert(s.deficit100==deficit,"deficit query did not honor the treasury boundary")
            assert(s.science100==math.max(0,base+deficit),"science did not retain the zero floor or partial-deficit rate")
            LekmodScenarioEvent("budget-science-boundary",s)
        end
    end
    player:SetGold(initial.gold)
    assert(LekmodScenarioJSON(LekmodScenario.snapshot(player))==LekmodScenarioJSON(initial),"treasury/query state was not restored")
    assert(research(player)==before,"query fixture changed technology progress, counts or overflow")
    LekmodScenarioRecord("budget-science-boundaries","PASS","path=native-queries supplied-treasury-inputs no-turn-settlement-claim")
    LekmodScenarioRecord("treasury-restored","PASS","original-balance-and-research-preserved=true")
    return true
end
