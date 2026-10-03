-- Native method surface: GameCore
-- Pantheon/religion choices, exact faith budgets and first-unit parking are
-- inputs. Ordinary owner turns must roll/spawn/debit the two real Prophets.
LekmodScenario={name="prophet-cost-births",items={"prophet-native-belief-inputs","prophet-zero-faith-control","prophet-first-cost-birth","prophet-second-cost-birth","prophet-first-only-expiry","prophet-owner-debits"}}
local civ=assert(LekmodScenarioParameters.civ);local founderMode=assert(LekmodScenarioParameters.founder)
local civName=({mali="CIVILIZATION_MALI",madagascar="CIVILIZATION_MADAGASCAR",lithuania="CIVILIZATION_LITHUANIA"})[civ]
local founderOwner=civ=="lithuania"and 1 or 0
local founder=GameInfoTypes[founderMode=="messiah"and"BELIEF_MESSIAH"or"BELIEF_TITHE"]
local phase,religion,start,count,birth,observed,currentCost="init",nil,nil,0,nil,false,nil
local results={}
local reformation=GameInfoTypes.BELIEF_WORK_ETHIC
local reformed=false
GameEvents.ReformationAdded.Add(function(owner,id,belief)
 if owner==founderOwner then assert(phase=="reformation"and id==religion and belief==reformation);reformed=true;LekmodScenarioEvent("native-price-neutral-reformation",{owner=owner,religion=id,belief=belief})end
end)
local function div(n,d)return math.floor(n/d)end
local function cost(p,n)
 local value=GameDefines.RELIGION_MIN_FAITH_FIRST_PROPHET+GameDefines.RELIGION_FAITH_DELTA_NEXT_PROPHET*n*(n+1)/2
 if founderOwner==0 then value=div(value*(100+GameInfo.Beliefs[founder].ProphetCostModifier),100)end
 if civ=="lithuania"and n==0 then value=div(value*50,100)end
 value=div(value*GameInfo.GameSpeeds[Game.GetGameSpeedType()].TrainPercent,100)
 return div(value,GameDefines.GOLD_PURCHASE_VISIBLE_DIVISOR)*GameDefines.GOLD_PURCHASE_VISIBLE_DIVISOR
end
local function has(list,id)for _,v in ipairs(list)do if v==id then return true end end;return false end
GameEvents.UnitCreated.Add(function(owner,id)
 if owner~=0 then return end;local p=Players[0];local u=p:GetUnitByID(id)
 if not u or u:GetUnitClassType()~=GameInfoTypes.UNITCLASS_PROPHET then return end
 assert(phase=="funded"and not birth,"unexpected supplied/free/repeated Prophet birth")
 assert(p:GetFaith()>=currentCost+100)
 birth={id=id,cost=currentCost,faith_before=p:GetFaith(),turn=Game.GetGameTurn(),ordinal=count+1}
 LekmodScenarioEvent("native-costed-prophet-birth",birth)
end)
GameEvents.PlayerDoTurn.Add(function(owner)
 if owner~=0 or phase~="funded"or not birth or observed then return end
 local p=Players[0];assert(p:GetFaith()==birth.faith_before-birth.cost and p:GetMinimumFaithNextGreatProphet()==cost(p,count+1),"native birth debit/next price differs")
 local u=assert(p:GetUnitByID(birth.id));local expectedReligion=p:GetReligionCreatedByPlayer();if expectedReligion<=0 then expectedReligion=p:GetCapitalCity():GetReligiousMajority()end;assert(u:GetReligion()==expectedReligion)
 birth.faith_after=p:GetFaith();birth.next_cost=p:GetMinimumFaithNextGreatProphet();birth.religion=u:GetReligion();birth.spreads=u:GetSpreadsLeft();observed=true
 LekmodScenarioEvent("native-prophet-cost-accounting",birth)
end)
local function fund(p)
 currentCost=cost(p,count);assert(currentCost==p:GetMinimumFaithNextGreatProphet());p:ChangeFaith(currentCost+100-p:GetFaith());birth=nil;observed=false;phase="funded";start=Game.GetGameTurn()
 LekmodScenarioEvent("fixture-setup",{operation="provided-faith-above-native-guaranteed-spawn-chance",cost=currentCost,faith=p:GetFaith(),ordinal=count+1});return "turn"
end
function LekmodScenario.snapshot(p)
 local units={};for u in p:Units()do if u:GetUnitClassType()==GameInfoTypes.UNITCLASS_PROPHET then units[u:GetID()]={type=u:GetUnitType(),x=u:GetX(),y=u:GetY(),religion=u:GetReligion(),spreads=u:GetSpreadsLeft(),moves=u:GetMoves()}end end
 return {civ=civ,founder=founderMode,founder_owner=founderOwner,turn=Game.GetGameTurn(),faith=p:GetFaith(),faith_choice=p:GetFaithPurchaseType(),next_prophet=p:GetMinimumFaithNextGreatProphet(),religion=p:GetReligionCreatedByPlayer(),majority=p:GetCapitalCity():GetReligiousMajority(),pantheon=p:GetBeliefInPantheon(),units=units}
