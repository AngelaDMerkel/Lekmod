-- Read-only, registered before the actual Aksum handler in its own Lua context.
local lekmodTestHealBefore
GameEvents.UnitHealed.Add(function(owner,id,change,x,y)
 lekmodTestHealBefore={owner=owner,id=id,change=change,x=x,y=y,faith=Players[owner]:GetFaith()}
end)
