-- Existing agents are relocated through normal network commands. Research,
-- population and buildings are supplied inputs. Progress, rank, capture/death,
-- science awards, RNG and owner-turn state are never assigned.
LekmodScenario={name="counterspy",items={"counterspy-defender-arrival","counterspy-intruder-surveillance","counterspy-interception","counterspy-no-science-award","counterspy-defender-promotion"}}
local phase,attacker,defender,cityID,tech,start,rankBefore,lastState="init"
local observedSurveillance=false
local function spy(owner,id)
 for _,s in ipairs(Players[owner]:GetEspionageSpies())do if s.AgentID==id then return s end end
 error("expected spy disappeared: "..owner..":"..tostring(id))
end
local function rank(s)return assert(tonumber(s.Rank:match("_(%d+)$")),"unknown spy rank")end
local function relocate(owner,id,target,city)
 local legal=false
 for _,c in ipairs(Players[owner]:GetAvailableSpyRelocationCities(id))do if c.PlayerID==target and c.CityID==city:GetID()then legal=true;break end end
 assert(legal,"spy relocation not legal for owner "..owner)
 Network.SendMoveSpy(owner,id,target,city:GetID(),false)
 LekmodScenarioEvent("spy-command",{owner=owner,agent=id,target=target,city=city:GetID(),path="normal-network"})
end
function LekmodScenario.snapshot(player)
 local cities={};for c in Players[1]:Cities()do cities[c:GetID()]={x=c:GetX(),y=c:GetY(),population=c:GetPopulation(),science=c:GetYieldRateTimes100(YieldTypes.YIELD_SCIENCE)}end
 return {turn=Game.GetGameTurn(),human_spies=player:GetEspionageSpies(),AI_spies=Players[1]:GetEspionageSpies(),defender_cities=cities}
end
function LekmodScenario.step(player)
 start=start or Game.GetGameTurn();assert(Game.GetGameTurn()-start<=19,"counterspy case exceeded bounded ordinary turns")
 if phase=="init"then
  for _,s in ipairs(player:GetEspionageSpies())do if s.State=="TXT_KEY_SPY_STATE_UNASSIGNED"and rank(s)==0 then attacker=s.AgentID;break end end
  assert(attacker~=nil,"existing unassigned recruit required")
  local city=assert(Players[1]:GetCapitalCity());cityID=city:GetID()
  if not Teams[player:GetTeam()]:IsHasMet(Players[1]:GetTeam())then Teams[player:GetTeam()]:Meet(Players[1]:GetTeam(),false)end
  city:Plot():SetRevealed(player:GetTeam(),true)
  for t in GameInfo.Technologies()do
   if t.Era=="ERA_MODERN"and not Teams[player:GetTeam()]:GetTeamTechs():HasTech(t.ID)then tech=t.ID;break end
  end
  assert(tech,"no unknown modern spy research target")
  LekmodScenarioGrantTech(Players[1],GameInfo.Technologies[tech].Type)
  for row in GameInfo.Technology_PrereqTechs{TechType=GameInfo.Technologies[tech].Type}do LekmodScenarioGrantTech(player,row.PrereqTech)end
  assert(not Teams[player:GetTeam()]:GetTeamTechs():HasTech(tech))
  city:SetPopulation(32,true);city:SetFood(1000)
  for _,kind in ipairs({"BUILDING_LIBRARY","BUILDING_UNIVERSITY","BUILDING_PUBLIC_SCHOOL","BUILDING_LABORATORY","BUILDING_CONSTABLE","BUILDING_INTELLIGENCE_AGENCY"})do city:SetNumRealBuilding(assert(GameInfoTypes[kind]),1)end
  for _,s in ipairs(Players[1]:GetEspionageSpies())do if s.State~="TXT_KEY_SPY_STATE_DEAD"then defender=s.AgentID;break end end
  assert(defender~=nil,"existing AI spy required")
  player:ChangeGold(2000);Players[1]:ChangeGold(2000)
  LekmodScenarioEvent("fixture-setup",{operation="provided-counterspy-research-city",owner=1,city=cityID,population=32,food=1000,science=city:GetYieldRateTimes100(YieldTypes.YIELD_SCIENCE),technology=tech,buildings={"library","university","school","laboratory","constabulary","NIA"},gold_each=2000})
  phase="home";return "turn"
 elseif phase=="home"then
  local city=assert(Players[1]:GetCityByID(cityID))
  -- Observe the AI's own assignment. Its espionage AI already selected this
  -- city in the first trial, before the test tried to issue a duplicate move.
  for _,s in ipairs(Players[1]:GetEspionageSpies())do if s.CityX==city:GetX()and s.CityY==city:GetY()then defender=s.AgentID;break end end
  local d=spy(1,defender)
  local state=d.State..":"..d.TurnsLeft
  if state~=lastState then LekmodScenarioEvent("counterspy-travel",d);lastState=state end
  if d.State~="TXT_KEY_SPY_STATE_COUNTER_INTEL"then return "turn"end
  local c=assert(Players[1]:GetCityByID(cityID));assert(d.CityX==c:GetX()and d.CityY==c:GetY())
  rankBefore=rank(d)
  assert(rank(spy(0,attacker))+2-(rankBefore+3)<0,"provided defense does not support killed-spy branch")
  LekmodScenarioRecord("counterspy-defender-arrival","PASS","AI chose its own defensive assignment and travelled normally; no spy rank/progress set")
  relocate(0,attacker,1,c);phase="intruder";return false
 elseif phase=="intruder"then
  local a=spy(0,attacker);local d=spy(1,defender);local c=assert(Players[1]:GetCityByID(cityID))
  assert(d.State=="TXT_KEY_SPY_STATE_COUNTER_INTEL"and d.CityX==c:GetX()and d.CityY==c:GetY(),"AI reassigned defender; fixture must be reviewed")
  local state=a.State..":"..a.TurnsLeft;if state~=lastState then LekmodScenarioEvent("counterspy-progress",{attacker=a,defender=d});lastState=state end
  if a.EstablishedSurveillance then observedSurveillance=true end
  if a.State~="TXT_KEY_SPY_STATE_DEAD"then return "turn"end
  assert(observedSurveillance,"intruder never established normal surveillance")
  assert(a.CityX==-1 and a.CityY==-1 and not player:CanSpyStageCoup(attacker),"killed spy not extracted/ineligible")
  for t in GameInfo.Technologies()do assert(not player:canStealTech(1,t.ID),"intercepted mission granted science claim")end
  assert(rank(d)==math.min(2,rankBefore+1),"counterspy did not earn capped promotion")
  LekmodScenarioRecord("counterspy-intruder-surveillance","PASS","ordinary travel and surveillance preceded interception")
  LekmodScenarioRecord("counterspy-interception","PASS","actual counterspy mission killed/extracted human recruit; dead agent ineligible")
  LekmodScenarioRecord("counterspy-no-science-award","PASS","intercepted mission produced no claimable technology science")
  LekmodScenarioRecord("counterspy-defender-promotion","PASS","earned rank "..rankBefore.." -> "..rank(d))
  return true
 end
 return false
end
