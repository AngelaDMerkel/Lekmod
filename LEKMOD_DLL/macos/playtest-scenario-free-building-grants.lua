-- Native method surface: GameCore
-- Legal founding sites, ownership reasons, population and a survival unit are
-- fixture inputs. Native city creation/acquisition/research grants are outcomes.
-- Direct AcquireCity calls test that consumer, not combat or negotiated gifts.
LekmodScenario={name="free-building-grants",items={"free-grant-data","free-grant-initial","free-grant-positive","free-grant-controls","free-grant-transition","free-grant-nonstack","free-grant-next-turn"}}
local mode=assert(LekmodScenarioParameters.mode)
local configs={
 khmer={family="first",owner=6,civ="CIVILIZATION_KHMER",kind="BUILDING_BARAY",class="BUILDINGCLASS_GARDEN"},
 scotland={family="first",owner=7,civ="CIVILIZATION_SCOTLAND",kind="BUILDING_SCOTLAND_TRAIT",class="BUILDINGCLASS_SCOTLAND_UA"},
 zimbabwe={family="first",owner=4,civ="CIVILIZATION_ZIMBABWE",kind="BUILDING_ZIMBABWE_TRAIT",class="BUILDINGCLASS_ZIMBABWE_TRAIT"},
 gaul={family="capital",owner=0,foreign=1,civ="CIVILIZATION_GAUL",kind="BUILDING_MURUS_GALLICUS",trait="TRAIT_GAULS"},
 normandy={family="all",owner=3,civ="CIVILIZATION_NORMANDY",kind="BUILDING_WIRR",trait="TRAIT_WIRR"},
 carthage={family="all",owner=10,civ="CIVILIZATION_CARTHAGE",kind="BUILDING_HARBOR",trait="TRAIT_PHOENICIAN_HERITAGE",water=true},
 akkad={family="acquire",owner=0,foreign=1,civ="CIVILIZATION_AKKAD",kind="BUILDING_UA_AKKAD",trait="TRAIT_AKKAD"},
 ayyubids={family="acquire",owner=9,civ="CIVILIZATION_AYYUBIDS",kind="BUILDING_BURIAL_TOMB",trait="TRAIT_JUSTICE_OF_SALADIN"},
 oman={family="acquire",owner=6,civ="CIVILIZATION_OMAN",kind="BUILDING_SEAPORT",trait="TRAIT_MC_CHAIN_OF_THE_EARTH"}}
local cfg=assert(configs[mode]);local bid=assert(GameInfoTypes[cfg.kind])
local owner,foreign
for i=0,GameDefines.MAX_MAJOR_CIVS-1 do local p=Players[i]
 if p and p:IsAlive()then
  if p:GetCivilizationType()==GameInfoTypes[cfg.civ]then assert(not owner,"duplicate target civilization");owner=i end
  if p:GetCivilizationType()==GameInfoTypes.CIVILIZATION_ROME then foreign=i end
 end
end
assert(owner and foreign and owner~=foreign,"dedicated roster is required");cfg.owner=owner
local phase,turn,giftPlot,conquestPlot,choice="init",nil,nil,nil,nil
local expected={};local captures={};local founding={}
LuaEvents.LekmodCaptureChoiceDone.Add(function(kind,id)choice={kind=kind,id=id}end)
GameEvents.PlayerCityFounded.Add(function(owner,x,y)founding[owner..":"..x..":"..y]=true end)
GameEvents.CityCaptureComplete.Add(function(old,capital,x,y,new,pop,conquest)captures[x..":"..y]={old=old,new=new,conquest=conquest}end)
local function measure(c)
 return {owner=c:GetOwner(),city=c:GetID(),x=c:GetX(),y=c:GetY(),capital=c:IsCapital(),real=c:GetNumRealBuilding(bid),free=c:GetNumFreeBuilding(bid),total=c:GetNumBuilding(bid),palace=c:GetNumBuilding(GameInfoTypes.BUILDING_PALACE),coastal=c:IsCoastal(-1)}
end
local function expect(c,real,free,label)
 local v=measure(c);assert(v.real==real and v.free==free and v.total==real+free,label.." grant differs "..LekmodScenarioJSON(v))
 LekmodScenarioEvent("native-free-building-count",{mode=mode,label=label,kind=cfg.kind,expected_real=real,expected_free=free,state=v});return c
