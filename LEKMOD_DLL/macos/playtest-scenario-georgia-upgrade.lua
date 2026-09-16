-- Medieval Georgia with supplied prerequisites/Warrior/Artist/iron/gold.
-- The paid upgrade itself must preserve the current golden-age ability.
LekmodScenario={name="georgia-upgrade",items={"georgia-paid-upgrade","georgia-upgrade-golden-age","georgia-gift-away"}}
local phase,id,newID,artist,turn,gold,cost,recipient,gifted,converted,giftID="init"
local promotion=GameInfoTypes.PROMOTION_GEORGIA_KHEVSUR_GA
GameEvents.UnitUpgraded.Add(function(owner,old,new,ruin)
    if owner==Game.GetActivePlayer() and old==id and not ruin then newID=new end
end)
GameEvents.UnitConverted.Add(function(oldOwner,newOwner,oldID,newUnitID,upgrade)
    if oldOwner==Game.GetActivePlayer() then
        if upgrade and oldID==id then converted={owner=newOwner,id=newUnitID} end
        if not upgrade and oldID==giftID then gifted={owner=newOwner,id=newUnitID} end
    end
end)
local function action(u,kind)
    UI.SelectUnit(u)
    for i=0,#GameInfoActions do if GameInfoActions[i] and GameInfoActions[i].Type==kind then
        assert(Game.CanHandleAction(i),"normal action unavailable: "..kind);Game.HandleAction(i);return
    end end
    error("missing action "..kind)
end
function LekmodScenario.snapshot(player)
    local units={}
    for owner=0,GameDefines.MAX_CIV_PLAYERS do local p=Players[owner]
        if p then for u in p:Units() do if u:GetUnitType()==GameInfoTypes.UNIT_GEORGIA_KHEVSUR then
            units[owner..":"..u:GetID()]={golden=u:IsHasPromotion(promotion),combat=u:GetExtraCombatPercent(),level=u:GetLevel(),xp=u:GetExperience()}
        end end end
    end
    return {turn=Game.GetGameTurn(),civ=player:GetCivilizationType(),gold=player:GetGold(),golden_turns=player:GetGoldenAgeTurns(),units=units}
