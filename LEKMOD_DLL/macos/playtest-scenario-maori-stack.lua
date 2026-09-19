-- Supplied legal civilian/combat stacks. Only an ordinary owner turn may
-- expire the bonus and refresh/clamp movement; the scenario never sets moves.
LekmodScenario={name="maori-stack",items={"maori-worker-stack-preserved","maori-general-stack-preserved"}}
local phase,turn="init",nil
local pairsToCheck={}
local function state(u)
 return {type=u:GetUnitType(),created=u:GetGameTurnCreated(),x=u:GetX(),y=u:GetY(),moves=u:GetMoves(),maximum=u:MaxMoves(),stack_maximum=u:MaxMovesWithStack(),maori=u:IsHasPromotion(GameInfoTypes.PROMOTION_MAORI),civilian=u:IsHasPromotion(GameInfoTypes.PROMOTION_MAORI_CIVILIAN)}
end
function LekmodScenario.snapshot(player)
 local units={};for u in player:Units()do if not u:IsDelayedDeath()then units[u:GetID()]=state(u)end end
 return {turn=Game.GetGameTurn(),units=units}
end
local function supply(player,receiverType,donorType,item)
 local plot;local capital=assert(player:GetCapitalCity())
 for i=0,Map.GetNumPlots()-1 do local p=Map.GetPlotByIndex(i)
  if (p:GetOwner()==player:GetID() or p:GetOwner()==-1) and p:GetNumUnits()==0 and not p:IsCity() and not p:IsWater() and not p:IsMountain() and p:GetArea()==capital:Plot():GetArea() and Map.PlotDistance(capital:GetX(),capital:GetY(),p:GetX(),p:GetY())<=3 then plot=p;break end
 end
 assert(plot,"no empty nearby owned or neutral land for legal stack")
 -- Create the receiver first so the donor follows it in the unit iterator.
 local receiver=assert(player:InitUnit(GameInfoTypes[receiverType],plot:GetX(),plot:GetY()))
 local donor=assert(player:InitUnit(GameInfoTypes[donorType],plot:GetX(),plot:GetY()))
 assert(receiver:GetX()==donor:GetX() and receiver:GetY()==donor:GetY() and receiver:IsHasPromotion(GameInfoTypes.PROMOTION_MAORI_CIVILIAN) and donor:IsHasPromotion(GameInfoTypes.PROMOTION_MAORI))
 local own=GameInfo.Units[receiverType].Moves*GameDefines.MOVE_DENOMINATOR
 local escort=GameInfo.Units[donorType].Moves*GameDefines.MOVE_DENOMINATOR
 assert(escort>own)
 pairsToCheck[#pairsToCheck+1]={receiver=receiver:GetID(),donor=donor:GetID(),own=own,reported_maximum=(receiverType=="UNIT_GREAT_GENERAL" and escort or own),escort=escort,item=item}
 LekmodScenarioEvent("fixture-setup",{operation="provided-native-movement-stack",territory=plot:GetOwner(),receiver=state(receiver),receiver_id=receiver:GetID(),donor=state(donor),donor_id=donor:GetID()})
end
function LekmodScenario.step(player)
 assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_MAORI and Game.GetGameTurn()>=6)
 if phase=="init" then
  turn=Game.GetGameTurn()
  supply(player,"UNIT_WORKER","UNIT_AKKAD_SPEARMAN","maori-worker-stack-preserved")
  supply(player,"UNIT_GREAT_GENERAL","UNIT_SWEDISH_HAKKAPELIITTA","maori-general-stack-preserved")
  phase="expired";return "turn"
 end
 if Game.GetGameTurn()==turn then return "turn" end
 assert(Game.GetGameTurn()==turn+1)
 for _,pair in ipairs(pairsToCheck)do
  local receiver=assert(player:GetUnitByID(pair.receiver));local donor=assert(player:GetUnitByID(pair.donor));local r,d=state(receiver),state(donor)
  LekmodScenarioEvent("maori-native-expired-stack",{receiver=r,donor=d,item=pair.item})
  assert(r.x==d.x and r.y==d.y,"test stack moved apart")
  assert(not r.maori and not r.civilian and not d.maori and not d.civilian,"stack retained an expired Maori promotion")
  assert(r.maximum==pair.reported_maximum and d.maximum==pair.escort and r.stack_maximum==pair.escort and r.moves==pair.escort,"expiry lost legitimate escort movement or retained expired bonus")
  LekmodScenarioRecord(pair.item,"PASS","normal-next-turn reported-maximum="..r.maximum.." escort-allowance="..r.stack_maximum.." remaining="..r.moves)
 end
 return true
end
