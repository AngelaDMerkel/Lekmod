#!/usr/bin/env python3
"""Exercise delayed writes, copy races, and native writable-descriptor observation."""
from pathlib import Path
import os
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch
from playtest_save import CheckpointCopier, game_save_writer_open

class SaveTests(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory();self.addCleanup(self.tmp.cleanup);self.root=Path(self.tmp.name)
        self.source=self.root/'manual.Civ5Save';self.target=self.root/'copies/checkpoint.Civ5Save';self.now=0;self.open=True
        self.c=CheckpointCopier(lambda _:self.open,2,lambda:self.now)
    def test_delayed_write_cannot_be_promoted_after_callback_ack(self):
        self.source.write_bytes(b'partial');self.assertIsNone(self.c.copy_if_ready(self.source,self.target))
        self.now=20;self.assertIsNone(self.c.copy_if_ready(self.source,self.target));self.assertFalse(self.target.exists())
        self.source.write_bytes(b'complete original');self.open=False
        self.assertIsNone(self.c.copy_if_ready(self.source,self.target));self.now=22
        result=self.c.copy_if_ready(self.source,self.target);self.assertTrue(result['source_copy_match'])
        self.assertEqual(self.target.read_bytes(),b'complete original');self.assertEqual(self.source.read_bytes(),b'complete original')
    def test_closed_file_change_restarts_quiet_period(self):
        self.open=False;self.source.write_bytes(b'first');self.assertIsNone(self.c.copy_if_ready(self.source,self.target))
        self.now=3;self.source.write_bytes(b'final');self.assertIsNone(self.c.copy_if_ready(self.source,self.target))
        self.now=5;self.assertIsNotNone(self.c.copy_if_ready(self.source,self.target))
    def test_change_during_copy_is_retained_but_never_loaded(self):
        self.open=False;self.source.write_bytes(b'first');self.c.settle_seconds=0
        import shutil
        original=shutil.copy2
        def racing(a,b):
            original(a,b);a.write_bytes(b'completed later')
        with patch('playtest_save.shutil.copy2',side_effect=racing):self.assertIsNone(self.c.copy_if_ready(self.source,self.target))
        self.assertFalse(self.target.exists());partials=list(self.target.parent.glob('*.partial'));self.assertEqual(len(partials),1)
        self.assertEqual(partials[0].read_bytes(),b'first')
        self.assertIsNotNone(self.c.copy_if_ready(self.source,self.target));self.assertEqual(self.target.read_bytes(),b'completed later')
    def test_reopened_writer_after_copy_blocks_handoff(self):
        self.source.write_bytes(b'bytes');self.c.settle_seconds=0
        with patch.object(self.c,'writer_open',side_effect=[False,True]):self.assertIsNone(self.c.copy_if_ready(self.source,self.target))
        self.assertFalse(self.target.exists())
    def test_existing_checkpoint_and_symlink_are_refused(self):
        self.source.write_bytes(b'bytes');self.open=False;self.c.settle_seconds=0;self.target.parent.mkdir();self.target.write_bytes(b'keep')
        with self.assertRaisesRegex(ValueError,'overwrite'):self.c.copy_if_ready(self.source,self.target)
        linked=self.root/'linked';linked.symlink_to(self.source)
        with self.assertRaisesRegex(ValueError,'symbolic'):self.c.copy_if_ready(linked,self.root/'new')
        self.assertEqual(self.target.read_bytes(),b'keep')
    def test_probe_error_is_not_treated_as_closed_writer(self):
        failure=subprocess.CompletedProcess([],1,'','permission denied')
        with patch('playtest_save.subprocess.run',return_value=failure):
            with self.assertRaises(RuntimeError):game_save_writer_open(os.getpid(),self.source)
    def test_real_native_writer_then_close_then_reader(self):
        script='import sys; f=open(sys.argv[1],"wb"); f.write(b"partial"); f.flush(); print("ready",flush=True); input(); f.write(b"-complete"); f.close(); print("closed",flush=True); input(); f=open(sys.argv[1],"rb"); print("reader",flush=True); input()'
        p=subprocess.Popen([sys.executable,'-c',script,str(self.source)],stdin=subprocess.PIPE,stdout=subprocess.PIPE,text=True)
        try:
            self.assertEqual(p.stdout.readline().strip(),'ready');self.assertTrue(game_save_writer_open(p.pid,self.source))
            p.stdin.write('\n');p.stdin.flush();self.assertEqual(p.stdout.readline().strip(),'closed');self.assertFalse(game_save_writer_open(p.pid,self.source))
            p.stdin.write('\n');p.stdin.flush();self.assertEqual(p.stdout.readline().strip(),'reader');self.assertFalse(game_save_writer_open(p.pid,self.source))
            p.stdin.write('\n');p.stdin.flush();p.wait(timeout=5);self.assertEqual(self.source.read_bytes(),b'partial-complete')
        finally:
            if p.poll()is None:p.kill();p.wait()
            p.stdin.close();p.stdout.close()
if __name__=='__main__':unittest.main()
