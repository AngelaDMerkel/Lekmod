// Test-process-only AppKit adapter. The game may render, but cannot activate
// itself or raise its windows above the user's applications. No system-wide
// hooks and no persistent application/library modifications are made.
#import <AppKit/AppKit.h>
#import <objc/runtime.h>
#import <dispatch/dispatch.h>
#include <execinfo.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <libproc.h>
#include <sys/resource.h>
#include <stdarg.h>
#include <pthread.h>
#include <dlfcn.h>
#include <sys/stat.h>
#include <time.h>
#include <stddef.h>

typedef unsigned int (*HostLastErrorFunction)(void);
static HostLastErrorFunction hostLastError = NULL;

static pthread_mutex_t localizationStreamMutex = PTHREAD_MUTEX_INITIALIZER;
static const void *localizationStreams[128];
static void rememberLocalizationStream(const void *stream, CFURLRef url, const char *kind) {
    int savedErrno = errno;
    unsigned char path[PATH_MAX];
    if (stream && CFURLGetFileSystemRepresentation(url, true, path, sizeof(path)) &&
        strstr((const char *)path, "Localization")) {
        pthread_mutex_lock(&localizationStreamMutex);
        for (unsigned i = 0; i < 128; ++i) if (!localizationStreams[i]) { localizationStreams[i] = stream; break; }
        pthread_mutex_unlock(&localizationStreamMutex);
        fprintf(stderr, "[LEKMOD_TEST] localization-stream-create kind=%s stream=%p path=%s\n", kind, stream, path);
    }
    errno = savedErrno;
}
static bool localizationStreamKnown(const void *stream, bool remove) {
    bool found = false;
    pthread_mutex_lock(&localizationStreamMutex);
    for (unsigned i = 0; i < 128; ++i) if (localizationStreams[i] == stream) {
        found = true; if (remove) localizationStreams[i] = NULL;
    }
    pthread_mutex_unlock(&localizationStreamMutex);
    return found;
}
static CFReadStreamRef observedReadStreamCreate(CFAllocatorRef allocator, CFURLRef url) {
    CFReadStreamRef stream = CFReadStreamCreateWithFile(allocator, url);
    rememberLocalizationStream(stream, url, "read"); return stream;
}
static CFWriteStreamRef observedWriteStreamCreate(CFAllocatorRef allocator, CFURLRef url) {
    CFWriteStreamRef stream = CFWriteStreamCreateWithFile(allocator, url);
    rememberLocalizationStream(stream, url, "write"); return stream;
}
static Boolean observedReadStreamOpen(CFReadStreamRef stream) {
    Boolean result = CFReadStreamOpen(stream); int savedErrno = errno;
    if (localizationStreamKnown(stream, false)) {
        CFStreamError error = CFReadStreamGetError(stream);
        fprintf(stderr, "[LEKMOD_TEST] localization-stream-open kind=read stream=%p result=%d domain=%ld error=%d\n",
                stream, result, error.domain, (int)error.error);
    }
    errno = savedErrno; return result;
}
static Boolean observedWriteStreamOpen(CFWriteStreamRef stream) {
    Boolean result = CFWriteStreamOpen(stream); int savedErrno = errno;
    if (localizationStreamKnown(stream, false)) {
        CFStreamError error = CFWriteStreamGetError(stream);
        fprintf(stderr, "[LEKMOD_TEST] localization-stream-open kind=write stream=%p result=%d domain=%ld error=%d\n",
                stream, result, error.domain, (int)error.error);
    }
    errno = savedErrno; return result;
}
static void observedReadStreamClose(CFReadStreamRef stream) {
    CFReadStreamClose(stream); int savedErrno = errno;
    localizationStreamKnown(stream, true); errno = savedErrno;
}
static void observedWriteStreamClose(CFWriteStreamRef stream) {
    CFWriteStreamClose(stream); int savedErrno = errno;
    localizationStreamKnown(stream, true); errno = savedErrno;
}

