-- City/ship inputs are explicit. Native start-of-turn promotion state is checked
-- against the shipped two-tile rule, not the wider workable-city radius cache.
LekmodScenario={name="newzealand-defender",items={"Defender-own-two","Defender-own-three-rejected","Defender-friend-two","Defender-friend-three-rejected","Defender-far-and-normal-controls"}}
local phase="init"
local ids,turn,observed={},nil,nil
local default=GameInfoTypes.PROMOTION_JFD_DEFENDER
local active=GameInfoTypes.PROMOTION_JFD_DEFENDER_ACTIVE
local function distanceToCities(owner,plot)
 local best=999;for city in Players[owner]:Cities()do best=math.min(best,Map.PlotDistance(city:GetX(),city:GetY(),plot:GetX(),plot:GetY()))end;return best
end
local function shipState(u)
 local p=u:GetPlot()
 return {id=u:GetID(),type=u:GetUnitType(),x=u:GetX(),y=u:GetY(),moves=u:GetMoves(),default=u:IsHasPromotion(default),active=u:IsHasPromotion(active),own_distance=distanceToCities(0,p),friend_distance=distanceToCities(1,p),own_work_radius=p:IsPlayerCityRadius(0),friend_work_radius=p:IsPlayerCityRadius(1)}
end
local function coastalInput(owner)
 for city in Players[owner]:Cities()do if city:IsCoastal(10)then return end end
 for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i)
  if p:GetOwner()==-1 and p:GetNumUnits()==0 and Players[owner]:CanFound(p:GetX(),p:GetY())then
   local coast=false
   for d=0,5 do local q=Map.PlotDirection(p:GetX(),p:GetY(),d);if q and q:IsWater()and not q:IsLake()and q:GetFeatureType()~=GameInfoTypes.FEATURE_ICE then coast=true end end
   if coast then
    Players[owner]:Found(p:GetX(),p:GetY());local c=assert(p:GetPlotCity())
    if c:IsCoastal(10)then LekmodScenarioEvent("fixture-setup",{operation="provided-coastal-city",owner=owner,id=c:GetID(),x=c:GetX(),y=c:GetY()});return end
    error("supplied coast failed engine water-area requirement")
   end
  end
 end
 error("no legal coastal city input")
end
local function supply(player,label,ownDistance,friendDistance,typeID)
 for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i)
  if p:IsWater()and not p:IsLake()and p:GetNumUnits()==0 and p:GetFeatureType()~=GameInfoTypes.FEATURE_ICE then
   local own=distanceToCities(0,p);local other=distanceToCities(1,p)
   local ownOK=ownDistance and own==ownDistance or(not ownDistance and own>=4)
   local otherOK=friendDistance and other==friendDistance or(not friendDistance and other>=4)
   if ownOK and otherOK then
    local u=assert(player:InitUnit(typeID,p:GetX(),p:GetY()));ids[label]=u:GetID()
    assert(u:GetX()==p:GetX()and u:GetY()==p:GetY(),"ship input was relocated")
    assert(not u:IsHasPromotion(active),"new ship already has active Defender marker")
    assert(u:IsHasPromotion(default)==(typeID==GameInfoTypes.UNIT_JFD_DEFENDER),"native Defender marker differs")
    LekmodScenarioEvent("fixture-setup",{operation="provided-Defender-boundary-ship",label=label,state=shipState(u)})
    return
   end
  end
 end
 error("no isolated water plot for "..label)
end
LuaEvents.LekmodNZAfterOwnerTurn.Add(function(owner)
 if owner~=0 or phase~="turn"then return end
 observed={};for label,id in pairs(ids)do observed[label]=shipState(assert(Players[0]:GetUnitByID(id)))end
 LekmodScenarioEvent("Defender-after-native-owner-handler",observed)
end)
function LekmodScenario.snapshot(player)
 local units,cities={},{}
 for u in player:Units()do if u:GetUnitType()==GameInfoTypes.UNIT_JFD_DEFENDER or u:GetUnitType()==GameInfoTypes.UNIT_IRONCLAD then units[u:GetID()]=shipState(u)end end
 for owner=0,1 do cities[owner]={};for city in Players[owner]:Cities()do cities[owner][city:GetID()]={x=city:GetX(),y=city:GetY()}end end
 return {turn=Game.GetGameTurn(),DoF01=player:IsDoF(1),DoF10=Players[1]:IsDoF(0),cities=cities,units=units}
end
function LekmodScenario.step(player)
 assert(player:IsDoF(1)and Players[1]:IsDoF(0),"requires retained real Rome/Argentina friendship")
 if phase=="init"then
  coastalInput(0);coastalInput(1)
  player:SetGold(1000);LekmodScenarioEvent("fixture-setup",{operation="provided-ship-upkeep",gold=1000})
  for u in player:Units()do assert(u:GetUnitType()~=GameInfoTypes.UNIT_JFD_DEFENDER and u:GetUnitType()~=GameInfoTypes.UNIT_IRONCLAD,"fixture already contains probe ship types")end
  supply(player,"own2",2,nil,GameInfoTypes.UNIT_JFD_DEFENDER)
  supply(player,"own3",3,nil,GameInfoTypes.UNIT_JFD_DEFENDER)
  supply(player,"friend2",nil,2,GameInfoTypes.UNIT_JFD_DEFENDER)
  supply(player,"friend3",nil,3,GameInfoTypes.UNIT_JFD_DEFENDER)
  supply(player,"far",nil,nil,GameInfoTypes.UNIT_JFD_DEFENDER)
  supply(player,"normal",2,nil,GameInfoTypes.UNIT_IRONCLAD)
  assert(GameInfo.UnitPromotions[active].IgnoreZOC==true or GameInfo.UnitPromotions[active].IgnoreZOC==1,"active promotion does not enable ignore-ZOC")
  turn=Game.GetGameTurn();phase="turn";return "turn"
 elseif phase=="turn"then
  if not observed then return "turn"end
  assert(Game.GetGameTurn()==turn+1,"Defender observation must follow one ordinary turn")
  local expected={own2=true,own3=false,friend2=true,friend3=false,far=false,normal=false}
  local labels={own2="Defender-own-two",own3="Defender-own-three-rejected",friend2="Defender-friend-two",friend3="Defender-friend-three-rejected"}
  for label,item in pairs(labels)do local row=observed[label]
   assert((label=="own2"and row.own_distance==2)or(label=="own3"and row.own_distance==3)or(label=="friend2"and row.friend_distance==2)or(label=="friend3"and row.friend_distance==3),"ship moved before the owner-turn observation")
   LekmodScenarioRecord(item,row.active==expected[label]and row.default~=expected[label]and"PASS"or"FAIL","native beginning-of-turn state; expected active="..tostring(expected[label]).." actual="..tostring(row.active))
  end
  local controls=not observed.far.active and observed.far.default and not observed.normal.active and not observed.normal.default
  LekmodScenarioRecord("Defender-far-and-normal-controls",controls and"PASS"or"FAIL","far Defender and ordinary Ironclad have no ignore-ZOC marker")
  LekmodScenarioEvent("Defender-final",LekmodScenario.snapshot(player));return true
 end
 return false
end
