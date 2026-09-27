-- Native method surface: GameCore
-- Culture buildings, contact, survival cities and a funded AI attacker are inputs.
-- Real AI-turn capture changes the capital/owner; the actual Cuban owner callback
-- computes culture. No reward marker, capital, damage, owner or alive state is set.
local mode=assert(LekmodScenarioParameters.mode)
assert(mode=="own"or mode=="foreign"or mode=="eliminate")
LekmodScenario={name="cuba-capital-transfer",items={"cuba-transfer-initial-quote","cuba-transfer-real-capture","cuba-transfer-capital-transition","cuba-transfer-recomputed-quote","cuba-transfer-no-stale-marker","cuba-transfer-next-turn"}}
local marker=GameInfoTypes.BUILDING_CUBA_TRAIT_UB2
local phase,oldOwner,x,y,oldCapital,beforeQuote,capture,capturedTurn,lastTurn="init"
local attacker,sent=nil,false
local turns,quoted=0,nil
local function quote()
 local total,sources=0,{}
 for id=1,3 do local p=Players[id];local c=p:GetCapitalCity()
  if c and Teams[Players[0]:GetTeam()]:IsHasMet(p:GetTeam())then
   local culture=c:GetBaseJONSCulturePerTurn();local n=math.floor(culture*0.20)
   sources[id]={x=c:GetX(),y=c:GetY(),culture=culture,contribution=n};total=total+n
  end
 end
 return {count=total,sources=sources}
end
function LekmodScenario.snapshot(player)
 local owners={}
 for id=0,3 do local p=Players[id];local cities={}
  for c in p:Cities()do cities[c:GetID()]={x=c:GetX(),y=c:GetY(),capital=c:IsCapital(),original=c:GetOriginalOwner(),marker=c:GetNumRealBuilding(marker),culture=c:GetBaseJONSCulturePerTurn()}end
  owners[id]={alive=p:IsAlive(),cities=cities,civilization=p:GetCivilizationType()}
 end
 return {turn=Game.GetGameTurn(),owners=owners,quote=quote()}
end
GameEvents.CityCaptureComplete.Add(function(old,capital,cx,cy,new,pop,conquest)
 if cx==x and cy==y then
  assert(not capture and old==oldOwner and new==1 and capital and conquest)
  capture={old=old,new=new,capital=capital,conquest=conquest,old_alive=Players[old]:IsAlive(),old_cities=Players[old]:GetNumCities()}
  capturedTurn=Game.GetGameTurn();LekmodScenarioEvent("native-Cuban-source-capture",capture)
 end
end)
GameEvents.PlayerDoTurn.Add(function(owner)
 if owner==0 then turns=turns+1;quoted={turn=Game.GetGameTurn(),quote=quote()};return end
 if owner~=1 or phase~="capture"or sent then return end
 local p=Players[owner];assert(p:IsTurnActive()and not p:IsHuman())
 local target=Map.GetPlot(x,y);local tile
 for d=0,5 do local q=Map.PlotDirection(x,y,d)
  if q and not q:IsWater()and not q:IsMountain()and not q:IsCity()and q:GetNumUnits()==0 then tile=q;break end
 end
 assert(tile);p:ChangeGold(1000);p:ChangeNumResourceTotal(GameInfoTypes.RESOURCE_URANIUM,1)
 local u=assert(p:InitUnit(GameInfoTypes.UNIT_MECH,tile:GetX(),tile:GetY()));attacker=u:GetID()
 LekmodScenarioEvent("fixture-setup",{operation="provided-AI-capture-attacker",owner=1,unit=attacker,x=tile:GetX(),y=tile:GetY(),gold_added=1000,uranium_added=1})
 assert(u:CanMoveOrAttackInto(target));sent=true;u:PushMission(MissionTypes.MISSION_MOVE_TO,x,y,0,0,1)
end)
local function survival(p)
 local capital=assert(p:GetCapitalCity());local site,best=nil,9999
 for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i);local d=Map.PlotDistance(capital:GetX(),capital:GetY(),q:GetX(),q:GetY())
  if d>=4 and d<best and q:GetArea()==capital:Plot():GetArea()and q:GetOwner()==-1 and q:GetNumUnits()==0 and p:CanFound(q:GetX(),q:GetY())then site=q;best=d end
 end
 assert(site);p:Found(site:GetX(),site:GetY());assert(p:GetNumCities()==2)
 LekmodScenarioEvent("fixture-setup",{operation="provided-survival-city",owner=p:GetID(),x=site:GetX(),y=site:GetY()})
