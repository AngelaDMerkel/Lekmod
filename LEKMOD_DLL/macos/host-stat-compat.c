// Experimental process-local correction for the pinned Aspyr host's SQLite
// lstat ABI mismatch. Unrelated callers keep the legacy ABI. No host code writes.
#include <sys/stat.h>
#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include <errno.h>
#include <stdio.h>
#include <execinfo.h>
#include <mach-o/dyld.h>
#include <mach-o/loader.h>
#include <pthread.h>

_Static_assert(sizeof(struct stat) == 144, "requires verified Darwin stat ABI");
_Static_assert(offsetof(struct stat, st_mode) == 4, "requires INODE64 mode layout");
extern int legacy_lstat_original(const char *, void *) __asm__("_lstat");
static const uintptr_t wrapper_return = 0x1b9e60, sqlite_return = 0x1e1000;
static const unsigned char host_uuid[16] = {0x0c,0x91,0xa3,0xde,0x65,0xcb,0x31,0x22,0x89,0xf3,0xd0,0xae,0x89,0x6c,0x83,0x95};
static const unsigned char wrapper_bytes[] = {0x89,0xc3,0xf6,0x45,0xe0,0x01,0x74,0x09};
static const unsigned char mode_bytes[] = {0x0f,0xb7,0x85,0x14,0xff,0xff,0xff,0x25,0x00,0xf0,0x00,0x00,0x3d,0x00,0xa0,0x00,0x00};
static bool validated_host(const unsigned char *base) {
    if (!base) return false;
    const struct mach_header_64 *h = (const struct mach_header_64 *)base;
    if (h->magic != MH_MAGIC_64 || h->cputype != CPU_TYPE_X86_64 ||
        h->ncmds > 128 || h->sizeofcmds > 65536) return false;
    const unsigned char *p = base + sizeof(*h), *end = p + h->sizeofcmds;
    bool uuid = false, text = false;
    for (uint32_t n = 0; n < h->ncmds; ++n) {
        if ((size_t)(end-p) < sizeof(struct load_command)) return false;
        const struct load_command *lc = (const struct load_command *)p;
        if (lc->cmdsize < sizeof(*lc) || lc->cmdsize > (size_t)(end-p)) return false;
        if (lc->cmd == LC_UUID && lc->cmdsize >= sizeof(struct uuid_command))
            uuid = memcmp(((const struct uuid_command *)p)->uuid, host_uuid, 16) == 0;
        if (lc->cmd == LC_SEGMENT_64 && lc->cmdsize >= sizeof(struct segment_command_64)) {
            const struct segment_command_64 *seg = (const struct segment_command_64 *)p;
            if (strncmp(seg->segname,"__TEXT",16)==0)
                text = seg->vmaddr == 0x100000000ULL && seg->fileoff == 0 &&
                       seg->vmsize > 0x1e1020 + sizeof(mode_bytes) &&
                       seg->filesize > 0x1e1020 + sizeof(mode_bytes);
        }
        p += lc->cmdsize;
    }
    return uuid && text &&
        memcmp(base+wrapper_return,wrapper_bytes,sizeof(wrapper_bytes))==0 &&
        memcmp(base+0x1e1020,mode_bytes,sizeof(mode_bytes))==0;
}
static bool matched_frames(void *const *frames, int count, uintptr_t base, bool verified) {
    if (!verified) return false;
    for (int i=0;i+1<count;++i)
        if ((uintptr_t)frames[i] == base+wrapper_return &&
            (uintptr_t)frames[i+1] == base+sqlite_return) return true;
    return false;
}
static int stat_dispatch(const char *path, void *status, bool correct) {
    return correct ? lstat(path,(struct stat *)status) : legacy_lstat_original(path,status);
}
static pthread_once_t once = PTHREAD_ONCE_INIT;
static uintptr_t image_base;
static bool image_verified;
static void inspect_main_image(void) {
    image_base=(uintptr_t)_dyld_get_image_header(0);
    image_verified=validated_host((const unsigned char *)image_base);
}
#ifndef LEKMOD_HOST_STAT_NO_INTERPOSE
__attribute__((noinline)) static int corrected_legacy_lstat(const char *path, void *status) {
    int incoming=errno;
    pthread_once(&once,inspect_main_image);
    bool correct=false;
    if (image_verified && (uintptr_t)__builtin_return_address(0)==image_base+wrapper_return) {
        void *frames[16];int count=backtrace(frames,16);
        correct=matched_frames(frames,count,image_base,image_verified);
    }
    errno=incoming;
    int result=stat_dispatch(path,status,correct), saved=errno;
    if (correct && path && strstr(path,"Localization"))
        fprintf(stderr,"[LEKMOD_HOST_STAT] corrected sqlite lstat result=%d errno=%d path=%s\n",result,result<0?saved:0,path);
    errno=saved;return result;
}
__attribute__((used)) static const struct {const void *replacement,*original;} interpose[]
__attribute__((section("__DATA,__interpose"))) = {
    {(const void *)&corrected_legacy_lstat,(const void *)&legacy_lstat_original}
};
#endif
