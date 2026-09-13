#!/usr/bin/env python3
"""Build Lua 5.1.4 in Git-ignored test storage; never installs system software."""
import hashlib
from pathlib import Path
import subprocess
import tarfile
import urllib.request

VERSION = "5.1.4"
SHA256 = "b038e225eaf2a5b57c9bcc35cd13aa8c6c8288ef493d52970c9545074098af3a"
URL = "https://www.lua.org/ftp/lua-5.1.4.tar.gz"
ROOT = Path(__file__).resolve().parents[2] / "build/macos/test-deps"


def main():
    ROOT.mkdir(parents=True, exist_ok=True)
    archive = ROOT / ("lua-" + VERSION + ".tar.gz")
    if not archive.exists():
        data = urllib.request.urlopen(URL, timeout=30).read()
        if hashlib.sha256(data).hexdigest() != SHA256:
            raise SystemExit("Lua source download hash mismatch")
        archive.write_bytes(data)
    if hashlib.sha256(archive.read_bytes()).hexdigest() != SHA256:
        raise SystemExit("Cached Lua source hash mismatch")
    source = ROOT / ("lua-" + VERSION)
    binary = source / "src/lua"
    if not binary.exists():
        with tarfile.open(archive) as bundle:
            for member in bundle.getmembers():
                path = ROOT / member.name
                path.resolve().relative_to(source.resolve())
                if member.isdir():
                    path.mkdir(parents=True, exist_ok=True)
                elif member.isfile():
                    path.parent.mkdir(parents=True, exist_ok=True)
                    path.write_bytes(bundle.extractfile(member).read())
                else:
                    raise SystemExit("Unexpected Lua archive member type")
        result = subprocess.run(["make", "-C", str(source), "generic"], capture_output=True, text=True)
        if result.returncode:
            raise SystemExit(result.stdout + result.stderr)
    version = subprocess.run([str(binary), "-v"], capture_output=True, text=True, check=True)
    if "Lua " + VERSION not in version.stdout + version.stderr:
        raise SystemExit("Unexpected cached Lua version")
    print(binary)


if __name__ == "__main__":
    main()
