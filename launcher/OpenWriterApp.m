#import <Cocoa/Cocoa.h>
#import <signal.h>

@interface OpenWriterAppDelegate : NSObject <NSApplicationDelegate>
@property(nonatomic, strong) NSWindow *window;
@property(nonatomic, strong) NSTextField *statusLabel;
@property(nonatomic, strong) NSButton *openButton;
@property(nonatomic) NSInteger servicePort;
@property(nonatomic, copy) NSString *serviceArtifact;
@end

@implementation OpenWriterAppDelegate

- (void)installMenu {
    NSMenu *menuBar = [[NSMenu alloc] init];
    NSMenuItem *appItem = [[NSMenuItem alloc] initWithTitle:@"OpenWriter Mac" action:nil keyEquivalent:@""];
    NSMenu *appMenu = [[NSMenu alloc] init];
    [appMenu addItemWithTitle:@"About OpenWriter Mac" action:@selector(orderFrontStandardAboutPanel:) keyEquivalent:@""];
    NSMenuItem *openItem = [appMenu addItemWithTitle:@"Open OpenWriter" action:@selector(openWriter:) keyEquivalent:@"o"];
    openItem.target = self;
    NSMenuItem *updateItem = [appMenu addItemWithTitle:@"Check for Updates…" action:@selector(checkForUpdates:) keyEquivalent:@""];
    updateItem.target = self;
    [appMenu addItem:[NSMenuItem separatorItem]];
    [appMenu addItemWithTitle:@"Quit OpenWriter Mac" action:@selector(terminate:) keyEquivalent:@"q"];
    appItem.submenu = appMenu;
    [menuBar addItem:appItem];
    [NSApp setMainMenu:menuBar];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    [self installMenu];
    NSString *port = NSProcessInfo.processInfo.environment[@"OPENWRITER_PORT"];
    if (!port.length) port = [NSBundle.mainBundle objectForInfoDictionaryKey:@"OpenWriterPort"];
    NSInteger requestedPort = port.integerValue;
    self.servicePort = requestedPort >= 1 && requestedPort <= 65535 ? requestedPort : 5050;

    NSString *stampPath = [NSBundle.mainBundle.resourcePath stringByAppendingPathComponent:@"openwriter/dist/build-info.json"];
    NSData *stampData = [NSData dataWithContentsOfFile:stampPath];
    NSDictionary *stamp = stampData ? [NSJSONSerialization JSONObjectWithData:stampData options:0 error:nil] : nil;
    self.serviceArtifact = [stamp[@"artifact"] isKindOfClass:NSString.class] ? stamp[@"artifact"] : @"";

    self.window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 480, 205)
                                           styleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable)
                                             backing:NSBackingStoreBuffered defer:NO];
    self.window.title = @"OpenWriter Mac";
    [self.window center];
    NSView *content = self.window.contentView;

    NSTextField *heading = [NSTextField labelWithString:@"OpenWriter Mac"];
    heading.font = [NSFont boldSystemFontOfSize:23];
    heading.frame = NSMakeRect(28, 143, 420, 32);
    [content addSubview:heading];

    self.statusLabel = [NSTextField wrappingLabelWithString:@"Starting your local writing space…"];
    self.statusLabel.font = [NSFont systemFontOfSize:14];
    self.statusLabel.frame = NSMakeRect(28, 78, 420, 55);
    [content addSubview:self.statusLabel];

    self.openButton = [NSButton buttonWithTitle:@"Open OpenWriter" target:self action:@selector(openWriter:)];
    self.openButton.frame = NSMakeRect(28, 25, 155, 32);
    self.openButton.bezelStyle = NSBezelStyleRounded;
    self.openButton.enabled = NO;
    [content addSubview:self.openButton];

    [self.window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{ [self startServiceAndOpenBrowser]; });
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)visible {
    if (!visible) [self.window makeKeyAndOrderFront:nil];
    return YES;
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    // The browser uses this local service. Quit stops only the process launched
    // from this exact app path; a developer's separate OpenWriter stays alone.
    [self stopStaleServiceForCurrentBundleIfSafe];
}

