//
//  SitePreferenceController.h
//  DMHY
//
//  Created by 小笠原やきん on 3/22/16.
//  Copyright © 2016 yaqinking. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MASPreferencesViewController.h"

@interface SitePreferenceController : NSViewController<MASPreferencesViewController>

+ (void)setupDefaultSites;

@end
