-- Contact, one staged military unit, its uranium and an upkeep budget are
-- labeled inputs. Influence must accrue through a normal turn without tribute.
LekmodScenario={name="mexico-influence",items={"mexico-afraid-rate","mexico-afraid-accrual","mexico-tribute-boundary"}}
local phase,target,before,turn,loot,gold="init"
local function minorState(minor,major)
    return {met=Teams[major:GetTeam()]:IsHasMet(minor:GetTeam()),influence=minor:GetMinorCivFriendshipWithMajor(major:GetID()),base=minor:GetMinorCivBaseFriendshipWithMajor(major:GetID()),rate100=minor:GetFriendshipChangePerTurnTimes100(major:GetID()),can_tribute=minor:CanMajorBullyGold(major:GetID()),personality=minor:GetMinorCivPersonalityType()}
end
function LekmodScenario.snapshot(player)
    local minors,units={},{}
    for id,p in pairs(Players) do if p:IsAlive() and p:IsMinorCiv() then minors[id]=minorState(p,player) end end
    for u in player:Units() do if not u:IsDelayedDeath() then units[u:GetID()]={type=u:GetUnitType(),x=u:GetX(),y=u:GetY(),moves=u:GetMoves()} end end
    return {turn=Game.GetGameTurn(),gold=player:GetGold(),minors=minors,units=units}
end
function LekmodScenario.step(player)
    assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_MEXICO,"requires Mexico")
    if phase=="init" then
        local plot
        for id=GameDefines.MAX_MAJOR_CIVS,GameDefines.MAX_CIV_PLAYERS-2 do
            local minor=Players[id];local city=minor and minor:GetCapitalCity()
            if city and minor:IsAlive() and minor:IsMinorCiv() and not Teams[player:GetTeam()]:IsAtWar(minor:GetTeam())
                and minor:GetMinorCivBaseFriendshipWithMajor(player:GetID())==0 and not minor:CanMajorBullyGold(player:GetID()) then
                for i=0,Map.GetNumPlots()-1 do local candidate=Map.GetPlotByIndex(i)
                    local distance=Map.PlotDistance(city:GetX(),city:GetY(),candidate:GetX(),candidate:GetY())
                    if distance>=2 and distance<=4 and candidate:GetOwner()==-1 and not candidate:IsWater() and not candidate:IsMountain()
                        and candidate:GetFeatureType()==-1 and candidate:GetNumUnits()==0 then target=id;plot=candidate;break end
                end
                if target then break end
            end
        end
        assert(target and plot,"no neutral military staging tile and eligible minor control")
        local minor=Players[target]
        Teams[player:GetTeam()]:Meet(minor:GetTeam(),true)
        local baseline=minorState(minor,player)
        assert(not baseline.can_tribute and baseline.base==0 and baseline.rate100==0,"contact control is not zero influence/rate without tribute eligibility")
        player:ChangeGold(1000)
        player:ChangeNumResourceTotal(GameInfoTypes.RESOURCE_URANIUM,1)
        local unit=assert(player:InitUnit(GameInfoTypes.UNIT_MECH,plot:GetX(),plot:GetY()))
        LekmodScenarioEvent("fixture-setup",{operation="provided-contact-military-and-upkeep-budget",minor=target,unit=unit:GetID(),x=plot:GetX(),y=plot:GetY(),uranium=1,gold_added=1000})
        before=minorState(minor,player)
        LekmodScenarioEvent("mexico-afraid-rate",{minor=target,before=baseline,after=before,details=minor:GetMajorBullyGoldDetails(player:GetID())})
        assert(before.can_tribute,"provided military did not qualify for normal tribute")
        local expected=math.floor(GameInfo.Traits.TRAIT_MEXICO.AfraidMinorPerTurnInfluence*GameInfo.GameSpeeds[Game.GetGameSpeedType()].GoldGiftMod/100)
        assert(before.rate100-baseline.rate100==expected and expected>0,"Mexico did not add its speed-scaled afraid influence")
        assert(before.base==0,"military input itself changed friendship")
        LekmodScenarioRecord("mexico-afraid-rate","PASS","native-eligibility=true added-rate100="..expected)
        turn=Game.GetGameTurn();phase="accrued";return "turn"
    elseif phase=="accrued" then
        if Game.GetGameTurn()==turn then return "turn" end
        assert(Game.GetGameTurn()==turn+1,"influence observation exceeded one ordinary turn")
        local minor=Players[target];local after=minorState(minor,player)
        LekmodScenarioEvent("mexico-afraid-after-turn",{minor=target,state=after})
        assert(after.base==math.floor(before.rate100/100),"ordinary influence differs from the integer view of the quoted accrual")
        LekmodScenarioRecord("mexico-afraid-accrual","PASS","path=ordinary-turn no-tribute-taken=true whole-influence="..after.base)
        assert(after.can_tribute,"tribute eligibility disappeared before its boundary test")
        loot=minor:GetMinorCivBullyGoldAmount(player:GetID());gold=player:GetGold()
        assert(loot>0,"tribute gold quote is nonpositive")
        Game.DoMinorBullyGold(player:GetID(),target)
        phase="tribute"
    elseif phase=="tribute" then
        local minor=Players[target];local after=minorState(minor,player)
        LekmodScenarioEvent("mexico-after-tribute",{minor=target,state=after,gold_before=gold,gold=player:GetGold(),quoted_gold=loot})
        assert(player:GetGold()==gold+loot,"normal tribute did not deliver its quoted gold")
        assert(not after.can_tribute,"recent tribute did not remove current eligibility")
        assert(after.rate100<before.rate100,"afraid bonus did not stop after tribute")
        LekmodScenarioRecord("mexico-tribute-boundary","PASS","path=normal-tribute-command quoted-gold-paid=true eligibility-removed=true")
        return true
    end
    return false
end
