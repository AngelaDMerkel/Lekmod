-- Supplied foreign capital and unit positions; actual synchronized moves must
-- distinguish a normal Scout, Zabonah capital discovery and repeat discovery.
LekmodScenario={name="nabatea-discovery",items={"zabonah-scout-control","zabonah-capital-discovery","zabonah-no-repeat"}}
local phase,targetCity,zabID,scoutID,startPlot,endPlot,repeatPlot,gold,turn="init"
local function noWonderNear(plot,radius)
 for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i);local feature=p:GetFeatureType()
  if feature>=0 and Map.PlotDistance(plot:GetX(),plot:GetY(),p:GetX(),p:GetY())<=radius then
   local info=GameInfo.Features[feature];if info and(info.NaturalWonder==true or info.NaturalWonder==1)then return false end
  end
 end
 return true
end
local function clearLand(p)return p and not p:IsWater()and not p:IsMountain()and not p:IsHills()and not p:IsCity()and p:GetOwner()==-1 and p:GetNumUnits()==0 end
local function move(u,p)
 assert(u:GetMoves()>0 and u:CanMoveOrAttackInto(p),"normal exploration move is unavailable")
 UI.SelectUnit(u);Game.SelectionListGameNetMessage(GameMessageTypes.GAMEMESSAGE_PUSH_MISSION,MissionTypes.MISSION_MOVE_TO,p:GetX(),p:GetY(),0,false,false)
end
function LekmodScenario.snapshot(player)
 local cities,units={},{},{}
 for c in Players[1]:Cities()do cities[c:GetID()]={capital=c:IsCapital(),revealed=c:IsRevealed(player:GetTeam()),x=c:GetX(),y=c:GetY()}end
 for u in player:Units()do if u:GetUnitType()==GameInfoTypes.UNIT_MC_ZABONAH or u:GetUnitType()==GameInfoTypes.UNIT_SCOUT then units[u:GetID()]={type=u:GetUnitType(),x=u:GetX(),y=u:GetY(),moves=u:GetMoves(),sight=u:VisibilityRange()}end end
 return {turn=Game.GetGameTurn(),gold=player:GetGold(),foreign_cities=cities,units=units,multiplayer=Game.IsGameMultiPlayer()}
