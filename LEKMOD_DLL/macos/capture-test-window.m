// Capture only a supplied Civ V PID, including an independent background window.
// Never request screen-recording permission, activate apps, or capture a desktop.
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <ScreenCaptureKit/ScreenCaptureKit.h>
#import <ImageIO/ImageIO.h>

int main(int argc, const char **argv) {
    @autoreleasepool {
        if (argc != 3 || atoi(argv[1]) <= 0 || argv[2][0] != '/') {
            fprintf(stderr, "Usage: capture-test-window CIV_PID /absolute/output.png\n");
            return 2;
        }
        // ScreenCaptureKit needs an initialized WindowServer/AppKit connection.
        // No windows or event loop activation are requested by this helper.
        [[NSApplication sharedApplication] setActivationPolicy:NSApplicationActivationPolicyProhibited];
        if (!CGPreflightScreenCaptureAccess()) {
            fprintf(stderr, "Existing screen-capture access unavailable; no prompt requested\n");
            return 3;
        }
        const pid_t targetPID = atoi(argv[1]);
        NSString *output = [NSString stringWithUTF8String:argv[2]];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            fprintf(stderr, "Window capture timed out\n");
            exit(124);
        });
        [SCShareableContent getShareableContentExcludingDesktopWindows:YES onScreenWindowsOnly:NO
            completionHandler:^(SCShareableContent *content, NSError *error) {
            if (error) { fprintf(stderr, "%s\n", error.localizedDescription.UTF8String); exit(4); }
            SCWindow *selected = nil;
            for (SCWindow *window in content.windows) {
                if (window.owningApplication.processID != targetPID || window.frame.size.width <= 100) continue;
                if (![window.owningApplication.applicationName.lowercaseString containsString:@"civilization"]) continue;
                if (!selected || window.frame.size.width * window.frame.size.height >
                    selected.frame.size.width * selected.frame.size.height) selected = window;
            }
            if (!selected) { fprintf(stderr, "No shareable Civ V test window\n"); exit(5); }
            SCContentFilter *filter = [[SCContentFilter alloc] initWithDesktopIndependentWindow:selected];
            SCStreamConfiguration *config = [SCStreamConfiguration new];
            config.width = (size_t)(selected.frame.size.width * 2);
            config.height = (size_t)(selected.frame.size.height * 2);
            config.showsCursor = NO;
            [SCScreenshotManager captureImageWithFilter:filter configuration:config
                completionHandler:^(CGImageRef captured, NSError *captureError) {
                if (!captured || captureError) {
                    fprintf(stderr, "Capture failed: %s\n", captureError.localizedDescription.UTF8String);
                    exit(6);
                }
                CGImageDestinationRef dest = CGImageDestinationCreateWithURL(
                    (__bridge CFURLRef)[NSURL fileURLWithPath:output], CFSTR("public.png"), 1, NULL);
                if (!dest) exit(7);
                CGImageDestinationAddImage(dest, captured, NULL);
                BOOL saved = CGImageDestinationFinalize(dest);
                CFRelease(dest);
                exit(saved ? 0 : 8);
            }];
        }];
        dispatch_main();
    }
}
