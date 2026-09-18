# Phoenicia founding-reward validation

Current Mac, standard UI, single-player: normally selected human and AI Phoenicia,
plus a normally random Ayyubid AI control, on Ancient/Tiny Pangaea with no
city-states or barbarians. Two extra Settlers and their legal staging locations,
and Optics prerequisites for all three teams, were explicit inputs. Founding
used real unit actions; no population, gold, reward marker or turn was assigned.

## Fixture diagnosis

`20260918T081644Z` assumed a pre-Optics expansion would have population 1 and
failed. Exact-world diagnostic replay `081938Z` showed population 2 but no reward
marker or gold, with Optics false through both native technology APIs. `082331Z`
then used that population as its control and incorrectly expected 3 after Optics.
`083007Z` traced real founding and SetPopulation events: the post-Optics handler
correctly added 1 to the new city's initial 1, while the earlier control had gained
an unrelated population point before its founding event. The GoodyHutPopup log
and native CvPlot ownership path identified an adjacent ancient ruin collected
when founding claimed its tile. These are retained failed fixture attempts, not
Phoenicia product defects.

The final site selector excludes ruins within two tiles rather than deleting
ruins or supplying a replacement population. The population/founding observers
are read-only, and their exact rendered source is retained with each run.

## Passing outcomes

`20260918T083648Z` replayed the same initial world with ruin-free sites:

- Capital and pre-Optics expansion: population 1, no marker and no gold award.
- Granting Optics: no retroactive marker on either existing city.
- A normal subsequent Found action: population 1→2, exactly 50 gold (0→50), one
  founding marker and consumed Settler.
- One ordinary turn let the AI players found normally. AI Phoenicia had marker 1,
  population 2 and gold 50. Ayyubids also knew Optics but had marker 0, population 1
  and gold 0. The human's treasury was 53 after ordinary income.

Save SHA-256: `364915db77a0f89f378001cf9ff6702d059c8e8cfea694098e30dcdfaecb36df`.
`083956Z` matched all three players' city identities, positions, populations,
markers, capital flags, Optics and treasury values exactly on reload.
Reload-save SHA-256:
`673ffe0756782f24526ec0a4a5e1a6b2eb32c74cfbb0a713873ac7fbf8ea3e22`.
Both saved/exited normally (0), restored settings/hooks and preserved manual
saves, with no Lua/synchronization errors. These are scripted actions and native
outcomes, not mouse input or earned Settlers/research.

The old Lua comment incorrectly described 40 gold and happiness; it now matches
the shipped tooltip/data and observed 50-gold population reward. No gameplay
code change was needed. Sailing's free ship, Trade Harbour and remaining owner/
capture boundaries remain separate from this founding test.
