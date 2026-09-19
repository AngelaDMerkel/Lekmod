-- Supplied culture buildings and contact; real owner-turn callbacks must update
-- the capital marker. Rates are observations, not earned-yield settlement.
LekmodScenario={name="cuba-capital",items={"cuba-unmet-capital","cuba-met-capital-counts","cuba-capital-bonus-decrease","cuba-capital-owner-control"}}
local phase,turn="init",nil
local expected,previous={},{}
local dummy=GameInfoTypes.BUILDING_CUBA_TRAIT_UB2
local buildings={GameInfoTypes.BUILDING_MONUMENT,GameInfoTypes.BUILDING_AMPHITHEATER}
local function quote(owner)
 local player=Players[owner];local total,sources=0,{}
 for id=0,GameDefines.MAX_MAJOR_CIVS-1 do local other=Players[id];local c=other and other:GetCapitalCity()
  if id~=owner and c then
   local met=Teams[player:GetTeam()]:IsHasMet(other:GetTeam());local culture=c:GetBaseJONSCulturePerTurn();local n=met and math.floor(culture/5) or 0
   sources[id]={met=met,culture=culture,contribution=n};total=total+n
  end
 end
 return {count=total,sources=sources}
end
GameEvents.PlayerDoTurn.Add(function(owner)
 if owner==0 or owner==2 then
  expected[owner]={turn=Game.GetGameTurn(),quote=quote(owner)}
  LekmodScenarioEvent("cuba-real-owner-turn-quote",{owner=owner,value=expected[owner]})
 end
end)
function LekmodScenario.snapshot(player)
 local owners={}
 for id=0,2 do local c=Players[id]:GetCapitalCity();owners[id]={civilization=Players[id]:GetCivilizationType(),quote=quote(id)}
  if c then owners[id].city={id=c:GetID(),culture=c:GetBaseJONSCulturePerTurn(),marker=c:GetNumRealBuilding(dummy),monument=c:GetNumRealBuilding(buildings[1]),amphitheater=c:GetNumRealBuilding(buildings[2])}end
 end
 return {turn=Game.GetGameTurn(),owners=owners}
end
local function meet(a,b)
 local team=Teams[Players[a]:GetTeam()]
 if not team:IsHasMet(Players[b]:GetTeam())then team:Meet(Players[b]:GetTeam(),false);LekmodScenarioEvent("fixture-setup",{operation="provided-contact",owner=a,other=b})end
end
local function matches(owner,minTurn)
 local c=Players[owner]:GetCapitalCity();local e=assert(expected[owner],"owner turn not observed")
 assert(e.turn>=minTurn and c:GetNumRealBuilding(dummy)==e.quote.count,"native Cuba marker differs from owner-turn source quotes")
 return c:GetNumRealBuilding(dummy)
end
function LekmodScenario.step(player)
 assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_CUBA and Players[1]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_ROME and Players[2]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_CUBA)
 if phase=="init" then
  for id=0,2 do if not Players[id]:GetCapitalCity()then return "turn"end end
  for _,id in ipairs({0,2})do assert(not Teams[Players[id]:GetTeam()]:IsHasMet(Players[1]:GetTeam()),"requires initially unmet Roman source")end
  for _,owner in ipairs({0,1})do local c=Players[owner]:GetCapitalCity()
   for _,b in ipairs(buildings)do c:SetNumRealBuilding(b,1)end
   LekmodScenarioEvent("fixture-setup",{operation="provided-culture-buildings",owner=owner,culture=c:GetBaseJONSCulturePerTurn()})
  end
  assert(Players[1]:GetCapitalCity():GetBaseJONSCulturePerTurn()>=5)
  turn=Game.GetGameTurn();phase="unmet";return "turn"
 elseif phase=="unmet" then
  if Game.GetGameTurn()==turn then return "turn"end
  previous[0]=matches(0,turn+1);previous[2]=matches(2,turn)
  for _,id in ipairs({0,2})do assert(not expected[id].quote.sources[1].met and expected[id].quote.sources[1].contribution==0)end
  LekmodScenarioRecord("cuba-unmet-capital","PASS","native-human-and-AI marker excludes-unmet-Roman-capital=true")
  meet(0,1);meet(0,2);meet(2,1);turn=Game.GetGameTurn();phase="met";return "turn"
 elseif phase=="met" then
  if Game.GetGameTurn()==turn then return "turn"end
  for _,id in ipairs({0,2})do local n=matches(id,id==0 and turn+1 or turn);assert(n>previous[id],"new contact did not raise capital marker");previous[id]=n end
  LekmodScenarioEvent("cuba-after-contact",LekmodScenario.snapshot(player))
  LekmodScenarioRecord("cuba-met-capital-counts","PASS","native-human-and-AI markers match per-capital rounded quotes and increase=true")
  local c=Players[1]:GetCapitalCity();for _,b in ipairs(buildings)do c:SetNumRealBuilding(b,0)end
  assert(c:GetBaseJONSCulturePerTurn()<5,"provided source reduction did not cross the five-culture boundary")
  LekmodScenarioEvent("fixture-setup",{operation="removed-provided-source-buildings",owner=1,culture=c:GetBaseJONSCulturePerTurn()})
  turn=Game.GetGameTurn();phase="reduced";return "turn"
 elseif phase=="reduced" then
  if Game.GetGameTurn()==turn then return "turn"end
  for _,id in ipairs({0,2})do local n=matches(id,id==0 and turn+1 or turn);assert(n<previous[id],"source reduction did not reduce capital marker")end
  assert(Players[1]:GetCapitalCity():GetNumRealBuilding(dummy)==0,"Rome received a Cuban capital marker")
  LekmodScenarioEvent("cuba-after-source-reduction",LekmodScenario.snapshot(player))
  LekmodScenarioRecord("cuba-capital-bonus-decrease","PASS","real-human-and-AI owner-turn updates remove stale marker counts=true")
  LekmodScenarioRecord("cuba-capital-owner-control","PASS","Roman-capital marker=0")
  return true
 end
 return false
end
