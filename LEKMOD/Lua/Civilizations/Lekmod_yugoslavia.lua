-- Author: EnormousApplePie

include("Lekmod_utilities.lua")

local this_civ = GameInfoTypes["CIVILIZATION_YUGOSLAVIA"]
local is_active = LekmodUtilities:is_civilization_active(this_civ)

------------------------------------------------------------------------------------------------------------------------
-- Yugoslavia UA: Award a free Tenet when adopting or switching Ideologies
------------------------------------------------------------------------------------------------------------------------
function lekmod_yugoslavia_ideology_tenet(player_id, policy_branch_id)

   local player = Players[player_id]
   if player:GetCivilizationType() ~= this_civ or not player:IsAlive() then return end

   -- Normal human and AI revolutions set anarchy before this event. The trait
   -- also promises its free tenet when switching, so anarchy is not a rejection.

   if policy_branch_id == GameInfoTypes["POLICY_BRANCH_AUTOCRACY"]
   or policy_branch_id == GameInfoTypes["POLICY_BRANCH_FREEDOM"]
   or policy_branch_id == GameInfoTypes["POLICY_BRANCH_ORDER"] then
      local free_tenets = player:GetNumFreeTenets()
      print ("Player has " .. free_tenets .. " free tenets")
      player:SetNumFreeTenets(free_tenets + 1, true)
   end

end
------------------------------------------------------------------------------------------------------------------------
if is_active then
   -- Note: PlayerPolicyBranchUnlocked is a Lekmod event. It is not available in the base game
   GameEvents.PlayerPolicyBranchUnlocked.Add(lekmod_yugoslavia_ideology_tenet)
end
