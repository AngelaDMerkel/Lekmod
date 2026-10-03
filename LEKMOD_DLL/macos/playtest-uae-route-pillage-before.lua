-- Read-only observations immediately before the product UAE callbacks.
local lekmodUaeGuardBefore,lekmodUaePillageBefore
GameEvents.PlayerDoTurn.Add(function(owner)
 local p=Players[owner];lekmodUaeGuardBefore=nil
 if not p or not p:IsAlive()then return end
 local b={owner=owner,gold=p:GetGold(),units={},eligible=0}
 for u in p:Units()do
  local eligible=u:IsCombatUnit()and #p:GetInternationalTradeRoutePlotToolTip(u:GetPlot())>0
  b.units[u:GetID()]={xp=u:GetExperience(),eligible=eligible,tag=u:GetScriptData()}
  if eligible then b.eligible=b.eligible+1 end
 end
 lekmodUaeGuardBefore=b
end)
GameEvents.UnitPillaged.Add(function(owner,id,x,y)
 local p=Players[owner];local u=p and p:GetUnitByID(id);lekmodUaePillageBefore=nil
 if u then lekmodUaePillageBefore={owner=owner,id=id,x=x,y=y,xp=u:GetExperience(),moves=u:GetMoves(),gold=p:GetGold()}end
end)
