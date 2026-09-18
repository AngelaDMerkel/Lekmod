include("Lekmod_utilities.lua")

local this_civ = GameInfoTypes["CIVILIZATION_VENEZ"]
local compassTech = GameInfoTypes["TECH_COMPASS"]

-- Each team's Compass change belongs to its own Venice players. Keep the
-- listener: another Venice may research Compass on a later turn.
function lekmod_venice_route_compass(team_id, tech_id, change)
    if tech_id ~= compassTech or not change or change == 0 then return end
    for _, player in pairs(Players) do
        if player:IsAlive() and player:GetTeam() == team_id
            and player:GetCivilizationType() == this_civ then
            player:ChangeNumMiscTradeRoutes(change)
        end
    end
end

-- This is Lekmod's only miscellaneous-route award. Recover older saves where
-- the first Venice removed the listener before another team learned Compass,
-- and late-era starts where the technology predates this Lua context. Preserve
-- existing awards (including any larger externally supplied value) on reload.
local function restore_known_compass_routes()
    for _, player in pairs(Players) do
        if player:IsAlive() and player:GetCivilizationType() == this_civ
            and player:GetNumMiscTradeRoutes() == 0
            and Teams[player:GetTeam()]:GetTeamTechs():HasTech(compassTech) then
            player:ChangeNumMiscTradeRoutes(1)
        end
    end
end

if LekmodUtilities:is_civilization_active(this_civ) then
    GameEvents.TeamTechResearched.Add(lekmod_venice_route_compass)
    Events.SequenceGameInitComplete.Add(restore_known_compass_routes)
end
