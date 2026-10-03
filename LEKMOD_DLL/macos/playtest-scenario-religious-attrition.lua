-- Native method surface: GameCore
-- Normal one-human team/minor fixture. Research/religion, unit/plot staging and
-- upkeep are inputs; ordinary owner turns must apply losses/exemptions/death.
LekmodScenario={name="religious-attrition",items={"attrition-fixture-and-data","attrition-border-state","attrition-initial-strengths","attrition-territory-controls","attrition-base-strength-loss","attrition-fourth-turn-boundary","attrition-native-death"}}
local mode=assert(LekmodScenarioParameters.mode)
local phase,start,observed,minor,closed,accepted,proposed,err="init",nil,0,nil,false,nil,nil,nil
local probes,deaths={},{}
local tradeResource
local wanted=mode=="open"and 2 or 11
LuaEvents.LekmodScenarioDiplomacyResponse.Add(function(kind)if kind=="closed"then closed=true end end)
LuaEvents.LekmodAttritionDealAccepted.Add(function(kind)accepted=kind end)
LuaEvents.LekmodAttritionDealProposed.Add(function(kind)proposed=kind end)
local function request(kind)
 closed=false;accepted=nil;proposed=nil;LuaEvents.LekmodAttritionDeal({player=1,kind=kind,resource=tradeResource});LuaEvents.LekmodScenarioDiplomacyOpen(1)
end
GameEvents.UnitPrekill.Add(function(owner,id)if owner==0 then for _,r in ipairs(probes)do if r.id==id then deaths[id]=Game.GetGameTurn();LekmodScenarioEvent("native-religious-attrition-death",{unit=id,kind=r.kind,turn=Game.GetGameTurn()})end end end end)
local function site(owner,used)
 for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
  if not used[i]and q:GetOwner()==owner and not q:IsCity()and not q:IsWater()and not q:IsMountain()and q:GetNumUnits()==0 then used[i]=true;return q end
 end
 error("no eligible territory probe for owner "..owner)
