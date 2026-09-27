-- Read-only, appended after the actual Aksum handler. No healing or faith setter.
GameEvents.UnitHealed.Add(function(owner,id,change,x,y)
 local before=assert(lekmodTestHealBefore)
 assert(before.owner==owner and before.id==id and before.change==change and before.x==x and before.y==y)
 LuaEvents.LekmodAksumHealObserved(owner,id,change,x,y,before.faith,Players[owner]:GetFaith())
end)
