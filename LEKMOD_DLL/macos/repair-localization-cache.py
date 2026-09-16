#!/usr/bin/env python3
"""Inspect or preserve/remove a confirmed empty generated localization cache.

No game launch, source database edit, save edit, or automatic retry is performed.
"""
import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import shutil
import sqlite3
import subprocess


def inspect_cache(user_data):
    cache=Path(user_data)/"cache"/"Localization-Merged.db"
    if cache.is_symlink() or cache.parent.is_symlink():
        raise RuntimeError("refusing a symlinked localization cache")
    if not cache.exists():
        return {"path":str(cache),"status":"absent"}
    if not cache.is_file():
        raise RuntimeError("localization cache is not a regular file")
    size=cache.stat().st_size
    if size==0:
        return {"path":str(cache),"status":"empty","size":0}
    try:
        with sqlite3.connect(cache.resolve().as_uri()+"?mode=ro",uri=True) as connection:
            tables={row[0] for row in connection.execute("SELECT name FROM sqlite_master WHERE type='table'")}
            healthy={"Languages","LocalizedText"} <= tables
        return {"path":str(cache),"status":"has-localization-tables" if healthy else "inspect-nonempty-cache","size":size}
    except sqlite3.DatabaseError as error:
        return {"path":str(cache),"status":"inspect-nonempty-cache","size":size,"error":str(error)}


def preserve_empty_cache(user_data, backup_directory):
    state=inspect_cache(user_data)
    if state["status"]!="empty":
        raise RuntimeError("repair only permits a confirmed zero-byte generated cache")
    cache=Path(state["path"])
    if any(Path(str(cache)+suffix).exists() for suffix in ("-wal","-shm","-journal")):
        raise RuntimeError("SQLite sidecars exist; inspect them before any repair")
    destination=Path(backup_directory)
    destination.mkdir(parents=True,exist_ok=False)
    backup=destination/cache.name
    shutil.copy2(cache,backup)
    digest=hashlib.sha256(backup.read_bytes()).hexdigest()
    # Recheck immediately before removal; never discard a regenerated cache.
    if cache.is_symlink() or cache.stat().st_size!=0:
        raise RuntimeError("cache changed during backup; leaving it in place")
    cache.unlink()
    result={**state,"action":"preserved-empty-cache-for-regeneration","backup":str(backup.resolve()),"sha256":digest}
    (destination/"repair.json").write_text(json.dumps(result,indent=2)+"\n")
    return result


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--user-data",type=Path,default=Path.home()/"Library/Application Support/Sid Meier's Civilization 5")
    parser.add_argument("--repair-empty",action="store_true",help="Preserve and remove only a zero-byte merged cache while Civ V is closed")
    parser.add_argument("--backup-directory",type=Path)
    args=parser.parse_args()
    if not args.repair_empty:
        print(json.dumps(inspect_cache(args.user_data),indent=2));return
    process=subprocess.run(["pgrep","-x","Civilization V"],capture_output=True)
    if process.returncode!=1:
        raise SystemExit("Civ V must be closed, with process inspection available")
    backup=args.backup_directory or Path(__file__).resolve().parents[2]/"build/macos/cache-repairs"/datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    print(json.dumps(preserve_empty_cache(args.user_data,backup),indent=2))


if __name__=="__main__":
    main()
