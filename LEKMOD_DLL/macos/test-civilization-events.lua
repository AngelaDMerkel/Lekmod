-- Execute real product Lua handlers using the C++ event argument contracts.
include=function() end
GameInfoTypes={CIVILIZATION_MUGHALS=1,CIVILIZATION_BOLIVIA=2,BUILDING_DUMMY_MUGHALS=101,
    BUILDING_BOLIVIA_TRAIT_PRODUCTION=102,BUILDING_BOLIVIA_TRAIT_FOOD=103,
    UNIT_ARTIST=10,UNIT_WRITER=11,UNIT_COLORADO=12}
GameInfo={Units={[12]={Combat=30}}}
GameDefines={MAX_MAJOR_CIVS=4,MAX_CIV_PLAYERS=5}
ReligionTypes={RELIGION_PANTHEON=0}
Game={GetActivePlayer=function() return 0 end}
LekmodUtilities={is_civilization_active=function() return true end,get_round=function(_,x) return math.floor(x+0.5) end}
local events={}
GameEvents=setmetatable({}, {__index=function(_,name)
    events[name]=events[name] or {}
    return {Add=function(fn) table.insert(events[name],fn) end}
end})
Events=setmetatable({}, {__index=function() return {Add=function() end} end})
local stored={}
Modding={OpenSaveData=function() return {GetValue=function(k) return stored[k] end,SetValue=function(k,v) stored[k]=v end} end}
assert(loadfile(arg[1]))()
assert(loadfile(arg[2]))()
local function city(id,owner,religion,holy)
    local c={id=id,owner=owner,religion=religion or -1,holy=holy,buildings={}}
    function c:GetID() return self.id end
    function c:GetOwner() return self.owner end
    function c:GetReligiousMajority() return self.religion end
    function c:IsHolyCityForReligion(r) return self.holy==r end
    function c:IsHasBuilding(b) return (self.buildings[b] or 0)>0 end
    function c:SetNumRealBuilding(b,n) self.buildings[b]=n end
    function c:IsHuman() return false end
    return c
end
local function player(id,civ,cities,units)
    local p={id=id,civ=civ,cities=cities or {},units=units or {},alive=true,happiness=10}
    function p:GetID() return self.id end
    function p:GetCivilizationType() return self.civ end
    function p:IsAlive() return self.alive end
    function p:IsHuman() return false end
    function p:IsMinorCiv() return self.id>=4 end
    function p:IsBarbarian() return self.id==5 end
    function p:HasCreatedReligion() return self.religion~=nil end
    function p:GetReligionCreatedByPlayer() return self.religion or -1 end
    function p:GetCapitalCity() return self.cities[1] end
    function p:GetExcessHappiness() return self.happiness end
    function p:Cities() local i=0;return function() i=i+1;return self.cities[i] end end
    function p:Units() local i=0;return function() i=i+1;return self.units[i] end end
    function p:GetUnitByID(id) for _,u in ipairs(self.units) do if u.id==id then return u end end end
    return p
end
local function unit(id,kind)
    local u={id=id,kind=kind,strength=30}
    function u:GetUnitType() return self.kind end
    function u:GetID() return self.id end
    function u:SetBaseCombatStrength(v) self.strength=v end
    return u
