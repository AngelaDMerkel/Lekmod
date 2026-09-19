-- Actual product callback. Movement/stack stand-ins model the recorded turn
-- boundary; native movement evidence and native binding tests are separate.
local source=assert(arg[1]);local handler
include=function()end
GameInfoTypes={CIVILIZATION_MAORI=1,PROMOTION_MAORI=10,PROMOTION_MAORI_CIVILIAN=11}
LekmodUtilities={is_civilization_active=function()return true end}
GameEvents={PlayerDoTurn={Add=function(f)handler=f end}}
local turn,elapsed=5,nil;Game={GetGameTurn=function()return turn end,GetElapsedGameTurns=function()return elapsed~=nil and elapsed or turn end}
local function unit(base,remaining,promo)
 local u={base=base,moves=remaining,created=math.max(0,turn-1),promotions={[promo or 10]=true},writes=0}
 function u:GetGameTurnCreated()return self.created end
 function u:IsHasPromotion(p)return self.promotions[p] or false end
 function u:SetHasPromotion(p,v)self.promotions[p]=v end
 function u:MaxMoves()return self.base+(self:IsHasPromotion(10)and 120 or 0)+(self:IsHasPromotion(11)and 120 or 0)end
 function u:GetMoves()return self.moves end
 function u:SetMoves(n)assert(n<=self.moves,"must never restore movement");self.moves=n;self.writes=self.writes+1 end
 function u:MaxMovesWithStack()return math.max(self:MaxMoves(),self.donor and self.donor:MaxMoves() or 0)end
 return u
end
local function player(civ,alive,units)
 return {IsAlive=function()return alive end,GetCivilizationType=function()return civ end,
 Units=function()local i=0;return function()i=i+1;return units[i]end end}
end
assert(loadfile(source))()
local tests={};local function test(name,fn)tests[#tests+1]={name,fn}end
for _,t in ipairs({0,4})do test("opening turn "..t.." preserves bonus",function()
 turn=t;local u=unit(120,240);Players[0]=player(1,true,{u});handler(0);assert(u:MaxMoves()==240 and u.moves==240 and u.writes==0)
end)end
for _,t in ipairs({5,6})do test("expiry turn "..t.." removes stale extra budget",function()
 turn=t;local u=unit(120,240);local v=unit(120,240,11);Players[0]=player(1,true,{u,v});handler(0)
 assert(u:MaxMoves()==120 and v:MaxMoves()==120 and u.moves==120 and v.moves==120)
end)end
for _,moves in ipairs({0,60})do test("spent movement "..moves.." is never increased",function()
 local u=unit(120,moves);Players[0]=player(1,true,{u});handler(0);assert(u.moves==moves and u.writes==0 and not u:IsHasPromotion(10))
end)end
for _,reverse in ipairs({false,true})do test("stack donor expiry is independent of iteration order "..tostring(reverse),function()
 local donor=unit(180,300);local receiver=unit(120,300,11);receiver.donor=donor
 Players[0]=player(1,true,reverse and {donor,receiver}or{receiver,donor});handler(0)
 assert(donor.moves==180 and receiver.moves==180 and receiver:MaxMoves()==120,"legitimate stack movement lost or expired donor bonus retained")
end)end
test("higher general escort allowance survives",function()
 local donor=unit(300,420);local general=unit(240,420,11);general.donor=donor;Players[0]=player(1,true,{general,donor});handler(0)
 assert(general.moves==300 and general:MaxMoves()==240)
end)
test("foreign recipient expires inherited bonus",function()local u=unit(120,240);Players[0]=player(2,true,{u});handler(0);assert(not u:IsHasPromotion(10) and u:MaxMoves()==120 and u.moves==120)end)
test("dead owner is untouched",function()local u=unit(120,240);Players[0]=player(1,false,{u});handler(0);assert(u:MaxMoves()==240 and u.moves==240)end)
test("unrelated overfilled unit is untouched",function()local u=unit(120,300);u.promotions={};Players[0]=player(1,true,{u});handler(0);assert(u.moves==300 and u.writes==0)end)
test("two promotions expire together",function()local u=unit(120,360);u.promotions[11]=true;Players[0]=player(1,true,{u});handler(0);assert(u:MaxMoves()==120 and u.moves==120)end)
test("AI owner does not alter other owner's unit",function()
 local human=unit(120,240);local ai=unit(120,240);Players[0]=player(1,true,{human});Players[1]=player(1,true,{ai});handler(1);assert(ai.moves==120 and human.moves==240)
end)
test("normal production keeps the current owner-turn bonus",function()
 local u=unit(120,240);u.created=turn;Players[0]=player(1,true,{u});handler(0)
 assert(u:IsHasPromotion(10) and u:MaxMoves()==240 and u.moves==240 and u.writes==0)
end)
test("normally produced unit expires on the following owner turn",function()
 local u=unit(120,240,11);u.created=turn;Players[0]=player(1,true,{u});handler(0);assert(u:IsHasPromotion(11))
 turn=turn+1;handler(0);assert(not u:IsHasPromotion(11) and u:MaxMoves()==120 and u.moves==120)
end)
for _,age in ipairs({1,4})do test("later-era opening elapsed "..age.." retains bonus",function()
 turn=40+age;elapsed=age;local u=unit(120,240);u.created=40;Players[0]=player(1,true,{u});handler(0)
 assert(u:IsHasPromotion(10) and u.moves==240 and u:MaxMoves()==240)
end)end
test("later-era opening expires at elapsed five",function()
 turn=45;elapsed=5;local u=unit(120,240);u.created=40;Players[0]=player(1,true,{u});handler(0)
 assert(not u:IsHasPromotion(10) and u.moves==120)
end)
test("later-era new unit at elapsed five keeps first owner turn",function()
 turn=45;elapsed=5;local u=unit(120,240);u.created=45;Players[0]=player(1,true,{u});handler(0)
 assert(u:IsHasPromotion(10) and u.moves==240)
end)
test("foreign recipient keeps current-birth-turn bonus",function()
 local u=unit(120,240);u.created=turn;Players[0]=player(2,true,{u});handler(0);assert(u:IsHasPromotion(10) and u.moves==240)
end)
test("foreign recipient keeps unexpired opening bonus",function()
 turn=4;local u=unit(120,240);Players[0]=player(2,true,{u});handler(0);assert(u:IsHasPromotion(10) and u.moves==240)
end)
test("non-major owner slot expires inherited civilian bonus",function()
 local u=unit(120,240,11);Players[63]=player(-1,true,{u});handler(63);assert(not u:IsHasPromotion(11) and u.moves==120)
end)
test("legacy DLL lacks optional query without Lua error",function()
 local u=unit(120,240);u.MaxMovesWithStack=nil;Players[0]=player(1,true,{u});handler(0);assert(u:MaxMoves()==120 and u.moves==240 and u.writes==0)
end)
local failed=0
for _,t in ipairs(tests)do turn=5;elapsed=nil;Players={};local ok,err=pcall(t[2]);print((ok and "PASS "or"FAIL ")..t[1]..(ok and ""or": "..tostring(err)));if not ok then failed=failed+1 end end
print(#tests.." Maori expiry cases; "..failed.." failures");os.exit(failed==0 and 0 or 1)
