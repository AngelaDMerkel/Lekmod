#!/usr/bin/env python3
"""Read-only discovery for the current-Mac gameplay acceptance register.

Discovery is intentionally conservative: a non-default field, relation table or
Lua listener is a coverage obligation, not proof of a distinct reachable effect
or a passing test. Manual triage must resolve reachability, units and oracles.
No game process is launched and no installed game/cache is opened for writing.
"""
import argparse
from collections import Counter, defaultdict
import hashlib
import json
from pathlib import Path
import re
import sqlite3
import zipfile

ROOT = Path(__file__).resolve().parents[2]
BASE_TABLES = {
    'Traits', 'Buildings', 'Units', 'UnitPromotions', 'Policies', 'Beliefs',
    'Improvements', 'Projects', 'Technologies', 'Eras', 'Resources', 'Features',
    'Terrains', 'Builds', 'GameSpeeds', 'HandicapInfos', 'Leaders',
    'MinorCivilizations', 'Resolutions', 'LeagueProjectRewards', 'LeagueProjects',
    'Specialists', 'Routes', 'GoodyHuts', 'Worlds', 'Processes', 'TradeConnections',
    'MinorCivTraits', 'GameOptions', 'Civilizations', 'PolicyBranchTypes',
}
# Presentation/identity fields are inventoried separately, never silently lost.
METADATA_FIELDS = {
    'ID', 'Type', 'Description', 'ShortDescription', 'Civilopedia', 'Strategy',
    'Help', 'ThemingBonusHelp', 'Quote', 'PortraitIndex', 'IconAtlas',
    'IconAtlasAchieved', 'AlphaIconAtlas', 'IconString', 'ArtDefineTag',
    'WonderSplashImage', 'WonderSplashAnchor', 'WonderSplashAudio', 'MovieDefineTag',
    'ArtInfoCulturalVariation', 'ArtInfoEraVariation', 'ArtInfoRandomVariation',
    'UnitArtInfo', 'UnitArtInfoCulturalVariation', 'UnitArtInfoEraVariation',
    'UnitFlagIconOffset', 'UnitFlagAtlas', 'AudioIntro', 'AudioIntroHeader',
    'WorldSoundscapeAudioScript', 'PediaType', 'PediaEntry', 'Sound', 'HotKey',
    'GridX', 'GridY', 'DisplayPosition', 'MoveRate', 'DontShowYields', 'ShowInPedia',
    'CivilopediaTag', 'Adjective', 'DefaultPlayerColor', 'ArtStyleType',
    'ArtStyleSuffix', 'ArtStylePrefix', 'PortraitIndex', 'MapImage',
    'DawnOfManQuote', 'DawnOfManImage', 'DawnOfManAudio', 'PackageID', 'SoundtrackTag',
}
META_TABLE_PREFIXES = ('ArtDefine_', 'ArtStyle', 'Audio_', 'Icon', 'Animation', 'Language_', 'sqlite_')
META_TABLES = {
    'ScannedFiles', 'DownloadableContent', 'ApplicationInfo', 'Colors', 'PlayerColors',
    'Concepts', 'Concepts_RelatedConcept', 'Civilization_CityNames',
    'Civilization_SpyNames', 'MinorCivilization_CityNames', 'Diplomacy_Responses',
    'Unit_UniqueNames', 'UnitGameplay2DScripts', 'UnitMemberAudio', 'CitySizes',
    'Era_CitySoundscapes', 'Era_NewEraVOs', 'Era_Soundtracks', 'MovementRates',
    'EntityEvents', 'EntityEvent_AnimationPaths', 'MultiUnitPositions', 'Cursors',
    'HistoricRankings', 'LeagueNames', 'Months', 'Seasons', 'Calendars',
}
MP_TABLES = {'MPProposals', 'MultiplayerOptions', 'TurnTimers'}


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def digest(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True, ensure_ascii=False,
                                     separators=(',', ':')).encode()).hexdigest()


def quoted(name):
    return '"' + name.replace('"', '""') + '"'


def normal(value, declared_type):
    if declared_type.lower() == 'boolean':
        if value in (False, 0, '0', 'false', 'FALSE'):
            return False
        if value in (True, 1, '1', 'true', 'TRUE'):
            return True
    return value


