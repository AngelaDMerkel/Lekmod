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
#include <dlfcn.h>
unsigned int GetLastError(void){return 1234;}
int main(int argc,char **argv){
 if(atoi(argv[2])==8){
  typedef int (*LegacyLstat)(const char*,void*);
  LegacyLstat legacy=(LegacyLstat)dlsym(RTLD_NEXT,"lstat");if(!legacy)return 60;
  unsigned char bytes[512]={0};struct stat correct={0};
  if(lstat(argv[3],&correct)||!S_ISREG(correct.st_mode)||legacy(argv[3],bytes))return 61;
  printf("modern-mode=0%o legacy-prefix=",(unsigned)correct.st_mode);
  for(unsigned i=0;i<16;++i)printf("%02x",bytes[i]);printf("\n");
  char target[256];errno=0;
  if(readlink(argv[3],target,sizeof(target))!=-1||errno!=EINVAL)return 62;
  printf("legacy-and-readlink-results-preserved=1\n");return 0;
 }
 if(atoi(argv[2])==7){
  int fd=open(argv[3],O_CREAT|O_EXCL|O_RDWR,0600);if(fd<0)return 50;
  if(write(fd,"probe",5)!=5)return 51;
  const char message[]="unable to open database: simulated\n";
  errno=EDOM;
  if(fwrite(message,1,sizeof(message)-1,stdout)!=sizeof(message)-1||errno!=EDOM)return 52;
  if(fcntl(fd,F_GETFD)<0||write(fd,"tail",4)!=4)return 53;
  if(lseek(fd,0,SEEK_SET)!=0)return 54;
  char bytes[10]={0};if(read(fd,bytes,9)!=9||strcmp(bytes,"probetail"))return 55;
  if(close(fd))return 56;
  if(fwrite(message,1,sizeof(message)-1,stdout)!=sizeof(message)-1)return 57;
  printf("descriptor-results-preserved=1\n");return 0;
 }
 if(atoi(argv[2])==6){
  struct stat status;int fd=open(argv[3],O_CREAT|O_EXCL|O_RDWR,0600);if(fd<0)return 30;
  if(write(fd,"probe",5)!=5||close(fd))return 31;
  if(stat(argv[3],&status)||status.st_size!=5)return 32;
  if(lstat(argv[3],&status)||status.st_size!=5)return 33;
  if(access(argv[3],R_OK|W_OK))return 34;
  errno=0;if(stat(argv[4],&status)!=-1||errno!=ENOENT)return 35;
  errno=0;if(lstat(argv[4],&status)!=-1||errno!=ENOENT)return 36;
  errno=0;if(access(argv[4],F_OK)!=-1||errno!=ENOENT)return 37;
  if(rename(argv[3],argv[4]))return 38;
  errno=0;if(access(argv[3],F_OK)!=-1||errno!=ENOENT)return 39;
  if(unlink(argv[4]))return 40;
  errno=0;if(unlink(argv[4])!=-1||errno!=ENOENT)return 41;
  printf("metadata-results-preserved=1\n");return 0;
 }
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
            self.assertIn("host-file-error value=1234",result.stderr)
            legacy_path=root/"Localization-Legacy.db";legacy_path.write_bytes(b"metadata-only")
            control=subprocess.run([str(probe),"0","8",str(legacy_path)],text=True,capture_output=True,timeout=10)
            result=subprocess.run([str(probe),"0","8",str(legacy_path)],env=environment,text=True,capture_output=True,timeout=10)
            self.assertEqual(control.returncode,0,control.stderr);self.assertEqual(result.returncode,0,result.stderr)
            self.assertEqual(result.stdout,control.stdout)
            self.assertIn("operation=lstat-legacy result=0",result.stderr)
            self.assertIn("localization-legacy-stat",result.stderr)
            self.assertIn("compiled_mode_offset=",result.stderr)
            self.assertIn("operation=readlink result=-1 errno=22",result.stderr)
            self.assertEqual(legacy_path.read_bytes(),b"metadata-only")
            result=subprocess.run([str(probe),"0","7",str(root/"Localization-Live.db")],env=environment,text=True,capture_output=True,timeout=10)
            self.assertEqual(result.returncode,0,result.stderr)
            self.assertEqual(result.stdout,"unable to open database: simulated\nunable to open database: simulated\ndescriptor-results-preserved=1\n")
            live=[line for line in result.stderr.splitlines() if "localization-descriptor stage=database-failure" in line and "Localization-Live.db" in line]
            self.assertEqual(len(live),1,result.stderr)
            self.assertIn("offset=5",live[0]);self.assertIn("open_flags=",live[0])
            self.assertRegex(result.stderr,r"localization-descriptor-scan queried=\d+ unavailable=\d+ matches=1")
            self.assertRegex(result.stderr,r"localization-descriptor-scan queried=\d+ unavailable=\d+ matches=0")
            self.assertEqual((root/"Localization-Live.db").read_bytes(),b"probetail")
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
            result=subprocess.run([str(probe),"0","6",str(root/"Localization-Metadata.db"),
                str(root/"Localization-Renamed.db")],env=environment,text=True,capture_output=True,timeout=10)
            self.assertEqual(result.returncode,0,result.stderr)
            self.assertEqual(result.stdout,"metadata-results-preserved=1\n")
            for operation in ("stat","lstat","access","unlink","rename-from","rename-to"):
                self.assertIn("localization-open operation="+operation,result.stderr)
            for operation in ("stat","lstat","access","unlink"):
                self.assertIn("operation="+operation+" result=-1 errno=2",result.stderr)
            self.assertIn("flags=0x",result.stderr);self.assertIn("thread=",result.stderr);self.assertIn("monotonic=",result.stderr)
            result=subprocess.run([str(probe),"0","5",str(root/"Localization-Stream.db"),
                str(root/"missing/Localization-Stream.db")],env=environment,text=True,capture_output=True,timeout=10)
            self.assertEqual(result.returncode,0,result.stderr)
            self.assertEqual(result.stdout,"stream-results-preserved=1\n")
            self.assertIn("localization-stream-open kind=read",result.stderr)
            self.assertIn("localization-stream-open kind=write",result.stderr)
            self.assertIn("result=0 domain=1 error=2",result.stderr)


    def test_activation_only_control_has_no_interposition_or_flush_timer(self):
        source=Path(__file__).with_name("background-playtest.m")
        with tempfile.TemporaryDirectory(prefix="lekmod-activation-control-") as directory:
            root=Path(directory);library=root/"control.dylib";probe=root/"probe"
            subprocess.run(["clang","-arch","x86_64","-dynamiclib","-framework","AppKit",
                "-framework","Foundation","-DLEKMOD_TEST_ALLOW_FOREGROUND","-DLEKMOD_TEST_ACTIVATION_ONLY",
                str(source),"-o",str(library)],check=True)
            sections=subprocess.check_output(["otool","-l",str(library)],text=True)
            self.assertNotIn("__interpose",sections)
            (root/"probe.c").write_text(r"""
#include <stdio.h>
#include <unistd.h>
#include <sys/stat.h>
#include <dispatch/dispatch.h>
int main(int argc,char **argv){
 FILE *file=fopen(argv[1],"w");if(!file)return 3;
 static char buffer[4096];setvbuf(file,buffer,_IOFBF,sizeof(buffer));
 fputs("Failed to Save database.\n",file);
 dispatch_after(dispatch_time(DISPATCH_TIME_NOW,2200000000LL),dispatch_get_main_queue(),^{
  struct stat status;_exit(stat(argv[1],&status)==0&&status.st_size==0?42:8);
 });
 dispatch_main();
}
""")
            subprocess.run(["clang","-arch","x86_64","-fblocks",str(root/"probe.c"),"-o",str(probe)],check=True)
            logs=root/"Logs";logs.mkdir()
            output=logs/"Localization-Probe.db"
            result=subprocess.run([str(probe),str(output)],env={**os.environ,"DYLD_INSERT_LIBRARIES":str(library)},
                text=True,capture_output=True,timeout=10)
            self.assertEqual(result.returncode,42,result.stderr)
            self.assertEqual(output.stat().st_size,0)
            self.assertIn("activation-only control",result.stderr)
            for observer in ("nonzero-exit","database-failure-write","localization-open","descriptor-state"):
                self.assertNotIn(observer,result.stderr)


if __name__=="__main__":
    unittest.main()
