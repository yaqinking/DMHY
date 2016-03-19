//
//  PreferenceController.m
//  DMHY
//
//  Created by 小笠原やきん on 9/16/15.
//  Copyright © 2015 yaqinking. All rights reserved.
//

#import "PreferenceController.h"
#import "DMHYAPI.h"
#include <Carbon/Carbon.h>

@interface PreferenceController ()
@property (weak) IBOutlet NSMatrix *downloadLinkTypeMatrix;
@property (weak) IBOutlet NSTextField *savePathLabel;
@property (weak) IBOutlet NSTextField *fetchIntervalTextField;
@property (weak) IBOutlet NSMatrix *downloadSiteMatrix;

@end

@implementation PreferenceController

- (instancetype)init {
    self = [super initWithWindowNibName:@"Preference"];
    if (self) {
//        [self.window makeKeyAndOrderFront:self];
    }
    return self;
}

#pragma mark - NSWindowDelegate

- (void)windowDidBecomeKey:(NSNotification *)notification {
    NSLog(@"windowDidBecomeKey");
}

- (void)windowDidBecomeMain:(NSNotification *)notification {
    NSLog(@"windowDidBecomeMain");
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    [self configurePreference];
}

- (void)configurePreference {
    NSInteger idx = [PreferenceController preferenceDownloadLinkType];
    [self.downloadLinkTypeMatrix selectCellAtRow:idx column:0];
    
    NSInteger siteIdx = [PreferenceController preferenceDownloadSite];
    [self.downloadSiteMatrix selectCellAtRow:siteIdx column:0];
    
    NSURL *url = [PreferenceController preferenceSavePath];
    self.savePathLabel.stringValue = [url path];
    
    NSInteger seconds = [PreferenceController preferenceFetchInterval];
    NSInteger minutes = seconds / 60;
    self.fetchIntervalTextField.stringValue = [NSString stringWithFormat:@"%li", (long)minutes];
}

- (IBAction)downloadLinkTypeChanged:(id)sender {
    //这里仅有 0 1 这两中，直接偷懒（毕竟 YES = 1 NO = 0）
    NSInteger linkType = [self.downloadLinkTypeMatrix selectedRow];
    [PreferenceController setPreferenceDownloadLinkType:linkType];
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    NSDictionary *dict = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:linkType] forKey:kDownloadLinkType];
    [notificationCenter postNotificationName:DMHYDownloadLinkTypeNotification object:self userInfo:dict];
}
- (IBAction)downloadSiteChanged:(id)sender {
    NSInteger site = [self.downloadSiteMatrix selectedRow];
    [PreferenceController setPreferenceDownloadSite:site];
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    NSDictionary *dict = [NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:site] forKey:kDownloadSite];
    [notificationCenter postNotificationName:DMHYDownloadSiteChangedNotification object:self userInfo:dict];
    
}

- (IBAction)changeSavePath:(id)sender {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.canChooseFiles       = NO;
    openPanel.canChooseDirectories = YES;
    openPanel.prompt               = @"OK";
    if ([openPanel runModal] == NSModalResponseOK) {
        [PreferenceController setPreferenceSavePath:[openPanel URL]];
        self.savePathLabel.stringValue = [[openPanel URL] path];
    }
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter postNotificationName:DMHYSavePathChangedNotification object:self];
}

- (IBAction)changeFetchInterval:(id)sender {
    NSInteger minitues = self.fetchIntervalTextField.integerValue;
    NSInteger seconds = minitues * 60;
    [PreferenceController setPreferenceFetchInterval:seconds];
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter postNotificationName:DMHYFetchIntervalChangedNotification object:self];
}


#pragma mark - Setup

+ (void)setupDefaultPreference {
    NSURL *savePath = [PreferenceController preferenceSavePath];
    if (savePath == nil) {
        [PreferenceController setPreferenceDownloadLinkType:NO];
        [PreferenceController setPreferenceSavePath:[self userDownloadPath]];
        [PreferenceController setPreferenceFetchInterval:kFetchIntervalMinimum];
    }
    //For has v0.9.2.1 version installed check
    NSInteger fetchInterval = [PreferenceController preferenceFetchInterval];
    NSLog(@"%li",(long)fetchInterval);
    if (fetchInterval < kFetchIntervalMinimum) {
        [PreferenceController setPreferenceFetchInterval:kFetchIntervalMinimum];
        NSLog(@"Set FetchInterval to default %i minitues.",kFetchIntervalMinimum);
    }
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"NSConstraintBasedLayoutVisualizeMutuallyExclusiveConstraints"];
}

+ (NSURL *)userDownloadPath {
    NSURL *downloadDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDownloadsDirectory
                                                                         inDomain:NSUserDomainMask
                                                                appropriateForURL:nil
                                                                           create:NO
                                                                            error:nil];
    return downloadDirectoryURL;
}


+ (void)setPreferenceDownloadLinkType:(BOOL)type {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:type forKey:kDownloadLinkType];
    [userDefaults synchronize];
}

+ (BOOL)preferenceDownloadLinkType {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults boolForKey:kDownloadLinkType];
}

+ (void)setPreferenceDownloadSite:(NSInteger)site {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:site forKey:kDownloadSite];
    [userDefaults synchronize];
}

+ (NSInteger)preferenceDownloadSite {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults integerForKey:kDownloadSite];
}

+ (void)setPreferenceSavePath:(NSURL *)path {
    NSUserDefaults *userDefautls = [NSUserDefaults standardUserDefaults];
    [userDefautls setURL:path forKey:kSavePath];
    [userDefautls synchronize];
}

+ (NSURL *)preferenceSavePath {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults URLForKey:kSavePath];
}

+ (void)setPreferenceFetchInterval:(NSInteger)seconds {
    NSUserDefaults *userDefautls = [NSUserDefaults standardUserDefaults];
    if (seconds < kFetchIntervalMinimum || seconds > kFetchIntervalMaximun) {
        //Not allowed set to default
        [userDefautls setInteger:kFetchIntervalMinimum forKey:kFetchInterval];
        [userDefautls synchronize];
    }
    [userDefautls setInteger:seconds forKey:kFetchInterval];
    [userDefautls synchronize];
    NSLog(@"Set Fetch Interval to %li seconds.",(long)seconds);
}

+ (NSInteger)preferenceFetchInterval {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults integerForKey:kFetchInterval];
}

+ (void)setPreferenceTheme:(NSInteger)themeCode {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    switch (themeCode) {
        case DMHYThemeLight:
            [userDefaults setInteger:DMHYThemeLight forKey:DMHYThemeKey];
            break;
        case DMHYThemeDark:
            [userDefaults setInteger:DMHYThemeDark forKey:DMHYThemeKey];
            break;
        default:
            [userDefaults setInteger:DMHYThemeLight forKey:DMHYThemeKey];
            break;
    }
    [userDefaults synchronize];
}

+ (NSInteger)preferenceTheme {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults integerForKey:DMHYThemeKey];
}
@end
