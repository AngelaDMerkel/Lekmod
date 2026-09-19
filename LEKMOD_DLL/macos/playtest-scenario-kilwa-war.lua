-- Normal synchronized war declaration; observe route cancellation without
-- assigning route/marker/yield outcomes or advancing a turn.
LekmodScenario={name="kilwa-war",items={"kilwa-war-route-cancellation","kilwa-war-internal-preserved","kilwa-war-food-removed"}}
local phase,turn,modifier,observations="init",nil,nil,0
local marker=GameInfoTypes.BUILDING_KILWA_TRAIT
function LekmodScenario.snapshot(player)
 local cities,routes,units={},{},{}
 for c in player:Cities()do cities[c:GetID()]={marker=c:GetNumRealBuilding(marker),modifier=c:GetBaseYieldRateModifier(YieldTypes.YIELD_FOOD),food_base=c:GetBaseYieldRate(YieldTypes.YIELD_FOOD),food_rate=c:GetYieldRateTimes100(YieldTypes.YIELD_FOOD),food=c:GetFoodTimes100()}end
 for i,r in ipairs(player:GetTradeRoutes())do routes[i]={from=r.FromCity:GetID(),to=r.ToCity:GetID(),to_owner=r.ToID,kind=r.ConnectionType,gold=r.FromGPT,food=r.ToFood,left=r.TurnsLeft}end
 for u in player:Units()do if u:IsTrade()then units[u:GetID()]={type=u:GetUnitType(),x=u:GetX(),y=u:GetY()}end end
 return {turn=Game.GetGameTurn(),war=Teams[player:GetTeam()]:IsAtWar(Players[1]:GetTeam()),cities=cities,routes=routes,units=units,used=player:GetNumInternationalTradeRoutesUsed()}
end
function LekmodScenario.step(player)
 assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_KILWA,"Kilwa fixture required")
 local c=assert(player:GetCapitalCity());local other=Players[1]
 if phase=="init"then
  assert(not Game.IsOption(GameInfoTypes.GAMEOPTION_ALWAYS_PEACE),"use the original unrestricted fixture")
  assert(not Teams[player:GetTeam()]:IsAtWar(other:GetTeam())and #player:GetTradeRoutes()==3 and c:GetNumRealBuilding(marker)==2,"requires two foreign and one internal route at peace")
  modifier=c:GetBaseYieldRateModifier(YieldTypes.YIELD_FOOD)-10;turn=Game.GetGameTurn()
  LekmodScenarioEvent("kilwa-before-war",LekmodScenario.snapshot(player))
  Network.SendChangeWar(other:GetTeam(),true);phase="war";return false
 end
 if not LekmodScenarioAwait("kilwa-war-declared",Teams[player:GetTeam()]:IsAtWar(other:GetTeam()))then return false end
 assert(Game.GetGameTurn()==turn,"war comparison unexpectedly advanced a turn")
 local routes=player:GetTradeRoutes();if not LekmodScenarioAwait("foreign-routes-cancelled",#routes==1)then return false end
 local r=routes[1];assert(r.ToID==0 and r.ConnectionType==1 and r.ToFood==175 and r.FromGPT==400,"internal food/four-gold route changed during foreign cancellation")
 local count=0;for u in player:Units()do if u:IsTrade()then count=count+1 end end
 assert(count==1 and player:GetNumInternationalTradeRoutesUsed()==1,"attacker foreign caravans were not removed or internal caravan was lost")
 observations=observations+1;local s=LekmodScenario.snapshot(player)
 LekmodScenarioEvent("kilwa-after-war",{observation=observations,state=s})
 if observations<3 then return false end
 LekmodScenarioRecord("kilwa-war-route-cancellation","PASS","two foreign routes/attackercaravans removed by normal war command")
 LekmodScenarioRecord("kilwa-war-internal-preserved","PASS","one internal route food175/gold400 anditscaravan retained")
 local correct=c:GetNumRealBuilding(marker)==0 and c:GetBaseYieldRateModifier(YieldTypes.YIELD_FOOD)==modifier
 LekmodScenarioRecord("kilwa-war-food-removed",correct and"PASS"or"FAIL","three stable observations; marker="..c:GetNumRealBuilding(marker).." modifier="..c:GetBaseYieldRateModifier(YieldTypes.YIELD_FOOD).." expected="..modifier)
 return true
end
