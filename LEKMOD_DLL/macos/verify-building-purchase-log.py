#!/usr/bin/env python3
"""Check native baseline purchase quotes against an immutable resolved database."""
import argparse
import hashlib
import json
from pathlib import Path
import sqlite3

VARIANTS = {
    'standard-settler': ('GAMESPEED_STANDARD', 'HANDICAP_SETTLER'),
    'epic-deity': ('GAMESPEED_EPIC', 'HANDICAP_DEITY'),
    'marathon-prince': ('GAMESPEED_MARATHON', 'HANDICAP_PRINCE'),
    'quick-immortal': ('GAMESPEED_QUICK', 'HANDICAP_IMMORTAL'),
    'online-prince': ('GAMESPEED_ONLINE', 'HANDICAP_PRINCE'),
}

def trunc(n, d=100):
    return (abs(n) // d) * (-1 if n < 0 else 1)

def verify(database, log):
    db = sqlite3.connect(database.resolve().as_uri() + '?mode=ro&immutable=1', uri=True)
    db.row_factory = sqlite3.Row
    def table(name, key='Type'):
        return {row[key]: dict(row) for row in db.execute('SELECT * FROM ' + name)}
    buildings = table('Buildings', 'ID')
    speeds, eras, handicaps, defines = table('GameSpeeds'), table('Eras', 'ID'), table('HandicapInfos'), table('Defines', 'Name')
    assert len(buildings) == 258
    constant = lambda name: defines[name]['Value']
    observations, comparisons, explicit = {}, 0, set()
    for line in log.read_text().splitlines():
        if 'event=observation value=' not in line:
            continue
        event = json.loads(line.split('event=observation value=', 1)[1])
        if event.get('event') != 'native-building-purchase-quotes':
            continue
        value = event['value']
        mode, owner, state = value['mode'], value['owner'], value['state']
        key = mode, owner
        assert mode in VARIANTS and event['mode'] == 'run' and key not in observations
        speed, handicap = speeds[VARIANTS[mode][0]], handicaps[VARIANTS[mode][1]]
        mods = state['modifiers']
        assert state['cities']
        for city in state['cities'].values():
            assert city['majority'] <= 0 and set(map(int, city['quotes'])) == set(buildings)
            for ident, building in buildings.items():
                actual = city['quotes'][str(ident)]
                hurry = building['HurryCostModifier']
                if hurry == -1 or building['GoldCost'] < 0:
                    gold = -1
                else:
                    if building['GoldCost'] > 0:
                        gold = trunc(building['GoldCost'] * (100 + hurry))
                        gold = trunc(gold * speed['ConstructPercent'])
                        explicit.add(building['Type'])
                    else:
                        gold = int((actual['production'] * constant('GOLD_PURCHASE_GOLD_PER_PRODUCTION')) ** constant('HURRY_GOLD_PRODUCTION_EXPONENT'))
                        gold = trunc(gold * (100 + mods['hurry']))
                        gold = trunc(gold * speed['HurryPercent'])
                        gold = trunc(gold * (100 + hurry))
                    gold = trunc(gold * (100 + mods['gold']))
                    gold = trunc(gold, constant('GOLD_PURCHASE_VISIBLE_DIVISOR')) * constant('GOLD_PURCHASE_VISIBLE_DIVISOR')
                faith = trunc(building['FaithCost'] * eras[state['team_era']]['FaithCostMultiplier'])
                if faith > 0 and building['FaithCost'] > 0 and building['UnlockedByBelief'] and building['Cost'] == -1:
                    faith = trunc(faith * (100 + mods['faith']))
                faith = trunc(faith * speed['ConstructPercent'])
                if not state['human'] and not state['teammate']:
                    faith = trunc(faith * handicap['AIConstructPercent'])
                divisor = constant('FAITH_PURCHASE_VISIBLE_DIVISOR') * 2
                faith = trunc(faith, divisor) * divisor
                assert actual['gold'] == gold and actual['faith'] == faith, (key, building['Type'], actual, gold, faith)
                comparisons += 2
        observations[key] = state
    variants = {}
    for mode in VARIANTS:
        owners = {owner for name, owner in observations if name == mode}
        assert {0, 1} <= owners
        for owner in owners:
            state = observations[mode, owner]
            assert state['human'] == (owner == 0) and state['minor'] == (owner not in (0, 1))
        variants[mode] = {'owners': sorted(owners), 'city_count': sum(len(observations[mode, owner]['cities']) for owner in owners)}
    assert explicit == {'BUILDING_ISRAEL_NATIONAL_COLLEGE'}
    return {'valid': True, 'database_sha256': hashlib.sha256(database.read_bytes()).hexdigest(),
            'log_sha256': hashlib.sha256(log.read_bytes()).hexdigest(), 'building_definitions': len(buildings),
            'owner_observations': len(observations), 'independent_currency_comparisons': comparisons,
            'variants': variants, 'explicit_gold_definitions': sorted(explicit),
            'scope': 'Baseline quote arithmetic using recorded production/hurry/active-policy inputs; no transaction or excluded special-rule claim.'}

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--database', type=Path, required=True)
    parser.add_argument('--log', type=Path, required=True)
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    result = verify(args.database, args.log)
    if args.output:
        args.output.write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps(result, indent=2))

if __name__ == '__main__':
    main()
