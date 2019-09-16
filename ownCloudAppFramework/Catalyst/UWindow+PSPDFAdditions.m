// From: https://gist.github.com/steipete/30c33740bf0ebc34a0da897cba52fefe

#import "UIWindow+PSPDFAdditions.h"

@implementation UIWindow (PSPDFAdditions)

#if TARGET_OS_UIKITFORMAC

- (id)nsWindow {
    // This is public AppKit API and should be safe to use.
    NSArray *const nsWindows = [NSClassFromString(@"NSApplication") valueForKeyPath:@"sharedApplication.windows"];
    for (id nsWindow in nsWindows) {
        NSArray<UIWindow *> *uiWindows;
        @try {
            /*
               NSWindow hosts one or multiple UIWindows.
               (e.g. your app window + the text selection window).
               Accessing uiWindow returns nil, uiWindows works.
               We use private API here, so try/catch is a good idea.
             */
            uiWindows = [nsWindow valueForKey:@"uiWindows"];
        } @catch (NSException *exception) {
            NSLog(@"Failed to fetch window: %@", exception);
        }
        for (id uiWindow in uiWindows) {
            if (uiWindow == self) {  // Pointer equality is fine
                return nsWindow;
            }
        }
    }
    return (id)nil;
}

#endif

@end
