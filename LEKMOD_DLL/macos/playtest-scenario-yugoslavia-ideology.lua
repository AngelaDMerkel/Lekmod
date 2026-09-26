-- Native method surface: GameCore
-- Technology, culture, population, opponent ideology and staged musicians are
-- explicit inputs. Human adoption/revolution use original UI callbacks; actual
-- AI concerts and ordinary turns generate the public-opinion prerequisite.
LekmodScenario={name="yugoslavia-ideology",items={"ideology-cancel","yugo-adoption-tenet","yugo-foreign-control","yugo-concert-pressure","revolution-cancel","revolution-content-rejection","yugo-switch-tenet","yugo-switch-anarchy","yugo-anarchy-expiry","yugo-Freedom-markers","yugo-Order-markers"}}
local phase,chosen,adoptionFree,initialFree,started,concerts,switchBefore,expectedFree,replied,switchTurn="init",nil,nil,nil,nil,0
local freedom,order=GameInfoTypes.POLICY_BRANCH_FREEDOM,GameInfoTypes.POLICY_BRANCH_ORDER
LuaEvents.LekmodIdeologyChosen.Add(function(branch)chosen=branch end)
LuaEvents.LekmodRevolutionFinished.Add(function()replied=true end)
function LekmodScenario.snapshot(player)
 local owners={}
 for owner=0,1 do local p=Players[owner];local policies={}
  for row in GameInfo.Policies()do if p:HasPolicy(row.ID)then policies[row.ID]=true end end
  local markers={}
  for c in p:Cities()do markers[c:GetID()]={capital=c:IsCapital(),freedom=c:GetNumRealBuilding(GameInfoTypes.BUILDING_YUGO_FREEDOM),order=c:GetNumRealBuilding(GameInfoTypes.BUILDING_YUGO_ORDER),autocracy=c:GetNumRealBuilding(GameInfoTypes.BUILDING_YUGO_AUTOCRACY)}end
  owners[owner]={markers=markers,civilization=p:GetCivilizationType(),ideology=p:GetLateGamePolicyTree(),policies=policies,free=p:GetNumFreeTenets(),free_policies=p:GetNumFreePolicies(),culture=p:GetJONSCulture(),lifetime_culture=p:GetJONSCultureEverGenerated(),anarchy=p:GetAnarchyNumTurns(),unhappiness=p:GetPublicOpinionUnhappiness(),preferred=p:GetPublicOpinionPreferredIdeology(),influence_other=p:GetInfluenceOn(1-owner)}
 end
 return {turn=Game.GetGameTurn(),winner=Game.GetWinner(),owners=owners}