end
function LekmodScenario.step(player)
    assert(player:GetCivilizationType()==GameInfoTypes.CIVILIZATION_GEORGIA,"choose Georgia")
    local city=player:GetCapitalCity();if not city then return "turn" end
    if phase=="init" then
        assert(not Teams[player:GetTeam()]:GetTeamTechs():HasTech(GameInfoTypes.TECH_STEEL),"start before Steel obsoletes Khevsurs")
        LekmodScenarioGrantTech(player,"TECH_GUILDS")
        local iron=GameInfoTypes.RESOURCE_IRON;local amount=2-player:GetNumResourceAvailable(iron,true)
        if amount>0 then player:ChangeNumResourceTotal(iron,amount);LekmodScenarioEvent("fixture-setup",{operation="provided-iron",added=amount}) end
        turn=Game.GetGameTurn();phase="prerequisites";return "turn"
    elseif phase=="prerequisites" then
        if Game.GetGameTurn()==turn then return "turn" end
        assert(not player:IsGoldenAge(),"fixture unexpectedly started a golden age")
        local u=assert(player:InitUnit(GameInfoTypes.UNIT_WARRIOR,city:GetX(),city:GetY()));id=u:GetID()
        local a=assert(player:InitUnit(GameInfoTypes.UNIT_ARTIST,city:GetX(),city:GetY()));artist=a:GetID()
        LekmodScenarioEvent("fixture-setup",{operation="provided-warrior-and-artist",warrior=id,artist=artist})
        assert(u:GetUpgradeUnitType()==GameInfoTypes.UNIT_GEORGIA_KHEVSUR,"Warrior's legal upgrade is not a Khevsur")
        cost=u:UpgradePrice(GameInfoTypes.UNIT_GEORGIA_KHEVSUR)
        if player:GetGold()<cost then local amount=cost-player:GetGold()+50;player:ChangeGold(amount);LekmodScenarioEvent("fixture-setup",{operation="provided-gold",added=amount}) end
        action(a,"MISSION_GOLDEN_AGE");phase="golden"
    elseif phase=="golden" then
        if not LekmodScenarioAwait("upgrade-golden-age",player:IsGoldenAge()) then return false end
        local u=assert(player:GetUnitByID(id));assert(not u:IsHasPromotion(promotion),"Warrior received Khevsur bonus")
        assert(u:CanUpgradeRightNow(),"ordinary paid upgrade unavailable")
        gold=player:GetGold();action(u,"COMMAND_UPGRADE");phase="upgraded"
    elseif phase=="upgraded" then
        if not newID then return false end
        local u=assert(player:GetUnitByID(newID))
        if not LekmodScenarioAwait("georgia-paid-upgrade",u:GetUnitType()==GameInfoTypes.UNIT_GEORGIA_KHEVSUR and player:GetGold()==gold-cost) then return false end
        local old=player:GetUnitByID(id);assert(not old or old:IsDead() or old:IsDelayedDeath(),"upgrade retained old Warrior")
        LekmodScenarioRecord("georgia-paid-upgrade","PASS","path=normal-upgrade-action gold="..cost)
        LekmodScenarioEvent("georgia-upgrade-state",{golden=player:IsGoldenAge(),promotion=u:IsHasPromotion(promotion),combat=u:GetExtraCombatPercent(),id=newID})
        assert(player:IsGoldenAge() and u:IsHasPromotion(promotion) and u:GetExtraCombatPercent()==33,"paid upgrade lost its golden-age ability during conversion")
        assert(converted and converted.owner==player:GetID() and converted.id==newID,"post-conversion event arguments are wrong")
        LekmodScenarioRecord("georgia-upgrade-golden-age","PASS","path=normal-upgrade combat-added=33")
        local plot
        for owner=0,GameDefines.MAX_MAJOR_CIVS-1 do local p=Players[owner]
            if owner~=player:GetID() and p and p:IsAlive() and p:GetCivilizationType()~=GameInfoTypes.CIVILIZATION_GEORGIA
                and not Teams[player:GetTeam()]:IsAtWar(p:GetTeam()) then
                for i=0,Map.GetNumPlots()-1 do local candidate=Map.GetPlotByIndex(i)
                    if candidate:GetOwner()==owner and not candidate:IsWater() and not candidate:IsMountain() and not candidate:IsCity() and candidate:GetNumUnits()==0 then recipient,plot=owner,candidate;break end
                end
                if plot then break end
            end
        end
        assert(plot,"no peaceful foreign gift location")
        u=assert(player:InitUnit(GameInfoTypes.UNIT_GEORGIA_KHEVSUR,city:GetX(),city:GetY()));giftID=u:GetID()
        assert(u:IsHasPromotion(promotion),"supplied gift Khevsur lacks the existing golden-age benefit")
        LekmodScenarioEvent("fixture-setup",{operation="provided-Khevsur-for-gift-boundary",id=giftID})
        if not Teams[player:GetTeam()]:IsHasMet(Players[recipient]:GetTeam()) then
            Teams[player:GetTeam()]:Meet(Players[recipient]:GetTeam(),false)
            LekmodScenarioEvent("fixture-setup",{operation="established-contact",other=recipient})
        end
        u:SetXY(plot:GetX(),plot:GetY(),false,true,false,false)
        LekmodScenarioEvent("fixture-setup",{operation="position-unit-for-gift",id=giftID,x=u:GetX(),y=u:GetY(),recipient=recipient})
        assert(u:CanGift(),"ordinary unit gift unavailable")
        action(u,"COMMAND_GIFT");phase="gifted"
    elseif phase=="gifted" then
        if not gifted then return false end
        assert(gifted.owner==recipient,"conversion event reported wrong recipient")
        local u=assert(Players[recipient]:GetUnitByID(gifted.id))
        local old=player:GetUnitByID(giftID)
        assert((not old or old:IsDead() or old:IsDelayedDeath()) and u:GetUnitType()==GameInfoTypes.UNIT_GEORGIA_KHEVSUR,"gift did not transfer the supplied unit")
        assert(not u:IsHasPromotion(promotion),"foreign recipient retained Georgia's golden-age ability")
        LekmodScenarioRecord("georgia-gift-away","PASS","path=normal-gift-and-post-conversion owner="..recipient.." golden-promotion=false")
        return true
    end
    return false
end
