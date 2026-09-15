#!/usr/bin/env python3
"""The process-only diagnostic must preserve zero/nonzero exit behavior."""
from pathlib import Path
import os
import subprocess
import tempfile
import unittest


class ExitObserverTests(unittest.TestCase):
    def test_real_x86_process_exit_status_and_trace(self):
        source=Path(__file__).with_name("background-playtest.m")
        with tempfile.TemporaryDirectory(prefix="lekmod-exit-test-") as directory:
            root=Path(directory);library=root/"observer.dylib";probe=root/"probe"
            subprocess.run(["clang","-arch","x86_64","-dynamiclib","-framework","AppKit",
                "-framework","Foundation","-DLEKMOD_TEST_ALLOW_FOREGROUND",str(source),"-o",str(library)],check=True)
            (root/"probe.c").write_text("#include <stdlib.h>\nint main(int argc,char **argv){exit(atoi(argv[1]));}\n")
            subprocess.run(["clang","-arch","x86_64",str(root/"probe.c"),"-o",str(probe)],check=True)
            environment={**os.environ,"DYLD_INSERT_LIBRARIES":str(library)}
            for status in (0,42,255):
                with self.subTest(status=status):
                    result=subprocess.run([str(probe),str(status)],env=environment,text=True,capture_output=True,timeout=10)
                    self.assertEqual(result.returncode,status,result.stderr)
                    if status:
                        self.assertIn("nonzero-exit status="+str(status),result.stderr)
                        self.assertIn("probe",result.stderr)
                    else:
                        self.assertNotIn("nonzero-exit",result.stderr)


if __name__=="__main__":
    unittest.main()
