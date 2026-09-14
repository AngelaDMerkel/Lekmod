-- A normal game configured for two turns exercises actual score resolution.
-- No score, winner, elapsed-turn, synchronization or wait flag is assigned.
LekmodScenario={name="endgame",items={"score-victory","endgame-panel"}}
function LekmodScenario.snapshot(player)
    return {turn=Game.GetGameTurn(),winner=Game.GetWinner(),victory=Game.GetVictory()}
end
function LekmodScenario.step(player)
    if Game.GetWinner()~=-1 then return false end
    return "turn"
end
