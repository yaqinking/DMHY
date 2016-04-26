//
//  PreferenceController.h
//  DMHY
//
//  Created by 小笠原やきん on 9/16/15.
//  Copyright © 2015 yaqinking. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MASPreferencesViewController.h"

extern NSString * const FliterKeywordKey;
extern NSString * const DontDownloadCollectionKey;
extern NSString * const DMHYDontDownloadCollectionKeyDidChangedNotification;

@interface PreferenceController : NSViewController<MASPreferencesViewController, NSTextFieldDelegate>

+ (void)setPreferenceDownloadLinkType:(BOOL)type;
+ (BOOL)preferenceDownloadLinkType;

+ (void)setPreferenceSavePath:(NSURL *)path;
+ (NSURL *)preferenceSavePath;

+ (void)setFileWatchPath:(NSURL *)path;
+ (NSURL *)fileWatchPath;

+ (void)setPreferenceFetchInterval:(NSInteger) seconds;
+ (NSInteger)preferenceFetchInterval;

+ (void)setPreferenceTheme:(NSInteger) themeCode;
+ (NSInteger)preferenceTheme;

+ (void)setPreferenceDontDownloadCollection:(BOOL)value;
+ (BOOL)preferenceDontDownloadCollection;

+ (NSURL *)userDownloadPath;

+ (void)setViewPreferenceTableViewRowStyle:(NSInteger)style;
+ (NSInteger)viewPreferenceTableViewRowStyle;
+ (void)setPreferenceDoubleAction:(NSInteger)action;
+ (NSInteger)preferenceDoubleAction;

@end
