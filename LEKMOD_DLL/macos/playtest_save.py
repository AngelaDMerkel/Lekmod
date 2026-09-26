"""Read-only writer checks and verified checkpoint handoff for asynchronous saves."""
import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time


def game_save_writer_open(pid, path):
    if not isinstance(pid, int) or pid <= 0:
        raise RuntimeError('Native game PID is required for save verification')
    os.kill(pid, 0)  # An exited/uninspectable process is not proof of a completed save.
    result = subprocess.run(['/usr/sbin/lsof', '-n', '-P', '-a', '-p', str(pid),
                             '-Ffa', '--', str(path)], capture_output=True, text=True)
    if result.returncode not in (0, 1) or result.stderr.strip():
        raise RuntimeError('Cannot verify game save descriptors: ' + result.stderr.strip())
    if result.returncode == 1 and result.stdout.strip():
        raise RuntimeError('Ambiguous game save descriptor result')
    return any(line in ('aw', 'au') for line in result.stdout.splitlines())


def signature(path):
    s = path.stat()
    return (s.st_dev, s.st_ino, s.st_size, s.st_mtime_ns, s.st_ctime_ns)


class CheckpointCopier:
    def __init__(self, writer_open, settle_seconds=2.0, clock=time.monotonic):
        self.writer_open = writer_open
        self.settle_seconds = settle_seconds
        self.clock = clock
        self.observed = {}

    def copy_if_ready(self, source, target):
        if source.is_symlink():
            raise ValueError('Refusing a symbolic-link checkpoint source')
        if not source.is_file() or not source.stat().st_size:
            return None
        if self.writer_open(source):
            self.observed.pop(source, None)
            return None
        current = signature(source)
        previous, since = self.observed.get(source, (None, self.clock()))
        if previous != current:
            since = self.clock()
            self.observed[source] = (current, since)
        if self.clock() - since < self.settle_seconds:
            return None
        if target.exists() or target.is_symlink():
            raise ValueError('Refusing checkpoint overwrite')
        target.parent.mkdir(exist_ok=True)
        with tempfile.NamedTemporaryFile(dir=target.parent, prefix=target.name+'.candidate-', suffix='.partial', delete=False) as stream:
            candidate = Path(stream.name)
        shutil.copy2(source, candidate)
        digest = hashlib.sha256(candidate.read_bytes()).hexdigest()
        stable = (signature(source) == current and not self.writer_open(source) and
                  hashlib.sha256(source.read_bytes()).hexdigest() == digest and
                  signature(source) == current)
        if not stable:
            # Keep the rejected bytes for diagnosis; never offer them as a loadable save.
            self.observed.pop(source, None)
            return None
        candidate.replace(target)
        self.observed.pop(source, None)
        return {'size': current[2], 'sha256': digest, 'writer_closed': True,
                'stable_seconds_required': self.settle_seconds, 'source_copy_match': True}
