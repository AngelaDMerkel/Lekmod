#!/usr/bin/env python3
"""Offline inventory and refusal checks; never launch Civ V."""
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import unittest
import tempfile
import zipfile
import xml.etree.ElementTree as ET

PORT=Path(__file__).resolve().parent;ROOT=PORT.parents[1]
class MatrixTests(unittest.TestCase):
    def test_every_playable_civilization_occurs_once_and_matches_source(self):
        plan=json.loads((PORT/'civilization-startup-groups.json').read_text())
        source=ROOT/'LEKMOD/Override/CIV5Units.xml'
        self.assertEqual(hashlib.sha256(source.read_bytes()).hexdigest(),plan['source_xml_sha256'])
        xml=ET.parse(source).getroot()
        expected={r.findtext('Type')for r in xml.findall('Civilizations/Row')if r.findtext('Playable','true').lower()in('true','1')and r.findtext('Type')not in('CIVILIZATION_MINOR','CIVILIZATION_BARBARIAN')}
        actual=[c for g in plan['groups']for c in g]
        self.assertEqual(len(actual),114);self.assertEqual(set(actual),expected)
        self.assertEqual(len(actual),len(set(actual)))
        self.assertTrue(all(2<=len(g)<=12 for g in plan['groups']))
        self.assertEqual(plan['group_turn_cap'],3)
    def test_preflight_needs_no_package_or_native_desktop_prerequisites(self):
        r=subprocess.run([sys.executable,str(PORT/'civilization-startup-matrix.py'),'--all','--preflight-only'],capture_output=True,text=True)
        self.assertEqual(r.returncode,0,r.stderr)
        result=json.loads(r.stdout);self.assertEqual(result['civilizations'],114)
        self.assertEqual(result['maximum_functional_turns'],30)
    def test_custom_rosters_keep_human_first_and_independent_turn_caps(self):
        r=subprocess.run([sys.executable,str(PORT/'civilization-startup-matrix.py'),
            '--roster','CIVILIZATION_CZECHIA,CIVILIZATION_ROME',
            '--roster','CIVILIZATION_MAURYA,CIVILIZATION_ROME','--preflight-only'],capture_output=True,text=True)
        self.assertEqual(r.returncode,0,r.stderr)
        result=json.loads(r.stdout);self.assertEqual(result['groups'],[1,2])
        self.assertEqual(result['civilizations'],4);self.assertEqual(result['maximum_functional_turns'],6)
    def test_custom_rosters_refuse_unknown_duplicate_and_oversized_inventory(self):
        cases=[['--roster','CIVILIZATION_MISSING,CIVILIZATION_ROME'],
               ['--roster','CIVILIZATION_ROME,CIVILIZATION_ROME'],
               ['--roster','CIVILIZATION_ROME'],
               ['--roster','CIVILIZATION_CZECHIA,CIVILIZATION_ROME']*11]
        for args in cases:
            with self.subTest(args=args):
                r=subprocess.run([sys.executable,str(PORT/'civilization-startup-matrix.py'),*args,'--preflight-only'],capture_output=True,text=True)
                self.assertEqual(r.returncode,2,r.stderr)
                self.assertIn('Custom rosters require',r.stderr)
    def test_duplicate_fixture_requires_explicit_custom_roster(self):
        tool=[sys.executable,str(PORT/'civilization-startup-matrix.py')]
        r=subprocess.run(tool+['--roster','CIVILIZATION_CUBA,CIVILIZATION_PALMYRA,CIVILIZATION_PALMYRA,CIVILIZATION_ROME','--allow-duplicate-civilizations','--preflight-only'],capture_output=True,text=True)
        self.assertEqual(r.returncode,0,r.stderr)
        self.assertEqual(json.loads(r.stdout)['maximum_functional_turns'],3)
        r=subprocess.run(tool+['--all','--allow-duplicate-civilizations','--preflight-only'],capture_output=True,text=True)
        self.assertEqual(r.returncode,2,r.stderr)
        self.assertIn('requires an explicit --roster',r.stderr)
        r=subprocess.run(tool+['--roster','CIVILIZATION_MISSING,CIVILIZATION_ROME','--allow-duplicate-civilizations','--preflight-only'],capture_output=True,text=True)
        self.assertEqual(r.returncode,2,r.stderr)

    def test_wrong_package_data_refuses_before_native_prerequisites(self):
        with tempfile.TemporaryDirectory()as directory:
            package=Path(directory)/'wrong.zip'
            with zipfile.ZipFile(package,'w')as archive:archive.writestr('payload/LEKMOD/Override/CIV5Units.xml','wrong data')
            digest=hashlib.sha256(package.read_bytes()).hexdigest()
            r=subprocess.run([sys.executable,str(PORT/'civilization-startup-matrix.py'),'--group','1','--package',str(package),'--sha256',digest],capture_output=True,text=True)
            self.assertEqual(r.returncode,2,r.stderr)
            self.assertIn('Package gameplay XML differs',r.stderr)
    def test_invalid_group_and_budget_refuse_before_native_work(self):
        for args in (['--group','11'],['--all','--from-group','0'],['--all','--minutes','4'],['--group','1','--from-group','2']):
            with self.subTest(args=args):
                r=subprocess.run([sys.executable,str(PORT/'civilization-startup-matrix.py'),*args,'--preflight-only'],capture_output=True,text=True)
                self.assertEqual(r.returncode,2,r.stderr)
if __name__=='__main__':unittest.main()
