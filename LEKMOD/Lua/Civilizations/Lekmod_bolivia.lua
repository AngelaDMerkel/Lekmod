-- Author: EnormousApplePie

include("Lekmod_utilities.lua")

local this_civ = GameInfoTypes["CIVILIZATION_BOLIVIA"]
local is_active = LekmodUtilities:is_civilization_active(this_civ)

-- Write to the save file for remembering the last expended great person
Lek_SaveData = Modding.OpenSaveData()

Lek_Properties = {}

function lekmod_bolivia_get_persistent_property(name)
   if not Lek_Properties[name] then
      Lek_Properties[name] = Lek_SaveData.GetValue(name)
   end
   return Lek_Properties[name]
end

function lekmod_bolivia_set_persistent_data(name, value)
   if lekmod_bolivia_get_persistent_property(name) == value then return end
   Lek_SaveData.SetValue(name, value)
   Lek_Properties[name] = value
end


------------------------------------------------------------------------------------------------------------------------
-- Bolivia UA. Add a dummy building that either gives +1 production or +1 food to mines globally when
-- either a writer or artist is expended. Save this data to the save file so that it can be remembered
------------------------------------------------------------------------------------------------------------------------
local function last_expended_for_player(player_id)
   local key = "bolivia_last_expended_" .. player_id
   local value = lekmod_bolivia_get_persistent_property(key)
   if value ~= nil then return tonumber(value) end
   -- Older saves stored one player's unit type and ID concatenated together.
   -- Migrate only a matching owner; never copy another Bolivia's history.
   local legacy = tostring(lekmod_bolivia_get_persistent_property("bolivia_last_expended") or "")
   for _, unit_type in ipairs({GameInfoTypes.UNIT_ARTIST, GameInfoTypes.UNIT_WRITER}) do
      if legacy == unit_type .. player_id then
         lekmod_bolivia_set_persistent_data(key, unit_type)
         return unit_type
      end
   end
end

local function refresh_bolivia_benefit(player_id)
   local player = Players[player_id]
   if not player then return end
   local capital, last
   if player:IsAlive() and player:GetCivilizationType() == this_civ then
      capital = player:GetCapitalCity()
      last = last_expended_for_player(player_id)
   end
   for city in player:Cities() do
      local production = city == capital and last == GameInfoTypes.UNIT_ARTIST and 1 or 0
      local food = city == capital and last == GameInfoTypes.UNIT_WRITER and 1 or 0
      city:SetNumRealBuilding(GameInfoTypes.BUILDING_BOLIVIA_TRAIT_PRODUCTION, production)
      city:SetNumRealBuilding(GameInfoTypes.BUILDING_BOLIVIA_TRAIT_FOOD, food)
   end
end

function lekmod_bolivia_is_person_expended(player_id, unit_id, arg3, arg4, new_player_id)
   local player = Players[player_id]
   if not player then return end
   -- GreatPersonExpended has two arguments. PlayerCityFounded supplies x/y,
   -- and CityCaptureComplete supplies the new owner in argument five.
   local expended = arg3 == nil and arg4 == nil and new_player_id == nil and
      (unit_id == GameInfoTypes.UNIT_ARTIST or unit_id == GameInfoTypes.UNIT_WRITER)
   if expended and player:IsAlive() and player:GetCivilizationType() == this_civ then
      lekmod_bolivia_set_persistent_data("bolivia_last_expended_" .. player_id, unit_id)
      if player:IsHuman() and Game.GetActivePlayer() == player_id then
         local key = unit_id == GameInfoTypes.UNIT_ARTIST and
            "TXT_KEY_THP_BOLIVIA_BUTTON_TITLE_RIGHT" or "TXT_KEY_THP_BOLIVIA_BUTTON_TITLE_LEFT"
         Events.GameplayAlertMessage(Locale.ConvertTextKey(key))
      end
   end
   refresh_bolivia_benefit(player_id)
   if new_player_id ~= nil and new_player_id ~= player_id then
      refresh_bolivia_benefit(new_player_id)
   end
end

function lekmod_bolivia_retain_building_capture(player_id)
   refresh_bolivia_benefit(player_id)
end
------------------------------------------------------------------------------------------------------------------------
-- Bolivia UU. Colorado. Add a combat strength bonus to the Colorado unit based on excess happiness.
------------------------------------------------------------------------------------------------------------------------
-- Note: Might want to make a lua hook for when a player's happiness changes to update the combat strength better
function lekmod_bolivia_uu_combat_strength(player_id, unit_id)


   local colorado_unit_id = GameInfoTypes["UNIT_COLORADO"]
	local player = Players[player_id]
	if not player or not player:IsAlive() then return end
   -- UnitCreated supplies an instance ID, not a unit type. HappinessChanged
   -- supplies only the player and should refresh every Colorado it owns.
   if unit_id ~= nil then
      local created = player:GetUnitByID(unit_id)
      if not created or created:GetUnitType() ~= colorado_unit_id then return end
   end
	local colorado_base_strength = GameInfo.Units[colorado_unit_id].Combat
	local happiness_number = player:GetExcessHappiness()
	local bonus_combat_strength = math.min(LekmodUtilities:get_round(happiness_number/5))
   local strength_to_set = colorado_base_strength
	if (bonus_combat_strength > 0 ) then
		strength_to_set = colorado_base_strength + (bonus_combat_strength * 2)
	end
	for unit in player:Units() do
		if unit:GetUnitType() == colorado_unit_id then
			unit:SetBaseCombatStrength(strength_to_set)
		end
	end
end
------------------------------------------------------------------------------------------------------------------------
if is_active then
	--GameEvents.PlayerDoTurn.Add(bolivia_uu_combat_strength)
   -- Note: PlayerHappinessChanged is a Lekmod specific event
	
	GameEvents.GreatPersonExpended.Add(lekmod_bolivia_is_person_expended)
   GameEvents.CityCaptureComplete.Add(lekmod_bolivia_is_person_expended)
   GameEvents.PlayerCityFounded.Add(lekmod_bolivia_is_person_expended)
end
GameEvents.PlayerHappinessChanged.Add(lekmod_bolivia_uu_combat_strength)
GameEvents.UnitCreated.Add(lekmod_bolivia_uu_combat_strength)
------------------------------------------------------------------------------------------------------------------------
