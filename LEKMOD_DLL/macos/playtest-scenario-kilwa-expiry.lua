-- Observe only the three preserved contracts through natural expiration.
-- No route duration, marker, food or unit-return state is assigned.
LekmodScenario={name="kilwa-expiry",items={"kilwa-natural-expiry","kilwa-expiry-markers","kilwa-returned-caravans","kilwa-expired-cargo"}}
local start,deadline,used,unitCount,lastTurn,markerTurn,markerWait
local ends,origins,mismatches={},{},{}
local marker=GameInfoTypes.BUILDING_KILWA_TRAIT
local function key(r)return table.concat({r.Domain,r.FromID,r.FromCity:GetID(),r.ToID,r.ToCity:GetID(),r.ConnectionType},":")end
local function trade(c,y)return c:GetYieldRateTimes100(y,false)-c:GetYieldRateTimes100(y,true)end
function LekmodScenario.snapshot(player)
 local cities,units,routes={},{},{}
 for c in player:Cities()do cities[c:GetID()]={marker=c:GetNumRealBuilding(marker),food=c:GetFoodTimes100(),population=c:GetPopulation(),food_trade=trade(c,YieldTypes.YIELD_FOOD),production_trade=trade(c,YieldTypes.YIELD_PRODUCTION),gold_trade=trade(c,YieldTypes.YIELD_GOLD),food_modifier=c:GetBaseYieldRateModifier(YieldTypes.YIELD_FOOD)}end
 for u in player:Units()do if u:IsTrade()then units[u:GetID()]={type=u:GetUnitType(),x=u:GetX(),y=u:GetY(),moves=u:GetMoves(),in_city=u:GetPlot():IsCity()}end end
 for i,r in ipairs(player:GetTradeRoutes())do routes[i]={key=key(r),left=r.TurnsLeft,gold=r.FromGPT,food=r.ToFood}end
 return {always_peace=Game.IsOption(GameInfoTypes.GAMEOPTION_ALWAYS_PEACE),no_barbarians=Game.IsOption(GameInfoTypes.GAMEOPTION_NO_BARBARIANS),turn=Game.GetGameTurn(),cities=cities,units=units,routes=routes,used=player:GetNumInternationalTradeRoutesUsed(),gold=player:GetGold()}
end
function LekmodScenario.step(player)
 assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_KILWA,"Kilwa route fixture required")
 local routes=player:GetTradeRoutes();local now=Game.GetGameTurn()
 if not start then
  assert(Game.IsOption(GameInfoTypes.GAMEOPTION_ALWAYS_PEACE)and Game.IsOption(GameInfoTypes.GAMEOPTION_NO_BARBARIANS),"natural expiry requires the explicit peace/no-barbarian fixture")
  assert(#routes==3,"requires the accepted three-route Kilwa save")
  start=now;deadline=now;used=player:GetNumInternationalTradeRoutesUsed();unitCount=0
  for u in player:Units()do if u:IsTrade()then unitCount=unitCount+1 end end
  assert(unitCount==3 and used==3,"fixture trade unit inventory differs")
  for _,r in ipairs(routes)do
   assert(r.FromID==0 and r.TurnsLeft>0 and r.TurnsLeft<=18,"contract outside explicit short expiry scope")
   ends[key(r)]=now+r.TurnsLeft;deadline=math.max(deadline,now+r.TurnsLeft)
   origins[r.FromCity:GetX()..":"..r.FromCity:GetY()]=true
  end
  LekmodScenarioEvent("kilwa-expiry-contracts",{start=start,deadline=deadline,ends=ends,units=unitCount})
 end
 local active,counts={},{}
 for _,r in ipairs(routes)do
  local k=key(r);assert(ends[k],"unexpected new route during expiry test");active[k]=true
  assert(r.TurnsLeft>0 and now+r.TurnsLeft==ends[k],"contract countdown changed relative to quoted end")
  if r.ToID~=player:GetID()then counts[r.FromCity:GetID()]=(counts[r.FromCity:GetID()]or 0)+1 end
 end
 for k,finish in pairs(ends)do assert(active[k]or now>=finish,"route disappeared before its quoted end")end
 local bad={}
 for c in player:Cities()do
  local actual=c:GetNumRealBuilding(marker);local expected=counts[c:GetID()]or 0
  if actual~=expected then bad[#bad+1]={turn=now,city=c:GetID(),actual=actual,expected=expected}end
 end
 if markerTurn~=now then markerTurn=now;markerWait=0 end
 if #bad>0 and markerWait<3 then
  markerWait=markerWait+1;LekmodScenarioEvent("kilwa-expiry-marker-observation",{attempt=markerWait,mismatches=bad});return false
 end
 if lastTurn~=now then
  lastTurn=now
  for _,b in ipairs(bad)do mismatches[#mismatches+1]=b end
  LekmodScenarioEvent("kilwa-expiry-progress",{turn=now,active=#routes,counts=counts,stable_mismatches=bad,state=LekmodScenario.snapshot(player)})
 end
 if #routes>0 then assert(now<=deadline,"contracts exceeded their quoted end");return "turn"end
 assert(now==deadline,"all contracts ended at an unexpected turn")
 LekmodScenarioRecord("kilwa-natural-expiry","PASS","three original contracts ended naturally; elapsed="..now-start)
 LekmodScenarioRecord("kilwa-expiry-markers",#mismatches==0 and"PASS"or"FAIL","stable marker/count mismatches="..#mismatches)
 local returned=0;local correctLocations=true
 for u in player:Units()do if u:IsTrade()then
  returned=returned+1
  if not u:GetPlot():IsCity()or not origins[u:GetX()..":"..u:GetY()]then correctLocations=false end
 end end
 LekmodScenarioRecord("kilwa-returned-caravans",returned==unitCount and correctLocations and player:GetNumInternationalTradeRoutesUsed()==used and"PASS"or"FAIL","returned="..returned.." used="..player:GetNumInternationalTradeRoutesUsed())
 local cargoGone=true
 for c in player:Cities()do if trade(c,YieldTypes.YIELD_FOOD)~=0 or trade(c,YieldTypes.YIELD_PRODUCTION)~=0 then cargoGone=false end end
 LekmodScenarioRecord("kilwa-expired-cargo",cargoGone and"PASS"or"FAIL","no own outgoing routes; former internal food cargo cleared; treasury settlement not asserted")
 LekmodScenarioEvent("kilwa-expiry-final",{mismatches=mismatches,state=LekmodScenario.snapshot(player)})
 return true
end