static void recordLocalizationOpen(const char *operation, const char *path, int result, int error, int flags) {
    // Observe only localization paths, including an untranslated emulated path.
    // Preserve the syscall result/errno and never retry or change access flags.
    if (path && strstr(path, "Localization")) {
        struct timespec when = {0, 0}; uint64_t thread = 0;
        clock_gettime(CLOCK_MONOTONIC, &when); pthread_threadid_np(NULL, &thread);
        fprintf(stderr, "[LEKMOD_TEST] localization-open operation=%s result=%d errno=%d path=%s flags=0x%x thread=%llu monotonic=%lld.%09ld\n",
                operation, result, result < 0 ? error : 0, path, flags,
                (unsigned long long)thread, (long long)when.tv_sec, when.tv_nsec);
    }
    errno = error;
}
static int observedOpen(const char *path, int flags, ...) {
    int result;
    if (flags & O_CREAT) {
        va_list args; va_start(args, flags); int mode = va_arg(args, int); va_end(args);
        result = open(path, flags, mode);
    } else result = open(path, flags);
    int error = errno;
    recordLocalizationOpen("open", path, result, error, flags);
    return result;
}
static int observedOpenat(int directory, const char *path, int flags, ...) {
    int result;
    if (flags & O_CREAT) {
        va_list args; va_start(args, flags); int mode = va_arg(args, int); va_end(args);
        result = openat(directory, path, flags, mode);
    } else result = openat(directory, path, flags);
    int error = errno;
    recordLocalizationOpen("openat", path, result, error, flags);
    return result;
}
static FILE *observedFopen(const char *path, const char *mode) {
    FILE *result = fopen(path, mode);
    int error = errno;
    recordLocalizationOpen("fopen", path, result ? fileno(result) : -1, error, 0);
    return result;
}

// Observe the game's own metadata/removal calls; never issue an extra operation,
// retry a failure, alter access flags, or change the result/errno seen by callers.
static int observedStat(const char *path, struct stat *status) {
    int result = stat(path, status); int error = errno;
    recordLocalizationOpen("stat", path, result, error, 0); return result;
}
static int observedLstat(const char *path, struct stat *status) {
    int result = lstat(path, status); int error = errno;
    recordLocalizationOpen("lstat", path, result, error, 0); return result;
}
// The host resolves the unversioned lstat symbol dynamically. Keep that ABI
// distinct from the SDK's lstat$INODE64 alias and preserve its original bytes.
extern int nativeLegacyLstat(const char *path, void *status) __asm__("_lstat");
static int observedLegacyLstat(const char *path, void *status) {
    int result = nativeLegacyLstat(path, status); int error = errno;
    recordLocalizationOpen("lstat-legacy", path, result, error, 0);
    if (result == 0 && status && path && strstr(path, "Localization")) {
        char prefix[33];
        for (unsigned i = 0; i < 16; ++i)
            snprintf(prefix + 2 * i, 3, "%02x", ((const unsigned char *)status)[i]);
        mode_t interpretedMode = 0;
        memcpy(&interpretedMode, (const char *)status + offsetof(struct stat, st_mode), sizeof(interpretedMode));
        fprintf(stderr, "[LEKMOD_TEST] localization-legacy-stat path=%s prefix16=%s compiled_mode_offset=%zu interpreted_mode=0%o caller=%p\n",
                path, prefix, offsetof(struct stat, st_mode), (unsigned)interpretedMode, __builtin_return_address(0));
        static int mergedTraceRecorded = 0;
        if (strstr(path, "Localization-Merged.db") && __sync_bool_compare_and_swap(&mergedTraceRecorded, 0, 1)) {
            void *frames[12]; int depth = backtrace(frames, 12);
            fprintf(stderr, "[LEKMOD_TEST] localization-legacy-callstack frames=%d\n", depth);
            backtrace_symbols_fd(frames, depth, STDERR_FILENO);
        }
    }
    errno = error; return result;
}
static ssize_t observedReadlink(const char *path, char *buffer, size_t length) {
    ssize_t result = readlink(path, buffer, length); int error = errno;
    recordLocalizationOpen("readlink", path, (int)result, error, 0);
    if (result < 0 && path && strstr(path, "Localization")) {
        fprintf(stderr, "[LEKMOD_TEST] localization-readlink-failure path=%s errno=%d caller=%p\n",
                path, error, __builtin_return_address(0));
    }
    errno = error; return result;
}
static int observedAccess(const char *path, int mode) {
    int result = access(path, mode); int error = errno;
    recordLocalizationOpen("access", path, result, error, mode); return result;
}
static int observedUnlink(const char *path) {
    int result = unlink(path); int error = errno;
    recordLocalizationOpen("unlink", path, result, error, 0); return result;
}
static int observedRename(const char *oldPath, const char *newPath) {
    int result = rename(oldPath, newPath); int error = errno;
    recordLocalizationOpen("rename-from", oldPath, result, error, 0);
    recordLocalizationOpen("rename-to", newPath, result, error, 0); return result;
}

