//
//  AddKeywordViewController.m
//  DMHY
//
//  Created by 小笠原やきん on 7/17/16.
//  Copyright © 2016 yaqinking. All rights reserved.
//

#import "AddKeywordViewController.h"
#import "DMHYCoreDataStackManager.h"

@interface AddKeywordViewController ()

@property (weak) IBOutlet NSTextField *keywordTextField;
@property (weak) IBOutlet NSPopUpButton *sitesPopUpButton;
@property (weak) IBOutlet NSPopUpButton *weekdayPopUpButton;

@end

@implementation AddKeywordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    self.preferredContentSize = NSMakeSize(580, 140);
    [self setupData];
}

- (void)setupData {
    NSMutableArray *siteNames = [[NSMutableArray alloc] init];
    NSArray<DMHYSite *> *sites = [[DMHYCoreDataStackManager sharedManager] allSites];
    [sites enumerateObjectsUsingBlock:^(DMHYSite * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [siteNames addObject:obj.name];
    }];
    [self.sitesPopUpButton addItemsWithTitles:siteNames];
    // A cheat at visual feeling
    NSArray<NSString *> *weekdays = @[@"周一", @"周二", @"周三", @"周四", @"周五", @"周六", @"周日", @"其他"];
    [self.weekdayPopUpButton addItemsWithTitles:weekdays];
}

- (IBAction)addKeyword:(id)sender {
    NSString *newKeyword = self.keywordTextField.stringValue;
    if ([newKeyword isEqualToString:@""]) {
        return;
    }
    NSMenuItem *siteItem = [self.sitesPopUpButton selectedItem];
    NSInteger siteIndex = [self.sitesPopUpButton indexOfItem:siteItem];
    DMHYSite *site = [[[DMHYCoreDataStackManager sharedManager] allSites] objectAtIndex:siteIndex];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"keyword == %@", self.weekdayPopUpButton.selectedItem.title];
    DMHYKeyword *weekdayKeyword = [[[site.keywords allObjects] filteredArrayUsingPredicate:predicate] firstObject];
    DMHYKeyword *keyword = [NSEntityDescription insertNewObjectForEntityForName:DMHYKeywordEntityKey inManagedObjectContext:[[DMHYCoreDataStackManager sharedManager] managedObjectContext]];
    keyword.keyword = newKeyword;
    keyword.createDate = [NSDate new];
    keyword.isSubKeyword = @YES;
    [weekdayKeyword addSubKeywordsObject:keyword];
    [[DMHYCoreDataStackManager sharedManager] saveContext];
    [DMHYNotification postNotificationName:DMHYKeywordAddedNotification object:site];
}

@end
