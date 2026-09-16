-- Author: 404NotFound & EnormousApplePie

include("Lekmod_utilities.lua")
include("PlotIterators.lua")

local this_civ = GameInfoTypes["CIVILIZATION_PALMYRA"]
local is_active = LekmodUtilities:is_civilization_active(this_civ)

------------------------------------------------------------------------------------------------------------------------
-- Palmyra UA: Add fresh water to cities settled
------------------------------------------------------------------------------------------------------------------------
function lekmod_ua_palmyra_add_fresh_water(player_id, x, y, new_player_id)

   local player = Players[player_id]
   local new_player = Players[new_player_id]

   -- The old owner can already be eliminated when CityCaptureComplete fires.
   -- Either civilization makes the capture relevant, but the current city
   -- owner decides whether the ability still applies (including duplicates).
   if (not player or player:GetCivilizationType() ~= this_civ)
      and (not new_player or new_player:GetCivilizationType() ~= this_civ) then
      return
   end

   local plot = Map.GetPlot(x, y)
   local owner = Players[plot:GetOwner()]
   local is_owned = plot:IsCity() and owner and owner:IsAlive()
      and owner:GetCivilizationType() == this_civ

   for loop_plot in PlotAreaSweepIterator(plot, 1, SECTOR_NORTH, DIRECTION_CLOCKWISE, DIRECTION_OUTWARDS, CENTRE_EXCLUDE) do

      if is_owned then
         if not loop_plot:IsWater() then
            loop_plot:SetFreshWater(true)
         end
      else
         loop_plot:SetFreshWater(false)
      end
   end

end
function lekmod_ua_palmyra_add_fresh_water_city_capture(player_id, _, x, y, new_player_id)

   lekmod_ua_palmyra_add_fresh_water(player_id, x, y, new_player_id)

end

if is_active then
   GameEvents.PlayerCityFounded.Add(lekmod_ua_palmyra_add_fresh_water)
   GameEvents.CityCaptureComplete.Add(lekmod_ua_palmyra_add_fresh_water_city_capture)
end