def lua_tokens(source):
    """Tokenize enough Lua 5.1 to distinguish executable calls from comments/text."""
    tokens, i, line = [], 0, 1
    long = re.compile(r'\[(=*)\[')
    while i < len(source):
        start = i
        if source[i].isspace():
            line += source[i] == '\n'; i += 1; continue
        comment = source.startswith('--', i)
        if comment:
            i += 2
        match = long.match(source, i)
        if match:
            close = ']' + match.group(1) + ']'
            end = source.find(close, match.end())
            if end < 0:
                raise ValueError('unterminated Lua long comment/string')
            if not comment:
                tokens.append(('string', source[match.end():end], line))
            i = end + len(close)
        elif comment:
            end = source.find('\n', i); i = len(source) if end < 0 else end
        elif source[i] in ('"', "'"):
            quote, j = source[i], i + 1
            while j < len(source):
                if source[j] == '\\': j += 2; continue
                if source[j] == quote: break
                j += 1
            if j == len(source): raise ValueError('unterminated Lua string')
            tokens.append(('string', source[i + 1:j], line)); i = j + 1
        else:
            match = re.match(r'[A-Za-z_][A-Za-z_0-9]*', source[i:])
            if match:
                tokens.append(('name', match.group(), line)); i += len(match.group())
            else:
                tokens.append(('symbol', source[i], line)); i += 1
        line += source[start:i].count('\n')
    return tokens


def lua_calls(source):
    tokens = lua_tokens(source); contexts, includes, listeners = [], [], []
    anonymous = Counter()
    for i, (kind, value, line) in enumerate(tokens):
        tail = tokens[i:]
        vals = [x[1] for x in tail[:8]]
        if (value == 'LoadNewContext' and len(tail) > 2 and
                vals[1] == '(' and tail[2][0] == 'string'):
            contexts.append({'context': vals[2], 'line': line})
        if value == 'include' and len(tail) > 2 and vals[1] == '(' and tail[2][0] == 'string':
            includes.append({'include': vals[2], 'line': line})
        if (value in ('GameEvents', 'Events', 'LuaEvents') and len(tail) >= 7 and
                vals[1] == '.' and vals[3:6] == ['.', 'Add', '(']):
            handler = vals[6]
            if handler == 'function':
                anonymous[value + '.' + vals[2]] += 1
                handler = 'anonymous-' + str(anonymous[value + '.' + vals[2]])
            listeners.append({'event': value + '.' + vals[2], 'handler': handler, 'line': line})
    return contexts, includes, listeners


def group_for(name):
    """Scheduling hint only; never an automatic triage/pass decision."""
    if re.search(r'Trade|Diploma|Minor|CityState|League|Resolution|Vote|Plunder|Bully', name): return 'G5'
    if re.search(r'Belief|Religion|Faith|Policy|Policies|Culture|Tourism|GreatPerson|GoldenAge|GreatWork', name): return 'G6'
    if name.startswith(('Units', 'Unit_', 'UnitPromotions', 'Mission', 'Command')): return 'G3'
    if name.startswith(('Buildings', 'Building_', 'Improvement', 'Builds', 'BuildFeatures', 'Resource', 'Terrain', 'Feature')): return 'G4'
    return 'G7'


