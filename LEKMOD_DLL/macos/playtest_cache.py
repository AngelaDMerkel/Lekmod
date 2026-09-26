"""Preserve startup cache evidence before managed stock restoration invalidates it."""
import hashlib
import json
from pathlib import Path
import shutil


def preserve_cache(cache: Path, output: Path, game_pids):
    """Copy regular files without repair/removal; require the game to be closed."""
    if game_pids():
        raise RuntimeError('Cache preservation requires Civ V closed')
    if cache.is_symlink():
        raise RuntimeError('Refusing a symbolic-link cache directory')
    output.mkdir(parents=True, exist_ok=False)
    files = output / 'files'
    files.mkdir()
    result = {'source': str(cache), 'source_exists': cache.exists(), 'files': {}, 'skipped': {}}
    for source in sorted(cache.iterdir()) if cache.exists() else []:
        if source.is_symlink() or not source.is_file():
            result['skipped'][source.name] = 'symlink or non-regular entry'
            continue
        before = source.read_bytes()
        digest = hashlib.sha256(before).hexdigest()
        target = files / source.name
        shutil.copy2(source, target)
        if hashlib.sha256(target.read_bytes()).hexdigest() != digest or source.read_bytes() != before:
            raise RuntimeError('Cache changed during preservation: ' + source.name)
        result['files'][source.name] = {'size': len(before), 'sha256': digest}
    (output / 'manifest.json').write_text(json.dumps(result, indent=2) + '\n')
    return result
