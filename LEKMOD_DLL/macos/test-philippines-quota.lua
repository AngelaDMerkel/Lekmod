-- Actual product handler, isolated owner/history boundaries.
local source=assert(arg[1])
function include()end
GameInfoTypes={CIVILIZATION_PHILIPPINES=1,BUILDING_PHILIPPINES_TRAIT=2}
LekmodUtilities={is_civilization_active=function()return true end}
local handler
GameEvents={PlayerCityFounded={Add=function(f)handler=f end}}
Players={};local currentCity
Map={GetPlot=function()return {GetPlotCity=function()return currentCity end}end}
assert(loadfile(source))()
local tests={
 {name="capital",founded=1,owned=0,capital=true,want=0},
 {name="first-expansion",founded=2,owned=0,want=1},
 {name="second-expansion",founded=3,owned=1,want=1},
 {name="third-expansion",founded=4,owned=2,want=0},
 {name="lost-one-awarded-city",founded=5,owned=1,want=0},
 {name="lost-both-awarded-cities",founded=6,owned=0,want=0},
 {name="acquired-cities-do-not-use-founding-quota",founded=2,owned=0,total_cities=7,want=1},
 {name="independent-AI-owner",id=1,founded=2,owned=0,want=1},
 {name="other-civilization",civ=3,founded=2,owned=0,want=0},
 {name="dead-player",alive=false,founded=2,owned=0,want=0},
 {name="legacy-DLL-first-expansion",legacy=true,founded=2,owned=0,want=1},
 {name="legacy-DLL-full-quota",legacy=true,founded=4,owned=2,want=0},
}
local failed=0
for _,t in ipairs(tests)do
 local id=t.id or 0;local awarded=0
 local p={GetCivilizationType=function()return t.civ or 1 end,IsAlive=function()return t.alive~=false end,
 CountNumBuildings=function()return t.owned end,GetNumCities=function()return t.total_cities or t.founded end}
 if not t.legacy then p.GetNumCitiesFounded=function()return t.founded end end
 Players[id]=p
 currentCity={IsCapital=function()return t.capital or false end,SetNumRealBuilding=function(_,building,n)assert(building==2);awarded=n end}
 local ok,err=pcall(function()handler(id,5,6);assert(awarded==t.want,"wrong award "..awarded)end)
 print((ok and "PASS " or "FAIL ")..t.name..(ok and "" or " "..tostring(err)))
 if not ok then failed=failed+1 end
end
print(#tests.." Philippines quota cases; "..failed.." failures")
os.exit(failed==0 and 0 or 1)