static void recordDescriptorState(const char *stage) {
    int savedErrno = errno;
    struct rlimit limit = {0, 0};
    int limitStatus = getrlimit(RLIMIT_NOFILE, &limit);
    struct proc_fdinfo descriptors[4096];
    int bytes = proc_pidinfo(getpid(), PROC_PIDLISTFDS, 0, descriptors, sizeof(descriptors));
    fprintf(stderr, "[LEKMOD_TEST] descriptor-state stage=%s limit_status=%d soft=%llu hard=%llu open=%d truncated=%d\n",
            stage, limitStatus, (unsigned long long)limit.rlim_cur, (unsigned long long)limit.rlim_max,
            bytes > 0 ? bytes / (int)sizeof(struct proc_fdinfo) : -1, bytes == sizeof(descriptors));
    if (strcmp(stage, "database-failure") == 0 && bytes > 0) {
        // Read only this process's current vnode descriptors at the error.
        // No opens, closes, flushes, access changes or retries are introduced.
        int count = bytes / (int)sizeof(struct proc_fdinfo);
        if (count > 4096) count = 4096;
        int queried = 0, unavailable = 0, matches = 0;
        for (int i = 0; i < count; ++i) {
            if (descriptors[i].proc_fdtype != PROX_FDTYPE_VNODE) continue;
            struct vnode_fdinfowithpath info = {0};
            ++queried;
            int size = proc_pidfdinfo(getpid(), descriptors[i].proc_fd,
                                     PROC_PIDFDVNODEPATHINFO, &info, sizeof(info));
            if (size != sizeof(info)) { ++unavailable; continue; }
            info.pvip.vip_path[sizeof(info.pvip.vip_path) - 1] = 0;
            if (strstr(info.pvip.vip_path, "Localization")) {
                ++matches;
                fprintf(stderr, "[LEKMOD_TEST] localization-descriptor stage=%s fd=%d open_flags=0x%x offset=%lld path=%s\n",
                        stage, descriptors[i].proc_fd, info.pfi.fi_openflags,
                        (long long)info.pfi.fi_offset, info.pvip.vip_path);
            }
        }
        fprintf(stderr, "[LEKMOD_TEST] localization-descriptor-scan queried=%d unavailable=%d matches=%d\n",
                queried, unavailable, matches);
    }
    errno = savedErrno;
}

static void flushLoggingStream(FILE *stream) {
    // Never flush game databases or other buffered data streams. Only live
    // diagnostic logs need early visibility to the bounded test supervisor.
    int savedErrno = errno;
    char path[PATH_MAX] = {0};
    int fd = fileno(stream);
    if (stream == stdout || stream == stderr ||
        (fd >= 0 && fcntl(fd, F_GETPATH, path) == 0 && strstr(path, "/Logs/")))
        fflush(stream);
    errno = savedErrno;
}

