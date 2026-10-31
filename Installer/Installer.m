// Copyright (c) 2026 James Marculewicz. See ../LICENSE.
#import <Cocoa/Cocoa.h>

@interface InstallerDelegate : NSObject <NSApplicationDelegate>
@property NSWindow *window;
@end
@implementation InstallerDelegate
- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    self.window=[[NSWindow alloc] initWithContentRect:NSMakeRect(0,0,500,230)
        styleMask:NSWindowStyleMaskTitled|NSWindowStyleMaskClosable backing:NSBackingStoreBuffered defer:NO];
    self.window.title=@"Install SaveHollywood 2.7.1";
    NSTextField *label=[NSTextField wrappingLabelWithString:@"Play your videos as a screen saver.\n\nInstalls SaveHollywood for your user account. An existing copy is backed up beside it. Your settings are preserved.\n\nOriginal software by Stephane Sudre / WhiteBox."];
    label.frame=NSMakeRect(25,75,450,130); [self.window.contentView addSubview:label];
    NSButton *button=[NSButton buttonWithTitle:@"Install Screensaver" target:self action:@selector(install:)];
    button.frame=NSMakeRect(285,25,190,32); [self.window.contentView addSubview:button];
    [self.window center]; [self.window makeKeyAndOrderFront:nil]; [NSApp activateIgnoringOtherApps:YES];
}
- (void)install:(id)sender {
    NSFileManager *fm=NSFileManager.defaultManager; NSError *error=nil;
    NSURL *source=[NSBundle.mainBundle URLForResource:@"SaveHollywood" withExtension:@"saver"];
    NSURL *library=[fm URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask].firstObject;
    NSURL *folder=[library URLByAppendingPathComponent:@"Screen Savers" isDirectory:YES];
    NSURL *destination=[folder URLByAppendingPathComponent:@"SaveHollywood.saver" isDirectory:YES];
    NSURL *backup=[folder URLByAppendingPathComponent:[NSString stringWithFormat:@"SaveHollywood-backup-%@.saver",NSUUID.UUID.UUIDString]];
    NSURL *stage=[folder URLByAppendingPathComponent:[NSString stringWithFormat:@".SaveHollywood-%@.saver",NSUUID.UUID.UUIDString]];
    BOOL backedUp=NO;
    BOOL ok=source && [fm createDirectoryAtURL:folder withIntermediateDirectories:YES attributes:nil error:&error];
    if (ok) ok=[fm copyItemAtURL:source toURL:stage error:&error];
    if (ok && [fm fileExistsAtPath:destination.path]) {
        ok=[fm moveItemAtURL:destination toURL:backup error:&error]; backedUp=ok;
    }
    if (ok) ok=[fm moveItemAtURL:stage toURL:destination error:&error];
    if (!ok) {
        if (backedUp) [fm moveItemAtURL:backup toURL:destination error:NULL];
        [fm removeItemAtURL:stage error:NULL];
    }
    BOOL modernSettings=[NSProcessInfo.processInfo isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){26,0,0}];
    NSString *instructions=modernSettings?@"Open System Settings → Wallpaper → Screen Saver, choose Custom, and select SaveHollywood under Other. Close and reopen System Settings if the previous version is cached. Older backup copies can be removed after testing.":@"Select SaveHollywood in System Settings → Screen Saver. Close and reopen System Settings if the previous version is cached. Older backup copies can be removed after testing.";
    NSAlert *alert=[NSAlert new]; alert.messageText=ok?@"SaveHollywood installed":@"Installation failed";
    alert.informativeText=ok?instructions:(error.localizedDescription?:@"The screen saver could not be copied.");
    [alert runModal];
    if (ok) {
        NSString *settingsURL=modernSettings?@"x-apple.systempreferences:com.apple.Wallpaper-Settings.extension":@"x-apple.systempreferences:com.apple.ScreenSaver-Settings.extension";
        [NSWorkspace.sharedWorkspace openURL:[NSURL URLWithString:settingsURL]];
    }
}
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender { return YES; }
@end
int main(void) { @autoreleasepool {
    NSApplication *app=NSApplication.sharedApplication;
    InstallerDelegate *delegate=[InstallerDelegate new]; app.delegate=delegate;
    [app setActivationPolicy:NSApplicationActivationPolicyRegular]; [app run];
} return 0; }
