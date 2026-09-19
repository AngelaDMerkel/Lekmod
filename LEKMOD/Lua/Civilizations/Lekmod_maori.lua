-- Author: EnormousApplePie

include("Lekmod_utilities.lua")

local this_civ = GameInfoTypes["CIVILIZATION_MAORI"]
local is_active = LekmodUtilities:is_civilization_active(this_civ)

------------------------------------------------------------------------------------------------------------------------
-- Maori UA. Remove the opening bonus after five elapsed turns, then expire new units
-- on their next owner turn. Movement was refreshed before this callback.
------------------------------------------------------------------------------------------------------------------------
function lekmod_maori_ua(player_id)

   local maori_promotion_id = GameInfoTypes["PROMOTION_MAORI"]
   local maori_promotion_civilian_id = GameInfoTypes["PROMOTION_MAORI_CIVILIAN"]

	local player = Players[player_id]
	local game_turn = Game.GetGameTurn()

	-- The temporary promotion can be inherited through gifts or capture.
   if not player:IsAlive() then return end

   if Game.GetElapsedGameTurns() < 5 then return end

   -- City production runs before PlayerDoTurn; newborn units keep their first turn.
   local expired_units = {}
   for unit in player:Units() do
      if (unit:IsHasPromotion(maori_promotion_id) or unit:IsHasPromotion(maori_promotion_civilian_id)) and unit:GetGameTurnCreated() < game_turn then
         unit:SetHasPromotion(maori_promotion_id, false)
         unit:SetHasPromotion(maori_promotion_civilian_id, false)
         expired_units[#expired_units + 1] = unit
      end
   end

   -- Remove all bonuses before querying stack donors; iterator order must not
   -- preserve a donor's expired movement. Never increase spent movement.
   for _, unit in ipairs(expired_units) do
      -- Older DLLs do not expose the stack-aware query; preserve compatibility.
      if unit.MaxMovesWithStack then
         local allowance = unit:MaxMovesWithStack()
         if unit:GetMoves() > allowance then unit:SetMoves(allowance) end
      end
   end

end
------------------------------------------------------------------------------------------------------------------------
if is_active then
   GameEvents.PlayerDoTurn.Add(lekmod_maori_ua)
end