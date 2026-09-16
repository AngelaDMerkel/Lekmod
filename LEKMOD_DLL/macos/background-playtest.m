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

static void recordDescriptorState(const char *stage) {
    int savedErrno = errno;
    struct rlimit limit = {0, 0};
    int limitStatus = getrlimit(RLIMIT_NOFILE, &limit);
    struct proc_fdinfo descriptors[4096];
    int bytes = proc_pidinfo(getpid(), PROC_PIDLISTFDS, 0, descriptors, sizeof(descriptors));
    fprintf(stderr, "[LEKMOD_TEST] descriptor-state stage=%s limit_status=%d soft=%llu hard=%llu open=%d truncated=%d\n",
            stage, limitStatus, (unsigned long long)limit.rlim_cur, (unsigned long long)limit.rlim_max,
            bytes > 0 ? bytes / (int)sizeof(struct proc_fdinfo) : -1, bytes == sizeof(descriptors));
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
__attribute__((used)) static const struct {
    const void *replacement;
    const void *original;
} exitObserver[] __attribute__((section("__DATA,__interpose"))) = {
    { (const void *)&observedExit, (const void *)&exit },
    { (const void *)&observedImmediateExit, (const void *)&_exit },
    { (const void *)&observedFwrite, (const void *)&fwrite },
    { (const void *)&observedWrite, (const void *)&write },
    { (const void *)&observedSetrlimit, (const void *)&setrlimit }
};

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
        recordDescriptorState("startup");
        // Lua/engine file logs are flushed individually after their writes.
        // Keep only standard output streams on the timer; never fflush(NULL).
        static dispatch_source_t logFlushTimer;
        logFlushTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
        dispatch_source_set_timer(logFlushTimer, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC),
                                  NSEC_PER_SEC, NSEC_PER_SEC / 10);
        dispatch_source_set_event_handler(logFlushTimer, ^{ fflush(stdout); fflush(stderr); });
        dispatch_resume(logFlushTimer);
#ifdef LEKMOD_TEST_ALLOW_FOREGROUND
        fprintf(stderr, "[LEKMOD_TEST] explicitly approved foreground attachment test; log flushing only\n");
#else
        fprintf(stderr, "[LEKMOD_TEST] background activation guard installed\n");
#endif
    }
}
