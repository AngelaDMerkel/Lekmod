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
#include <fcntl.h>
#include <errno.h>
#include <string.h>
#include <CoreFoundation/CoreFoundation.h>
int main(int argc,char **argv){
 if(atoi(argv[2])==5){
  CFURLRef url=CFURLCreateFromFileSystemRepresentation(NULL,(const UInt8*)argv[3],strlen(argv[3]),false);
  CFWriteStreamRef writer=CFWriteStreamCreateWithFile(NULL,url);
  if(!writer||!CFWriteStreamOpen(writer)||CFWriteStreamWrite(writer,(const UInt8*)"probe",5)!=5)return 20;
  CFWriteStreamClose(writer);CFRelease(writer);
  CFReadStreamRef reader=CFReadStreamCreateWithFile(NULL,url);char bytes[6]={0};
  if(!reader||!CFReadStreamOpen(reader)||CFReadStreamRead(reader,(UInt8*)bytes,5)!=5||strcmp(bytes,"probe"))return 21;
  CFReadStreamClose(reader);CFRelease(reader);CFRelease(url);
  url=CFURLCreateFromFileSystemRepresentation(NULL,(const UInt8*)argv[4],strlen(argv[4]),false);
  reader=CFReadStreamCreateWithFile(NULL,url);if(CFReadStreamOpen(reader))return 22;
  CFStreamError error=CFReadStreamGetError(reader);if(error.domain!=kCFStreamErrorDomainPOSIX||error.error!=ENOENT)return 23;
  CFReadStreamClose(reader);CFRelease(reader);
  writer=CFWriteStreamCreateWithFile(NULL,url);if(CFWriteStreamOpen(writer))return 24;
  error=CFWriteStreamGetError(writer);if(error.domain!=kCFStreamErrorDomainPOSIX||error.error!=ENOENT)return 25;
  CFWriteStreamClose(writer);CFRelease(writer);CFRelease(url);
  printf("stream-results-preserved=1\n");return 0;
 }
 if(atoi(argv[2])==4){
  int fd=open(argv[3],O_CREAT|O_EXCL|O_RDWR,0600);if(fd<0)return 10;
  if(write(fd,"probe",5)!=5)return 11;close(fd);
  fd=openat(AT_FDCWD,argv[3],O_RDONLY);if(fd<0)return 12;
  char bytes[6]={0};if(read(fd,bytes,5)!=5||strcmp(bytes,"probe"))return 13;close(fd);
  FILE *file=fopen(argv[3],"r");if(!file)return 14;fclose(file);
  errno=0;fd=open(argv[4],O_RDONLY);if(fd!=-1||errno!=ENOENT)return 15;
  errno=0;fd=openat(AT_FDCWD,argv[4],O_RDONLY);if(fd!=-1||errno!=ENOENT)return 16;
  errno=0;file=fopen(argv[4],"r");if(file||errno!=ENOENT)return 17;
  printf("open-results-preserved=1\n");return 0;
 }
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
            subprocess.run(["clang","-arch","x86_64","-fblocks","-framework","CoreFoundation",str(root/"probe.c"),"-o",str(probe)],check=True)
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
            result=subprocess.run([str(probe),"0","4",str(root/"Localization-Probe.db"),
                str(root/"Localization-Missing.db")],env=environment,text=True,capture_output=True,timeout=10)
            self.assertEqual(result.returncode,0,result.stderr)
            self.assertEqual(result.stdout,"open-results-preserved=1\n")
            for operation in ("open","openat","fopen"):
                self.assertIn("localization-open operation="+operation,result.stderr)
                self.assertIn("operation="+operation+" result=-1 errno=2",result.stderr)
            result=subprocess.run([str(probe),"0","5",str(root/"Localization-Stream.db"),
                str(root/"missing/Localization-Stream.db")],env=environment,text=True,capture_output=True,timeout=10)
            self.assertEqual(result.returncode,0,result.stderr)
            self.assertEqual(result.stdout,"stream-results-preserved=1\n")
            self.assertIn("localization-stream-open kind=read",result.stderr)
            self.assertIn("localization-stream-open kind=write",result.stderr)
            self.assertIn("result=0 domain=1 error=2",result.stderr)


if __name__=="__main__":
    unittest.main()
