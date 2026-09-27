-- Native method surface: GameCore
-- Unit/plot ownership, war and (for the cap case) a supplied capital location are
-- inputs. Only ordinary Sell Exotic Goods missions may grant gold/XP or use stock.
local kind=assert(LekmodScenarioParameters.unit)
LekmodScenario={name="exotic-goods",items={"exotic-one-use-input","exotic-no-neighbor-war-controls","exotic-near-reward","exotic-repeat-rejection","exotic-capped-reward","exotic-edge-tutorial"}}
local phase,index,unitID,plot,neighbors,before,expected,waits="setup",1,nil,nil,nil,nil,nil,0
local edgeVerified=false
LuaEvents.LekmodTutorialEdgeResult.Add(function(city,missing,status)assert(Players[0]:GetCapitalCity():GetID()==city and missing>0);edgeVerified=true;LekmodScenarioRecord("exotic-edge-tutorial","PASS","actual registered siege-check/plot callbacks handle missing edge neighbors; status="..status)end)
local minGold,maxGold=GameDefines.EXOTIC_GOODS_GOLD_MIN,GameDefines.EXOTIC_GOODS_GOLD_MAX
local minXP,maxXP=GameDefines.EXOTIC_GOODS_XP_MIN,GameDefines.EXOTIC_GOODS_XP_MAX
local width,height=Map.GetGridSize();local threshold=math.floor((width+height)/2)
local function canSell(u)return u:CanStartMission(MissionTypes.MISSION_SELL_EXOTIC_GOODS,-1,-1,u:GetPlot(),0)end
local function send(u)
 UI.SelectUnit(u);assert(UI.GetHeadSelectedUnit():GetID()==u:GetID())
 Game.SelectionListGameNetMessage(GameMessageTypes.GAMEMESSAGE_PUSH_MISSION,MissionTypes.MISSION_SELL_EXOTIC_GOODS,-1,-1,0,false,false)
