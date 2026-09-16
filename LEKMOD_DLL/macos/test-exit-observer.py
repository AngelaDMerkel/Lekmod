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
            (root/"probe.c").write_text(r"""
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <sys/stat.h>
#include <dispatch/dispatch.h>
int main(int argc,char **argv){
 if(atoi(argv[2])==2){const char text[]="Failed to Save database.\n";fwrite(text,1,sizeof(text)-1,stdout);return 0;}
 if(atoi(argv[2])==3){
  FILE *file=fopen(argv[3],"w");if(!file)return 3;
  static char buffer[4096];setvbuf(file,buffer,_IOFBF,sizeof(buffer));
  fwrite("buffered database bytes",1,23,file);
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW,2200000000LL),dispatch_get_main_queue(),^{
   struct stat status;int ok=stat(argv[3],&status)==0&&status.st_size==0;
   fclose(file);printf("buffer-preserved=%d\n",ok);exit(ok?0:4);
  });
  dispatch_main();
 }
 if(atoi(argv[2]))_exit(atoi(argv[1]));exit(atoi(argv[1]));
}
""")
            subprocess.run(["clang","-arch","x86_64","-fblocks",str(root/"probe.c"),"-o",str(probe)],check=True)
            environment={**os.environ,"DYLD_INSERT_LIBRARIES":str(library)}
            for immediate in (0,1):
                for status in (0,42,255):
                    with self.subTest(status=status,immediate=immediate):
                        result=subprocess.run([str(probe),str(status),str(immediate)],env=environment,text=True,capture_output=True,timeout=10)
                        self.assertEqual(result.returncode,status,result.stderr)
                        if status:
                            self.assertIn("nonzero-exit status="+str(status),result.stderr)
                            self.assertIn("probe",result.stderr)
                        else:
                            self.assertNotIn("nonzero-exit",result.stderr)
            result=subprocess.run([str(probe),"0","2"],env=environment,text=True,capture_output=True,timeout=10)
            self.assertEqual(result.returncode,0)
            self.assertEqual(result.stdout,"Failed to Save database.\n")
            self.assertIn("database-failure-write",result.stderr)
            self.assertIn("descriptor-state stage=database-failure",result.stderr)
            result=subprocess.run([str(probe),"0","3",str(root/"buffered.db")],env=environment,text=True,capture_output=True,timeout=10)
            self.assertEqual(result.returncode,0,result.stderr)
            self.assertEqual(result.stdout,"buffer-preserved=1\n")
            self.assertEqual((root/"buffered.db").read_text(),"buffered database bytes")


if __name__=="__main__":
    unittest.main()
