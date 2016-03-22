//
//  PreferenceController.h
//  DMHY
//
//  Created by 小笠原やきん on 9/16/15.
//  Copyright © 2015 yaqinking. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MASPreferencesViewController.h"

@interface PreferenceController : NSViewController<MASPreferencesViewController>

+ (void)setupDefaultPreference;

+ (void)setPreferenceDownloadLinkType:(BOOL)type;
+ (BOOL)preferenceDownloadLinkType;

+ (void)setPreferenceSavePath:(NSURL *)path;
+ (NSURL *)preferenceSavePath;

+ (void)setFileWatchPath:(NSURL *)path;
+ (NSURL *)fileWatchPath;

+ (void)setPreferenceFetchInterval:(NSInteger) seconds;
+ (NSInteger)preferenceFetchInterval;

+ (void)setFileWatchInterval:(NSInteger) seconds;
+ (NSInteger)fileWatchInterval;

+ (void)setPreferenceTheme:(NSInteger) themeCode;
+ (NSInteger)preferenceTheme;

+ (NSURL *)userDownloadPath;

@end
