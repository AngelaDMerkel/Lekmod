#!/usr/bin/env python3
"""Add the committed, signed startup correction to a verified native archive."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys
import zipfile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--base', type=Path, required=True)
    parser.add_argument('--sha256', required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--installer-repo', type=Path)
    args = parser.parse_args()
    repo = Path(__file__).resolve().parents[2]
    installer = args.installer_repo or repo.parent / 'Civ5ModDlcPacker'
    sys.path.insert(0, str(installer))
    import civ5_gamecore as core
    import civ5_host_startup as startup
    if args.output.exists():
        raise ValueError('output exists; choose a new archive path')
    source = Path(__file__).with_name('host-stat-compat.c')
    commit = subprocess.check_output(['git', '-C', str(repo), 'rev-parse', 'HEAD'], text=True).strip()
    committed = subprocess.check_output(['git', '-C', str(repo), 'show', commit + ':LEKMOD_DLL/macos/host-stat-compat.c'])
    if source.read_bytes() != committed:
        raise ValueError('startup correction source must match the recorded commit')
    with core.open_artifact(args.base, args.sha256) as (stage, manifest):
        if manifest['product'] != 'lekmod' or manifest.get('host_startup'):
            raise ValueError('expected a verified Lekmod archive without a startup correction')
        library = stage / startup.LIBRARY
        subprocess.run(['clang', '-arch', 'x86_64', '-dynamiclib', '-mmacosx-version-min=10.11',
                        '-install_name', startup.LOAD_PATH, str(source), '-o', str(library)], check=True)
        subprocess.run(['codesign', '--force', '--sign', '-', '--timestamp=none', str(library)], check=True)
        subprocess.run(['codesign', '--verify', '--strict', str(library)], check=True)
        source_copy = stage / 'licenses/host-stat-compat.c'
        shutil.copy2(source, source_copy)
        manifest['files'][startup.LIBRARY] = core.sha256(library)
        manifest['files']['licenses/host-stat-compat.c'] = core.sha256(source_copy)
        manifest['host_startup'] = {'kind': startup.KIND, 'library_sha256': core.sha256(library)}
        manifest['host_startup_source'] = {'repository': 'https://github.com/AngelaDMerkel/Lekmod',
                                          'commit': commit, 'sha256': core.sha256(source)}
        manifest['destinations']['host_startup'] = startup.LIBRARY_RELATIVE
        manifest['runtime_validated'] = False
        (stage / 'manifest.json').write_text(json.dumps(manifest, indent=2, sort_keys=True) + '\n')
        files = core.tree_files(stage)
        (stage / 'SHA256SUMS').write_text(''.join(f'{digest}  {name}\n' for name, digest in sorted(files.items()) if name != 'SHA256SUMS'))
        core.verify_package(stage)
        args.output.parent.mkdir(parents=True, exist_ok=True)
        with zipfile.ZipFile(args.output, 'x', compression=zipfile.ZIP_DEFLATED) as archive:
            for name in sorted(core.tree_files(stage)):
                archive.write(stage / name, name)
    print(json.dumps({'archive': str(args.output.resolve()), 'sha256': core.sha256(args.output),
                      'base_sha256': args.sha256, 'host_startup_source_commit': commit}, indent=2))


if __name__ == '__main__':
    main()
