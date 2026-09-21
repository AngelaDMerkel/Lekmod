#!/usr/bin/env python3
"""Verify lifecycle evidence collection and refusal boundaries without launching Civ V."""
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import types
import unittest

PORT=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('lifecycle',PORT/'lifecycle-playtest.py')
lifecycle=importlib.util.module_from_spec(spec);spec.loader.exec_module(lifecycle)

class LifecycleTests(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory();self.addCleanup(self.tmp.cleanup)
        self.root=Path(self.tmp.name);self.cache=self.root/'data/cache';self.cache.mkdir(parents=True)
        self.original=lifecycle.runner;lifecycle.runner=types.SimpleNamespace(DATA=self.root/'data',game_pids=lambda:[])
        self.addCleanup(setattr,lifecycle,'runner',self.original)
    def test_snapshot_preserves_sources_and_copies_only_merged_family(self):
        files={'Localization-Merged.db':b'merged','Localization-Merged.db-wal':b'journal','source.db':b'source'}
        for name,value in files.items():(self.cache/name).write_bytes(value)
        out=self.root/'out';result=lifecycle.cache_snapshot(out)
        for name,value in files.items():self.assertEqual((self.cache/name).read_bytes(),value)
        self.assertEqual((out/'Localization-Merged.db').read_bytes(),b'merged')
        self.assertEqual((out/'Localization-Merged.db-wal').read_bytes(),b'journal')
        self.assertFalse((out/'source.db').exists())
        self.assertEqual(result,json.loads((out/'manifest.json').read_text()))
    def test_empty_cache_is_preserved_without_repair(self):
        p=self.cache/'Localization-Merged.db';p.write_bytes(b'')
        result=lifecycle.cache_snapshot(self.root/'out')
        self.assertTrue(p.exists());self.assertEqual(p.stat().st_size,0)
        self.assertEqual(result[p.name]['size'],0)
    def test_active_game_refuses_snapshot(self):
        lifecycle.runner.game_pids=lambda:[123]
        with self.assertRaisesRegex(RuntimeError,'Civ V closed'):lifecycle.cache_snapshot(self.root/'out')
    def test_cycle_budget_and_hash_failure_precede_native_prerequisites(self):
        f=self.root/'fixture.Civ5Save';f.write_bytes(b'fixture');sha=lifecycle.digest(f)
        base=[sys.executable,str(PORT/'lifecycle-playtest.py'),'--fixture',str(f),'--fixture-sha256',sha,'--package',str(f),'--package-sha256',sha]
        r=subprocess.run(base+['--cycles','6'],capture_output=True,text=True)
        self.assertEqual(r.returncode,2);self.assertIn('1–5 lifecycle cycles',r.stderr)
        r=subprocess.run(base+['--fixture-sha256','0'*64],capture_output=True,text=True)
        self.assertEqual(r.returncode,2);self.assertIn('hash mismatch',r.stderr)
if __name__=='__main__':unittest.main()
