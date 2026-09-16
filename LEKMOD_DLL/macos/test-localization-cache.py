#!/usr/bin/env python3
import importlib.util
from pathlib import Path
import sqlite3
import tempfile
import unittest

spec=importlib.util.spec_from_file_location("cache_repair",Path(__file__).with_name("repair-localization-cache.py"))
repair=importlib.util.module_from_spec(spec);spec.loader.exec_module(repair)


class LocalizationCacheTests(unittest.TestCase):
    def setUp(self):
        self.directory=tempfile.TemporaryDirectory(prefix="lekmod-cache-test-")
        self.root=Path(self.directory.name);(self.root/"cache").mkdir()
        self.cache=self.root/"cache/Localization-Merged.db"
        self.backup=self.root/"backup"

    def tearDown(self):
        self.directory.cleanup()

    def test_missing_cache_is_not_created_by_inspection(self):
        self.assertEqual(repair.inspect_cache(self.root)["status"],"absent")
        self.assertFalse(self.cache.exists())

    def test_empty_cache_is_preserved_before_removal(self):
        self.cache.touch();source=self.root/"cache/Localization-BaseGame.db";source.write_bytes(b"source unchanged")
        result=repair.preserve_empty_cache(self.root,self.backup)
        self.assertFalse(self.cache.exists());self.assertEqual(Path(result["backup"]).read_bytes(),b"")
        self.assertEqual(source.read_bytes(),b"source unchanged")

    def test_valid_cache_is_read_only_and_not_repaired(self):
        with sqlite3.connect(self.cache) as db:
            db.execute("CREATE TABLE Languages(id)");db.execute("CREATE TABLE LocalizedText(tag)")
        before=self.cache.read_bytes()
        self.assertEqual(repair.inspect_cache(self.root)["status"],"has-localization-tables")
        with self.assertRaises(RuntimeError):repair.preserve_empty_cache(self.root,self.backup)
        self.assertEqual(self.cache.read_bytes(),before)

    def test_nonempty_malformed_cache_is_preserved(self):
        self.cache.write_bytes(b"inspect this")
        with self.assertRaises(RuntimeError):repair.preserve_empty_cache(self.root,self.backup)
        self.assertEqual(self.cache.read_bytes(),b"inspect this")

    def test_sidecars_prevent_destructive_repair(self):
        self.cache.touch();Path(str(self.cache)+"-wal").write_bytes(b"pending data")
        with self.assertRaises(RuntimeError):repair.preserve_empty_cache(self.root,self.backup)
        self.assertTrue(self.cache.exists())

    def test_symlink_is_not_followed_for_repair(self):
        other=self.root/"other";other.touch();self.cache.symlink_to(other)
        with self.assertRaises(RuntimeError):repair.preserve_empty_cache(self.root,self.backup)
        self.assertTrue(other.exists())


if __name__=="__main__":unittest.main()
