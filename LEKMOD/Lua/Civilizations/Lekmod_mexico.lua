-- Author: EnormousApplePie
include("Lekmod_utilities.lua")

local this_civ = GameInfoTypes["CIVILIZATION_MEXICO"]
local is_active = LekmodUtilities:is_civilization_active(this_civ)

-- Minor settlers found their capitals after the first major-player callbacks.
-- Reveal their starting locations for every Mexico player, then refresh the
-- city visibility when the actual capital is founded during that opening turn.
local function reveal_for_mexico(plot)
    if not plot then return end
    for _, player in pairs(Players) do
        if player:IsAlive() and player:GetCivilizationType() == this_civ then
            local start_plot = player:GetStartingPlot()
            if start_plot then
                local distance = Map.PlotDistance(start_plot:GetX(), start_plot:GetY(), plot:GetX(), plot:GetY())
                if distance > 0 and distance <= 10 then
                    plot:SetRevealed(player:GetTeam(), true)
                end
            end
        end
    end
end

function lekmod_mexico_initial_locations()
    if Game.GetElapsedGameTurns() ~= 0 then return end
    for _, player in pairs(Players) do
        if player:IsAlive() and player:IsMinorCiv() then
            reveal_for_mexico(player:GetStartingPlot())
        end
    end
end

function lekmod_mexico_initial_city(player_id, x, y)
    if Game.GetElapsedGameTurns() ~= 0 then return end
    local player = Players[player_id]
    if not player or not player:IsAlive() or not player:IsMinorCiv() then return end
    -- Reapplying true also reveals the newly founded city on an already known
    -- plot. No fog is cleared or reset first.
    reveal_for_mexico(Map.GetPlot(x, y))
end

if is_active then
    Events.SequenceGameInitComplete.Add(lekmod_mexico_initial_locations)
    GameEvents.PlayerCityFounded.Add(lekmod_mexico_initial_city)
end
