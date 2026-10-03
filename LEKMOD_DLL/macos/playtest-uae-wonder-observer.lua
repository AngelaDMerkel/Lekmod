-- Read-only observation after the product callback, before unrelated turn income.
GameEvents.CityConstructed.Add(function(owner,city,building,gold,faith)
 local before=assert(lekmodUaeConstructBefore);assert(before.owner==owner and before.city==city and before.building==building)
 local p=Players[owner];local c=assert(p:GetCityByID(city))
 LuaEvents.LekmodUaeWonderObserved(owner,city,building,gold,faith,before.gold,p:GetGold(),before.king,c:GetWeLoveTheKingDayCounter())
end)
