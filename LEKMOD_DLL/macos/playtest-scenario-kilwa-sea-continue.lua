-- Verify ordinary AI owner-turn consistency after loading the pre-fix sea-plunder save.
LekmodScenario={name="kilwa-sea-continue",items={"kilwa-old-sea-load","kilwa-old-sea-refresh"}}
local start
local marker=GameInfoTypes.BUILDING_KILWA_TRAIT
function LekmodScenario.snapshot(player)
 local p=Players[1];local cities,routes={},{},{}
 for c in p:Cities()do cities[c:GetID()]={marker=c:GetNumRealBuilding(marker),modifier=c:GetBaseYieldRateModifier(YieldTypes.YIELD_FOOD),food=c:GetFoodTimes100(),population=c:GetPopulation()}end
 for i,r in ipairs(p:GetTradeRoutes())do routes[i]={from=r.FromCity:GetID(),to=r.ToCity:GetID(),to_owner=r.ToID,domain=r.Domain,left=r.TurnsLeft}end
 return {turn=Game.GetGameTurn(),cities=cities,routes=routes,used=p:GetNumInternationalTradeRoutesUsed(),war=Teams[player:GetTeam()]:IsAtWar(p:GetTeam())}
end
function LekmodScenario.step(player)
 local p=Players[1];assert(p:IsAlive()and not p:IsHuman()and p:GetCivilizationType()==GameInfoTypes.CIVILIZATION_KILWA,"requires AI Kilwa slot1")
 if not start then
  start=Game.GetGameTurn();assert(start==166 and #p:GetTradeRoutes()==0 and p:GetCapitalCity():GetNumRealBuilding(marker)==1,"requires preserved stale sea-plunder save")
  LekmodScenarioEvent("kilwa-old-sea-loaded",LekmodScenario.snapshot(player))
  LekmodScenarioRecord("kilwa-old-sea-load","PASS","pre-fix save retains AI marker1 with zero routes")
  return "turn"
 end
 if Game.GetGameTurn()==start then return "turn"end
 assert(Game.GetGameTurn()==start+1,"AI recovery exceeded its one-turn bound")
 local counts={}
 for _,r in ipairs(p:GetTradeRoutes())do if r.ToID~=1 then counts[r.FromCity:GetID()]=(counts[r.FromCity:GetID()]or 0)+1 end end
 for c in p:Cities()do assert(c:GetNumRealBuilding(marker)==(counts[c:GetID()]or 0),"AI owner-turn left a stale route-food marker")end
 LekmodScenarioEvent("kilwa-old-sea-refreshed",LekmodScenario.snapshot(player))
 LekmodScenarioRecord("kilwa-old-sea-refresh","PASS","all AI city markers match actual foreign-route counts after one ordinary owner turn")
 return true
end
