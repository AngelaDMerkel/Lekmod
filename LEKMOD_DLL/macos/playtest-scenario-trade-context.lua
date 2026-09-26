-- The reviewed scenario adapter is appended inside TradeLogic.lua so it can
-- access that module's private deal/player state. This explicit context adapter
-- preserves its SetUpdate callback instead of adding the generic test dismisser.
-- Original DiploTrade input, show/hide, and native message handlers stay intact.
print("[LEKMOD_DIAGNOSTIC] reviewed TradeLogic adapter owns this trade context")
