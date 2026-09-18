assert(loadfile(arg[1]))()
local nodes,unit
local function setup()
    nodes={}
    for id=0,5 do local p={id=id,owner=0,units={},through=true,destination=false,edges={},cost=60}
        function p:GetPlotIndex()return self.id end
        function p:GetX()return self.id end
        function p:GetY()return 0 end
        function p:GetOwner()return self.owner end
        function p:GetNumUnits()return #self.units end
        function p:GetUnit(i)return self.units[i+1] end
        function p:MovementCost(u,from,left)return self.cost end
        nodes[id]=p
    end
    unit={moves=120}
    function unit:GetPlot()return nodes[0]end
    function unit:GetMoves()return self.moves end
    function unit:GetOwner()return 0 end
    function unit:CanMoveThrough(p)return p.through end
    function unit:CanMoveOrAttackInto(p,war,dest)assert(war==0 and dest==1);return p.destination end
    Map={PlotDirection=function(x,y,d)return nodes[x].edges[d]end,PlotDistance=function(x,y,a,b)return math.abs(x-a)+math.abs(y-b)end}
end
local count=0
local function check(name,fn)setup();fn();count=count+1;print('PASS '..name)end
check('adjacent-legal-destination',function()nodes[0].edges[0]=nodes[1];nodes[1].destination=true;assert(LekmodFindStackedUnitDestination(unit)==nodes[1])end)
check('two-step-through-friendly-stack',function()nodes[0].edges[0]=nodes[1];nodes[1].edges[0]=nodes[2];nodes[2].destination=true;assert(LekmodFindStackedUnitDestination(unit)==nodes[2]);assert(unit.moves==120)end)
check('last-step-may-spend-all-remaining-moves',function()nodes[0].edges[0]=nodes[1];nodes[1].edges[0]=nodes[2];nodes[2].cost=180;nodes[2].destination=true;assert(LekmodFindStackedUnitDestination(unit)==nodes[2])end)
check('path-exceeds-remaining-moves',function()nodes[0].edges[0]=nodes[1];nodes[1].cost=120;nodes[1].edges[0]=nodes[2];nodes[2].destination=true;assert(LekmodFindStackedUnitDestination(unit)==nil)end)
check('cannot-traverse-blocked-terrain',function()nodes[0].edges[0]=nodes[1];nodes[1].through=false;nodes[1].edges[0]=nodes[2];nodes[2].destination=true;assert(LekmodFindStackedUnitDestination(unit)==nil)end)
check('foreign-territory-not-used',function()nodes[0].edges[0]=nodes[1];nodes[1].owner=1;nodes[1].destination=true;assert(LekmodFindStackedUnitDestination(unit)==nil)end)
check('foreign-unit-not-attacked',function()nodes[0].edges[0]=nodes[1];nodes[1].destination=true;nodes[1].units={{GetOwner=function()return 1 end}};assert(LekmodFindStackedUnitDestination(unit)==nil)end)
check('sea-destination-uses-engine-domain-eligibility',function()nodes[0].edges[0]=nodes[1];nodes[1].water=true;nodes[1].destination=true;assert(LekmodFindStackedUnitDestination(unit)==nodes[1])end)
check('no-moves-no-destination',function()unit.moves=0;nodes[0].edges[0]=nodes[1];nodes[1].destination=true;assert(LekmodFindStackedUnitDestination(unit)==nil)end)
check('search-is-bounded-to-three-steps',function()unit.moves=600;for i=0,3 do nodes[i].edges[0]=nodes[i+1]end;nodes[4].destination=true;assert(LekmodFindStackedUnitDestination(unit)==nil)end)
check('blocker-destination-must-be-outside-blocked-ring',function()function unit:GetPlot()return nodes[1]end;nodes[1].edges[0]=nodes[0];nodes[0].destination=true;nodes[1].edges[1]=nodes[2];nodes[2].destination=true;assert(LekmodFindStackedUnitDestination(unit,nodes[0])==nodes[2])end)
print(count..' movement-destination cases passed')