end
local function verifyQuote()
 assert(quoted and quoted.turn==Game.GetGameTurn(),"Cuban actual owner callback missing")
 local p=Players[0];local cap=assert(p:GetCapitalCity())
 assert(cap:GetNumRealBuilding(marker)==quoted.quote.count,"current capital culture marker differs from actual owner-turn quote")
 for id=0,3 do for city in Players[id]:Cities()do
  if id~=0 or not city:IsCapital()then assert(city:GetNumRealBuilding(marker)==0,"stale Cuban marker outside current Cuban capital")end
 end end
 return cap
end
function LekmodScenario.step(player)
 assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_CUBA and Players[1]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_PALMYRA and Players[3]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_ROME)
 if phase=="init"then
  oldOwner=mode=="own"and 0 or 3
  local capital=assert(Players[oldOwner]:GetCapitalCity());x,y=capital:GetX(),capital:GetY();oldCapital=capital:GetID()
  if mode~="eliminate"then survival(Players[oldOwner])end
  for id=1,3 do
   Teams[player:GetTeam()]:Meet(Players[id]:GetTeam(),true)
   local c=assert(Players[id]:GetCapitalCity());c:SetNumRealBuilding(GameInfoTypes.BUILDING_MONUMENT,1);c:SetNumRealBuilding(GameInfoTypes.BUILDING_AMPHITHEATER,1)
   LekmodScenarioEvent("fixture-setup",{operation="provided-capital-culture-buildings",owner=id,culture=c:GetBaseJONSCulturePerTurn()})
  end
  lastTurn=turns;phase="baseline";return "turn"
 elseif phase=="baseline"then
  if turns<=lastTurn then return "turn"end
  verifyQuote();beforeQuote=quoted.quote;assert(beforeQuote.count>=3)
  assert(beforeQuote.sources[3].contribution>=1)
  LekmodScenarioRecord("cuba-transfer-initial-quote","PASS","actual human owner callback matches rounded met-capital contributions")
  local attackerTeam=Teams[Players[1]:GetTeam()];local other=Players[oldOwner]:GetTeam()
  attackerTeam:Meet(other,true);assert(attackerTeam:CanDeclareWar(other));attackerTeam:DeclareWar(other)
  LekmodScenarioEvent("fixture-setup",{operation="provided-AI-war",attacker=1,target=oldOwner})
  phase="capture";return "turn"
 elseif phase=="capture"then
  if not capture or not quoted or quoted.turn<=capturedTurn then return "turn"end
  local oldCity=assert(Map.GetPlot(x,y):GetPlotCity());assert(oldCity:GetOwner()==1 and oldCity:GetOriginalOwner()==oldOwner)
  LekmodScenarioRecord("cuba-transfer-real-capture","PASS","actual AI owner-turn attack, original-capital conquest and capture event")
  local cap=verifyQuote()
  if mode=="own"then
   assert(player:IsAlive()and(cap:GetX()~=x or cap:GetY()~=y)and player:GetNumCities()==1)
  elseif mode=="foreign"then
   local nextCapital=assert(Players[3]:GetCapitalCity());assert(Players[3]:IsAlive()and(nextCapital:GetX()~=x or nextCapital:GetY()~=y))
   assert(quoted.quote.sources[3].contribution<beforeQuote.sources[3].contribution,"foreign replacement capital did not lower that source contribution")
  else
   assert(not Players[3]:IsAlive()and Players[3]:GetCapitalCity()==nil and not quoted.quote.sources[3])
  end
  LekmodScenarioRecord("cuba-transfer-capital-transition","PASS","mode="..mode.." native capital relocation/elimination and changed source verified")
  LekmodScenarioRecord("cuba-transfer-recomputed-quote","PASS","current capital marker="..cap:GetNumRealBuilding(marker).." expected="..quoted.quote.count)
  assert(oldCity:GetNumRealBuilding(marker)==0)
  LekmodScenarioRecord("cuba-transfer-no-stale-marker","PASS","no marker on former Cuban capital, foreign cities or noncapital Cuban city")
  lastTurn=turns;phase="settle";return "turn"
 elseif phase=="settle"then
  if turns<=lastTurn then return "turn"end
  verifyQuote();assert(Game.GetWinner()==-1)
  LekmodScenarioRecord("cuba-transfer-next-turn","PASS","a further actual Cuban owner callback recomputes exact state without duplicate reward")
  return true
 end
 return false
end
