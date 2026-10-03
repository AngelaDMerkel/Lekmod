-- Native method surface: GameCore
-- A legal extra city, population/religious pressure and a funded AI attacker are
-- inputs. Real founding, conversions, owner turns and conquest must maintain the
-- shared foreign-religion benefit. No reward marker, city owner or damage is set.
LekmodScenario={name="mughal-city-events",items={"mughal-native-founding","mughal-second-contributor","mughal-retained-holy-benefit","mughal-native-owner-turn","mughal-native-city-loss","mughal-last-contributor-cleanup","mughal-foreign-holy-cleanup","mughal-following-owner-turn"}}
local marker=GameInfoTypes.BUILDING_DUMMY_MUGHALS
local phase,own,foreign,sourceID,x,y,capture,captureTurn="init"
local turns,lastTurn,sent=0,nil,false
local founded,converted={},{}
local function source()return assert(Players[0]:GetCityByID(sourceID))end
local function cap()return assert(Players[0]:GetCapitalCity())end
local function holy()return assert(Players[1]:GetCapitalCity())end
GameEvents.PlayerCityFounded.Add(function(owner,cx,cy)if owner==0 then founded[cx..":"..cy]=true end end)
GameEvents.CityConvertsReligion.Add(function(owner,religion,cx,cy)
 if owner==0 then converted[cx..":"..cy]=religion;LekmodScenarioEvent("native-Mughal-city-conversion",{owner=owner,religion=religion,x=cx,y=cy})end
end)
GameEvents.CityCaptureComplete.Add(function(old,capital,cx,cy,new,pop,conquest)
 if cx==x and cy==y then assert(old==0 and new==1 and not capital and conquest and not capture);capture=true;captureTurn=Game.GetGameTurn();LekmodScenarioEvent("native-Mughal-contributor-capture",{old=old,new=new,capital=capital,conquest=conquest})end
end)
GameEvents.PlayerDoTurn.Add(function(owner)
 if owner==0 then turns=turns+1 end
 if owner~=1 or phase~="capture"or sent then return end
 local p=Players[1];assert(p:IsTurnActive()and not p:IsHuman());local tile
 for d=0,5 do local q=Map.PlotDirection(x,y,d)
  if q and not q:IsWater()and not q:IsMountain()and not q:IsCity()and q:GetNumUnits()==0 then tile=q;break end
 end
 assert(tile);p:ChangeGold(1000);p:ChangeNumResourceTotal(GameInfoTypes.RESOURCE_URANIUM,1)
 local u=assert(p:InitUnit(GameInfoTypes.UNIT_MECH,tile:GetX(),tile:GetY()));assert(u:CanMoveOrAttackInto(Map.GetPlot(x,y)));sent=true
 LekmodScenarioEvent("fixture-setup",{operation="provided-real-AI-turn-capture-attacker",owner=1,unit=u:GetID(),x=tile:GetX(),y=tile:GetY()});u:PushMission(MissionTypes.MISSION_MOVE_TO,x,y,0,0,1)
end)
function LekmodScenario.snapshot(p)
 local owners={}
 for id=0,1 do local q=Players[id];local cities={}
  for c in q:Cities()do cities[c:GetID()]={x=c:GetX(),y=c:GetY(),capital=c:IsCapital(),majority=c:GetReligiousMajority(),marker=c:GetNumRealBuilding(marker),population=c:GetPopulation()}end
  owners[id]={alive=q:IsAlive(),civ=q:GetCivilizationType(),religion=q:GetReligionCreatedByPlayer(),cities=cities}
 end
 return {turn=Game.GetGameTurn(),winner=Game.GetWinner(),owners=owners}
end
local function baseline()
 assert(cap():GetReligiousMajority()==own and cap():GetNumRealBuilding(marker)==0)
 assert(source():GetReligiousMajority()==foreign and source():GetNumRealBuilding(marker)==1)
 assert(holy():IsHolyCityForReligion(foreign)and holy():GetNumRealBuilding(marker)==1)
end
local function cleared()
 assert(cap():GetReligiousMajority()==own and cap():GetNumRealBuilding(marker)==0)
 assert(holy():IsHolyCityForReligion(foreign)and holy():GetNumRealBuilding(marker)==0)
 local c=assert(Map.GetPlot(x,y):GetPlotCity());assert(c:GetOwner()==1 and c:GetNumRealBuilding(marker)==0)
