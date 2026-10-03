------------------------------------------------------------------------------------------------------------------------
-- Resettlements. Add a few buildings to newly founded cities if the player has the policy
------------------------------------------------------------------------------------------------------------------------
function lekmod_resettlements_policy_new_buildings(player_id, x, y)

    local player = Players[player_id]
    if not player:HasPolicy(GameInfo.Policies["POLICY_RESETTLEMENT"].ID) then return end

    for loopCity in player:Cities() do
        if (loopCity:GetX() == x and loopCity:GetY() == y) then
            --Note: SetNumRealBuildingClass is a lekmod method. It is not available in the base game
            loopCity:SetNumRealBuildingClass(GameInfoTypes["BUILDINGCLASS_WORKSHOP"], 1)
            loopCity:SetNumRealBuildingClass(GameInfoTypes["BUILDINGCLASS_GRANARY"], 1)
            loopCity:SetNumRealBuildingClass(GameInfoTypes["BUILDINGCLASS_AQUEDUCT"], 1)
            loopCity:SetNumRealBuildingClass(GameInfoTypes["BUILDINGCLASS_MONUMENT"], 1)
            loopCity:SetNumRealBuildingClass(GameInfoTypes["BUILDINGCLASS_LIBRARY"], 1)
        end
    end

end
GameEvents.PlayerCityFounded.Add(lekmod_resettlements_policy_new_buildings)
------------------------------------------------------------------------------------------------------------------------
-- Policy_FreePromotionUnitCombats. Give a free promotion to units for specific combat classes as put in the xml table
------------------------------------------------------------------------------------------------------------------------
function lekmod_policy_free_promotion_unit_combats(player_id, unit_id)

    local player = Players[player_id]
    local unit = player:GetUnitByID(unit_id)
    if not player:IsAlive() or not unit then return end

    for row in GameInfo.Policy_FreePromotionUnitCombats() do

        local policy_id = GameInfoTypes[row.PolicyType]
        local promotion_id = GameInfoTypes[row.PromotionType]
        local combat_class_id = GameInfoTypes[row.UnitCombatType]

        if player:HasPolicy(policy_id)
        and unit:GetUnitCombatType() == combat_class_id
        and (not unit:IsHasPromotion(promotion_id)) then

            unit:SetHasPromotion(promotion_id, true)

        end

    end

end

function lekmod_policy_free_promotion_unit_combats_on_adopt(player_id)

    local player = Players[player_id]

    -- Apply to all the right currently existing units once upon adopting the policy
    for unit in player:Units() do
        if unit then
            lekmod_policy_free_promotion_unit_combats(player_id, unit:GetID())
        end
    end

end
GameEvents.PlayerAdoptPolicy.Add(lekmod_policy_free_promotion_unit_combats_on_adopt)
GameEvents.UnitCreated.Add(lekmod_policy_free_promotion_unit_combats)
------------------------------------------------------------------------------------------------------------------------
-- The saved policy-vote counter contains active policy base votes plus this
-- Consulates era bonus. Recompute that derived total so repeated notifications
-- cannot stack and old saves with a missed adopter recover their entitlement.
local function RefreshConsulatesVotes(player)
    local consulates = GameInfoTypes["POLICY_CONSULATES"]
    if not player or not player:IsAlive() or not player:HasPolicy(consulates) then return end

    local expected = 0
    for policy in GameInfo.Policies() do
        if player:HasPolicy(policy.ID) and not player:IsPolicyBlocked(policy.ID) then
            expected = expected + (policy.NumExtraLeagueVotes or 0)
        end
    end
    if not player:IsPolicyBlocked(consulates) then
        local era = player:GetCurrentEra()
        for _, threshold in ipairs({GameInfoTypes["ERA_INDUSTRIAL"],
            GameInfoTypes["ERA_MODERN"], GameInfoTypes["ERA_POSTMODERN"],
            GameInfoTypes["ERA_FUTURE"]}) do
            if era >= threshold then expected = expected + 1 end
        end
    end
    local difference = expected - player:GetNumPolicyLeagueVotes()
    if difference ~= 0 then player:ChangeNumPolicyLeagueVotes(difference) end
end

function Lekmod_OnAdoptConsulates(playerID, policyID)
    if policyID == GameInfoTypes["POLICY_CONSULATES"] then
        RefreshConsulatesVotes(Players[playerID])
    end
end

function Lekmod_OnEraChangeGiveConsulatesVote(teamID, newEraID)
    -- TeamSetEra supplies a team ID. Single-player teammates need independent
    -- rewards, and a different player's matching numeric ID is not an owner.
    for playerID = 0, GameDefines.MAX_MAJOR_CIVS - 1 do
        local player = Players[playerID]
        if player and player:GetTeam() == teamID then RefreshConsulatesVotes(player) end
    end
end

function Lekmod_RefreshConsulatesOnLoad()
    for playerID = 0, GameDefines.MAX_MAJOR_CIVS - 1 do
        RefreshConsulatesVotes(Players[playerID])
    end
end

GameEvents.PlayerAdoptPolicy.Add(Lekmod_OnAdoptConsulates)
GameEvents.TeamSetEra.Add(Lekmod_OnEraChangeGiveConsulatesVote)
Events.SequenceGameInitComplete.Add(Lekmod_RefreshConsulatesOnLoad)
