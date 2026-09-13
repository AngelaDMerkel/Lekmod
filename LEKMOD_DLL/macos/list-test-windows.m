#import <AppKit/AppKit.h>
#import <CoreGraphics/CoreGraphics.h>
int main(int argc, const char **argv) {
    @autoreleasepool {
        if (argc == 3 && strcmp(argv[1], "--process-status") == 0) {
            NSRunningApplication *app = [NSRunningApplication runningApplicationWithProcessIdentifier:atoi(argv[2])];
            NSDictionary *status = @{
                @"pid": @(atoi(argv[2])),
                @"registered": @(app != nil),
                @"bundle_id": app.bundleIdentifier ?: [NSNull null],
                @"executable": app.executableURL.path ?: [NSNull null],
                @"activation_policy": app ? @(app.activationPolicy) : [NSNull null],
                @"active": @(app.active),
                @"frontmost_bundle": NSWorkspace.sharedWorkspace.frontmostApplication.bundleIdentifier ?: [NSNull null]
            };
            NSData *data = [NSJSONSerialization dataWithJSONObject:status options:0 error:nil];
            puts([[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding].UTF8String);
            return 0;
        }
        if (argc == 2 && strcmp(argv[1], "--session-status") == 0) {
            CFDictionaryRef rawSession = CGSessionCopyCurrentDictionary();
            NSDictionary *session = (NSDictionary *)rawSession;
            NSDictionary *status = @{
                @"available": @(rawSession != NULL),
                @"locked": session[@"CGSSessionScreenIsLocked"] ?: [NSNull null],
                @"on_console": session[(id)kCGSessionOnConsoleKey] ?: [NSNull null]
            };
            NSData *data = [NSJSONSerialization dataWithJSONObject:status options:0 error:nil];
            puts([[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding].UTF8String);
            if (rawSession) CFRelease(rawSession);
            return 0;
        }
        CFArrayRef raw = CGWindowListCopyWindowInfo(kCGWindowListOptionAll, kCGNullWindowID);
        NSMutableArray* results = [NSMutableArray array];
        for (NSDictionary* item in (NSArray*)raw) {
            NSString* owner = [item[(id)kCGWindowOwnerName] lowercaseString];
            if (![owner containsString:@"steam"] && ![owner containsString:@"civilization"]) continue;
            [results addObject:item];
        }
        NSData* json = [NSJSONSerialization dataWithJSONObject:results options:NSJSONWritingPrettyPrinted error:nil];
        puts([[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding].UTF8String);
        if(raw) CFRelease(raw);
    }
}
