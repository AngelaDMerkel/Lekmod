-- Read-only snapshots registered before the product reward callback.
local lekmodUaeConstructBefore
GameEvents.CityConstructed.Add(function(owner,city,building,gold,faith)
 local p=Players[owner];local c=p and p:GetCityByID(city)
 lekmodUaeConstructBefore=c and {owner=owner,city=city,building=building,gold=p:GetGold(),king=c:GetWeLoveTheKingDayCounter()}or nil
end)
