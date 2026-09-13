-- Execute the actual product handlers with minimal engine objects. Lua 5.1.
include = function() end
LekmodUtilities = {is_civilization_active=function() return false end}
GameInfoTypes = {CIVILIZATION_NEW_ZEALAND=100, PROMOTION_JFD_DEFENDER=1,
    PROMOTION_JFD_DEFENDER_ACTIVE=2, PROMOTION_MOVE_ALL_TERRAIN=3,
    PROMOTION_EMBARKATION=4, PROMOTION_ATTACK_AWAY_CAPITAL=5}
GameDefines = {MAX_MAJOR_CIVS=4}
GameEvents = setmetatable({}, {__index=function() return {Add=function() end} end})
Game = {GetActivePlayer=function() return 0 end}
assert(loadfile(arg[1]))()
assert(loadfile(arg[2]))()

local function unit(promotions, radii)
    local p = {promotions=promotions, calls={}}
    local plot = {owner=-1, radii=radii or {}}
    function plot:IsPlayerCityRadius(owner)
        -- The C++ Lua binding converts a non-number to zero.
        return self.radii[tonumber(owner) or 0] or false
    end
    function plot:GetOwner() return self.owner end
    function p:GetPlot() return plot end
    function p:IsHasPromotion(id) return self.promotions[id] or false end
    function p:SetHasPromotion(id, value) self.promotions[id]=value; self.calls[#self.calls+1]={id,value} end
    return p, plot
end
local function player(id, units, options)
    options=options or {}
    local p = {id=id, units=units, options=options, dof_calls={}, influence=0}
    function p:IsAlive() return not self.options.dead end
    function p:IsMinorCiv() return self.options.minor or false end
    function p:IsBarbarian() return self.options.barbarian or false end
    function p:IsHuman() return false end
    function p:GetTeam() return self.options.team or self.id end
    function p:GetID() return self.id end
    function p:GetCivilizationType() return self.options.civilization or 100 end
    function p:GetCurrentResearch() return self.options.research or -1 end
    function p:GetOverflowResearch() return self.options.overflow or 0 end
    function p:ChangeOverflowResearch(amount) self.options.overflow=self:GetOverflowResearch()+amount end
    function p:Units()
        local i=0
        return function() i=i+1; return self.units[i] end
    end
    function p:IsDoF(other)
        self.dof_calls[#self.dof_calls+1]=other
        return self.options.friend == other
    end
    function p:GetMinorCivFriendshipLevelWithMajor(other)
        assert(type(other)=="number" and other >= 0 and other < GameDefines.MAX_MAJOR_CIVS,
            "city-state friendship requires a major player ID")
        return self.options.friendly and 1 or 0
    end
    function p:ChangeMinorCivFriendshipWithMajor(other, amount)
        assert(other < GameDefines.MAX_MAJOR_CIVS)
        self.influence=self.influence+amount
    end
    return p
end
local function reset()
    Players={}
    for id=0,3 do Players[id]=player(id, {}, {dead=true}) end
    Teams={}
    LekmodUtilities.get_random_between=function() return 3 end
end
local tests={}
local function test(name, body) tests[#tests+1]={name,body} end
test("defender-own-city",function()
    local u=unit({[1]=true}, {[0]=true}); Players[0]=player(0,{u})
    lekmod_new_zealand_uu_defender(0)
    assert(u.promotions[2] and not u.promotions[1], "own-city promotion missing")
end)
test("defender-friend-city",function()
    local u=unit({[1]=true}, {[1]=true}); Players[0]=player(0,{u}); Players[1]=player(1,{}, {friend=0})
    lekmod_new_zealand_uu_defender(0)
    assert(u.promotions[2] and not u.promotions[1], "friendly-city promotion missing")
end)
test("defender-player-id-not-team",function()
    local u=unit({[1]=true}, {[1]=true}); Players[0]=player(0,{u},{team=7}); Players[1]=player(1,{}, {friend=0})
    lekmod_new_zealand_uu_defender(0)
    assert(u.promotions[2], "friendship queried with team instead of player")
end)
test("defender-skips-self-friendship",function()
    local u=unit({[1]=true}); Players[0]=player(0,{u})
    lekmod_new_zealand_uu_defender(0)
    assert(#Players[0].dof_calls==0, "queried friendship with self")
end)
test("defender-leaving-radius",function()
    local u=unit({[2]=true}); Players[0]=player(0,{u})
    lekmod_new_zealand_uu_defender(0)
    assert(u.promotions[1] and not u.promotions[2], "outside-radius promotion not reverted")
end)
test("defender-unfriendly-city",function()
    local u=unit({[1]=true}, {[1]=true}); Players[0]=player(0,{u}); Players[1]=player(1,{})
    lekmod_new_zealand_uu_defender(0)
    assert(not u.promotions[2], "unfriendly city incorrectly granted promotion")
end)
test("defender-minor-own-city",function()
    local u=unit({[1]=true}, {[4]=true}); Players[4]=player(4,{u},{minor=true})
    lekmod_new_zealand_uu_defender(4)
    assert(u.promotions[2], "city-state Defender lost its own-city ability")
end)
test("defender-minor-no-major-friendship",function()
    local u=unit({[2]=true}); Players[4]=player(4,{u},{minor=true}); Players[1]=player(1,{},{friend=4})
    lekmod_new_zealand_uu_defender(4)
    assert(not u.promotions[2] and u.promotions[1], "city-state Defender promotion not reverted")
    assert(#Players[1].dof_calls==0, "minor used major friendship path")
end)
for _, kind in ipairs({"major","minor","barbarian"}) do
    test("embark-hover-"..kind,function()
        local u=unit({[3]=true,[4]=true}); Players[0]=player(0,{u},{minor=kind=="minor",barbarian=kind=="barbarian"})
        lekmod_embark_fix(0)
        assert(not u.promotions[4], "hover unit retained conflicting embark promotion")
    end)
end
test("embark-ordinary-unit",function()
    local u=unit({[4]=true}); Players[0]=player(0,{u})
    lekmod_embark_fix(0); assert(u.promotions[4], "ordinary unit lost embark ability")
end)
test("dead-player-unchanged",function()
    local u=unit({[1]=true,[3]=true,[4]=true}, {[0]=true}); Players[0]=player(0,{u},{dead=true})
    lekmod_embark_fix(0); lekmod_new_zealand_uu_defender(0)
    assert(#u.calls==0, "dead player's unit changed")
end)
test("battalion-major-influence",function()
    local u,plot=unit({[5]=true}); plot.owner=4
    Players[0]=player(0,{u}); Players[4]=player(4,{}, {minor=true,friendly=true})
    lekmod_new_zealand_uu_batallion(0)
    assert(Players[4].influence==1, "major did not receive city-state influence")
end)
test("battalion-minor-does-not-index-major-array",function()
    local u,plot=unit({[5]=true}); plot.owner=5
    Players[4]=player(4,{u},{minor=true}); Players[5]=player(5,{}, {minor=true,friendly=true})
    lekmod_new_zealand_uu_batallion(4)
    assert(Players[5].influence==0, "city-state received major-only influence")
end)
test("new-zealand-science-without-research",function()
    local calls={}
    local techs={ChangeResearchProgress=function(_,tech,amount,owner) calls[#calls+1]={tech,amount,owner} end}
    Teams[7]={GetTeamTechs=function() return techs end}
    local p=player(0,{}, {team=7,overflow=80})
    lekmod_new_zealand_ua_award_bonus(p,player(1,{}))
    assert(p:GetOverflowResearch()==92, "science reward was not added to overflow")
    assert(#calls==0, "overflow amount was used as a technology ID")
end)
test("new-zealand-science-with-research",function()
    local calls={}
    local techs={ChangeResearchProgress=function(_,tech,amount,owner) calls[#calls+1]={tech,amount,owner} end}
    Teams[7]={GetTeamTechs=function() return techs end}
    local p=player(0,{}, {team=7,overflow=80,research=42})
    lekmod_new_zealand_ua_award_bonus(p,player(1,{}))
    assert(#calls==1 and calls[1][1]==42 and calls[1][2]==12 and calls[1][3]==0,
        "science reward did not reach the selected team technology")
    assert(p:GetOverflowResearch()==80, "selected research incorrectly changed overflow")
end)
local failed=0
for _,entry in ipairs(tests) do
    reset()
    local ok,err=pcall(entry[2])
    io.write((ok and "PASS " or "FAIL ")..entry[1]..(ok and "" or " "..tostring(err)).."\n")
    if not ok then failed=failed+1 end
end
io.write(#tests.." checks; "..failed.." failures\n")
os.exit(failed==0 and 0 or 1)
