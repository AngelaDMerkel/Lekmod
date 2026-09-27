#!/usr/bin/env python3
"""Offline discovery checks; no Civ V process or installed cache is touched."""
import importlib.util
import json
from pathlib import Path
import sqlite3
import tempfile
from types import SimpleNamespace
import unittest
import zipfile

spec = importlib.util.spec_from_file_location('acceptance', Path(__file__).with_name('gameplay_acceptance.py'))
a = importlib.util.module_from_spec(spec); spec.loader.exec_module(a)


class DiscoveryTests(unittest.TestCase):
    def test_lua_comments_and_strings_are_not_executable_events(self):
        source = '''-- GameEvents.Fake.Add(fake)
--[=[GameEvents.LongFake.Add(fake)]=]
local text="GameEvents.TextFake.Add(fake)"
local another=[==[GameEvents.LongText.Add(fake)]==]
ContextPtr:LoadNewContext("Actual")
include('Helper.lua')
GameEvents.PlayerDoTurn.Add(run)
'''
        contexts, includes, listeners = a.lua_calls(source)
        self.assertEqual(contexts, [{'context': 'Actual', 'line': 5}])
        self.assertEqual(includes, [{'include': 'Helper.lua', 'line': 6}])
        self.assertEqual(listeners, [{'event': 'GameEvents.PlayerDoTurn', 'handler': 'run', 'line': 7}])

    def test_anonymous_ids_do_not_change_when_comments_are_inserted(self):
        s='GameEvents.PlayerDoTurn.Add(function(p) end)\nGameEvents.PlayerDoTurn.Add(function(p) end)'
        first=a.lua_calls(s)[2]; second=a.lua_calls('-- extra comment\n'+s)[2]
        self.assertEqual([r['handler'] for r in first], ['anonymous-1', 'anonymous-2'])
        self.assertEqual([r['handler'] for r in first], [r['handler'] for r in second])

    def test_repeated_registration_preserves_both_sites_and_dormant_context_is_excluded(self):
        with tempfile.TemporaryDirectory() as d:
            p=Path(d)/'package.zip'
            with zipfile.ZipFile(p, 'w') as z:
                z.writestr('payload/LEKMOD/Lua/UI/InGame.lua', 'ContextPtr:LoadNewContext("Active")\n--ContextPtr:LoadNewContext("Dormant")')
                z.writestr('payload/LEKMOD/Lua/Active.lua', 'GameEvents.PlayerDoTurn.Add(tick)\nGameEvents.PlayerDoTurn.Add(tick)')
                z.writestr('payload/LEKMOD/Lua/Dormant.lua', 'GameEvents.PlayerDoTurn.Add(dead)')
            with zipfile.ZipFile(p) as z: lua, candidates=a.discover_lua(z)
            self.assertEqual(len(candidates), 1)
            self.assertEqual(candidates[0]['registration_lines'], [1, 2])
            self.assertNotIn('Dormant', str(lua['files']))

    def test_ambiguous_and_external_includes_remain_explicitly_unresolved(self):
        with tempfile.TemporaryDirectory() as d:
            p=Path(d)/'package.zip'
            with zipfile.ZipFile(p, 'w') as z:
                z.writestr('payload/LEKMOD/Lua/UI/InGame.lua', 'include("External")\ninclude("Ambiguous")')
                z.writestr('payload/LEKMOD/Lua/A/Ambiguous.lua', '')
                z.writestr('payload/LEKMOD/Lua/B/Ambiguous.lua', '')
            with zipfile.ZipFile(p) as z: lua, _=a.discover_lua(z)
            self.assertEqual([len(r['candidates']) for r in lua['unresolved_references']], [0, 2])

    def test_database_enumeration_preserves_bytes_and_zero_overrides(self):
        with tempfile.TemporaryDirectory() as d:
            p=Path(d)/'sample.db'; c=sqlite3.connect(p)
            c.executescript('''CREATE TABLE Civilizations(Type TEXT, Playable INTEGER DEFAULT 1, AIPlayable INTEGER DEFAULT 1);
INSERT INTO Civilizations VALUES ('CIV_TEST',1,0);
CREATE TABLE Traits(Type TEXT, Description TEXT, Bonus INTEGER DEFAULT 5, Enabled BOOLEAN DEFAULT 'false');
INSERT INTO Traits VALUES ('TRAIT_A','label',0,0),('TRAIT_B','label',5,'false'),('TRAIT_C','label',5,1);
CREATE TABLE Trait_Links(TraitType TEXT, Amount INTEGER);
INSERT INTO Trait_Links VALUES('TRAIT_A',2);
CREATE TABLE EmptyTable(ID INTEGER);
CREATE TABLE MultiplayerOptions(Type TEXT);
INSERT INTO MultiplayerOptions VALUES('MP');''')
            c.close(); before=a.sha(p)
            tables, candidates, values, civs=a.discover_database(p)
            self.assertEqual(before,a.sha(p))
            self.assertEqual(values['data:Traits.Bonus'],[{'type':'TRAIT_A','value':0}])
            self.assertEqual(values['data:Traits.Enabled'],[{'type':'TRAIT_C','value':1}])
            self.assertNotIn('data:Traits.Description',values)
            self.assertEqual(len(civs),1)
            dispositions={r['name']:r['disposition']for r in tables}
            self.assertEqual(dispositions['EmptyTable'],'empty-table-no-configured-rows')
            self.assertEqual(dispositions['MultiplayerOptions'],'multiplayer-deferred')
            self.assertEqual(values['data:Trait_Links'],[{'TraitType':'TRAIT_A','Amount':2}])

    def test_wrong_input_hash_fails_before_outputs_are_created(self):
        with tempfile.TemporaryDirectory() as d:
            root=Path(d); package=root/'a.zip'; database=root/'a.db'
            package.write_bytes(b'package');database.write_bytes(b'database')
            args=SimpleNamespace(package=package,database=database,package_sha256='0'*64,
                                 database_sha256=a.sha(database),output=root/'out.json',parameters=root/'params.json')
            with self.assertRaisesRegex(ValueError,'hash mismatch'):a.generate(args)
            self.assertFalse(args.output.exists());self.assertFalse(args.parameters.exists())

    def test_malformed_lua_does_not_silently_drop_listeners(self):
        for source in ('--[=[ missing close', 'include("unterminated'):
            with self.assertRaises(ValueError):a.lua_calls(source)


if __name__ == '__main__': unittest.main()