end
local function remember(c,real,free,label)
 expect(c,real,free,label);expected[#expected+1]={plot=c:Plot():GetPlotIndex(),owner=c:GetOwner(),real=real,free=free};return c
end
local function found(p,coast,label)
 for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
  if q:GetOwner()==-1 and q:GetNumUnits()==0 and not q:IsWater()and not q:IsMountain()and(coast==nil or q:IsCoastalLand(-1)==coast)and p:CanFound(q:GetX(),q:GetY())then
   LekmodScenarioEvent("fixture-setup",{operation="provided-legal-founding-site",mode=mode,label=label,owner=p:GetID(),x=q:GetX(),y=q:GetY()})
   p:Found(q:GetX(),q:GetY());local c=assert(q:GetPlotCity());assert(c:GetOwner()==p:GetID()and founding[p:GetID()..":"..q:GetX()..":"..q:GetY()]);return c
  end
 end
 error("no legal founding site for "..label)
end
local function transfer(c,recipient,conquest,label)
 local x,y=c:GetX(),c:GetY();local old=c:GetOwner();assert(old~=recipient)
 LekmodScenarioEvent("fixture-setup",{operation="provided-native-acquisition-reason",mode=mode,label=label,old=old,new=recipient,conquest=conquest,trade=not conquest,x=x,y=y})
 if conquest and Players[recipient]:IsHuman()then choice=nil;LuaEvents.LekmodCaptureChoice("puppet")end
 Players[recipient]:AcquireCity(c,conquest,not conquest)
 local after=assert(Map.GetPlot(x,y):GetPlotCity(),"AI removed provided target immediately")
 assert(after:GetOwner()==recipient);local event=assert(captures[x..":"..y],"native acquisition event missing");assert(event.old==old and event.new==recipient and event.conquest==conquest)
 return after
end
local function observationsDone(p)
 LekmodScenarioRecord("free-grant-positive","PASS",mode.." declared positive grants observed in real/free/total native counts")
 LekmodScenarioRecord("free-grant-controls","PASS",mode.." foreign, location and noncapital exclusions checked where applicable")
 LekmodScenarioRecord("free-grant-transition","PASS",mode.." relevant founding/loss/refounding/research or ownership changes recompute declared grants")
 LekmodScenarioRecord("free-grant-nonstack","PASS",mode.." repeated founding/research or recipient reentry does not duplicate target count")
 turn=Game.GetGameTurn();phase="turn";p:ChangeGold(5000)
 LekmodScenarioEvent("fixture-setup",{operation="provided-upkeep-budget",owner=p:GetID(),added=5000});return "turn"
end
function LekmodScenario.snapshot(player)
 local owners={}
 for _,owner in ipairs({cfg.owner,foreign})do local p=Players[owner];local cities={};for c in p:Cities()do cities[c:GetID()]=measure(c)end
  owners[owner]={civilization=p:GetCivilizationType(),alive=p:IsAlive(),cities=cities,building_free=p:IsBuildingFree(bid),mining=Teams[p:GetTeam()]:IsHasTech(GameInfoTypes.TECH_MINING)}
 end
 return {mode=mode,turn=Game.GetGameTurn(),owners=owners}
end
function LekmodScenario.step(player)
 assert(not Game.IsGameMultiPlayer()and Game.IsOption(GameOptionTypes.GAMEOPTION_COMPLETE_KILLS));local p=Players[cfg.owner];local other=Players[foreign]
 assert(p:GetCivilizationType()==GameInfoTypes[cfg.civ]and other:GetCivilizationType()~=p:GetCivilizationType())
 if phase=="init"then
  assert(p:GetNumCities()==1 and other:GetCapitalCity());local cap=assert(p:GetCapitalCity())
  if cfg.family=="first"then
   local matched=false;for r in GameInfo.Civilization_FreeBuildingClasses{CivilizationType=cfg.civ}do if r.BuildingClassType==cfg.class then matched=true end end;assert(matched)
   expect(cap,1,0,"normal-first-capital");expect(other:GetCapitalCity(),0,0,"foreign-first-capital")
  else
   local trait=assert(GameInfo.Traits[cfg.trait]);assert(trait[cfg.family=="all"and"FreeBuilding"or cfg.family=="capital"and"FreeCapitalBuilding"or"FreeBuildingOnConquest"]==cfg.kind)
   if cfg.family=="all"then assert(p:IsBuildingFree(bid));expect(cap,0,(not cfg.water or cap:IsCoastal(-1))and 1 or 0,"normal-capital")
   elseif cfg.family=="capital"then assert(trait.CapitalFreeBuildingPrereqTech=="TECH_MINING"and not Teams[p:GetTeam()]:IsHasTech(GameInfoTypes.TECH_MINING));expect(cap,0,0,"before-mining")
   else expect(cap,0,0,"own-founded-capital-excluded")end
   expect(other:GetCapitalCity(),0,0,"foreign-capital-excluded")
  end
  LekmodScenarioRecord("free-grant-data","PASS","exact shipped owner/trait/class/building and initial fixture checked for "..mode)
  LekmodScenarioRecord("free-grant-initial","PASS","unmutated normal-start real/free counts match the initial grant rule")
  if cfg.family=="first"then
   local secondary=found(p,nil,"second-city");expect(secondary,0,0,"second-city-excluded")
   local guard=assert(p:InitUnit(GameInfoTypes.UNIT_SCOUT,cap:GetX(),cap:GetY()))
   LekmodScenarioEvent("fixture-setup",{operation="provided-survival-unit-and-city-loss",unit=guard:GetID(),owner=cfg.owner,cities={cap:GetID(),secondary:GetID()}})
   cap:Kill();assert(p:GetNumCities()==1);expect(p:GetCapitalCity(),0,0,"capital-relocation-does-not-regrant")
   p:GetCapitalCity():Kill();assert(p:IsAlive()and p:GetNumCities()==0)
   local replacement=found(p,nil,"first-city-after-loss");remember(replacement,1,0,"refounded-first-city")
   remember(found(p,nil,"second-city-after-loss"),0,0,"refounded-secondary-excluded")
   return observationsDone(p)
  elseif cfg.family=="capital"then
   local second=found(p,nil,"before-mining-secondary");expect(second,0,0,"before-mining-secondary")
   cap:SetNumRealBuilding(bid,1);LekmodScenarioEvent("fixture-setup",{operation="provided-existing-real-building",owner=cfg.owner,city=cap:GetID(),kind=cfg.kind,count=1});expect(cap,1,0,"real-building-before-tech")
   LekmodScenarioGrantTech(p,"TECH_MINING");expect(cap,0,1,"mining-converts-real-to-free");expect(second,0,0,"mining-noncapital-excluded");expect(other:GetCapitalCity(),0,0,"mining-foreign-excluded")
   Teams[p:GetTeam()]:SetHasTech(GameInfoTypes.TECH_MINING,true,cfg.owner,false,false);expect(cap,0,1,"repeat-mining-no-duplicate")
   remember(found(p,nil,"post-mining-secondary"),0,0,"post-mining-secondary-excluded")
   LekmodScenarioEvent("fixture-setup",{operation="provided-capital-loss",owner=cfg.owner,city=cap:GetID()});cap:Kill()
   for c in p:Cities()do remember(c,0,0,"no-research-reward-migration")end
   return observationsDone(p)
  elseif cfg.family=="all"then
   local positive=found(p,cfg.water and true or nil,"positive-new-city");expect(positive,0,1,"new-city-free")
   if cfg.water then remember(found(p,false,"inland-control"),0,0,"inland-excluded")end
   positive=transfer(positive,foreign,false,"foreign-transfer");expect(positive,0,0,"foreign-loses-free-only-grant")
   positive=transfer(positive,cfg.owner,false,"return-transfer");remember(positive,0,1,"return-restores-single-free-grant")
   remember(found(p,cfg.water and true or nil,"later-new-city"),0,1,"later-new-city-free")
   return observationsDone(p)
  else
   local gift=found(other,false,"gift-input");gift:SetPopulation(10,true);giftPlot=gift:Plot():GetPlotIndex();expect(gift,0,0,"foreign-target-before-gift")
   gift=transfer(gift,cfg.owner,false,"peaceful-acquisition");expect(gift,0,1,"gift-uses-same-native-grant")
   local conquest=found(other,false,"conquest-input");conquest:SetPopulation(10,true);conquestPlot=conquest:Plot():GetPlotIndex();expect(conquest,0,0,"foreign-target-before-conquest")
   transfer(conquest,cfg.owner,true,"conquest-acquisition");phase="acquired";return false
  end
 elseif phase=="acquired"then
  if p:IsHuman()and not choice then return false end
  local conquest=assert(Map.GetPlotByIndex(conquestPlot):GetPlotCity());remember(conquest,0,1,"conquest-grant")
  local gift=assert(Map.GetPlotByIndex(giftPlot):GetPlotCity());gift=transfer(gift,foreign,false,"gift-out");expect(gift,0,0,"foreign-free-grant-removed")
  gift=transfer(gift,cfg.owner,false,"gift-return");remember(gift,0,1,"reentry-single-free-grant")
  return observationsDone(p)
 elseif phase=="turn"then
  if Game.GetGameTurn()==turn then return "turn"end;assert(Game.GetGameTurn()==turn+1)
  for _,r in ipairs(expected)do local c=assert(Map.GetPlotByIndex(r.plot):GetPlotCity());assert(c:GetOwner()==r.owner);expect(c,r.real,r.free,"next-owner-round")end
  LekmodScenarioRecord("free-grant-next-turn","PASS","all final grant/control counts survive one ordinary owner round; exact snapshot follows")
  return true
 end
 return false
end
