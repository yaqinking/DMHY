//
//  AppDelegate.m
//  DMHY
//
//  Created by 小笠原やきん on 9/9/15.
//  Copyright © 2015 yaqinking. All rights reserved.
//

#import "AppDelegate.h"
#import "PreferenceController.h"
#import "DMHYCoreDataStackManager.h"
#import "DMHYKeyword+CoreDataProperties.h"
#import "DMHYAPI.h"

@interface AppDelegate ()

@property (nonatomic) PreferenceController *preferenceController;
@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;

@end

@implementation AppDelegate

@synthesize managedObjectContext = _context;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    [PreferenceController setupDefaultPreference];
    [self setupInitialWeekdaysData];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
    
}


#pragma mark - MenuItem

- (IBAction)showPreference:(id)sender {
    NSLog(@"show preference %@",self.preferenceController);
    [self.preferenceController showWindow:self];
}

- (IBAction)showDownloadPathInFinder:(id)sender {
    NSURL *savePath = [PreferenceController preferenceSavePath];
    [[NSWorkspace sharedWorkspace] openURL:savePath];
}

#pragma mark - Properties Initialization

- (PreferenceController *)preferenceController {
    if (!_preferenceController) {
        _preferenceController = [[PreferenceController alloc] init];
    }
    return _preferenceController;
}

- (NSManagedObjectContext *)managedObjectContext {
    if (!_context) {
        _context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        _context.persistentStoreCoordinator = [[DMHYCoreDataStackManager sharedManager] persistentStoreCoordinator];
    }
    return _context;
}

#pragma mark - Initial Data

- (void)setupInitialWeekdaysData {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:DMHYKeywordEntityKey];
    NSArray *fetchedWeekdays = [self.managedObjectContext executeFetchRequest:request error:NULL];
    if (fetchedWeekdays.count == 0) {
        NSLog(@"Initial weeks");
        NSArray *weekdays = [NSArray arrayWithObjects:@"周一",
                               @"周二",
                               @"周三",
                               @"周四",
                               @"周五",
                               @"周六",
                               @"周日",
                               @"其他",nil];
        for (int i = 0; i < weekdays.count; i++) {
            DMHYKeyword *keyword = [NSEntityDescription insertNewObjectForEntityForName:DMHYKeywordEntityKey inManagedObjectContext:self.managedObjectContext];
            keyword.keyword = weekdays[i];
            keyword.createDate = [NSDate new];
        };
        [self saveData];
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter postNotificationName:DMHYInitialWeekdayCompleteNotification
                                          object:nil
                                        userInfo:nil];
    } else {
        NSLog(@"Have %lu keywords count ",fetchedWeekdays.count);
    }
}

- (void)saveData {
    NSError *error = nil;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Error %@",[error localizedDescription]);
    }
}

@end
