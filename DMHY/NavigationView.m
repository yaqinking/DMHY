//
//  NavigationView.m
//  DMHY
//
//  Created by 小笠原やきん on 9/9/15.
//  Copyright © 2015 yaqinking. All rights reserved.
//

#import "NavigationView.h"
#import "PreferenceController.h"

#define DMHYThemeKey @"ThemeType"

typedef NS_ENUM(NSInteger, DMHYThemeType) {
    DMHYThemeLight,
    DMHYThemeDark
};

@implementation NavigationView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.

    NSInteger themecode = [PreferenceController preferenceTheme];
    switch (themecode) {
        case DMHYThemeLight:
           self.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantLight];
            break;
        case DMHYThemeDark:
            self.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark];
        default:
            break;
    }
}

- (BOOL)allowsVibrancy {
    return YES;
}

- (void)viewWillDraw {

}

@end