end
local tests={}
local function test(name,fn) tests[#tests+1]={name,fn} end
test("mughal-capture-fifth-argument-is-new-owner",function()
    local c=city(100,2,1);local holy=city(101,1,-1,1)
    Players[2]=player(2,1,{c});Players[1]=player(1,3,{holy})
    lekmod_ua_mughals_city_acquired(0,false,12,14,2,5,true,0,0)
    assert(c.buildings[101]==1 and holy.buildings[101]==1,"capture did not apply both benefits")
end)
test("mughal-conversion-clears-former-holy-benefit",function()
    local c=city(100,0,1);local holy=city(101,1,-1,1)
    Players[0]=player(0,1,{c});Players[1]=player(1,3,{holy})
    lekmod_ua_mughals_foreign_religion_check(0);assert(holy.buildings[101]==1)
    c.religion=-1;lekmod_ua_mughals_religion_changed(0,100,-1,true)
    assert(not holy:IsHasBuilding(101),"former holy city retained a stale benefit")
end)
test("mughal-shared-holy-benefit-retains-other-source",function()
    local a,b,h=city(100,0,1),city(101,2,1),city(102,1,-1,1)
    Players[0]=player(0,1,{a});Players[2]=player(2,1,{b});Players[1]=player(1,3,{h})
    lekmod_ua_mughals_foreign_religion_check(0);lekmod_ua_mughals_foreign_religion_check(2)
    a.religion=-1;lekmod_ua_mughals_foreign_religion_check(0)
    assert(h:IsHasBuilding(101),"remaining Mughal source lost its holy-city benefit")
end)
test("mughal-holy-city-under-minor-owner",function()
    local c,h=city(100,0,1),city(101,4,-1,1)
    Players[0]=player(0,1,{c});Players[4]=player(4,3,{h})
    lekmod_ua_mughals_foreign_religion_check(0)
    assert(h:IsHasBuilding(101),"captured holy city under a minor owner received no benefit")
end)
test("mughal-lost-final-city-clears-world-benefit",function()
    local c,h=city(100,0,1),city(101,1,-1,1)
    Players[0]=player(0,1,{c});Players[1]=player(1,3,{h})
    lekmod_ua_mughals_foreign_religion_check(0);assert(h:IsHasBuilding(101))
    Players[0].alive=false;Players[0].cities={};c.owner=2;Players[2]=player(2,3,{c})
    lekmod_ua_mughals_city_acquired(0,true,12,14,2,5,true,0,0)
    assert(not c:IsHasBuilding(101) and not h:IsHasBuilding(101),"lost source left stale city benefits")
end)
test("mughal-own-religion-and-pantheon-excluded",function()
    local own,pantheon,foreign=city(100,0,1),city(101,0,0),city(102,0,2)
    Players[0]=player(0,1,{own,pantheon,foreign});Players[0].religion=1
    lekmod_ua_mughals_foreign_religion_check(0)
    assert(not own:IsHasBuilding(101) and not pantheon:IsHasBuilding(101) and foreign:IsHasBuilding(101))
end)
test("mughal-subscribes-to-real-conversion-event",function()
    local c,h=city(100,0,1),city(101,1,-1,1)
    Players[0]=player(0,1,{c});Players[1]=player(1,3,{h})
    for _,fn in ipairs(events.CityConvertsReligion or {}) do fn(0,1,12,14) end
    assert(c:IsHasBuilding(101) and h:IsHasBuilding(101),"engine conversion event did not update Mughal benefits")
end)
test("colorado-creation-uses-instance-id",function()
    local u=unit(8192,12);Players[0]=player(0,2,{}, {u})
    lekmod_bolivia_uu_combat_strength(0,8192,12,14)
    assert(u.strength==34,"new Colorado missed current happiness bonus")
end)
test("colorado-happiness-change-and-negative-boundary",function()
    local u=unit(8192,12);Players[0]=player(0,2,{}, {u})
    lekmod_bolivia_uu_combat_strength(0);assert(u.strength==34)
    Players[0].happiness=-10;lekmod_bolivia_uu_combat_strength(0)
    assert(u.strength==30,"negative happiness applied an unintended penalty")
end)
test("bolivia-city-coordinate-is-not-great-person-type",function()
    local c=city(100,0);Players[0]=player(0,2,{c})
    lekmod_bolivia_is_person_expended(0,10,20)
    assert(not c:IsHasBuilding(102) and stored.bolivia_last_expended==nil,"city x coordinate was treated as an expended artist")
end)
test("bolivia-real-great-person-event",function()
    local c=city(100,0);Players[0]=player(0,2,{c})
    lekmod_bolivia_is_person_expended(0,10);assert(c:IsHasBuilding(102))
    lekmod_bolivia_is_person_expended(0,11);assert(c:IsHasBuilding(103) and not c:IsHasBuilding(102))
end)
test("bolivia-no-capital-does-not-crash",function()
    Players[0]=player(0,2,{})
    lekmod_bolivia_is_person_expended(0,10)
end)
test("bolivia-duplicate-civilizations-keep-independent-history",function()
    local a,b=city(100,0),city(101,1)
    Players[0]=player(0,2,{a});Players[1]=player(1,2,{b})
    lekmod_bolivia_is_person_expended(0,10)
    lekmod_bolivia_is_person_expended(1,11)
    local replacement=city(102,0);Players[0].cities={replacement,a}
    lekmod_bolivia_is_person_expended(0,20,20)
    assert(replacement:IsHasBuilding(102) and not a:IsHasBuilding(102),"another Bolivia erased the first player's history")
    assert(b:IsHasBuilding(103))
end)
test("bolivia-captured-capital-clears-foreign-benefit",function()
    local old,new=city(100,0),city(101,0)
    Players[0]=player(0,2,{old,new});lekmod_bolivia_is_person_expended(0,10)
    old.owner=1;Players[0].cities={new};Players[1]=player(1,3,{old})
    lekmod_bolivia_is_person_expended(0,true,20,20,1,5,true,0,0)
    assert(not old:IsHasBuilding(102),"non-Bolivian capital retained a captured trait benefit")
    assert(new:IsHasBuilding(102),"replacement Bolivian capital did not receive its benefit")
end)
test("bolivia-capture-between-duplicate-civs-refreshes-both",function()
    local old,replacement,new=city(100,0),city(101,0),city(102,1)
    Players[0]=player(0,2,{old,replacement});Players[1]=player(1,2,{new})
    lekmod_bolivia_is_person_expended(0,10);lekmod_bolivia_is_person_expended(1,11)
    old.owner=1;Players[0].cities={replacement};Players[1].cities={new,old}
    lekmod_bolivia_is_person_expended(0,true,20,20,1,5,true,0,0)
    assert(replacement:IsHasBuilding(102) and new:IsHasBuilding(103) and not old:IsHasBuilding(102))
end)
test("bolivia-existing-save-history-is-migrated",function()
    local c=city(100,0);Players[0]=player(0,2,{c});stored.bolivia_last_expended="100"
    lekmod_bolivia_is_person_expended(0,20,20)
    assert(c:IsHasBuilding(102),"legacy history was lost")
end)
local failures=0
for _,entry in ipairs(tests) do
    Players={};for id=0,5 do Players[id]=player(id,3) end
    stored={};Lek_Properties={}
    local ok,err=pcall(entry[2]);print((ok and "PASS " or "FAIL ")..entry[1]..(ok and "" or " "..tostring(err)))
    if not ok then failures=failures+1 end
end
print(#tests.." civilization-event cases; "..failures.." failures")
os.exit(failures==0 and 0 or 1)