static void observeDatabaseLogWrite(const void *bytes, size_t length) {
    // Retain the caller while it reports a cache failure, before startup
    // unwinds to _exit. Never alter the bytes or consume a database error.
    if (length == 0 || length > 4096) return;
    const char *messages[] = { "Failed to Save database.", "Failed to Load database.",
                              "unable to open database:" };
    for (unsigned message = 0; message < 3; ++message) {
        size_t count = strlen(messages[message]);
        if (length < count) continue;
        for (size_t offset = 0; offset <= length - count; ++offset) {
            if (memcmp((const char *)bytes + offset, messages[message], count) == 0) {
                int savedErrno = errno;
                if (hostLastError) fprintf(stderr, "[LEKMOD_TEST] host-file-error value=%u\n", hostLastError());
                void *frames[48];
                int depth = backtrace(frames, 48);
                recordDescriptorState("database-failure");
                fprintf(stderr, "[LEKMOD_TEST] database-failure-write frames=%d\n", depth);
                backtrace_symbols_fd(frames, depth, STDERR_FILENO);
                errno = savedErrno;
                return;
            }
        }
    }
}
static size_t observedFwrite(const void *bytes, size_t size, size_t count, FILE *stream) {
    size_t result = fwrite(bytes, size, count, stream);
    if (size && result && result <= SIZE_MAX / size) observeDatabaseLogWrite(bytes, size * result);
    if (result) flushLoggingStream(stream);
    return result;
}
static ssize_t observedWrite(int fd, const void *bytes, size_t length) {
    ssize_t result = write(fd, bytes, length);
    if (result > 0) observeDatabaseLogWrite(bytes, (size_t)result);
    return result;
}
static int observedSetrlimit(int resource, const struct rlimit *limit) {
    int result = setrlimit(resource, limit);
    int savedErrno = errno;
    if (resource == RLIMIT_NOFILE) {
        fprintf(stderr, "[LEKMOD_TEST] setrlimit-nofile result=%d errno=%d\n", result, savedErrno);
        recordDescriptorState("setrlimit");
    }
    errno = savedErrno;
    return result;
}

// Preserve the exit status while retaining the call site of startup-only
// failures such as 255, which need not create an OS crash report. dyld leaves
// calls from the interposing image itself bound to the original exit function.
static void recordExit(const char *path, int status) {
    if (status != 0) {
        void *frames[64];
        int count = backtrace(frames, 64);
        fprintf(stderr, "[LEKMOD_TEST] nonzero-exit status=%d path=%s frames=%d\n", status, path, count);
        fflush(stderr);
        backtrace_symbols_fd(frames, count, STDERR_FILENO);
    }
}
__attribute__((noreturn)) static void observedExit(int status) { recordExit("exit", status); exit(status); }
__attribute__((noreturn)) static void observedImmediateExit(int status) { recordExit("_exit", status); _exit(status); }
#ifndef LEKMOD_TEST_ACTIVATION_ONLY
__attribute__((used)) static const struct {
    const void *replacement;
    const void *original;
} exitObserver[] __attribute__((section("__DATA,__interpose"))) = {
    { (const void *)&observedExit, (const void *)&exit },
    { (const void *)&observedImmediateExit, (const void *)&_exit },
    { (const void *)&observedFwrite, (const void *)&fwrite },
    { (const void *)&observedWrite, (const void *)&write },
    { (const void *)&observedSetrlimit, (const void *)&setrlimit },
    { (const void *)&observedOpen, (const void *)&open },
    { (const void *)&observedOpenat, (const void *)&openat },
    { (const void *)&observedFopen, (const void *)&fopen },
    { (const void *)&observedStat, (const void *)&stat },
    { (const void *)&observedLstat, (const void *)&lstat },
    { (const void *)&observedLegacyLstat, (const void *)&nativeLegacyLstat },
    { (const void *)&observedReadlink, (const void *)&readlink },
    { (const void *)&observedAccess, (const void *)&access },
    { (const void *)&observedUnlink, (const void *)&unlink },
    { (const void *)&observedRename, (const void *)&rename },
    { (const void *)&observedReadStreamCreate, (const void *)&CFReadStreamCreateWithFile },
    { (const void *)&observedWriteStreamCreate, (const void *)&CFWriteStreamCreateWithFile },
    { (const void *)&observedReadStreamOpen, (const void *)&CFReadStreamOpen },
    { (const void *)&observedWriteStreamOpen, (const void *)&CFWriteStreamOpen },
    { (const void *)&observedReadStreamClose, (const void *)&CFReadStreamClose },
    { (const void *)&observedWriteStreamClose, (const void *)&CFWriteStreamClose }
};

