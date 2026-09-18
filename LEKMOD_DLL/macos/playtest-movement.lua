-- Read-only bounded destination search. The actual MOVE_TO mission still uses
-- the engine pathfinder; never assign position, moves or activity flags.
function LekmodFindStackedUnitDestination(unit,avoidPlot)
    local start=unit:GetPlot();local moves=unit:GetMoves();local owner=unit:GetOwner()
    if moves<=0 then return nil end
    local queue={{plot=start,cost=0,depth=0}};local best={[start:GetPlotIndex()]=0};local head=1
    while queue[head] do
        local node=queue[head];head=head+1
        if node.depth<3 then for direction=0,5 do
            local plot=Map.PlotDirection(node.plot:GetX(),node.plot:GetY(),direction)
            if plot and plot~=start and (plot:GetOwner()==-1 or plot:GetOwner()==owner) then
                local friendly=true
                for i=0,plot:GetNumUnits()-1 do if plot:GetUnit(i):GetOwner()~=owner then friendly=false;break end end
                -- A legal final step may spend all remaining moves even when
                -- the terrain quote is larger. Intermediate stacked tiles may
                -- only be crossed while enough movement remains to leave them.
                if friendly and node.cost<moves and unit:CanMoveOrAttackInto(plot,0,1)
                    and (not avoidPlot or Map.PlotDistance(avoidPlot:GetX(),avoidPlot:GetY(),plot:GetX(),plot:GetY())>1) then return plot end
                if friendly and unit:CanMoveThrough(plot) then
                    local cost=plot:MovementCost(unit,node.plot,moves-node.cost)
                    local total=node.cost+cost;local id=plot:GetPlotIndex()
                    if cost>=0 and total<=moves and (best[id]==nil or total<best[id]) then
                        best[id]=total
                        if total<moves then queue[#queue+1]={plot=plot,cost=total,depth=node.depth+1} end
                    end
                end
            end
        end end
    end
end
