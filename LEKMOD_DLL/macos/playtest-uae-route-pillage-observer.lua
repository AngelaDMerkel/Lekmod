-- Read-only observations after the product callback; no reward setter.
GameEvents.PlayerDoTurn.Add(function(owner)
 local b=lekmodUaeGuardBefore;if not b then return end;assert(b.owner==owner)
 local p=Players[owner]
 for id,v in pairs(b.units)do local u=p:GetUnitByID(id)
  LuaEvents.LekmodUaeGuardUnit(owner,id,v.eligible,v.xp,u and u:GetExperience()or -1,v.tag)
 end
 LuaEvents.LekmodUaeGuardOwner(owner,b.eligible,b.gold,p:GetGold())
end)
GameEvents.UnitPillaged.Add(function(owner,id,x,y)
 local b=assert(lekmodUaePillageBefore);assert(b.owner==owner and b.id==id and b.x==x and b.y==y)
 local p=Players[owner];local u=assert(p:GetUnitByID(id))
 LuaEvents.LekmodUaePillageObserved(owner,id,x,y,b.xp,u:GetExperience(),b.moves,u:GetMoves(),b.gold,p:GetGold())
end)
