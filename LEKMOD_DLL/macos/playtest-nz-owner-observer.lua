-- Appended after the real New Zealand registrations. Observation only: never
-- calls a product handler, changes a unit/influence, or alters turn ownership.
GameEvents.PlayerDoTurn.Add(function(owner)
 LuaEvents.LekmodNZAfterOwnerTurn(owner)
end)
