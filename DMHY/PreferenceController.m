//
//  PreferenceController.m
//  DMHY
//
//  Created by 小笠原やきん on 9/16/15.
//  Copyright © 2015 yaqinking. All rights reserved.
//

#import "PreferenceController.h"

#import "DMHYAPI.h"

@interface PreferenceController ()
@property (weak) IBOutlet NSMatrix *downloadLinkTypeMatrix;
@property (weak) IBOutlet NSTextField *savePathLabel;

@end

@implementation PreferenceController

- (instancetype)init {
    self = [super initWithWindowNibName:@"Preference"];
    if (self) {
        
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    [self configurePreference];
}

- (void)configurePreference {
    NSInteger idx = [PreferenceController preferenceDownloadLinkType];
    [self.downloadLinkTypeMatrix selectCellAtRow:idx column:0];
    
    NSURL *url = [PreferenceController preferenceSavePath];
    self.savePathLabel.stringValue = [url path];
}

- (IBAction)downloadLinkTypeChanged:(id)sender {
    //这里仅有 0 1 这两中，直接偷懒（毕竟 YES = 1 NO = 0）
    NSInteger linkType = [self.downloadLinkTypeMatrix selectedRow];
    [PreferenceController setPreferenceDownloadLinkType:linkType];
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    NSDictionary *dict = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:linkType] forKey:kDownloadLinkType];
    [notificationCenter postNotificationName:DMHYDownloadLinkTypeNotification object:self userInfo:dict];
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


#pragma mark - Setup

+ (void)setupDefaultPreference {
    NSURL *savePath = [PreferenceController preferenceSavePath];
    if (savePath == nil) {
        [PreferenceController setPreferenceDownloadLinkType:NO];
        [PreferenceController setPreferenceSavePath:[self userDownloadPath]];
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

@end
