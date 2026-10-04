-- Native method surface: GameCore
-- Units, contact and staging positions are inputs. Gifts run on their owner's
-- actual turn; treasury/influence rewards and conversion/consumption are native.
LekmodScenario={name="sweden-gift-actions",items={"gift-owner-controls","gift-great-person-payment","gift-great-person-consumption","gift-military-control","gift-civilian-rejection","gift-major-rejection","gift-post-action-quotes","gift-ordinary-settlement"}}
local phase,target,turn,err,swedenDone,romeDone,beforeSettlement="init",nil,nil,nil,false,false,nil
local converted={}
GameEvents.UnitConverted.Add(function(oldOwner,newOwner,oldID,newID,upgrade)if not upgrade then converted[oldOwner..":"..oldID]={owner=newOwner,id=newID}end end)
local function emptyLand(owner)
 for i=0,Map.GetNumPlots()-1 do local q=Map.GetPlotByIndex(i)
  if q:GetOwner()==owner and not q:IsWater()and not q:IsMountain()and not q:IsCity()and q:GetNumUnits()==0 then return q end
 end
 error("no legal empty gift staging tile")
end
local function input(p,kind,owner)
 local q=emptyLand(owner);local u=assert(p:InitUnit(GameInfoTypes[kind],q:GetX(),q:GetY()))
 assert(u:GetX()==q:GetX()and u:GetY()==q:GetY())
 LekmodScenarioEvent("fixture-setup",{operation="provided-gift-probe",owner=p:GetID(),kind=kind,id=u:GetID(),tile_owner=owner,x=q:GetX(),y=q:GetY()});return u
end
local function influence(m,owner)return Game.ReadMinorInfluenceForTest(m:GetID(),owner)end
local function alive(p,id)local u=p:GetUnitByID(id);return u and not u:IsDead()and not u:IsDelayedDeath()end
local function reject(p,kind,recipient)
 local u=input(p,kind,recipient);local id=u:GetID();local gold=p:GetGold();local inf=influence(Players[target],p:GetID())
 assert(not u:CanGift(),"invalid gift is reported legal: "..kind);u:DoCommand(CommandTypes.COMMAND_GIFT,-1,-1)
 assert(alive(p,id)and not converted[p:GetID()..":"..id]and p:GetGold()==gold and influence(Players[target],p:GetID())==inf)
 u:Kill(false,-1);LekmodScenarioEvent("native-gift-rejected",{owner=p:GetID(),kind=kind,recipient=recipient,gold=gold,influence100=inf,provided_probe_removed=true})
end
local function give(p,kind,isGreat)
 local m=Players[target];local u=input(p,kind,target);local id=u:GetID();local gold=p:GetGold();local inf=influence(m,p:GetID());local count=m:GetNumUnits()
 assert(u:CanGift());u:DoCommand(CommandTypes.COMMAND_GIFT,-1,-1)
 local event=assert(converted[p:GetID()..":"..id],"native gift conversion not observed");assert(event.owner==target and not alive(p,id))
 local gifted=m:GetUnitByID(event.id);local expected=isGreat and 10000 or 500
 assert(influence(m,p:GetID())==inf+expected and p:GetGold()==gold+(isGreat and 200 or 0))
 if isGreat then assert(not gifted or gifted:IsDead()or gifted:IsDelayedDeath());assert(m:GetNumUnits()==count)
 else assert(gifted and gifted:GetOwner()==target and gifted:GetUnitType()==GameInfoTypes[kind]and m:GetNumUnits()==count+1)end
 LekmodScenarioEvent("native-sweden-gift",{kind=kind,great_person=isGreat,owner=p:GetID(),recipient=target,gold_before=gold,gold_after=p:GetGold(),influence_before=inf,influence_after=influence(m,p:GetID()),old_unit=id,new_unit=event.id,minor_units_before=count,minor_units_after=m:GetNumUnits()})
 return event
