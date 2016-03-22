//
//  ViewPreferenceController.m
//  DMHY
//
//  Created by 小笠原やきん on 3/22/16.
//  Copyright © 2016 yaqinking. All rights reserved.
//

#import "ViewPreferenceController.h"
#import "DMHYNotification.h"
#define kMainTableViewRowStyle @"MainTableViewRowStyle"
#define kDoubleAction @"DoubleAction"

#define DMHYMainTableViewRowStyleChangedNotification @"DMHYMainTableViewRowStyleChangedNotification"
#define DMHYDoubleActionChangedNotification @"DMHYDoubleActionChangedNotification"

@interface ViewPreferenceController ()
@property (weak) IBOutlet NSMatrix *mainViewRowStyleMatrix;
@property (weak) IBOutlet NSMatrix *doubleActionMatrix;

@end

@implementation ViewPreferenceController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configurePreference];
}

- (void)configurePreference {
    
    NSInteger rowStyleIdx = [ViewPreferenceController viewPreferenceTableViewRowStyle];
    [self.mainViewRowStyleMatrix selectCellAtRow:rowStyleIdx column:0];
    NSInteger rowDoubleAction = [ViewPreferenceController preferenceDoubleAction];
    [self.doubleActionMatrix selectCellAtRow:rowDoubleAction column:0];
}

+ (void)setupDefaultViewPreference {

}

+ (void)setViewPreferenceTableViewRowStyle:(NSInteger)style {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:style forKey:kMainTableViewRowStyle];
    [userDefaults synchronize];
}

+ (NSInteger)viewPreferenceTableViewRowStyle {
    return [[NSUserDefaults standardUserDefaults] integerForKey:kMainTableViewRowStyle];
}

+ (void)setPreferenceDoubleAction:(NSInteger)action {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:action forKey:kDoubleAction];
    [userDefaults synchronize];
}

+ (NSInteger)preferenceDoubleAction {
    return [[NSUserDefaults standardUserDefaults] integerForKey:kDoubleAction];
}

- (IBAction)mainTableViewRowStyleChanged:(id)sender {
    NSInteger style = [self.mainViewRowStyleMatrix selectedRow];
    [ViewPreferenceController setViewPreferenceTableViewRowStyle:style];
    [DMHYNotification postNotificationName:DMHYMainTableViewRowStyleChangedNotification];
}

- (IBAction)doubleActionChanged:(id)sender {
    NSInteger action = [self.doubleActionMatrix selectedRow];
    [ViewPreferenceController setPreferenceDoubleAction:action];
    [DMHYNotification postNotificationName:DMHYDoubleActionChangedNotification];
}

- (NSString *)identifier
{
    return @"ViewPreferences";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:@"ViewerPreferences"];
}

- (NSString *)toolbarItemLabel
{
    return @"查看";
}
@end
