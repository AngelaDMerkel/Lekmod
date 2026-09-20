-- Prepended before the product registers its owner-turn handlers. This signal
-- makes observation order explicit even when a batch stage is loaded later.
GameEvents.PlayerDoTurn.Add(function(owner)
 LuaEvents.LekmodNZBeforeOwnerTurn(owner)
end)
