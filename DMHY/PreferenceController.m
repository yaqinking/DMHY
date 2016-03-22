//
//  PreferenceController.m
//  DMHY
//
//  Created by 小笠原やきん on 9/16/15.
//  Copyright © 2015 yaqinking. All rights reserved.
//

#import "PreferenceController.h"
#import "ViewPreferenceController.h"
#import "SitePreferenceController.h"
#import "DMHYAPI.h"
#include <Carbon/Carbon.h>

@interface PreferenceController ()
@property (weak) IBOutlet NSMatrix *downloadLinkTypeMatrix;
@property (weak) IBOutlet NSTextField *savePathLabel;
@property (weak) IBOutlet NSTextField *fileWatchPathLabel;

@property (weak) IBOutlet NSTextField *fetchIntervalTextField;
@property (weak) IBOutlet NSMatrix *downloadSiteMatrix;
@property (weak) IBOutlet NSTextField *fileWatchIntervalTextField;

@end

@implementation PreferenceController

- (instancetype)init {
    return [super initWithNibName:@"Preference" bundle:nil];
}

- (NSString *)identifier
{
    return @"GeneralPreferences";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:NSImageNamePreferencesGeneral];
}

- (NSString *)toolbarItemLabel
{
    return @"常用";
}



- (void)viewDidLoad {
    [super viewDidLoad];
    [self configurePreference];
}

- (void)configurePreference {
    NSInteger idx = [PreferenceController preferenceDownloadLinkType];
    [self.downloadLinkTypeMatrix selectCellAtRow:idx column:0];
    NSURL *url = [PreferenceController preferenceSavePath];
    self.savePathLabel.stringValue = [url path];
    //Todo bug
//    self.fileWatchPathLabel.stringValue = [[PreferenceController fileWatchPath] path];
    NSURL *fileWatchPath = [PreferenceController fileWatchPath];
    if (fileWatchPath) {
        self.fileWatchPathLabel.stringValue = fileWatchPath.path;
    } else {
        self.fileWatchPathLabel.stringValue = @"请设置文件查看路径 <_<";
    }
    NSInteger seconds = [PreferenceController preferenceFetchInterval];
    NSInteger minutes = seconds / 60;
    self.fetchIntervalTextField.stringValue = [NSString stringWithFormat:@"%li", (long)minutes];
    NSInteger fileWatchInterval = [PreferenceController fileWatchInterval];
    self.fileWatchIntervalTextField.stringValue = [NSString stringWithFormat:@"%li", (fileWatchInterval/60)];
}

- (IBAction)downloadLinkTypeChanged:(id)sender {
    //这里仅有 0 1 这两中，直接偷懒（毕竟 YES = 1 NO = 0）
    NSInteger linkType = [self.downloadLinkTypeMatrix selectedRow];
    [PreferenceController setPreferenceDownloadLinkType:linkType];
    [DMHYNotification postNotificationName:DMHYDownloadLinkTypeNotification];
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
    [DMHYNotification postNotificationName:DMHYSavePathChangedNotification];
}

- (IBAction)changeFileWatchPath:(id)sender {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.canChooseFiles       = NO;
    openPanel.canChooseDirectories = YES;
    openPanel.prompt               = @"OK";
    if ([openPanel runModal] == NSModalResponseOK) {
        NSURL *url = [openPanel URL];
        [PreferenceController setFileWatchPath:url];
        self.fileWatchPathLabel.stringValue = [[openPanel URL] path];
    }
    [DMHYNotification postNotificationName:DMHYFileWatchPathChangedNotification];
}

- (IBAction)changeFetchInterval:(id)sender {
    NSInteger minitues = self.fetchIntervalTextField.integerValue;
    if (minitues < 1 || minitues > 720) {
        self.fetchIntervalTextField.integerValue = [PreferenceController preferenceFetchInterval]/60;
        return;
    }
    NSInteger seconds = minitues * 60;
    [PreferenceController setPreferenceFetchInterval:seconds];
    [DMHYNotification postNotificationName:DMHYFetchIntervalChangedNotification];
}

