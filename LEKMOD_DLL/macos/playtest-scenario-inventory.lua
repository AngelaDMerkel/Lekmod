LekmodScenario = {name="inventory", items={"system-inventory"}}
function LekmodScenario.snapshot(player)
    local result = {turn=Game.GetGameTurn(), human=player:GetID(),
        religion_disabled=Game.IsOption(GameOptionTypes.GAMEOPTION_NO_RELIGION),
        religions=Game.GetNumReligionsFounded(), religions_available=Game.GetNumReligionsStillToFound(),
        league=Game.GetActiveLeague() ~= nil, players={}}
    for id = 0, GameDefines.MAX_CIV_PLAYERS - 1 do
        local other = Players[id]
        if other and other:IsAlive() then
            local entry = {minor=other:IsMinorCiv(), era=other:GetCurrentEra(), gold=other:GetGold(),
                faith=other:GetFaith(), religion=other:GetReligionCreatedByPlayer(), spies=other:GetNumSpies(),
                routes_used=other:GetNumInternationalTradeRoutesUsed(), routes_max=other:GetNumInternationalTradeRoutesAvailable(),
                met=Teams[player:GetTeam()]:IsHasMet(other:GetTeam()), cities={}}
            for city in other:Cities() do
                entry.cities[city:GetID()] = {x=city:GetX(), y=city:GetY(), population=city:GetPopulation(),
                    majority=city:GetReligiousMajority(), holy=city:IsHolyCityAnyReligion(), faith=city:GetFaithPerTurn()}
            end
            result.players[id] = entry
        end
    end
    result.spies=player:GetEspionageSpies()
    result.trade_routes={}
    for index, route in ipairs(player:GetTradeRoutes()) do
        local row={}
        for key, value in pairs(route) do
            if key == "FromCity" or key == "ToCity" then row[key]=value:GetID()
            else row[key]=value end
        end
        result.trade_routes[index]=row
    end
    return result
end
function LekmodScenario.step(player)
    local snapshot = LekmodScenario.snapshot(player)
    LekmodScenarioEvent("system-inventory", snapshot)
    LekmodScenarioRecord("system-inventory", "PASS", "scope=read-only-inventory actions=0")
    return true
end
