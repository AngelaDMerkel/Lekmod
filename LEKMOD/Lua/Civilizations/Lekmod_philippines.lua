
-- Author: EnormousApplePie
include("Lekmod_utilities.lua")

local this_civ = GameInfoTypes["CIVILIZATION_PHILIPPINES"]
local is_active = LekmodUtilities:is_civilization_active(this_civ)

------------------------------------------------------------------------------------------------------------------------
-- Philippines UA. Add a building to a new city that gives +1 population to the city until the maximum is reached.
------------------------------------------------------------------------------------------------------------------------
local dummy_building = GameInfoTypes["BUILDING_PHILIPPINES_TRAIT"]
local bonus_cities_amount = 2

local function has_remaining_expansion_bonus(player)
   if player.GetNumCitiesFounded then
      -- The capital counts as the first founded city. This serialized lifetime
      -- count survives captures/razing and ignores cities acquired from others.
      return player:GetNumCitiesFounded() <= bonus_cities_amount + 1
   end
   -- Preserve compatibility with older DLLs that lack the history query.
   return player:CountNumBuildings(dummy_building) < bonus_cities_amount
end


function lekmod_philippine_expand_population(player_id, iX, iY)
   local player = Players[player_id]
   if player:GetCivilizationType() == this_civ
      and player:IsAlive()
      and has_remaining_expansion_bonus(player)
   then
      local plot = Map.GetPlot(iX, iY)
      local city = plot:GetPlotCity()
      if not city:IsCapital() then
         city:SetNumRealBuilding(dummy_building, 1)
      end
   end
end
------------------------------------------------------------------------------------------------------------------------
if is_active then
   GameEvents.PlayerCityFounded.Add(lekmod_philippine_expand_population)
end