def discover_database(path):
    connection = sqlite3.connect(path.resolve().as_uri() + '?mode=ro&immutable=1', uri=True)
    connection.row_factory = sqlite3.Row
    try:
        if connection.execute('pragma quick_check').fetchone()[0] != 'ok':
            raise ValueError('database integrity check failed')
        tables, candidates, parameters = [], [], {}
        for (name,) in connection.execute("select name from sqlite_master where type='table' order by name"):
            schema = [dict(x) for x in connection.execute('pragma table_info(' + quoted(name) + ')')]
            rows = [dict(x) for x in connection.execute('select * from ' + quoted(name))]
            rows.sort(key=lambda x: json.dumps(x, sort_keys=True, ensure_ascii=False))
            record = {'name': name, 'row_count': len(rows), 'rows_sha256': digest(rows), 'columns': schema}
            if not rows:
                record['disposition'] = 'empty-table-no-configured-rows'
            elif name in MP_TABLES:
                record['disposition'] = 'multiplayer-deferred'
            elif name in META_TABLES or name.startswith(META_TABLE_PREFIXES):
                record['disposition'] = 'presentation-or-database-metadata'
            elif name in BASE_TABLES and 'Type' in rows[0]:
                record['disposition'] = 'scalar-fields-enumerated'
                fields = []
                for col in schema:
                    column = col['name']
                    if column in METADATA_FIELDS:
                        continue
                    default = connection.execute('select ' + col['dflt_value']).fetchone()[0] if col['dflt_value'] else None
                    values = [{'type': row['Type'], 'value': row[column]} for row in rows
                              if normal(row[column], col['type']) != normal(default, col['type'])]
                    if not values: continue
                    key = 'data:' + name + '.' + column
                    parameters[key] = values
                    candidates.append({'id': key, 'kind': 'scalar-field', 'table': name,
                                       'column': column, 'declared_type': col['type'], 'default': default,
                                       'parameter_count': len(values), 'parameters_sha256': digest(values),
                                       'suggested_group': group_for(name + '.' + column)})
                    fields.append(column)
                record['candidate_fields'] = fields
            else:
                record['disposition'] = 'relation-or-system-table-enumerated'
                key = 'data:' + name
                parameters[key] = rows
                candidates.append({'id': key, 'kind': 'table', 'table': name, 'parameter_count': len(rows),
                                   'parameters_sha256': digest(rows), 'suggested_group': group_for(name)})
            tables.append(record)
        playable = [dict(r) for r in connection.execute('select Type, Playable, AIPlayable from Civilizations where Playable=1 order by Type')]
        return tables, candidates, parameters, playable
    finally:
        connection.close()


def source_index(repo, names):
    """Return literal loader/reference hits; these are not inferred outcome oracles."""
    index = defaultdict(list); hashes = {}
    for path in sorted((repo / 'LEKMOD_DLL/CvGameCoreDLL_Expansion2').rglob('*.cpp')):
        source = path.read_text(errors='replace'); relative = path.relative_to(repo).as_posix()
        hits = []
        for number, line in enumerate(source.splitlines(), 1):
            for literal in re.findall(r'"([A-Za-z_][A-Za-z_0-9]*)"', line):
                if literal in names: hits.append((literal, number))
        if hits:
            hashes[relative] = sha(path)
            for name, line in hits: index[name].append({'path': relative, 'line': line})
    return index, hashes


def discover_lua(archive):
    prefix = 'payload/LEKMOD/'
    lua = {name: archive.read(name).decode('utf-8-sig', errors='replace')
           for name in archive.namelist() if name.startswith(prefix) and name.endswith('.lua')}
    by_name = defaultdict(list)
    for name in lua: by_name[Path(name).stem].append(name)
    entry = prefix + 'Lua/UI/InGame.lua'
    contexts, _, _ = lua_calls(lua[entry])
    queue = [entry]; edges, missing = [], []
    for context in contexts:
        paths = by_name.get(Path(context['context']).stem, [])
        if len(paths) != 1:
            missing.append({'from': entry, 'kind': 'context', **context, 'candidates': paths}); continue
        queue.append(paths[0]); edges.append({'from': entry, 'to': paths[0], 'kind': 'context', 'line': context['line']})
    visited, records, candidates = set(), [], []
    while queue:
        path = queue.pop(0)
        if path in visited: continue
        visited.add(path); _, includes, listeners = lua_calls(lua[path])
        records.append({'path': path, 'sha256': hashlib.sha256(archive.read(path)).hexdigest(),
                        'listeners': listeners})
        registered = {}
        for listener in listeners:
            key = 'lua:' + path[len(prefix):] + ':' + listener['event'] + ':' + listener['handler']
            if key in registered:
                registered[key]['registration_lines'].append(listener['line'])
                continue
            row = {'id': key, 'kind': 'lua-listener', 'path': path,
                   **listener, 'registration_lines': [listener['line']],
                   'suggested_group': 'G2' if 'Civilizations/' in path else 'G7'}
            registered[key] = row; candidates.append(row)
        for include in includes:
            paths = by_name.get(Path(include['include']).stem, [])
            if len(paths) != 1:
                missing.append({'from': path, 'kind': 'include', **include, 'candidates': paths}); continue
            queue.append(paths[0]); edges.append({'from': path, 'to': paths[0], 'kind': 'include', 'line': include['line']})
    return {'entry': entry, 'contexts': contexts, 'files': records, 'edges': edges,
            'unresolved_references': missing,
            'scope_note': 'Static literal context/include closure. Dynamic UI add-ins and other UI event wiring need separate review.'}, candidates


