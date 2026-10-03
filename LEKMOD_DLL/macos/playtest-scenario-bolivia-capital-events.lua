-- Native method surface: GameCore
-- Cities, a Writer, Colorado probes, a happiness building/population and an AI
-- attacker are supplied inputs. Writer action, native happiness events and real
-- conquest must update the reward; no marker, strength, capital or owner is set.
LekmodScenario={name="bolivia-capital-events",items={"bolivia-native-writer-history","bolivia-native-founding","bolivia-happiness-rise","bolivia-happiness-removal","bolivia-unhappy-strength-floor","bolivia-happiness-restored","bolivia-native-capital-loss","bolivia-relocated-food-marker","bolivia-foreign-marker-control","bolivia-next-owner-turn"}}
local phase,oldX,oldY,newCity,writer,expended,capture,captureTurn="init"
local sent,turns,lastTurn=false,0,nil
local happyEvents,foundEvents=0,{}
local happyBefore,basePopulation,controlUnit,controlStrength=nil,nil,nil,nil
local food=GameInfoTypes.BUILDING_BOLIVIA_TRAIT_FOOD
local production=GameInfoTypes.BUILDING_BOLIVIA_TRAIT_PRODUCTION
local colorado=GameInfoTypes.UNIT_COLORADO
local happinessBuilding=GameInfoTypes.BUILDING_CIRCUS_MAXIMUS
local function act(u,name)
 UI.SelectUnit(u)
 for id=0,#GameInfoActions do if GameInfoActions[id]and GameInfoActions[id].Type==name then assert(Game.CanHandleAction(id));Game.HandleAction(id);return end end
 error("normal action missing: "..name)
end
local function strength(p,label)
 local happiness=p:GetExcessHappiness();local expected=GameInfo.Units[colorado].Combat+2*math.max(0,math.floor(happiness/5+0.5));local count=0
 for u in p:Units()do if u:GetUnitType()==colorado then count=count+1;assert(u:GetBaseCombatStrength()==expected,"Colorado strength differs at "..label)end end
 assert(count>=2,"both Colorado probes must survive happiness checks")
 if controlUnit then local u=assert(p:GetUnitByID(controlUnit));assert(u:GetBaseCombatStrength()==controlStrength,"unrelated unit strength changed")end
 LekmodScenarioEvent("native-Colorado-happiness",{label=label,happiness=happiness,strength=expected,units=count,events=happyEvents})
end
local function markers(p)
 local cap=assert(p:GetCapitalCity())
 for owner=0,2 do for c in Players[owner]:Cities()do
  local expected=owner==p:GetID()and c:IsCapital()and 1 or 0
  assert(c:GetNumRealBuilding(food)==expected and c:GetNumRealBuilding(production)==0,"Writer history not confined to current Bolivian capital")
 end end
 return cap
end
GameEvents.PlayerHappinessChanged.Add(function(owner)if owner==0 then happyEvents=happyEvents+1 end end)
GameEvents.PlayerCityFounded.Add(function(owner,x,y)if owner==0 then foundEvents[x..":"..y]=true end end)
GameEvents.GreatPersonExpended.Add(function(owner,kind)if owner==0 then expended=kind end end)
GameEvents.CityCaptureComplete.Add(function(old,capital,x,y,new,pop,conquest)
 if x==oldX and y==oldY then assert(old==0 and new==1 and capital and conquest and not capture);capture=true;captureTurn=Game.GetGameTurn();LekmodScenarioEvent("native-Bolivian-capital-loss",{old=old,new=new,capital=capital,conquest=conquest})end
end)
GameEvents.PlayerDoTurn.Add(function(owner)
 if owner==0 then turns=turns+1 end
 if owner~=1 or phase~="capture"or sent then return end
 local p=Players[1];assert(p:IsTurnActive()and not p:IsHuman());local tile
 for d=0,5 do local q=Map.PlotDirection(oldX,oldY,d)
  if q and not q:IsWater()and not q:IsMountain()and not q:IsCity()and q:GetNumUnits()==0 then tile=q;break end
 end
 assert(tile);p:ChangeGold(1000);p:ChangeNumResourceTotal(GameInfoTypes.RESOURCE_URANIUM,1)
 local u=assert(p:InitUnit(GameInfoTypes.UNIT_MECH,tile:GetX(),tile:GetY()));assert(u:CanMoveOrAttackInto(Map.GetPlot(oldX,oldY)));sent=true
 LekmodScenarioEvent("fixture-setup",{operation="provided-real-AI-turn-capture-attacker",owner=1,unit=u:GetID(),x=tile:GetX(),y=tile:GetY()});u:PushMission(MissionTypes.MISSION_MOVE_TO,oldX,oldY,0,0,1)
end)
function LekmodScenario.snapshot(p)
 local owners={}
 for id=0,2 do local q=Players[id];local cities,units={},{}
  for c in q:Cities()do cities[c:GetID()]={x=c:GetX(),y=c:GetY(),capital=c:IsCapital(),food=c:GetNumRealBuilding(food),production=c:GetNumRealBuilding(production),population=c:GetPopulation()}end
  for u in q:Units()do if u:GetUnitType()==colorado then units[u:GetID()]={strength=u:GetBaseCombatStrength(),x=u:GetX(),y=u:GetY()}end end
  owners[id]={alive=q:IsAlive(),civilization=q:GetCivilizationType(),happiness=q:GetExcessHappiness(),cities=cities,Colorados=units}
 end
 return {turn=Game.GetGameTurn(),winner=Game.GetWinner(),owners=owners}
