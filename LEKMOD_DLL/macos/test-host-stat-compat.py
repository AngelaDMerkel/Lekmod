#!/usr/bin/env python3
"""Real x86 ABI/errno controls and fail-closed host/call-site matching."""
from pathlib import Path
import subprocess,tempfile,unittest,os
class HostStatTests(unittest.TestCase):
 def test_host_guards_and_native_abi_dispatch(self):
  source=Path(__file__).with_name('host-stat-compat.c').resolve()
  with tempfile.TemporaryDirectory(prefix='lekmod-stat-guard-')as d:
   p=Path(d);program=p/'probe.c';binary=p/'probe'
   program.write_text('#define LEKMOD_HOST_STAT_NO_INTERPOSE\n#include "'+str(source)+'"\n'+r'''
#include <stdlib.h>
#include <unistd.h>
#include <assert.h>
int main(int argc,char **argv){
 unsigned char *image=calloc(1,0x200000);assert(image);
 struct mach_header_64 *h=(void*)image;h->magic=MH_MAGIC_64;h->cputype=CPU_TYPE_X86_64;h->ncmds=2;
 struct segment_command_64 *seg=(void*)(image+sizeof(*h));seg->cmd=LC_SEGMENT_64;seg->cmdsize=sizeof(*seg);strcpy(seg->segname,"__TEXT");seg->vmaddr=0x100000000ULL;seg->filesize=seg->vmsize=0x200000;
 struct uuid_command *u=(void*)(seg+1);u->cmd=LC_UUID;u->cmdsize=sizeof(*u);memcpy(u->uuid,host_uuid,16);h->sizeofcmds=sizeof(*seg)+sizeof(*u);
 memcpy(image+wrapper_return,wrapper_bytes,sizeof(wrapper_bytes));memcpy(image+0x1e1020,mode_bytes,sizeof(mode_bytes));assert(validated_host(image));
 u->uuid[0]^=1;assert(!validated_host(image));u->uuid[0]^=1;
 image[0x1e1023]^=1;assert(!validated_host(image));image[0x1e1023]^=1;
 seg->vmsize=0x1000;assert(!validated_host(image));seg->vmsize=0x200000;
 h->cputype=CPU_TYPE_ARM64;assert(!validated_host(image));h->cputype=CPU_TYPE_X86_64;
 u->cmdsize=0;assert(!validated_host(image));u->cmdsize=sizeof(*u);
 void *frames[]={(void*)17,(void*)(0x100000000ULL+wrapper_return),(void*)(0x100000000ULL+sqlite_return)};
 assert(matched_frames(frames,3,0x100000000ULL,true));assert(!matched_frames(frames,3,0x100000000ULL,false));assert(!matched_frames(frames,2,0x100000000ULL,true));assert(!matched_frames(frames,3,0x110000000ULL,true));
 frames[2]=(void*)44;assert(!matched_frames(frames,3,0x100000000ULL,true));
 assert(!validated_host((const unsigned char*)_dyld_get_image_header(0)));
 unsigned char expected[512]={0},actual[512]={0};errno=EDOM;int a=legacy_lstat_original(argv[1],expected),ea=errno;errno=EDOM;int b=stat_dispatch(argv[1],actual,false),eb=errno;assert(a==b&&ea==eb&&!memcmp(expected,actual,sizeof(actual)));
 struct stat reference={0},fixed={0};assert(lstat(argv[1],&reference)==0);errno=EDOM;assert(stat_dispatch(argv[1],&fixed,true)==0&&errno==EDOM);assert(S_ISREG(fixed.st_mode)&&!memcmp(&reference,&fixed,sizeof(fixed)));
 assert(symlink(argv[1],argv[2])==0);assert(stat_dispatch(argv[2],&fixed,true)==0&&S_ISLNK(fixed.st_mode));
 errno=0;assert(stat_dispatch(argv[3],&fixed,true)==-1&&errno==ENOENT);errno=0;assert(stat_dispatch(argv[3],actual,false)==-1&&errno==ENOENT);
 free(image);puts("host-guards/legacy-pass-through/current-layout/symlink/errno=PASS");return 0;
}
''')
   subprocess.run(['clang','-arch','x86_64',str(program),'-o',str(binary)],check=True)
   file=p/'regular';file.write_bytes(b'unchanged')
   result=subprocess.run([str(binary),str(file),str(p/'link'),str(p/'missing')],capture_output=True,text=True)
   self.assertEqual(result.returncode,0,result.stderr);self.assertIn('=PASS',result.stdout);self.assertEqual(file.read_bytes(),b'unchanged')
   library=p/'corrector.dylib'
   subprocess.run(['clang','-arch','x86_64','-dynamiclib',str(source),'-o',str(library)],check=True)
   (p/'link').unlink()
   injected=subprocess.run([str(binary),str(file),str(p/'link'),str(p/'missing')],env={**os.environ,'DYLD_INSERT_LIBRARIES':str(library)},capture_output=True,text=True)
   self.assertEqual(injected.returncode,0,injected.stderr);self.assertEqual(injected.stdout,result.stdout)
   self.assertNotIn('[LEKMOD_HOST_STAT]',injected.stderr);self.assertEqual(file.read_bytes(),b'unchanged')

if __name__=='__main__':unittest.main()