def generate(args):
    package, database = args.package.resolve(), args.database.resolve()
    if sha(package) != args.package_sha256 or sha(database) != args.database_sha256:
        raise ValueError('package/database hash mismatch; refusing discovery')
    for path in (args.output, args.parameters):
        if path.exists(): raise ValueError('output exists; preserve it and choose a new path: ' + str(path))
    with zipfile.ZipFile(package) as archive:
        manifest = json.loads(archive.read('manifest.json'))
        if manifest['product'] != 'lekmod': raise ValueError('not a Lekmod package')
        for name, expected in manifest['files'].items():
            if hashlib.sha256(archive.read(name)).hexdigest() != expected:
                raise ValueError('artifact member hash mismatch: ' + name)
        lua, listeners = discover_lua(archive)
        xml = archive.read('payload/LEKMOD/Override/CIV5Units.xml')
        if hashlib.sha256(xml).hexdigest() != sha(ROOT / 'LEKMOD/Override/CIV5Units.xml'):
            raise ValueError('current authoritative gameplay XML differs from pinned package')
    tables, candidates, parameters, playable = discover_database(database)
    names = {r['table'] for r in candidates} | {r['column'] for r in candidates if 'column' in r}
    sources, hashes = source_index(ROOT, names)
    for row in candidates:
        row['source_literals'] = sources.get(row.get('column', row['table']), [])
    all_candidates = candidates + listeners
    if len({r['id'] for r in all_candidates}) != len(all_candidates):
        raise ValueError('duplicate candidate IDs')
    result = {'schema_version': 1, 'kind': 'discovery-not-acceptance',
              'package': str(package.relative_to(ROOT)), 'package_sha256': args.package_sha256,
              'database': str(database.relative_to(ROOT)), 'database_sha256': args.database_sha256,
              'manifest': {k: manifest[k] for k in ('source', 'compat', 'gamecore_sha256', 'payload_sha256', 'host_startup')},
              'gameplay_xml_sha256': hashlib.sha256(xml).hexdigest(),
              'source_file_hashes': hashes, 'playable_civilizations': playable,
              'tables': tables, 'lua': lua, 'candidates': all_candidates,
              'parameters_file': str(args.parameters), 'parameters_content_sha256': digest(parameters),
              'summary': {'tables': len(tables), 'playable_civilizations': len(playable),
                          'table_dispositions': dict(Counter(r['disposition'] for r in tables)),
                          'candidate_kinds': dict(Counter(r['kind'] for r in all_candidates)),
                          'suggested_groups': dict(Counter(r['suggested_group'] for r in all_candidates))},
              'limitations': ['Candidates are not executed tests or a final denominator.',
                              'Non-default fields are grouped with every parameter row retained; default-zero behavior still needs shared-path review.',
                              'Reachability, outcomes, units, exact consumers, owners, dynamic Lua paths and evidence applicability require manual triage.',
                              'Metadata excludes effect enumeration only; presentation coverage is separately required.']}
    for path, value in ((args.output, result), (args.parameters, parameters)):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(value, indent=2, sort_keys=True, ensure_ascii=False) + '\n')
    if sha(database) != args.database_sha256: raise RuntimeError('database changed during read-only discovery')
    print(json.dumps(result['summary'], indent=2))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--package', type=Path, required=True)
    parser.add_argument('--package-sha256', required=True)
    parser.add_argument('--database', type=Path, required=True)
    parser.add_argument('--database-sha256', required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--parameters', type=Path, required=True)
    generate(parser.parse_args())


if __name__ == '__main__': main()