end
local function createProbe(p,kind,label,owner,loss,used)
 local c=p:GetCapitalCity();local u=assert(p:InitUnit(GameInfoTypes[kind],c:GetX(),c:GetY()));local q=site(owner,used);u:SetXY(q:GetX(),q:GetY(),false,true,true)
 local info=GameInfo.Units[kind];assert(u:GetReligion()==p:GetReligionCreatedByPlayer()and u:GetConversionStrength()==info.ReligiousStrength*GameDefines.RELIGION_MISSIONARY_PRESSURE_MULTIPLIER and u:GetDamage()==0)
 local r={id=u:GetID(),kind=kind,label=label,plot=q:GetPlotIndex(),plot_owner=owner,loss=loss,base=info.ReligiousStrength,charges=u:GetSpreadsLeft()};probes[#probes+1]=r;LekmodScenarioEvent("fixture-setup",{operation="provided-religious-territory-probe",probe=r})
end
local function begin(p)
 assert(not Teams[p:GetTeam()]:IsAtWar(Players[1]:GetTeam()))
 p:ChangeGold(5000);local used={}
 if mode=="open"then
  assert(Teams[Players[1]:GetTeam()]:IsAllowsOpenBordersToTeam(p:GetTeam()))
  for _,kind in ipairs({"UNIT_MISSIONARY","UNIT_MAURYA_MISSIONARY"})do createProbe(p,kind,"open-foreign",1,0,used)end
 else
  assert(not Teams[Players[1]:GetTeam()]:IsAllowsOpenBordersToTeam(p:GetTeam()))
  for _,kind in ipairs({"UNIT_MISSIONARY","UNIT_MAURYA_MISSIONARY"})do
   for _,r in ipairs({{"own",0,0},{"neutral",-1,0},{"teammate",2,0},{"minor",minor,0},{"closed-foreign",1,25}})do createProbe(p,kind,r[1],r[2],r[3],used)end
  end
  createProbe(p,"UNIT_PROPHET","unpromoted-foreign",1,0,used)
 end
 assert(#probes==wanted);LekmodScenarioRecord("attrition-initial-strengths","PASS","both configured Missionary types start at their own raw data strength; nonpromoted Prophet control provided")
 LekmodScenarioRecord("attrition-border-state","PASS",mode=="open"and"original embassy/border/counteroffer callbacks accepted inbound permission; no team-open flag assigned"or"distinct foreign team has no open-border grant; teammate/minor/neutral controls distinguished")
 start=Game.GetGameTurn();phase="observe";return "turn"
end
GameEvents.PlayerDoTurn.Add(function(owner)
 if owner~=0 or phase~="observe"then return end
 local ok,e=pcall(function()
  local tick=Game.GetGameTurn()-start;assert(tick==observed+1 and tick<=4);local values={}
  for _,r in ipairs(probes)do local u=Players[0]:GetUnitByID(r.id);local expected=r.base-tick*math.floor(r.base*r.loss/100)
   if expected>0 then
    assert(u and not u:IsDead()and not u:IsDelayedDeath()and u:GetPlot():GetPlotIndex()==r.plot and u:GetPlot():GetOwner()==r.plot_owner)
    assert(u:GetConversionStrength()==expected*GameDefines.RELIGION_MISSIONARY_PRESSURE_MULTIPLIER and u:GetSpreadsLeft()==r.charges and u:GetDamage()==0)
    values[r.id]={strength=u:GetConversionStrength(),spreads=u:GetSpreadsLeft(),damage=u:GetDamage(),alive=true}
   else assert(not u or u:IsDead()or u:IsDelayedDeath());assert(deaths[r.id]==Game.GetGameTurn());values[r.id]={alive=false}end
  end
  observed=tick;LekmodScenarioEvent("native-religious-attrition-owner-turn",{mode=mode,tick=tick,turn=Game.GetGameTurn(),values=values})
 end)
 if not ok then err=tostring(e)end
end)
function LekmodScenario.snapshot(p)
 local units={};for u in p:Units()do local info=GameInfo.Units[u:GetUnitType()];if info.SpreadReligion or info.RemoveHeresy then units[u:GetID()]={type=u:GetUnitType(),x=u:GetX(),y=u:GetY(),plot_owner=u:GetPlot():GetOwner(),strength=u:GetConversionStrength(),spreads=u:GetSpreadsLeft(),damage=u:GetDamage(),religion=u:GetReligion()}end end
 local borders={};for owner=0,2 do local o=Players[owner];borders[owner]={team=o:GetTeam(),allows=Teams[o:GetTeam()]:IsAllowsOpenBordersToTeam(p:GetTeam())}end
 return {mode=mode,turn=Game.GetGameTurn(),units=units,borders=borders,faith=p:GetFaith()}
end
function LekmodScenario.step(p)
 assert(not err,err);assert(not Game.IsGameMultiPlayer()and p:IsHuman()and p:GetID()==0 and p:GetCivilizationType()==GameInfoTypes.CIVILIZATION_MAURYA and Players[1]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_ROME and Players[2]:GetTeam()==p:GetTeam()and Players[1]:GetTeam()~=p:GetTeam())
 if phase=="init"then
  assert(not Game.IsOption(GameOptionTypes.GAMEOPTION_NO_RELIGION));local count=0
  for owner=GameDefines.MAX_MAJOR_CIVS,GameDefines.MAX_CIV_PLAYERS-1 do local q=Players[owner];if q and q:IsAlive()and q:IsMinorCiv()then minor=owner;count=count+1 end end;assert(count==1 and Players[minor]:GetCapitalCity())
  assert(GameInfo.UnitPromotions.PROMOTION_UNWELCOME_EVANGELIST.ReligiousStrengthLossRivalTerritory==25)
  for _,name in ipairs({"UNIT_MISSIONARY","UNIT_MAURYA_MISSIONARY"})do local found=false;for r in GameInfo.Unit_FreePromotions{UnitType=name}do if r.PromotionType=="PROMOTION_UNWELCOME_EVANGELIST"then found=true end end;assert(found)end
  assert(not p:HasCreatedReligion());local religion;for row in GameInfo.Religions()do if row.ID>0 then religion=row.ID;break end end
  Game.FoundReligion(0,religion,nil,GameInfoTypes.BELIEF_TITHE,GameInfoTypes.BELIEF_MANDIRS,-1,-1,p:GetCapitalCity());Game.EnhanceReligion(0,religion,GameInfoTypes.BELIEF_HOLY_WARRIORS,GameInfoTypes.BELIEF_SANCTIFIED_INNOVATIONS)
  Network.SendFoundPantheon(0,GameInfoTypes.BELIEF_WORK_ETHIC);phase="religion"
  LekmodScenarioRecord("attrition-fixture-and-data","PASS","normal3major roster has one human, a different player teammate and one actual city-state; both recipient unit types use shipped25%base loss")
 elseif phase=="religion"then
  local found=false;for _,id in ipairs(Game.GetBeliefsInReligion(p:GetReligionCreatedByPlayer()))do if id==GameInfoTypes.BELIEF_WORK_ETHIC then found=true end end;if not LekmodScenarioAwait("attrition-reformation",found)then return false end
  if mode=="closed"then return begin(p)end
  for owner=0,1 do LekmodScenarioGrantTech(Players[owner],"TECH_CIVIL_SERVICE")end
  if not Teams[p:GetTeam()]:IsHasMet(Players[1]:GetTeam())then Teams[p:GetTeam()]:Meet(Players[1]:GetTeam(),true)end
  p:ChangeGold(5000);assert(p:CalculateGoldRate()>=1)
  local deal=UI.GetScratchDeal();deal:ClearItems();deal:SetFromPlayer(0);deal:SetToPlayer(1)
  for resource in GameInfo.Resources()do
   if resource.ResourceUsage==2 and Players[1]:GetNumResourceAvailable(resource.ID,true)==0 then
    if resource.TechCityTrade then LekmodScenarioGrantTech(p,resource.TechCityTrade)end
    local amount=math.max(0,2-p:GetNumResourceAvailable(resource.ID,true));if amount>0 then p:ChangeNumResourceTotal(resource.ID,amount)end
    if deal:IsPossibleToTradeItem(0,1,TradeableItems.TRADE_ITEM_RESOURCES,resource.ID,1,Game.GetDealDuration())then tradeResource=resource.ID;LekmodScenarioEvent("fixture-setup",{operation="provided-legal-counteroffer-budget",gold_added=5000,resource=resource.ID,resource_added=amount});break end
   end
  end
  assert(tradeResource);deal:ClearItems();request("embassies");phase="embassies"
 elseif phase=="embassies"then
  if not closed then return false end;assert(accepted=="embassies"and proposed=="embassies");request("borders");phase="borders"
 elseif phase=="borders"then
  if not closed then return false end;assert(accepted=="borders"and proposed=="borders");return begin(p)
 elseif phase=="observe"then
  if observed<4 then return "turn"end
  LekmodScenarioRecord("attrition-territory-controls","PASS",mode=="open"and"four ordinary owner turns under a real accepted inbound border deal preserve both strengths"or"own/neutral/same-team/minor territory and unpromoted foreign control preserve strength/charges/HP through4turns")
  LekmodScenarioRecord("attrition-base-strength-loss","PASS",mode=="open"and"open-border permission prevents the configured loss"or"each closed-border owner turn subtracts25%of original unit base, not25%of the diminishing remainder")
  LekmodScenarioRecord("attrition-fourth-turn-boundary","PASS",mode=="open"and"both units survive all4turns at full strength"or"25%remaining survives third tick; fourth tick reaches zero and removes only affected units")
  LekmodScenarioRecord("attrition-native-death","PASS",mode=="open"and"no attrition deaths under accepted open borders"or"native UnitPrekill confirms both closed-border missionary deaths; control units survive and snapshots retain exact state")
  LekmodScenarioEvent("native-attrition-complete",{mode=mode,probes=probes,observed=observed});return true
 end
 return false
end