- (NSDictionary *)serviceStatus {
    NSString *url = [NSString stringWithFormat:@"http://127.0.0.1:%ld/__build.json", (long)self.servicePort];
    NSTask *task = [[NSTask alloc] init];
    NSPipe *output = [NSPipe pipe];
    task.executableURL = [NSURL fileURLWithPath:@"/usr/bin/curl"];
    task.arguments = @[@"-fsS", @"--max-time", @"1", url];
    task.standardOutput = output;
    task.standardError = [NSFileHandle fileHandleWithNullDevice];
    @try {
        [task launch];
        [task waitUntilExit];
        if (task.terminationStatus != 0) return nil;
        NSData *data = [output.fileHandleForReading readDataToEndOfFile];
        id value = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        return [value isKindOfClass:NSDictionary.class] ? value : nil;
    } @catch (NSException *exception) { return nil; }
}

- (BOOL)isServiceHealthy {
    if (!self.serviceArtifact.length) return NO;
    NSDictionary *status = [self serviceStatus];
    NSString *artifact = [status[@"artifact"] isKindOfClass:NSString.class] ? status[@"artifact"] : nil;
    return [artifact isEqualToString:self.serviceArtifact];
}

- (void)stopStaleServiceForCurrentBundleIfSafe {
    NSTask *task = [[NSTask alloc] init];
    NSPipe *output = [NSPipe pipe];
    task.executableURL = [NSURL fileURLWithPath:@"/usr/sbin/lsof"];
    task.arguments = @[[NSString stringWithFormat:@"-tiTCP:%ld", (long)self.servicePort], @"-sTCP:LISTEN"];
    task.standardOutput = output;
    task.standardError = [NSFileHandle fileHandleWithNullDevice];
    @try { [task launch]; [task waitUntilExit]; } @catch (NSException *exception) { return; }
    NSString *pids = [[NSString alloc] initWithData:[output.fileHandleForReading readDataToEndOfFile] encoding:NSUTF8StringEncoding] ?: @"";
    for (NSString *line in [pids componentsSeparatedByCharactersInSet:NSCharacterSet.newlineCharacterSet]) {
        pid_t pid = (pid_t)line.integerValue;
        if (pid <= 0) continue;
        NSTask *ps = [[NSTask alloc] init];
        NSPipe *commandOutput = [NSPipe pipe];
        ps.executableURL = [NSURL fileURLWithPath:@"/bin/ps"];
        ps.arguments = @[@"-p", [NSString stringWithFormat:@"%d", pid], @"-o", @"command="];
        ps.standardOutput = commandOutput;
        ps.standardError = [NSFileHandle fileHandleWithNullDevice];
        @try { [ps launch]; [ps waitUntilExit]; } @catch (NSException *exception) { continue; }
        NSString *command = [[NSString alloc] initWithData:[commandOutput.fileHandleForReading readDataToEndOfFile] encoding:NSUTF8StringEncoding] ?: @"";
        if ([command containsString:NSBundle.mainBundle.bundlePath] && [command containsString:@"/Contents/Resources/openwriter/dist/bin/pad.js"]) {
            kill(pid, SIGTERM);
        }
    }
}

- (NSString *)shellQuote:(NSString *)value {
    return [NSString stringWithFormat:@"'%@'", [value stringByReplacingOccurrencesOfString:@"'" withString:@"'\"'\"'"]];
}