end
function LekmodScenario.step(player)
 assert(not Game.IsGameMultiPlayer()and player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_ROME and Players[1]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_ROME,"use single-player Roman owners; no Nabatea civilization active")
 local capital=player:GetCapitalCity()
 if phase=="init"and not capital then
  for u in player:Units()do if GameInfo.Units[u:GetUnitType()].Found and u:CanFound(u:GetPlot())then
   UI.SelectUnit(u);for i=0,#GameInfoActions do if GameInfoActions[i]and GameInfoActions[i].Type=="MISSION_FOUND"then assert(Game.CanHandleAction(i));Game.HandleAction(i);phase="founding";return false end end
  end end;error("normal Found action missing")
 end
 if phase=="founding"then if not LekmodScenarioAwait("discovery-capital-founded",capital~=nil)then return false end;phase="init"end
 if phase=="init"then
  assert(not Players[1]:GetCapitalCity(),"new fixture requires foreign capital not yet founded")
  local u=assert(player:InitUnit(GameInfoTypes.UNIT_MC_ZABONAH,capital:GetX(),capital:GetY()));zabID=u:GetID()
  local radius=u:VisibilityRange()+3;local width,height=Map.GetGridSize();local site
  for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i);local dist=Map.PlotDistance(capital:GetX(),capital:GetY(),p:GetX(),p:GetY())
   if dist>=12 and dist<=18 and p:GetY()>radius+1 and p:GetY()<height-radius-2 and p:GetArea()==capital:Plot():GetArea()and p:GetOwner()==-1 and p:GetNumUnits()==0 and Players[1]:CanFound(p:GetX(),p:GetY())then site=p;break end
  end
  assert(site,"no unrevealed foreign capital site for isolated discovery")
  Players[1]:Found(site:GetX(),site:GetY());targetCity=assert(site:GetPlotCity()):GetID()
  local city=Players[1]:GetCityByID(targetCity);assert(city:IsCapital()and not city:IsRevealed(player:GetTeam()),"provided capital was already revealed")
  LekmodScenarioEvent("fixture-setup",{operation="provided-foreign-capital",owner=1,id=targetCity,x=site:GetX(),y=site:GetY()})
  for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i)
   if clearLand(p)and Map.PlotDistance(p:GetX(),p:GetY(),site:GetX(),site:GetY())==radius and noWonderNear(p,u:VisibilityRange()+1)then
    for d=0,5 do local q=Map.PlotDirection(p:GetX(),p:GetY(),d)
     if clearLand(q)and Map.PlotDistance(q:GetX(),q:GetY(),site:GetX(),site:GetY())==radius+1 and noWonderNear(q,u:VisibilityRange()+1)then startPlot=q;endPlot=p;break end
    end
   end
   if startPlot then break end
  end
  assert(startPlot and endPlot,"no legal one-step capital discovery boundary")
  local scout=assert(player:InitUnit(GameInfoTypes.UNIT_SCOUT,capital:GetX(),capital:GetY()));scoutID=scout:GetID()
  scout:SetXY(startPlot:GetX(),startPlot:GetY(),false,true,false,false)
  LekmodScenarioEvent("fixture-setup",{operation="provided-Zabonah-Scout-and-control-position",zabonah=zabID,scout=scoutID,sight=u:VisibilityRange(),extended_radius=radius,start_x=startPlot:GetX(),start_y=startPlot:GetY(),end_x=endPlot:GetX(),end_y=endPlot:GetY()})
  phase="scout-ready";return false
 elseif phase=="scout-ready"then
  assert(not Players[1]:GetCityByID(targetCity):IsRevealed(player:GetTeam()),"control staging revealed capital")
  gold=player:GetGold();move(player:GetUnitByID(scoutID),endPlot);phase="scout-moved";return false
 elseif phase=="scout-moved"then
  local scout=assert(player:GetUnitByID(scoutID))
  if not LekmodScenarioAwait("Scout-control-move",scout:GetX()==endPlot:GetX()and scout:GetY()==endPlot:GetY())then return false end
  assert(player:GetGold()==gold and not Players[1]:GetCityByID(targetCity):IsRevealed(player:GetTeam()),"normal Scout received extended capital reveal/reward")
  LekmodScenarioRecord("zabonah-scout-control","PASS","normal Scout move at extended radius leaves capital unrevealed and gold unchanged")
  local spare
  for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i);if clearLand(p)and p~=startPlot and p~=endPlot and Map.PlotDistance(p:GetX(),p:GetY(),capital:GetX(),capital:GetY())<4 then spare=p;break end end
  assert(spare);scout:SetXY(spare:GetX(),spare:GetY(),false,true,false,false)
  local u=assert(player:GetUnitByID(zabID));u:SetXY(startPlot:GetX(),startPlot:GetY(),false,true,false,false)
  LekmodScenarioEvent("fixture-setup",{operation="cleared-control-and-positioned-Zabonah",scout_x=spare:GetX(),scout_y=spare:GetY(),zabonah_x=startPlot:GetX(),zabonah_y=startPlot:GetY()})
  phase="zab-ready";return false
 elseif phase=="zab-ready"then
  assert(not Players[1]:GetCityByID(targetCity):IsRevealed(player:GetTeam()),"Zabonah staging already revealed capital")
  gold=player:GetGold();move(player:GetUnitByID(zabID),endPlot);phase="discovered";return false
 elseif phase=="discovered"then
  local u=assert(player:GetUnitByID(zabID));if not LekmodScenarioAwait("Zabonah-discovery-move",u:GetX()==endPlot:GetX()and u:GetY()==endPlot:GetY())then return false end
  local c=Players[1]:GetCityByID(targetCity)
  LekmodScenarioEvent("Zabonah-native-discovery",{gold_before=gold,gold_after=player:GetGold(),capital_revealed=c:IsRevealed(player:GetTeam()),distance=Map.PlotDistance(u:GetX(),u:GetY(),c:GetX(),c:GetY()),sight=u:VisibilityRange()})
  assert(c:IsRevealed(player:GetTeam())and player:GetGold()==gold+10,"capital reveal or exact ten-gold reward missing")
  LekmodScenarioRecord("zabonah-capital-discovery","PASS","normal synchronized move discovers capital beyond ordinary sight and awards10gold; foreign unit owner works")
  phase="repeat-ready";return false
 elseif phase=="repeat-ready"then
  local u=assert(player:GetUnitByID(zabID));if u:GetMoves()==0 then return "turn"end
  local c=Players[1]:GetCityByID(targetCity)
  for d=0,5 do local p=Map.PlotDirection(u:GetX(),u:GetY(),d)
   if clearLand(p)and Map.PlotDistance(p:GetX(),p:GetY(),c:GetX(),c:GetY())<=u:VisibilityRange()+3 and noWonderNear(p,u:VisibilityRange()+1)and u:CanMoveOrAttackInto(p)then repeatPlot=p;break end
  end
  assert(repeatPlot,"no legal repeat-discovery move");gold=player:GetGold();move(u,repeatPlot);phase="repeated";return false
 elseif phase=="repeated"then
  local u=assert(player:GetUnitByID(zabID));if not LekmodScenarioAwait("repeat-move",u:GetX()==repeatPlot:GetX()and u:GetY()==repeatPlot:GetY())then return false end
  assert(player:GetGold()==gold and Players[1]:GetCityByID(targetCity):IsRevealed(player:GetTeam()),"already known capital awarded another discovery reward")
  LekmodScenarioRecord("zabonah-no-repeat","PASS","second normal movement within discovery radius gives no extra gold")
  LekmodScenarioEvent("zabonah-discovery-final",LekmodScenario.snapshot(player));return true
 end
 return false
end
