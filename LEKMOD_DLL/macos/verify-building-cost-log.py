#!/usr/bin/env python3
"""Independently compare native building quotes with an immutable resolved database."""
import argparse
import hashlib
import json
from pathlib import Path
import sqlite3

VARIANTS = {
    'standard-settler': ('GAMESPEED_STANDARD', 'HANDICAP_SETTLER', 'ERA_ANCIENT'),
    'epic-deity': ('GAMESPEED_EPIC', 'HANDICAP_DEITY', 'ERA_MEDIEVAL'),
    'marathon-prince': ('GAMESPEED_MARATHON', 'HANDICAP_PRINCE', 'ERA_RENAISSANCE'),
    'quick-immortal': ('GAMESPEED_QUICK', 'HANDICAP_IMMORTAL', 'ERA_INDUSTRIAL'),
    'online-prince': ('GAMESPEED_ONLINE', 'HANDICAP_PRINCE', 'ERA_ANCIENT'),
}

def trunc(numerator, denominator=100):
    return (abs(numerator) // denominator) * (-1 if numerator < 0 else 1)

def verify(database, log):
    connection = sqlite3.connect(database.resolve().as_uri() + '?mode=ro&immutable=1', uri=True)
    connection.row_factory = sqlite3.Row
    def rows(table, key='Type'):
        return {row[key]: dict(row) for row in connection.execute('SELECT * FROM ' + table)}
    buildings = rows('Buildings', 'ID')
    classes = rows('BuildingClasses')
    speeds, eras, handicaps = rows('GameSpeeds'), rows('Eras'), rows('HandicapInfos')
    defines = rows('Defines', 'Name')
    assert len(buildings) == 258
    assert not connection.execute('SELECT 1 FROM Resource_BuildingProductionCostModifiersLocal').fetchone()
    assert all(row['LaterEraBuildingConstructMod'] == 0 for row in eras.values())
    observations, comparisons = {}, 0
    for line in log.read_text().splitlines():
        if 'event=observation value=' not in line:
            continue
        event = json.loads(line.split('event=observation value=', 1)[1])
        if event.get('event') != 'native-building-cost-quotes':
            continue
        value = event['value']
        mode, label, owner = value['mode'], value['label'], value['owner']
        key = (mode, label, owner)
        assert event['mode'] == 'run' and mode in VARIANTS and key not in observations
        assert label in ('before-foundation', 'after-foundation')
        state = value['state']
        speed, handicap, start = (table[name] for table, name in zip((speeds, handicaps, eras), VARIANTS[mode]))
        assert set(map(int, state['quotes'])) == set(buildings)
        city_ids = None
        for ident, building in buildings.items():
            quote = state['quotes'][str(ident)]
            ids = set(quote['cities'])
            assert len(ids) == state['cities'] and ids
            if city_ids is None:
                city_ids = ids
            assert ids == city_ids
            expected = building['Cost'] + max(0, building['NumCityCostMod']) * state['cities']
            if state['minor']:
                expected = trunc(expected * defines['MINOR_CIV_PRODUCTION_PERCENT']['Value'])
            expected = trunc(expected * defines['BUILDING_PRODUCTION_PERCENT']['Value'])
            expected = trunc(expected * speed['ConstructPercent'])
            expected = trunc(expected * start['ConstructPercent'])
            if not state['human'] and not state['teammate']:
                world = classes[building['BuildingClass']]['MaxGlobalInstances'] != -1
                expected = trunc(expected * handicap['AIWorldConstructPercent' if world else 'AIConstructPercent'])
                expected = trunc(expected * max(0, 100 + handicap['AIPerEraModifier'] * state['era']))
            expected = max(1, expected)
            assert quote['player'] == expected, (key, building['Type'], quote['player'], expected)
            assert all(number == expected for number in quote['cities'].values()), (key, building['Type'], quote['cities'], expected)
            comparisons += 1 + len(ids)
        observations[key] = state
    modes = {}
    for mode in VARIANTS:
        owners = {owner for name, label, owner in observations if name == mode and label == 'before-foundation'}
        assert {0, 1} <= owners
        assert owners == {owner for name, label, owner in observations if name == mode and label == 'after-foundation'}
        changed = 0
        for owner in owners:
            before, after = (observations[mode, label, owner] for label in ('before-foundation', 'after-foundation'))
            assert before['human'] == after['human'] == (owner == 0)
            assert before['minor'] == after['minor'] == (owner not in (0, 1))
            assert after['cities'] == before['cities'] + (1 if owner == 1 else 0)
            for ident, building in buildings.items():
                a, b = before['quotes'][str(ident)]['player'], after['quotes'][str(ident)]['player']
                if owner == 1 and building['NumCityCostMod'] > 0:
                    assert b > a
                    changed += 1
                else:
                    assert a == b
        assert changed == 17
        modes[mode] = {'owners': sorted(owners), 'repriced_buildings': changed}
    return {'valid': True, 'database_sha256': hashlib.sha256(database.read_bytes()).hexdigest(),
            'log_sha256': hashlib.sha256(log.read_bytes()).hexdigest(), 'building_definitions': len(buildings),
            'owner_observations': len(observations), 'independent_quote_comparisons': comparisons, 'variants': modes,
            'scope': 'Production quotations/repricing only; no purchase-price, earned-construction or broad shared-field acceptance.'}

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
