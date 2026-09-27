-- Invoke the actual registered tutorial callbacks on request; no preference,
-- tutorial result, game state or synchronization flag is assigned.
LuaEvents.LekmodTutorialEdgeProbe.Add(function(cityID)
 local player=GetPlayer();assert(player)
 local city=assert(player:GetCityByID(cityID));local plot=city:Plot();local missing=0
 for dx=-1,1 do for dy=-1,1 do if not Map.GetPlotXY(plot:GetX(),plot:GetY(),dx,dy)then missing=missing+1 end end end
 assert(missing>0,"edge regression requires missing map neighbors")
 local entry=assert(GlobalTutorialInfo.CITY_UNDER_ATTACK)
 local status=entry.CheckFunction();local target=entry.PlotFunction()
 assert(status==ACTIVE or status==INACTIVE)
 assert((status==ACTIVE)==(target~=nil))
 LuaEvents.LekmodTutorialEdgeResult(cityID,missing,status)
end)