end
function LekmodScenario.step(p)
 assert(p:GetID()==0 and p:IsHuman()and p:GetCivilizationType()==GameInfoTypes.CIVILIZATION_BOLIVIA)
 assert(Players[1]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_ROME and Players[2]:IsAlive()and Players[2]:GetCapitalCity(),"three-major fixture prevents accidental domination victory")
 local cap=assert(p:GetCapitalCity())
 if phase=="init"then
  p:ChangeGold(10000);LekmodScenarioEvent("fixture-setup",{operation="provided-upkeep-gold",owner=0,amount=10000})
  assert(p:GetNumCities()==1);oldX,oldY=cap:GetX(),cap:GetY();lastTurn=turns;phase="history";return "turn"
 elseif phase=="history"then
  if turns<=lastTurn then return "turn"end
  local u=assert(p:InitUnit(GameInfoTypes.UNIT_WRITER,oldX,oldY));writer=u:GetID();assert(u:GetGivePoliciesCulture()>0)
  LekmodScenarioEvent("fixture-setup",{operation="provided-Writer",unit=writer});act(u,"MISSION_GIVE_POLICIES");phase="writer"
 elseif phase=="writer"then
  if not LekmodScenarioAwait("Bolivian-Writer",expended==GameInfoTypes.UNIT_WRITER and p:GetUnitByID(writer)==nil)then return false end
  markers(p);LekmodScenarioRecord("bolivia-native-writer-history","PASS","actual Writer action establishes food history before city creation and conquest")
  local site
  for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
   if Map.PlotDistance(oldX,oldY,q:GetX(),q:GetY())>=8 and q:GetOwner()==-1 and q:GetNumUnits()==0 and p:CanFound(q:GetX(),q:GetY())then site=q;break end
  end
  assert(site,"no separated survival-city site");p:Found(site:GetX(),site:GetY());local c=assert(site:GetPlotCity());newCity=c:GetID();assert(foundEvents[site:GetX()..":"..site:GetY()]);markers(p)
  LekmodScenarioRecord("bolivia-native-founding","PASS","real PlayerCityFounded preserves Writer history and leaves the new noncapital unmarked")
  local a=assert(p:InitUnit(colorado,c:GetX(),c:GetY()));local tile
  for d=0,5 do local q=Map.PlotDirection(c:GetX(),c:GetY(),d);if q and not q:IsWater()and not q:IsMountain()and not q:IsCity()and q:GetNumUnits()==0 then tile=q;break end end
  assert(tile);local b=assert(p:InitUnit(colorado,tile:GetX(),tile:GetY()))
  for u in p:Units()do if u:GetUnitType()~=colorado and u:GetBaseCombatStrength()>0 then controlUnit=u:GetID();controlStrength=u:GetBaseCombatStrength();break end end
  assert(controlUnit);LekmodScenarioEvent("fixture-setup",{operation="provided-survival-city-and-Colorado-probes",city=newCity,first=a:GetID(),second=b:GetID()});strength(p,"birth");phase="happy-add"
 elseif phase=="happy-add"then
  local c=assert(p:GetCityByID(newCity));assert(c:GetNumBuilding(happinessBuilding)==0);happyBefore=p:GetExcessHappiness();local before=happyEvents;c:SetNumRealBuilding(happinessBuilding,1)
  assert(happyEvents>before and p:GetExcessHappiness()==happyBefore+5);strength(p,"five-happiness-added")
  LekmodScenarioRecord("bolivia-happiness-rise","PASS","native building processing emits happiness event and recomputes both Colorado probes; unrelated unit unchanged");phase="happy-remove"
 elseif phase=="happy-remove"then
  local c=assert(p:GetCityByID(newCity));local before=happyEvents;c:SetNumRealBuilding(happinessBuilding,0);assert(happyEvents>before and p:GetExcessHappiness()==happyBefore);strength(p,"five-happiness-removed")
  LekmodScenarioRecord("bolivia-happiness-removal","PASS","removing the supplied building reverses strength using the real happiness event");basePopulation=c:GetPopulation();phase="negative"
 elseif phase=="negative"then
  local c=assert(p:GetCityByID(newCity));local before=happyEvents;c:SetPopulation(basePopulation+30,true);assert(happyEvents>before and p:GetExcessHappiness()<0);strength(p,"negative-happiness")
  LekmodScenarioRecord("bolivia-unhappy-strength-floor","PASS","native population-driven unhappiness removes the bonus without reducing base strength");phase="restore"
 elseif phase=="restore"then
  local c=assert(p:GetCityByID(newCity));local before=happyEvents;c:SetPopulation(basePopulation,true);assert(happyEvents>before and p:GetExcessHappiness()==happyBefore);strength(p,"population-restored")
  LekmodScenarioRecord("bolivia-happiness-restored","PASS","restored input population recomputes the original native strength");lastTurn=turns;phase="baseline";return "turn"
 elseif phase=="baseline"then
  if turns<=lastTurn then return "turn"end;markers(p);local otherTeam=Players[1]:GetTeam();local me=Teams[p:GetTeam()];local met=me:IsHasMet(otherTeam)
  if not met then me:Meet(otherTeam,true);LekmodScenarioEvent("fixture-setup",{operation="provided-team-contact",team=p:GetTeam(),other=otherTeam})end
  LekmodScenarioEvent("war-prerequisites",{met_before=met,met_now=me:IsHasMet(otherTeam),already_war=me:IsAtWar(otherTeam),can_declare=me:CanDeclareWar(otherTeam)})
  assert(me:CanDeclareWar(otherTeam),"native war eligibility refused after contact");Network.SendChangeWar(Players[1]:GetTeam(),true);phase="war"
 elseif phase=="war"then
  if not LekmodScenarioAwait("Bolivia-war",Teams[p:GetTeam()]:IsAtWar(Players[1]:GetTeam()))then return false end;phase="capture";return "turn"
 elseif phase=="capture"then
  if not capture or Game.GetGameTurn()<=captureTurn then return "turn"end
  assert(Map.GetPlot(oldX,oldY):GetPlotCity():GetOwner()==1 and p:IsAlive()and Game.GetWinner()==-1)
  LekmodScenarioRecord("bolivia-native-capital-loss","PASS","real AI owner-turn conquest, with surviving Bolivian city and third major preventing game end")
  local c=markers(p);assert(c:GetID()==newCity);LekmodScenarioRecord("bolivia-relocated-food-marker","PASS","saved Writer benefit moves to the native replacement capital")
  LekmodScenarioRecord("bolivia-foreign-marker-control","PASS","captured former capital and all Roman/Greek cities have no Bolivian reward markers")
  lastTurn=turns;phase="after";return "turn"
 elseif phase=="after"then
  if turns<=lastTurn then return "turn"end;assert(Game.GetWinner()==-1);markers(p)
  LekmodScenarioRecord("bolivia-next-owner-turn","PASS","a further ordinary owner round preserves exactly one correct reward marker; exact replay follows");return true
 end
 return false
end
