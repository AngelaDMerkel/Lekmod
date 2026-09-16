// Test-process-only AppKit adapter. The game may render, but cannot activate
// itself or raise its windows above the user's applications. No system-wide
// hooks and no persistent application/library modifications are made.
#import <AppKit/AppKit.h>
#import <objc/runtime.h>
#import <dispatch/dispatch.h>
#include <execinfo.h>
#include <stdlib.h>
#include <unistd.h>

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
    { (const void *)&observedImmediateExit, (const void *)&_exit }
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
        // Native Lua logs otherwise stay in 4 KiB stdio buffers and disappear
        // when a hung test must be terminated. Only the test process is affected.
        static dispatch_source_t logFlushTimer;
        logFlushTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
        dispatch_source_set_timer(logFlushTimer, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC),
                                  NSEC_PER_SEC, NSEC_PER_SEC / 10);
        dispatch_source_set_event_handler(logFlushTimer, ^{ fflush(NULL); });
        dispatch_resume(logFlushTimer);
#ifdef LEKMOD_TEST_ALLOW_FOREGROUND
        fprintf(stderr, "[LEKMOD_TEST] explicitly approved foreground attachment test; log flushing only\n");
#else
        fprintf(stderr, "[LEKMOD_TEST] background activation guard installed\n");
#endif
    }
}