- (void)startServiceAndOpenBrowser {
    if (![self isServiceHealthy]) {
        [self stopStaleServiceForCurrentBundleIfSafe];
        NSString *resources = NSBundle.mainBundle.resourcePath;
        NSString *node = [resources stringByAppendingPathComponent:@"runtime/node"];
        NSString *entry = [resources stringByAppendingPathComponent:@"openwriter/dist/bin/pad.js"];
        if (![[NSFileManager defaultManager] isExecutableFileAtPath:node] || ![[NSFileManager defaultManager] fileExistsAtPath:entry]) {
            [self showError:@"The bundled OpenWriter service is missing. Download the app again from GitHub Releases."];
            return;
        }
        NSString *script = [NSString stringWithFormat:@"/bin/mkdir -p \"$HOME/Library/Logs\"; nohup %@ %@ --no-open --port %ld </dev/null >\"$HOME/Library/Logs/OpenWriter-launcher.log\" 2>&1 &", [self shellQuote:node], [self shellQuote:entry], (long)self.servicePort];
        NSTask *task = [[NSTask alloc] init];
        task.executableURL = [NSURL fileURLWithPath:@"/bin/zsh"];
        task.arguments = @[@"-lc", script];
        task.standardOutput = [NSFileHandle fileHandleWithNullDevice];
        task.standardError = [NSFileHandle fileHandleWithNullDevice];
        @try { [task launch]; [task waitUntilExit]; } @catch (NSException *exception) { }
    }
    for (NSInteger attempt = 0; attempt < 75; attempt++) {
        if ([self isServiceHealthy]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.statusLabel.stringValue = @"OpenWriter is ready in your browser. This app keeps it running in the background.";
                self.openButton.enabled = YES;
                [self openWriter:nil];
            });
            return;
        }
        usleep(200000);
    }
    [self showError:@"OpenWriter could not start. Another version may already be using its local port. See ~/Library/Logs/OpenWriter-launcher.log for details."];
}

- (void)showError:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{ self.statusLabel.stringValue = message; });
}

- (void)openWriter:(id)sender {
    if (![self isServiceHealthy]) return;
    NSString *url = [NSString stringWithFormat:@"http://127.0.0.1:%ld/", (long)self.servicePort];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
}

- (void)checkForUpdates:(id)sender {
    NSURL *apiURL = [NSURL URLWithString:@"https://api.github.com/repos/iviaxpow3r/openwriter-mac-launcher/releases/latest"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:apiURL];
    [request setValue:@"OpenWriter-Mac-Launcher" forHTTPHeaderField:@"User-Agent"];
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        id body = (!error && data) ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
        NSDictionary *release = [body isKindOfClass:NSDictionary.class] ? body : nil;
        NSString *tag = [release[@"tag_name"] isKindOfClass:NSString.class] ? release[@"tag_name"] : nil;
        NSString *latest = [tag hasPrefix:@"v"] ? [tag substringFromIndex:1] : tag;
        NSString *current = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"0";
        BOOL available = latest.length && [latest compare:current options:NSNumericSearch] == NSOrderedDescending;
        dispatch_async(dispatch_get_main_queue(), ^{
            NSAlert *alert = [[NSAlert alloc] init];
            if (!latest.length) {
                alert.messageText = @"Could not check for updates";
                alert.informativeText = @"Open GitHub Releases to check manually.";
                [alert addButtonWithTitle:@"Open Releases"];
                [alert addButtonWithTitle:@"Cancel"];
            } else if (available) {
                alert.messageText = [NSString stringWithFormat:@"OpenWriter Mac %@ is available", latest];
                alert.informativeText = [NSString stringWithFormat:@"You have %@. Download the new DMG, drag the app into Applications, and choose Replace. Your writing remains in ~/.openwriter.", current];
                [alert addButtonWithTitle:@"Open Download Page"];
                [alert addButtonWithTitle:@"Later"];
            } else {
                alert.messageText = @"OpenWriter Mac is up to date";
                alert.informativeText = [NSString stringWithFormat:@"You have version %@.", current];
                [alert addButtonWithTitle:@"OK"];
            }
            if ([alert runModal] == NSAlertFirstButtonReturn && (!latest.length || available)) {
                [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/iviaxpow3r/openwriter-mac-launcher/releases/latest"]];
            }
        });
    }] resume];
}

@end

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        NSApplication *application = [NSApplication sharedApplication];
        [application setActivationPolicy:NSApplicationActivationPolicyRegular];
        static OpenWriterAppDelegate *delegate;
        delegate = [[OpenWriterAppDelegate alloc] init];
        application.delegate = delegate;
        [application run];
    }
    return 0;
}
