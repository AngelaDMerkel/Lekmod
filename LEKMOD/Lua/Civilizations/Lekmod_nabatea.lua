-- Author: EnormousApplePie
include("Lekmod_utilities.lua")
include("PlotIterators.lua")

local this_civ = GameInfoTypes["CIVILIZATION_NABATEA"]
local is_active = LekmodUtilities:is_civilization_active(this_civ)
------------------------------------------------------------------------------------------------------------------------
-- Nabatea UU. Award gold for discovering cities with a Zabonah.
------------------------------------------------------------------------------------------------------------------------
function lekmod_nabatea_unit_exploration(player_id, unit, unit_x, unit_y)

   local nabatea_unit = GameInfoTypes["UNIT_MC_ZABONAH"]
	local player = Players[player_id]
	if not player or not player:IsAlive() then return end
	local unit_id = player:GetUnitByID(unit)
	if not unit_id or unit_id:IsDelayedDeath() or unit_id:GetUnitType() ~= nabatea_unit then return end

	-- Unit removal also emits UnitSetXY with an invalid map position.
	local unit_plot = Map.GetPlot(unit_x, unit_y)
	if not unit_plot then return end
	local unit_team = unit_id:GetTeam()

	for loop_plot in PlotAreaSweepIterator(unit_plot, unit_id:VisibilityRange() + 3, SECTOR_NORTH, DIRECTION_CLOCKWISE, DIRECTION_OUTWARDS, CENTRE_EXCLUDE) do
		local city = loop_plot:GetPlotCity()
		if not city then -- skip
      elseif not(city:IsRevealed(unit_team)) and city:IsCapital() then

         loop_plot:SetRevealed(unit_team, true)
         local reward_amount = 10
         player:ChangeGold(reward_amount)

         if (player:IsHuman() and Game.GetActivePlayer() == player_id and reward_amount > 0 ) then
            local popup_text = Locale.ConvertTextKey("TXT_KEY_ZABONAH_DISCOVERED_CITY", reward_amount, city:GetName())
            Events.GameplayAlertMessage(popup_text)
         end
		end
	end

end
------------------------------------------------------------------------------------------------------------------------
   -- A unique unit can be present in the game without the civilization being active.
   GameEvents.UnitSetXY.Add(lekmod_nabatea_unit_exploration)