end
function LekmodScenario.step(p)
 assert(p:GetID()==0 and p:IsHuman()and p:GetCivilizationType()==GameInfoTypes.CIVILIZATION_MUGHALS)
 if phase=="init"then
  own=p:GetReligionCreatedByPlayer();foreign=Players[1]:GetReligionCreatedByPlayer();assert(own>0 and foreign>0 and own~=foreign)
  assert(p:GetNumCities()==1 and cap():GetReligiousMajority()==foreign and cap():GetNumRealBuilding(marker)==1 and holy():GetNumRealBuilding(marker)==1)
  p:ChangeGold(10000);local site
  for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
   if Map.PlotDistance(cap():GetX(),cap():GetY(),q:GetX(),q:GetY())>=8 and q:GetOwner()==-1 and q:GetNumUnits()==0 and p:CanFound(q:GetX(),q:GetY())then site=q;break end
  end
  assert(site,"no isolated noncapital contributor site");p:Found(site:GetX(),site:GetY());local c=assert(site:GetPlotCity());sourceID=c:GetID();x,y=c:GetX(),c:GetY();assert(not c:IsCapital()and founded[x..":"..y])
  local majority=c:GetReligiousMajority();local expected=majority>0 and majority~=own and 1 or 0
  assert(c:GetNumRealBuilding(marker)==expected and cap():GetNumRealBuilding(marker)==1 and holy():GetNumRealBuilding(marker)==1)
  LekmodScenarioRecord("mughal-native-founding","PASS","real founding event gives only religion-eligible city benefit and preserves existing contributors/foreign holy benefit")
  c:SetPopulation(5,true);if c:GetReligiousMajority()~=own then c:ConvertPercentFollowers(own,c:GetReligiousMajority(),100)end
  assert(c:GetReligiousMajority()==own and c:GetNumRealBuilding(marker)==0)
  LekmodScenarioEvent("fixture-setup",{operation="provided-noncapital-own-religion-city",city=sourceID,population=5,religion=own});phase="foreign"
 elseif phase=="foreign"then
  source():ConvertPercentFollowers(foreign,own,100);assert(converted[x..":"..y]==foreign and source():GetReligiousMajority()==foreign and source():GetNumRealBuilding(marker)==1)
  assert(cap():GetNumRealBuilding(marker)==1 and holy():GetNumRealBuilding(marker)==1)
  LekmodScenarioRecord("mughal-second-contributor","PASS","native foreign conversion creates a second contributor while holy benefit remains exactly one");phase="old-own"
 elseif phase=="old-own"then
  local c=cap();c:ConvertPercentFollowers(own,foreign,100);assert(converted[c:GetX()..":"..c:GetY()]==own);baseline()
  LekmodScenarioRecord("mughal-retained-holy-benefit","PASS","removing one contributor clears that city only; surviving source retains the foreign holy-city benefit")
  lastTurn=turns;phase="baseline";return "turn"
 elseif phase=="baseline"then
  if turns<=lastTurn then return "turn"end;baseline()
  LekmodScenarioRecord("mughal-native-owner-turn","PASS","real Mughal owner turn retains exact shared and excluded-own-religion state")
  local otherTeam=Players[1]:GetTeam();local me=Teams[p:GetTeam()];local met=me:IsHasMet(otherTeam)
  if not met then me:Meet(otherTeam,true);LekmodScenarioEvent("fixture-setup",{operation="provided-team-contact",team=p:GetTeam(),other=otherTeam})end
  LekmodScenarioEvent("war-prerequisites",{met_before=met,met_now=me:IsHasMet(otherTeam),already_war=me:IsAtWar(otherTeam),can_declare=me:CanDeclareWar(otherTeam)})
  assert(me:CanDeclareWar(otherTeam),"native war eligibility refused after contact");Network.SendChangeWar(Players[1]:GetTeam(),true);phase="war"
 elseif phase=="war"then
  if not LekmodScenarioAwait("Mughal-war",Teams[p:GetTeam()]:IsAtWar(Players[1]:GetTeam()))then return false end;phase="capture";return "turn"
 elseif phase=="capture"then
  if not capture or Game.GetGameTurn()<=captureTurn then return "turn"end
  assert(p:IsAlive()and p:GetNumCities()==1 and Game.GetWinner()==-1);cleared()
  LekmodScenarioRecord("mughal-native-city-loss","PASS","normal AI conquest removes the last foreign-religion source while both original capitals remain")
  LekmodScenarioRecord("mughal-last-contributor-cleanup","PASS","remaining own-religion Mughal capital and captured foreign-owned city have no marker")
  LekmodScenarioRecord("mughal-foreign-holy-cleanup","PASS","untouched foreign holy city loses its formerly positive marker when the last contributor changes owner")
  lastTurn=turns;phase="after";return "turn"
 elseif phase=="after"then
  if turns<=lastTurn then return "turn"end;assert(Game.GetWinner()==-1);cleared()
  LekmodScenarioRecord("mughal-following-owner-turn","PASS","another actual owner round preserves removal without reintroducing the foreign holy benefit");return true
 end
 return false
end
