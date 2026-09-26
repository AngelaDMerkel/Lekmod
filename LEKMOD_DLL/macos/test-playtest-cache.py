#!/usr/bin/env python3
"""Exercise failure-evidence preservation without touching game data."""
from pathlib import Path
import tempfile
import unittest
from playtest_cache import preserve_cache


class CachePreservationTests(unittest.TestCase):
    def test_regular_files_empty_cache_and_sidecar_are_preserved_without_changes(self):
        with tempfile.TemporaryDirectory() as d:
            root=Path(d);cache=root/'cache';cache.mkdir();out=root/'evidence'
            values={'Localization-Merged.db':b'', 'Localization-Merged.db-journal':b'journal', 'Localization-BaseGame.db':b'original', 'manifest.json':b'cache-owned-manifest'}
            for name,value in values.items():(cache/name).write_bytes(value)
            result=preserve_cache(cache,out,lambda:[])
            self.assertEqual(set(result['files']),set(values))
            for name,value in values.items():
                self.assertEqual((cache/name).read_bytes(),value)
                self.assertEqual((out/'files'/name).read_bytes(),value)
            self.assertTrue((out/'manifest.json').is_file())

    def test_running_game_does_not_create_evidence(self):
        with tempfile.TemporaryDirectory() as d:
            root=Path(d);out=root/'evidence'
            with self.assertRaises(RuntimeError):preserve_cache(root/'cache',out,lambda:[123])
            self.assertFalse(out.exists())

    def test_missing_cache_is_recorded_not_created(self):
        with tempfile.TemporaryDirectory() as d:
            root=Path(d);cache=root/'missing';result=preserve_cache(cache,root/'evidence',lambda:[])
            self.assertFalse(result['source_exists']);self.assertFalse(cache.exists())

    def test_symlinks_are_not_followed(self):
        with tempfile.TemporaryDirectory() as d:
            root=Path(d);cache=root/'cache';cache.mkdir();external=root/'external';external.write_bytes(b'not-cache')
            (cache/'link').symlink_to(external);(cache/'directory').mkdir()
            result=preserve_cache(cache,root/'evidence',lambda:[])
            self.assertEqual(result['files'],{});self.assertEqual(set(result['skipped']),{'link','directory'})
            self.assertEqual(external.read_bytes(),b'not-cache')
            linked=root/'linked';linked.symlink_to(cache)
            with self.assertRaises(RuntimeError):preserve_cache(linked,root/'blocked',lambda:[])
            self.assertFalse((root/'blocked').exists())

    def test_actual_runner_hook_preserves_before_external_invalidation(self):
        from textwrap import dedent
        source=Path(__file__).with_name('automated-playtest.py').read_text()
        start=source.index('        if report["localization_startup_failure"]:')
        end=source.index('        net_log = logs / "net_message_debug.log"',start)
        hook=dedent(source[start:end])
        with tempfile.TemporaryDirectory() as d:
            root=Path(d);cache=root/'data/cache';cache.mkdir(parents=True)
            merged=cache/'Localization-Merged.db';merged.write_bytes(b'retained failed cache')
            out=root/'run';out.mkdir();report={'localization_startup_failure':True,'status':'failed-early-exit'}
            exec(hook,{'report':report,'DATA':root/'data','output':out,'game_pids':lambda:[]})
            merged.unlink()  # Model the later managed product switch.
            self.assertEqual((out/'localization-failure-cache/files/Localization-Merged.db').read_bytes(),b'retained failed cache')
            self.assertIn('Localization-Merged.db',report['localization_cache_evidence']['files'])
            self.assertEqual(report['status'],'failed-early-exit')
            blocked={'localization_startup_failure':True}
            exec(hook,{'report':blocked,'DATA':root/'data','output':root/'blocked','game_pids':lambda:[1]})
            self.assertIn('localization_cache_preservation_error',blocked)
            self.assertFalse((root/'blocked').exists())

    def test_existing_evidence_is_never_overwritten(self):
        with tempfile.TemporaryDirectory() as d:
            root=Path(d);out=root/'evidence';out.mkdir();(out/'manifest.json').write_text('retain')
            with self.assertRaises(FileExistsError):preserve_cache(root/'cache',out,lambda:[])
            self.assertEqual((out/'manifest.json').read_text(),'retain')

if __name__=='__main__':unittest.main()
