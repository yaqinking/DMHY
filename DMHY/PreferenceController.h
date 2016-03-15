//
//  PreferenceController.h
//  DMHY
//
//  Created by 小笠原やきん on 9/16/15.
//  Copyright © 2015 yaqinking. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PreferenceController : NSWindowController<NSWindowDelegate>

+ (void)setupDefaultPreference;

+ (void)setPreferenceDownloadLinkType:(BOOL)type;
+ (BOOL)preferenceDownloadLinkType;

+ (void)setPreferenceSavePath:(NSURL *)path;
+ (NSURL *)preferenceSavePath;

+ (void)setPreferenceFetchInterval:(NSInteger) seconds;
+ (NSInteger)preferenceFetchInterval;

+ (void)setPreferenceTheme:(NSInteger) themeCode;
+ (NSInteger)preferenceTheme;

+ (void)setPreferenceDownloadSite:(NSInteger)site;
+ (NSInteger)preferenceDownloadSite;

@end