end
function LekmodScenario.step(p)
 assert(not Game.IsGameMultiPlayer()and not Game.IsOption(GameOptionTypes.GAMEOPTION_NO_RELIGION)and p:GetID()==0 and p:GetCivilizationType()==GameInfoTypes[civName])
 if phase=="init"then
  assert(not p:HasCreatedReligion()and p:GetCurrentEra()<GameInfoTypes.ERA_INDUSTRIAL)
  if not p:HasCreatedPantheon()then local belief=assert(Game.GetAvailablePantheonBeliefs()[1]);p:ChangeFaith(Game.GetMinimumFaithNextPantheon()-p:GetFaith());Game.FoundPantheon(0,belief);assert(p:HasCreatedPantheon())end
  local used={};for owner=0,GameDefines.MAX_MAJOR_CIVS-1 do local o=Players[owner];if o and o:IsAlive()and o:HasCreatedReligion()then used[o:GetReligionCreatedByPlayer()]=true end end
  for row in GameInfo.Religions()do if row.ID>0 and not used[row.ID]then religion=row.ID;break end end
  assert(religion and has(Game.GetAvailableFounderBeliefs(),founder)and has(Game.GetAvailableFollowerBeliefs(),GameInfoTypes.BELIEF_MANDIRS))
  local creator=Players[founderOwner];Game.FoundReligion(founderOwner,religion,nil,founder,GameInfoTypes.BELIEF_MANDIRS,-1,-1,creator:GetCapitalCity());assert(creator:GetReligionCreatedByPlayer()==religion)
  Game.EnhanceReligion(founderOwner,religion,GameInfoTypes.BELIEF_HOLY_WARRIORS,GameInfoTypes.BELIEF_SANCTIFIED_INNOVATIONS)
  if founderOwner~=0 then p:GetCapitalCity():ConvertPercentFollowers(religion,-1,100);p:GetCapitalCity():ConvertPercentFollowers(religion,0,100);assert(not p:HasCreatedReligion())end
  assert(p:GetCapitalCity():GetReligiousMajority()==religion and p:GetMinimumFaithNextGreatProphet()==cost(p,0))
  assert(has(Game.GetAvailableReformationBeliefs(),reformation)and GameInfo.Beliefs[reformation].NumFreeSettlers==0 and GameInfo.Beliefs[reformation].ProphetCostModifier==0)
  phase="reformation";Network.SendFoundPantheon(founderOwner,reformation);return false
 elseif phase=="reformation"then
  if not LekmodScenarioAwait("price-neutral-reformation",reformed and has(Game.GetBeliefsInReligion(religion),reformation))then return false end
  assert(p:GetMinimumFaithNextGreatProphet()==cost(p,0))
  p:SetFaithPurchaseType(FaithPurchaseTypes.FAITH_PURCHASE_SAVE_PROPHET);p:ChangeFaith(-p:GetFaith());assert(p:GetFaith()==0)
  LekmodScenarioRecord("prophet-native-belief-inputs","PASS","native valid pantheon/foundation/enhancement and no-grant/no-Prophet-cost reformation supplied; Lithuania retains foreign religion and never founds/enhances; threshold formula matches")
  start=Game.GetGameTurn();phase="below";return "turn"
 elseif phase=="below"then
  if Game.GetGameTurn()==start then return "turn"end
  assert(Game.GetGameTurn()==start+1 and not birth and p:GetFaith()<cost(p,0))
  LekmodScenarioRecord("prophet-zero-faith-control","PASS","one complete ordinary round starting at zero faith produced no Prophet")
  return fund(p)
 elseif phase=="funded"then
  if not observed then assert(Game.GetGameTurn()-start<3,"native Prophet did not arrive within bounded owner turns");return "turn"end
  assert(birth and p:GetUnitByID(birth.id));results[#results+1]=birth;count=count+1
  LekmodScenarioRecord(count==1 and"prophet-first-cost-birth"or"prophet-second-cost-birth","PASS","native owner-turn faith processing created Prophet and spent independent threshold cost="..birth.cost)
  if count<2 then
   local u=p:GetUnitByID(birth.id);local c=p:GetCapitalCity();local moved=false
   for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
    if not q:IsCity()and not q:IsWater()and not q:IsMountain()and q:GetNumUnits()==0 and(q:GetOwner()==-1 or q:GetOwner()==0)and Map.PlotDistance(q:GetX(),q:GetY(),c:GetX(),c:GetY())<=4 then u:SetXY(q:GetX(),q:GetY(),false,true,true);moved=true;break end
   end
   assert(moved);LekmodScenarioEvent("fixture-setup",{operation="parked-first-native-Prophet",unit=u:GetID()});return fund(p)
  end
  assert(results[2].cost==cost(p,1)and p:GetMinimumFaithNextGreatProphet()==cost(p,2))
  LekmodScenarioRecord("prophet-first-only-expiry","PASS","second threshold excludes first-only trait reduction; own founder reduction persists and foreign founder reduction never applies")
  LekmodScenarioRecord("prophet-owner-debits","PASS","both native births charged exact threshold amounts, with incoming faith observed before debit; no unit, spawn roll, counter or wait state assigned")
  LekmodScenarioEvent("native-two-prophet-costs",{civ=civ,founder=founderMode,founder_owner=founderOwner,speed=Game.GetGameSpeedType(),results=results,next_cost=p:GetMinimumFaithNextGreatProphet()});return true
 end
 return false
end
