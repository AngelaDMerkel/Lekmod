-- Author: EnormousApplePie & 404NotFound & Loup fixing Loup's fuckups ~~

include("Lekmod_utilities.lua")
include("PlotIterators.lua")

local this_civ = GameInfoTypes["CIVILIZATION_SWISS"]
local is_active = LekmodUtilities:is_civilization_active(this_civ)
-----------------------------------------------------------------------------------------------------------------------
-- Switzerland UU: Reislaufer. Check if the unit that just moved is a reislaufer and if it is near a mountain. If it is,
-- give it the active promotion. If it is not, remove the active promotion.
------------------------------------------------------------------------------------------------------------------------
local mountaineer = GameInfoTypes["PROMOTION_SWISS_MOUNTAINEER"];
local mountaineer_active = GameInfoTypes["PROMOTION_SWISS_MOUNTAINEER_ACTIVE"];

local function refresh_mountain_bonus(player_id, unit_id, fresh_unit)
   local player = Players[player_id]
   local unit = player and player:GetUnitByID(unit_id)
   if not unit or not unit:GetPlot() or not unit:IsHasPromotion(mountaineer) then return end

   -- The active promotion is derived from the current plot, including after
   -- city promotions and conversion have finished copying onto the unit.
   local nearby = unit:IsNearTerrainType(GameInfoTypes["TERRAIN_MOUNTAIN"], 1, false)
   if unit:IsHasPromotion(mountaineer_active) == nearby then return end
   local old_max = unit:MaxMoves()
   local was_full = unit:MovesLeft() == old_max
   unit:SetHasPromotion(mountaineer_active, nearby)
   -- Creation sets the movement allowance before Lua applies this bonus.
   -- Only a fresh, fully mobile unit receives the newly added allowance.
   -- Never refund spent movement or unlock a zero-move purchase.
   if fresh_unit and nearby and was_full and old_max > 0 then
      unit:SetMoves(unit:MaxMoves())
   end
end

function lekmod_switzerland_uu_mountain_bonus(player_id, unit_id)
   refresh_mountain_bonus(player_id, unit_id, false)
end

-- Unique units retain their ability under foreign and minor owners.
GameEvents.UnitSetXY.Add(lekmod_switzerland_uu_mountain_bonus)
GameEvents.UnitCreated.Add(function(player_id, unit_id)
   refresh_mountain_bonus(player_id, unit_id, true)
end)
GameEvents.CityTrained.Add(function(player_id, city_id, unit_id)
   refresh_mountain_bonus(player_id, unit_id, true)
end)
GameEvents.UnitConverted.Add(function(old_player_id, new_player_id, old_unit_id, new_unit_id)
   refresh_mountain_bonus(new_player_id, new_unit_id, false)
end)
Events.SequenceGameInitComplete.Add(function()
   for player_id = 0, GameDefines.MAX_CIV_PLAYERS - 1 do
      local player = Players[player_id]
      if player and player:IsAlive() then
         for unit in player:Units() do
            refresh_mountain_bonus(player_id, unit:GetID(), false)
         end
      end
   end
end)