end
local function layout(q,sea)
 if q:IsCity()or q:IsWater()~=sea or q:IsMountain()or q:IsImpassable()or q:GetNumUnits()>0 or q:GetOwner()~=-1 then return nil end
 if q:GetFeatureType()==GameInfoTypes.FEATURE_ICE then return nil end
 local around={}
 for d=0,5 do local n=Map.PlotDirection(q:GetX(),q:GetY(),d)
  if not n or n:IsCity()or n:GetNumUnits()>0 or n:GetOwner()~=-1 then return nil end
  around[#around+1]=n
 end
 return around
end
local function unambiguous(distance)
 for _,delta in ipairs({maxGold-minGold,maxXP-minXP})do local n=delta*distance/threshold;local f=n-math.floor(n);if f<0.05 or f>0.95 then return false end end
 return true
end
function LekmodScenario.snapshot(p)
 local units={};for u in p:Units()do if not u:IsDead()and not u:IsDelayedDeath()then units[u:GetID()]={kind=u:GetUnitType(),x=u:GetX(),y=u:GetY(),xp=u:GetExperience(),moves=u:GetMoves(),gold_quote=u:GetExoticGoodsGoldAmount(),xp_quote=u:GetExoticGoodsXPAmount()}end end
 local c=p:GetCapitalCity()
 return {turn=Game.GetGameTurn(),gold=p:GetGold(),capital={id=c:GetID(),x=c:GetX(),y=c:GetY()},units=units,war=Teams[p:GetTeam()]:IsAtWar(Players[1]:GetTeam())}
end
function LekmodScenario.step(p)
 if phase=="setup"then
  local info=assert(GameInfo.Units[kind]);assert(info.NumExoticGoods==1)
  assert(Players[1]:IsAlive()and Players[2]:IsAlive()and Players[1]:GetTeam()~=Players[2]:GetTeam())
  local sea=info.Domain=="DOMAIN_SEA";local capital=assert(p:GetCapitalCity())
  if index==1 then
   local best=9999
   for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i);local d=Map.PlotDistance(capital:GetX(),capital:GetY(),q:GetX(),q:GetY())
    if d>=2 and d<best and unambiguous(d)then local around=layout(q,sea);if around then plot,neighbors,best=q,around,d end end
   end
  else
   plot,neighbors=nil,nil
   local candidates={}
   for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
    if not q:IsWater()and not q:IsMountain()and not q:IsImpassable()and not q:IsCity()and q:GetOwner()==-1 and q:GetNumUnits()==0 and p:CanFound(q:GetX(),q:GetY())then
     candidates[#candidates+1]=q
    end
   end
   table.sort(candidates,function(a,b)return math.min(a:GetY(),height-1-a:GetY())<math.min(b:GetY(),height-1-b:GetY())end)
   local newCapital
   for n=1,math.min(32,#candidates)do local c=candidates[n]
    for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
     if Map.PlotDistance(c:GetX(),c:GetY(),q:GetX(),q:GetY())>threshold then local around=layout(q,sea);if around then newCapital,plot,neighbors=c,q,around;break end end
    end
    if plot then break end
   end
   assert(newCapital and plot,"fixture has no legal strict-cap capital/sale pair")
   p:Found(newCapital:GetX(),newCapital:GetY());local city=assert(newCapital:GetPlotCity())
   capital:SetNumRealBuilding(GameInfoTypes.BUILDING_PALACE,0);city:SetNumRealBuilding(GameInfoTypes.BUILDING_PALACE,1)
   assert(p:GetCapitalCity():GetID()==city:GetID());capital=city
   LekmodScenarioEvent("fixture-setup",{operation="provided-capital-location-for-distance-cap",city=city:GetID(),x=city:GetX(),y=city:GetY(),not_a_capital_transfer_gameplay_claim=true})
  end
  assert(plot and neighbors,"no legal exotic-goods layout")
  plot:SetOwner(0,-1,true,true);for _,q in ipairs(neighbors)do q:SetOwner(0,-1,true,true)end
  local u=assert(p:InitUnit(info.ID,plot:GetX(),plot:GetY()));unitID=u:GetID();assert(u:GetX()==plot:GetX()and u:GetY()==plot:GetY())
  before={gold=p:GetGold(),xp=u:GetExperience()}
  local d=Map.PlotDistance(capital:GetX(),capital:GetY(),plot:GetX(),plot:GetY());local f=d/threshold
  expected={distance=d,threshold=threshold,gold=math.min(minGold+math.floor((maxGold-minGold)*f),maxGold),xp=math.min(minXP+math.floor((maxXP-minXP)*f),maxXP)}
  assert(not canSell(u)and u:GetExoticGoodsGoldAmount()==0 and u:GetExoticGoodsXPAmount()==0)
  if index==1 then LekmodScenarioRecord("exotic-one-use-input","PASS",kind.." configured stock1; no foreign neighbor rejects with zero quotes")end
  LekmodScenarioEvent("fixture-setup",{operation="provided-sale-unit-and-border-ownership",kind=kind,unit=unitID,index=index,position=plot:GetPlotIndex(),expected=expected})
  neighbors[1]:SetOwner(1,-1,true,true)
  if index==1 then
   assert(canSell(u));Teams[p:GetTeam()]:Meet(Players[1]:GetTeam(),true);Network.SendChangeWar(Players[1]:GetTeam(),true);phase="war"
  else assert(Teams[p:GetTeam()]:IsAtWar(Players[1]:GetTeam()));LuaEvents.LekmodTutorialEdgeProbe(capital:GetID());phase="war"end
  return false
 elseif phase=="war"then
  if not LekmodScenarioAwait("exotic-war",Teams[p:GetTeam()]:IsAtWar(Players[1]:GetTeam()))then return false end
  local u=assert(p:GetUnitByID(unitID));assert(not canSell(u)and u:GetExoticGoodsGoldAmount()==0)
  neighbors[2]:SetOwner(2,-1,true,true);assert(not Teams[p:GetTeam()]:IsAtWar(Players[2]:GetTeam())and canSell(u))
  assert(u:GetExoticGoodsGoldAmount()==expected.gold and u:GetExoticGoodsXPAmount()==expected.xp,"native quote differs from independent distance formula")
  if index==1 then LekmodScenarioRecord("exotic-no-neighbor-war-controls","PASS","war-only border rejects; adding a separate peaceful foreign neighbor permits")end
  before={gold=p:GetGold(),xp=u:GetExperience()};send(u);phase="sold";return false
 elseif phase=="sold"then
  local u=assert(p:GetUnitByID(unitID))
  if not LekmodScenarioAwait("exotic-sale",p:GetGold()==before.gold+expected.gold)then return false end
  assert(u:GetExperience()==before.xp+expected.xp and not canSell(u)and u:GetExoticGoodsGoldAmount()==0 and u:GetExoticGoodsXPAmount()==0)
  if index==1 then
   LekmodScenarioRecord("exotic-near-reward","PASS","normal sale credits exactly"..expected.gold.." gold/"..expected.xp.." XP and exhausts stock")
  else
   assert(edgeVerified and expected.distance>threshold and expected.gold==maxGold and expected.xp==maxXP)
   LekmodScenarioRecord("exotic-capped-reward","PASS","normal sale beyond distance threshold credits capped"..maxGold.." gold/"..maxXP.." XP exactly")
  end
  before={gold=p:GetGold(),xp=u:GetExperience()};waits=0;send(u);phase="repeat";return false
 elseif phase=="repeat"then
  waits=waits+1;if waits<3 then return false end
  local u=assert(p:GetUnitByID(unitID));assert(p:GetGold()==before.gold and u:GetExperience()==before.xp and not canSell(u))
  if index==1 then LekmodScenarioRecord("exotic-repeat-rejection","PASS","normal same-position repeat has no stock and grants no further gold/XP");index=2;phase="setup";return false end
  return true
 end
 return false
end