#endif // LEKMOD_TEST_ACTIVATION_ONLY

static void noActivate(id self, SEL command, BOOL flag) {}
static BOOL noRunningActivate(id self, SEL command, NSApplicationActivationOptions options) { return NO; }
static BOOL (*originalPolicy)(id, SEL, NSApplicationActivationPolicy);
static BOOL backgroundPolicy(id self, SEL command, NSApplicationActivationPolicy policy) {
    return originalPolicy(self, command, NSApplicationActivationPolicyProhibited);
}
static void behind(id self, SEL command, id sender) { [self orderBack:nil]; }
static void behindRegardless(id self, SEL command) { [self orderBack:nil]; }
static void replace(Class cls, SEL selector, IMP implementation) {
    Method method = class_getInstanceMethod(cls, selector);
    if (method) method_setImplementation(method, implementation);
}

__attribute__((constructor)) static void keepGameInBackground(void) {
    @autoreleasepool {
#ifndef LEKMOD_TEST_ALLOW_FOREGROUND
        replace([NSApplication class], @selector(activateIgnoringOtherApps:), (IMP)noActivate);
        replace([NSRunningApplication class], @selector(activateWithOptions:), (IMP)noRunningActivate);
        Method policy = class_getInstanceMethod([NSApplication class], @selector(setActivationPolicy:));
        originalPolicy = (void *)method_getImplementation(policy);
        method_setImplementation(policy, (IMP)backgroundPolicy);
        replace([NSWindow class], @selector(makeKeyAndOrderFront:), (IMP)behind);
        replace([NSWindow class], @selector(orderFront:), (IMP)behind);
        replace([NSWindow class], @selector(orderFrontRegardless), (IMP)behindRegardless);
        [[NSApplication sharedApplication] setActivationPolicy:NSApplicationActivationPolicyProhibited];
#endif
#ifndef LEKMOD_TEST_ACTIVATION_ONLY
        hostLastError = (HostLastErrorFunction)dlsym(RTLD_DEFAULT, "GetLastError");
        recordDescriptorState("startup");
        // Lua/engine file logs are flushed individually after their writes.
        // Keep only standard output streams on the timer; never fflush(NULL).
        static dispatch_source_t logFlushTimer;
        logFlushTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
        dispatch_source_set_timer(logFlushTimer, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC),
                                  NSEC_PER_SEC, NSEC_PER_SEC / 10);
        dispatch_source_set_event_handler(logFlushTimer, ^{ fflush(stdout); fflush(stderr); });
        dispatch_resume(logFlushTimer);
#else
        fprintf(stderr, "[LEKMOD_TEST] activation-only control; syscall/stream observers and log-flush timer disabled\n");
#endif
#ifdef LEKMOD_TEST_ALLOW_FOREGROUND
        fprintf(stderr, "[LEKMOD_TEST] explicitly approved foreground attachment test; log flushing only\n");
#else
        fprintf(stderr, "[LEKMOD_TEST] background activation guard installed\n");
#endif
    }
}
