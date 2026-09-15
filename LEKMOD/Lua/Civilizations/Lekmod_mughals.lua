-- Author: EnormousApplePie

include("Lekmod_utilities.lua")
include("PlotIterators.lua")

local this_civ = GameInfoTypes["CIVILIZATION_MUGHALS"]
local is_active = LekmodUtilities:is_civilization_active(this_civ)

local DUMMY_BUILDING = "BUILDING_DUMMY_MUGHALS"

------------------------------------------------------------------------------------------------------------------------
-- Mughal UA: Foreign religions give benefits to both the Mughal city and the religion's holy city
------------------------------------------------------------------------------------------------------------------------

-- Rebuild the shared benefit from all living Mughal cities. A holy city can
-- have multiple contributing cities/players and can change owner, so updating
-- just the triggering player's cities leaves stale or missing benefits.
local function rebuild_mughal_religion_benefits()
   local dummy_building_id = GameInfoTypes[DUMMY_BUILDING]
   if not dummy_building_id then
      print("Error: Could not find " .. DUMMY_BUILDING)
      return
   end
   local wanted, religions = {}, {}
   for player_id = 0, GameDefines.MAX_CIV_PLAYERS do
      local player = Players[player_id]
      if player and player:IsAlive() and player:GetCivilizationType() == this_civ then
         local own_religion = player:HasCreatedReligion() and player:GetReligionCreatedByPlayer() or -1
         for city in player:Cities() do
            local religion = city:GetReligiousMajority()
            if religion ~= -1 and religion ~= ReligionTypes.RELIGION_PANTHEON and religion ~= own_religion then
               wanted[player_id .. ":" .. city:GetID()] = true
               religions[religion] = true
            end
         end
      end
   end
   for player_id = 0, GameDefines.MAX_CIV_PLAYERS do
      local player = Players[player_id]
      if player and player:IsAlive() then
         for city in player:Cities() do
            local has_benefit = wanted[player_id .. ":" .. city:GetID()] or false
            for religion in pairs(religions) do
               if city:IsHolyCityForReligion(religion) then has_benefit = true; break end
            end
            if city:IsHasBuilding(dummy_building_id) ~= has_benefit then
               city:SetNumRealBuilding(dummy_building_id, has_benefit and 1 or 0)
            end
         end
      end
   end
end

function lekmod_ua_mughals_foreign_religion_check(player_id)
   local player = Players[player_id]
   if player and player:GetCivilizationType() == this_civ then
      rebuild_mughal_religion_benefits()
   end
end

-- Callback for when a city changes religion
function lekmod_ua_mughals_religion_changed(player_id, religion_id, x, y)
   lekmod_ua_mughals_foreign_religion_check(player_id)
end

-- Callback for turn start to ensure everything is up to date
function lekmod_ua_mughals_turn_start(player_id)
   lekmod_ua_mughals_foreign_religion_check(player_id)
end

-- Check when a city is acquired (captured or traded)
function lekmod_ua_mughals_city_acquired(old_owner_id, was_capital, x, y, new_owner_id)
   -- Capturing a foreign holy city also matters, even when neither owner is
   -- Mughal. The C++ event supplies the new owner as its fifth argument.
   rebuild_mughal_religion_benefits()
end

-- Register events if Mughal civilization is active
if is_active then
   GameEvents.PlayerDoTurn.Add(lekmod_ua_mughals_turn_start)
   GameEvents.CityConvertsReligion.Add(lekmod_ua_mughals_religion_changed)
   GameEvents.CityCaptureComplete.Add(lekmod_ua_mughals_city_acquired)
   GameEvents.PlayerCityFounded.Add(function(player_id) lekmod_ua_mughals_foreign_religion_check(player_id) end)
end
