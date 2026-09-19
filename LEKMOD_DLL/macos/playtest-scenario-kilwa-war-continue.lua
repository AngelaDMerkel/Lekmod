-- Load the preserved pre-fix wartime save and observe ordinary owner-turn
-- refresh of its serialized marker. No gameplay state is assigned.
LekmodScenario={name="kilwa-war-continue",items={"kilwa-old-war-load","kilwa-old-war-refresh"}}
local start,initialMarker
local marker=GameInfoTypes.BUILDING_KILWA_TRAIT
function LekmodScenario.snapshot(player)
 local cities,routes={},{},{}
 for c in player:Cities()do cities[c:GetID()]={marker=c:GetNumRealBuilding(marker),modifier=c:GetBaseYieldRateModifier(YieldTypes.YIELD_FOOD),food=c:GetFoodTimes100(),population=c:GetPopulation()}end
 for i,r in ipairs(player:GetTradeRoutes())do routes[i]={from=r.FromCity:GetID(),to=r.ToCity:GetID(),to_owner=r.ToID,kind=r.ConnectionType,left=r.TurnsLeft,gold=r.FromGPT,food=r.ToFood}end
 return {turn=Game.GetGameTurn(),war=Teams[player:GetTeam()]:IsAtWar(Players[1]:GetTeam()),cities=cities,routes=routes,used=player:GetNumInternationalTradeRoutesUsed()}
end
function LekmodScenario.step(player)
 assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_KILWA and Teams[player:GetTeam()]:IsAtWar(Players[1]:GetTeam()),"requires affected Kilwa wartime save")
 if not start then
  start=Game.GetGameTurn();initialMarker=player:GetCapitalCity():GetNumRealBuilding(marker)
  assert(start==166 and initialMarker>=0 and initialMarker<=1,"unexpected affected-save starting state")
  LekmodScenarioEvent("kilwa-old-war-loaded",LekmodScenario.snapshot(player))
  LekmodScenarioRecord("kilwa-old-war-load","PASS","preserved failed war save loaded; initialmarker="..initialMarker)
  if initialMarker~=0 then return "turn"end
 elseif initialMarker~=0 and Game.GetGameTurn()==start then return "turn"end
 assert(Game.GetGameTurn()==start+(initialMarker~=0 and 1 or 0),"affected-save continuation exceeded the one-turn scope")
 for _,r in ipairs(player:GetTradeRoutes())do assert(r.ToID==player:GetID(),"wartime fixture acquired unexpected foreign route")end
 for c in player:Cities()do assert(c:GetNumRealBuilding(marker)==0,"ordinary owner-turn refresh retained a stale Kilwa food marker")end
 LekmodScenarioEvent("kilwa-old-war-refreshed",LekmodScenario.snapshot(player))
 LekmodScenarioRecord("kilwa-old-war-refresh","PASS",initialMarker~=0 and"existing PlayerDoTurn refresh cleared saved marker after one ordinary turn"or"marker already consistent on load; no turn requested")
 return true
end
