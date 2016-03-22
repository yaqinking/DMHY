//
//  ViewPreferenceController.h
//  DMHY
//
//  Created by 小笠原やきん on 3/22/16.
//  Copyright © 2016 yaqinking. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MASPreferencesViewController.h"

@interface ViewPreferenceController : NSViewController<MASPreferencesViewController>

+ (void)setupDefaultViewPreference;
+ (void)setViewPreferenceTableViewRowStyle:(NSInteger)style;
+ (NSInteger)viewPreferenceTableViewRowStyle;
+ (void)setPreferenceDoubleAction:(NSInteger)action;
+ (NSInteger)preferenceDoubleAction;

@end