end
GameEvents.PlayerDoTurn.Add(function(owner)
 if phase~="actors"or(owner~=1 and owner~=2)then return end
 local ok,e=pcall(function()
  local p=Players[owner];assert(not p:IsHuman()and p:IsTurnActive())
  if owner==1 and not swedenDone then
   give(p,"UNIT_SCIENTIST",true)
   LekmodScenarioRecord("gift-great-person-payment","PASS","real Swedish Scientist gift grants100 influence and200 gold exactly once")
   LekmodScenarioRecord("gift-great-person-consumption","PASS","native conversion consumes donor and recipient great-person units")
   local m=Players[target];local gold=p:GetGold();local inf=influence(m,1)
   for _,distance in ipairs({false,true})do assert(m:GetFriendshipFromUnitGift(1,true,distance)==100)end
   assert(p:GetGold()==gold and influence(m,1)==inf);LekmodScenarioRecord("gift-post-action-quotes","PASS","both post-gift quotes preserve the paid treasury and influence")
   give(p,"UNIT_WARRIOR",false);LekmodScenarioRecord("gift-military-control","PASS","ordinary gift transfers one unit, gives5 influence and grants no Swedish great-person gold")
   for _,kind in ipairs({"UNIT_WORKER","UNIT_SCOUT","UNIT_SETTLER","UNIT_PROPHET"})do reject(p,kind,target)end
   LekmodScenarioRecord("gift-civilian-rejection","PASS","worker/scout/settler/religious Prophet commands reject without consuming units or granting rewards")
   reject(p,"UNIT_SCIENTIST",2);LekmodScenarioRecord("gift-major-rejection","PASS","great-person gift to a major rejects without reward")
   beforeSettlement={raw100=influence(m,1),rate100=m:GetFriendshipChangePerTurnTimes100(1),anchor=m:GetMinorCivFriendshipAnchorWithMajor(1)};swedenDone=true
  elseif owner==2 and not romeDone then reject(p,"UNIT_SCIENTIST",target);romeDone=true end
 end)
 if not ok then err=tostring(e)end
end)
function LekmodScenario.snapshot(p)
 local owners,minors={},{}
 for owner=0,2 do local v=Players[owner];local units={};for u in v:Units()do if not u:IsDead()and not u:IsDelayedDeath()then units[u:GetID()]={type=u:GetUnitType(),x=u:GetX(),y=u:GetY(),moves=u:GetMoves()}end end;owners[owner]={gold=v:GetGold(),units=units}end
 for id=GameDefines.MAX_MAJOR_CIVS,GameDefines.MAX_CIV_PLAYERS-1 do local m=Players[id]
  if m and m:IsAlive()and m:IsMinorCiv()then local values={};for owner=0,2 do values[owner]={raw100=influence(m,owner),rate100=m:GetFriendshipChangePerTurnTimes100(owner)}end;minors[id]={units=m:GetNumUnits(),influence=values}end
 end
 return {turn=Game.GetGameTurn(),owners=owners,minors=minors}
end
function LekmodScenario.step(p)
 assert(not err,err);assert(p:IsHuman()and p:GetID()==0 and not Game.IsGameMultiPlayer())
 assert(p:GetCivilizationType()==GameInfoTypes.CIVILIZATION_GOLDEN_HORDE and Players[1]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_SWEDEN and Players[2]:GetCivilizationType()==GameInfoTypes.CIVILIZATION_ROME)
 if phase=="init"then
  for id=GameDefines.MAX_MAJOR_CIVS,GameDefines.MAX_CIV_PLAYERS-1 do local m=Players[id]
   if m and m:IsAlive()and m:IsMinorCiv()and not(GameInfo.Minor_Civ_Personalities[m:GetMinorCivPersonalityType()].NoGifts==true or GameInfo.Minor_Civ_Personalities[m:GetMinorCivPersonalityType()].NoGifts==1)then
    local ok=pcall(emptyLand,id);if ok then target=id;break end
   end
  end
  assert(target,"no ordinary gift-accepting minor with legal staging plots")
  for owner=0,2 do Teams[Players[owner]:GetTeam()]:Meet(Players[target]:GetTeam(),true)end
  Teams[Players[1]:GetTeam()]:Meet(Players[2]:GetTeam(),true)
  assert(not Players[target]:IsProxyWarActiveForMajor(1));reject(p,"UNIT_SCIENTIST",target)
  turn=Game.GetGameTurn();phase="actors";return "turn"
 elseif phase=="actors"then
  if Game.GetGameTurn()==turn then return "turn"end;assert(Game.GetGameTurn()==turn+1 and swedenDone and romeDone)
  LekmodScenarioRecord("gift-owner-controls","PASS","human GoldenHorde and real Roman AI-turn Scientist gifts reject; only Swedish trait enables this path")
  local after=influence(Players[target],1);local expected=beforeSettlement.raw100+beforeSettlement.rate100
  if beforeSettlement.raw100>=beforeSettlement.anchor*100 and expected<beforeSettlement.anchor*100 then expected=beforeSettlement.anchor*100 end
  assert(after==expected,"ordinary post-gift influence differs from its quote")
  LekmodScenarioEvent("native-gift-settlement",{minor=target,before=beforeSettlement,after100=after})
  LekmodScenarioRecord("gift-ordinary-settlement","PASS","native ordinary minor update settles quoted influence before exact replay")
  return true
 end
 return false
end