- (IBAction)changeFileWatchInterval:(id)sender {
    NSInteger minitues = self.fileWatchIntervalTextField.integerValue;
    if (minitues < 1 || minitues > 720 ) {
        self.fileWatchIntervalTextField.integerValue = [PreferenceController fileWatchInterval]/60;
        return;
    }
    NSInteger seconds = minitues * 60;
    [PreferenceController setFileWatchInterval:seconds];
    [DMHYNotification postNotificationName:DMHYFileWatchIntervalChangedNotification];
}

#pragma mark - Setup

+ (void)setupDefaultPreference {
    NSURL *savePath = [PreferenceController preferenceSavePath];
    if (savePath == nil) {
        [PreferenceController setPreferenceDownloadLinkType:NO];
        [PreferenceController setPreferenceSavePath:[self userDownloadPath]];
        [PreferenceController setPreferenceFetchInterval:kFetchIntervalMinimum];
        // And Other PreferenceViewController default value
        [ViewPreferenceController setViewPreferenceTableViewRowStyle:2];
        [SitePreferenceController setupDefaultSites];
    }
    //For has v0.9.2.1 version installed check
    NSInteger fetchInterval = [PreferenceController preferenceFetchInterval];
    NSLog(@"%li",(long)fetchInterval);
    if (fetchInterval < kFetchIntervalMinimum) {
        [PreferenceController setPreferenceFetchInterval:kFetchIntervalMinimum];
        NSLog(@"Set FetchInterval to default %i minitues.",kFetchIntervalMinimum);
    }
    //For has 1.3 version
    
    NSInteger fileWatchInterval = [PreferenceController fileWatchInterval];
    if (fileWatchInterval < kFileWatchIntervalMinimum) {
        [PreferenceController setFileWatchInterval:kFileWatchIntervalMinimum];
        NSLog(@"Set File Watch Interval To Default %i s", kFileWatchIntervalMinimum);
    }
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

+ (void)setPreferenceSavePath:(NSURL *)path {
    NSUserDefaults *userDefautls = [NSUserDefaults standardUserDefaults];
    [userDefautls setURL:path forKey:kSavePath];
    [userDefautls synchronize];
}

+ (NSURL *)preferenceSavePath {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults URLForKey:kSavePath];
}

+ (void)setFileWatchPath:(NSURL *)url {
    NSData *data = [url bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope includingResourceValuesForKeys:nil relativeToURL:nil error:nil];
    NSUserDefaults *userDefautls = [NSUserDefaults standardUserDefaults];
    [userDefautls setObject:data forKey:kFileWatchPath];
    [userDefautls synchronize];
    [DMHYNotification postNotificationName:DMHYFileWatchPathChangedNotification];
}

+ (NSURL *)fileWatchPath {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSData *filePathData = [userDefaults objectForKey:kFileWatchPath];
    BOOL bookmarkISStable = NO;
    NSURL *fileWatchPath = [NSURL URLByResolvingBookmarkData:filePathData options:NSURLBookmarkResolutionWithSecurityScope relativeToURL:nil bookmarkDataIsStale:&bookmarkISStable error:nil];
    return fileWatchPath;
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

+ (void)setFileWatchInterval:(NSInteger)seconds {
    NSUserDefaults *userDefautls = [NSUserDefaults standardUserDefaults];
    if (seconds < kFileWatchIntervalMinimum || seconds > kFileWatchIntervalMaximum) {
        //Not allowed set to default
        [userDefautls setInteger:kFileWatchIntervalMinimum forKey:kFileWatchInterval];
        [userDefautls synchronize];
    }
    [userDefautls setInteger:seconds forKey:kFileWatchInterval];
    [userDefautls synchronize];
    NSLog(@"Set File Watch Interval to %li seconds.",(long)seconds);
}

+ (NSInteger)fileWatchInterval {
    return [[NSUserDefaults standardUserDefaults] integerForKey:kFileWatchInterval];
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
