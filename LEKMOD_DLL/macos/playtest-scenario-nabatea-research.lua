-- Load the preserved farm baseline. Removing its supplied Mathematics and
-- supplying all but one research point are setup inputs. Completion, worked
-- plot/city yields and the subsequent food settlement use ordinary turns.
LekmodScenario={name="nabatea-research",items={"nabatea-normal-mathematics","nabatea-worked-farm-cache","nabatea-farm-food-settlement"}}
local phase="init"
local mathTech=GameInfoTypes.TECH_MATHEMATICS
local fresh,dry,city,turn,base,foodQuote,foodBefore,population
local researched=false
GameEvents.TeamTechResearched.Add(function(team,tech,change)
 if team==Players[Game.GetActivePlayer()]:GetTeam()and tech==mathTech and change>0 then
  researched=true;LekmodScenarioEvent("native-mathematics-completed",{team=team,tech=tech,change=change,turn=Game.GetGameTurn()})
 end
end)
local function locate(player)
 for i=0,Map.GetNumPlots()-1 do local plot=Map.GetPlotByIndex(i)
  if plot:GetOwner()==player:GetID()and plot:GetImprovementType()==GameInfoTypes.IMPROVEMENT_FARM then
   if plot:IsFreshWater()then fresh=plot else dry=plot end
  end
 end
 assert(fresh and dry,"requires preserved fresh/dry farms")
 city=assert(fresh:GetWorkingCity())
end
function LekmodScenario.snapshot(player)
 locate(player)
 return {turn=Game.GetGameTurn(),math=Teams[player:GetTeam()]:GetTeamTechs():HasTech(mathTech),fresh=fresh:GetYield(YieldTypes.YIELD_FOOD),calculated=fresh:CalculateYield(YieldTypes.YIELD_FOOD,false),dry=dry:GetYield(YieldTypes.YIELD_FOOD),worked=city:IsWorkingPlot(fresh),forced=city:IsForcedWorkingPlot(fresh),terrain_food=city:GetBaseYieldRateFromTerrain(YieldTypes.YIELD_FOOD),gross_food=city:GetYieldRateTimes100(YieldTypes.YIELD_FOOD),food=city:GetFoodTimes100(),population=city:GetPopulation(),city=city:GetID()}
end
function LekmodScenario.step(player)
 local team=Teams[player:GetTeam()];local techs=team:GetTeamTechs()
 if phase=="init"then
  assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_NABATEA)
  assert(techs:HasTech(mathTech)and not techs:HasTech(GameInfoTypes.TECH_CIVIL_SERVICE),"requires Mathematics-only failed farm fixture")
  locate(player)
  team:SetHasTech(mathTech,false,player:GetID(),false,false)
  player:SetGold(500)
  LekmodScenarioEvent("fixture-setup",{operation="removed-provided-Mathematics-and-supplied-upkeep",gold=500})
  phase="assign";return false
 elseif phase=="assign"then
  assert(not techs:HasTech(mathTech)and player:CanResearch(mathTech))
  if not city:IsForcedWorkingPlot(fresh)then
   local index
   for i=1,city:GetNumCityPlots()-1 do if city:GetCityIndexPlot(i)==fresh then index=i;break end end
   assert(index,"farm outside city plot index")
   Network.SendDoTask(city:GetID(),TaskTypes.TASK_CHANGE_WORKING_PLOT,index,-1,false,false,false,false)
  end
  phase="selected";return false
 elseif phase=="selected"then
  if not LekmodScenarioAwait("fresh-farm-assigned",city:IsWorkingPlot(fresh)and city:IsForcedWorkingPlot(fresh))then return false end
  base=LekmodScenario.snapshot(player)
  assert(base.fresh==base.calculated and player:GetScienceTimes100()>0)
  local cost=player:GetResearchCost(mathTech)
  techs:SetResearchProgress(mathTech,cost-1,player:GetID())
  LekmodScenarioEvent("fixture-setup",{operation="provided-near-complete-research",tech=mathTech,progress=cost-1,cost=cost})
  assert(not techs:HasTech(mathTech),"provided progress completed technology")
  Network.SendResearch(mathTech,0,-1,false);phase="research-selected";return false
 elseif phase=="research-selected"then
  if not LekmodScenarioAwait("Mathematics-selected",player:GetCurrentResearch()==mathTech)then return false end
  turn=Game.GetGameTurn();phase="researched";return "turn"
 elseif phase=="researched"then
  if Game.GetGameTurn()==turn then return "turn"end
  assert(Game.GetGameTurn()==turn+1 and researched and techs:HasTech(mathTech),"ordinary research did not complete Mathematics")
  LekmodScenarioRecord("nabatea-normal-mathematics","PASS","native TeamTechResearched after one ordinary turn; prior progress supplied")
  local s=LekmodScenario.snapshot(player)
  LekmodScenarioEvent("worked-farm-research-result",{before=base,after=s})
  assert(s.population==base.population and s.worked and s.forced,"worked plot/population changed")
  assert(s.fresh==base.fresh+1 and s.calculated==s.fresh and s.dry==base.dry,"farm cache did not follow ordinary research")
  assert(s.terrain_food==base.terrain_food+1,"worked-city terrain food did not update")
  LekmodScenarioRecord("nabatea-worked-farm-cache","PASS","fresh+1 dry unchanged worked-city terrain food+1")
  foodQuote=city:FoodDifferenceTimes100();foodBefore=city:GetFoodTimes100();population=city:GetPopulation()
  assert(foodQuote>0 and foodBefore+foodQuote<city:GrowthThreshold()*100,"food settlement would include growth")
  LekmodScenarioEvent("food-settlement-quote",{food=foodBefore,difference=foodQuote,population=population})
  phase="settled";return "turn"
 elseif phase=="settled"then
  if Game.GetGameTurn()==turn+1 then return "turn"end
  assert(Game.GetGameTurn()==turn+2 and city:GetPopulation()==population and city:GetFoodTimes100()==foodBefore+foodQuote,"normal food settlement differs from quote")
  LekmodScenarioEvent("food-settlement-result",LekmodScenario.snapshot(player))
  LekmodScenarioRecord("nabatea-farm-food-settlement","PASS","exact food-storage delta after ordinary turn; no food/yield setter")
  return true
 end
 return false
end
