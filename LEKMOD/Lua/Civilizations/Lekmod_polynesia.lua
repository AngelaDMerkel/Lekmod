-- Author: EnormousApplePie
include("Lekmod_utilities.lua")

local this_civ = GameInfoTypes["CIVILIZATION_POLYNESIA"]
local is_active = LekmodUtilities:is_civilization_active(this_civ)

------------------------------------------------------------------------------------------------------------------------
-- Polynesia UA Bug fix : Remove ocean impassable promotion from upgraded units (galley -> galleas)
------------------------------------------------------------------------------------------------------------------------
function lekmod_polynesia_ua_ocean_impassable_fix(player_id)

	local player = Players[player_id]
	if not player:IsAlive() or player:GetCivilizationType() ~= this_civ then return end

   for unit in player:Units() do
      if unit:IsHasPromotion(GameInfoTypes["PROMOTION_OCEAN_IMPASSABLE"]) then
         unit:SetHasPromotion(GameInfoTypes["PROMOTION_OCEAN_IMPASSABLE"], false)
      end
   end

end
------------------------------------------------------------------------------------------------------------------------
-- Older saves can retain the promotion copied by an upgrade. Reconcile this
-- derived trait state once the loaded players and units are available.
local function restore_polynesia_ocean_access()
   for player_id = 0, GameDefines.MAX_MAJOR_CIVS - 1 do
      if Players[player_id] then
         lekmod_polynesia_ua_ocean_impassable_fix(player_id)
      end
   end
end

if is_active then
   Events.SequenceGameInitComplete.Add(restore_polynesia_ocean_access)
   -- Note: UnitCreated is a Lekmod event! Not in the base game.
   GameEvents.UnitCreated.Add(lekmod_polynesia_ua_ocean_impassable_fix)
   -- Conversion reapplies the target type's free promotions after creation.
   -- Refresh the recipient after that copy, including paid upgrades and gifts.
   GameEvents.UnitConverted.Add(function(old_player_id, new_player_id)
      lekmod_polynesia_ua_ocean_impassable_fix(new_player_id)
   end)
end