end
GameEvents.PlayerDoTurn.Add(function(owner)
 if owner~=1 or phase~="pressure"or concerts>0 then return end
 local p=Players[1];local human=Players[0];local c=human:GetCapitalCity();local q
 assert(p:IsTurnActive()and not p:IsHuman())
 for d=0,5 do local n=Map.PlotDirection(c:GetX(),c:GetY(),d)
  if n and n:GetOwner()==0 and not n:IsWater()and not n:IsMountain()then q=n;break end
 end
 assert(q,"no land concert location")
 repeat
  concerts=concerts+1;assert(concerts<=10)
  local home=p:GetCapitalCity();local u=assert(p:InitUnit(GameInfoTypes.UNIT_MUSICIAN,home:GetX(),home:GetY()));u:SetXY(q:GetX(),q:GetY(),false,true,false,false)
  local before=p:GetInfluenceOn(0);local strength=u:GetBlastTourism();assert(before+strength<human:GetJONSCultureEverGenerated(),"concert would reach victory threshold")
  LekmodScenarioEvent("fixture-setup",{operation="provided-positioned-AI-musician",owner=1,unit=u:GetID(),strength=strength,x=q:GetX(),y=q:GetY()})
  assert(u:CanStartMission(GameInfoTypes.MISSION_ONE_SHOT_TOURISM,-1,-1,u:GetPlot(),0));u:PushMission(GameInfoTypes.MISSION_ONE_SHOT_TOURISM,-1,-1,0,0,1)
  assert(p:GetInfluenceOn(0)==before+strength and(u:IsDead()or u:IsDelayedDeath()))
  LekmodScenarioEvent("native-pressure-concert",{before=before,after=p:GetInfluenceOn(0),strength=strength})
 until p:GetInfluenceOn(0)>=human:GetJONSCultureEverGenerated()*0.7
end)
function LekmodScenario.step(player)
 assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_YUGOSLAVIA and Players[1]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_SPAIN and Game.GetWinner()==-1)
 if phase=="init"then
  assert(player:GetLateGamePolicyTree()==-1 and Players[1]:GetLateGamePolicyTree()==-1)
  LekmodScenarioGrantTech(player,"TECH_RADIO");started=Game.GetGameTurn();phase="waiting"
 elseif phase=="waiting"then
  assert(player:GetLateGamePolicyTree()==-1,"ideology selected outside reviewed popup")
  if player:GetEndTurnBlockingType()~=EndTurnBlockingTypes.ENDTURN_BLOCKING_CHOOSE_IDEOLOGY then assert(Game.GetGameTurn()-started<3);return "turn"end
  initialFree=player:GetNumFreeTenets();adoptionFree=Game.GetNumFreePolicies(freedom)
  LuaEvents.LekmodChooseTestIdeology(freedom);UI.ActivateNotification(player:GetEndTurnBlockingNotificationIndex());phase="adopted"
 elseif phase=="adopted"then
  if not chosen or not LekmodScenarioAwait("Yugoslav-Freedom",player:GetLateGamePolicyTree()==freedom)then return false end
  assert(chosen==freedom and player:GetAnarchyNumTurns()==0 and player:GetNumFreeTenets()==initialFree+adoptionFree+1)
  LekmodScenarioRecord("yugo-adoption-tenet","PASS","normal ideology popup adds standard early-adopter allowance plus one Yugoslav tenet")
  local markers=LekmodScenario.snapshot(player).owners[0].markers;local correct=true
  for _,m in pairs(markers)do correct=correct and m.freedom==0 and m.order==1 and m.autocracy==1 end
  LekmodScenarioRecord("yugo-Freedom-markers",correct and"PASS"or"FAIL","normal Freedom adoption installs both rival-ideology effect buildings; actual="..LekmodScenarioJSON(markers))
  local foreign=Players[1];LekmodScenarioGrantTech(foreign,"TECH_RADIO")
  local oldFree=foreign:GetNumFreeTenets();local standard=Game.GetNumFreePolicies(order);foreign:SetPolicyBranchUnlocked(order,true,false)
  assert(foreign:GetNumFreeTenets()==oldFree+standard)
  LekmodScenarioEvent("fixture-setup",{operation="provided-opposing-Spanish-ideology",ideology=order,standard_free=standard})
  LekmodScenarioRecord("yugo-foreign-control","PASS","supplied Spanish native branch unlock receives only its standard allowance")
  local c=player:GetCapitalCity();local pop=c:GetPopulation();c:SetPopulation(25,true);player:ChangeJONSCulture(1000)
  Teams[player:GetTeam()]:Meet(foreign:GetTeam(),true)
  LekmodScenarioEvent("fixture-setup",{operation="provided-pressure-population-culture-contact",previous_population=pop,population=25,culture_added=1000,lifetime=player:GetJONSCultureEverGenerated()})
  started=Game.GetGameTurn();phase="pressure";return "turn"
 elseif phase=="pressure"then
  if concerts==0 or player:GetPublicOpinionUnhappiness()==0 then assert(Game.GetGameTurn()-started<5,"concerts did not generate public pressure");return "turn"end
  assert(player:GetPublicOpinionPreferredIdeology()==order and not player:IsAnarchy())
  LekmodScenarioRecord("yugo-concert-pressure","PASS","actual foreign concerts and ordinary turns create Order pressure below victory threshold")
  switchBefore=LekmodScenario.snapshot(player).owners[0]
  expectedFree=player:GetNumFreeTenets()+Game.GetNumFreePolicies(order)+math.max(0,player:GetNumPoliciesInBranch(freedom)-GameDefines.SWITCH_POLICY_BRANCHES_TENETS_LOST)+1
  LekmodScenarioEvent("Yugoslav-revolution-before",{state=switchBefore,expected_free=expectedFree})
  LuaEvents.LekmodTestRevolution();phase="switched"
 elseif phase=="switched"then
  if not replied then return false end
  assert(player:GetLateGamePolicyTree()==order and not player:IsPolicyBranchUnlocked(freedom)and player:GetJONSCulture()==switchBefore.culture)
  local markers=LekmodScenario.snapshot(player).owners[0].markers;local correct=true
  for _,m in pairs(markers)do correct=correct and m.freedom==(m.capital and 1 or 0)and m.order==0 and m.autocracy==1 end
  LekmodScenarioRecord("yugo-Order-markers",correct and"PASS"or"FAIL","normal Order revolution replaces rival-ideology effect buildings; actual="..LekmodScenarioJSON(markers))
  local actual=player:GetNumFreeTenets()
  LekmodScenarioRecord("yugo-switch-tenet",actual==expectedFree and"PASS"or"FAIL","normal revolution free tenets expected="..expectedFree.." actual="..actual.."; expected includes Yugoslav bonus")
  assert(player:GetAnarchyNumTurns()==GameDefines.SWITCH_POLICY_BRANCHES_ANARCHY_TURNS)
  LekmodScenarioRecord("yugo-switch-anarchy","PASS","normal revolution preserves required anarchy and clears old branch")
  LekmodScenarioEvent("Yugoslav-revolution-after",LekmodScenario.snapshot(player));switchTurn=Game.GetGameTurn();phase="expiry";return "turn"
 elseif phase=="expiry"then
  if player:IsAnarchy()then assert(Game.GetGameTurn()-switchTurn<=GameDefines.SWITCH_POLICY_BRANCHES_ANARCHY_TURNS+1);return "turn"end
  assert(Game.GetGameTurn()>switchTurn and player:GetLateGamePolicyTree()==order and player:GetPublicOpinionUnhappiness()==0)
  LekmodScenarioRecord("yugo-anarchy-expiry","PASS","ordinary rounds end revolution anarchy; selected ideology remains and public pressure is resolved")
  return true
 end
 return false
end
