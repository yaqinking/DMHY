//
//  AppDelegate.m
//  DMHY
//
//  Created by 小笠原やきん on 9/9/15.
//  Copyright © 2015 yaqinking. All rights reserved.
//

#import "AppDelegate.h"
#import "PreferenceController.h"
#import "SitePreferenceController.h"
#import "DMHYCoreDataStackManager.h"
#import "DMHYKeyword+CoreDataProperties.h"
#import "DMHYAPI.h"
#import "DMHYTorrent.h"
#import "MASPreferencesWindowController.h"

@import Quartz;

@interface AppDelegate ()


@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;

@end

@implementation AppDelegate

@synthesize managedObjectContext = _context;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


#pragma mark - MenuItem

- (IBAction)showPreference:(id)sender {
    [self.preferencesWindowController showWindow:nil];
}

- (IBAction)showDownloadPathInFinder:(id)sender {
    NSURL *savePath = [PreferenceController preferenceSavePath];
    [[NSWorkspace sharedWorkspace] openURL:savePath];
}

- (IBAction)deleteAllExistTorrents:(id)sender {
    NSFetchRequest *existTorrentRequest = [NSFetchRequest fetchRequestWithEntityName:@"Torrent"];
    //    existTorrentRequest.predicate = [NSPredicate predicateWithFormat:@"title LIKE %@",@"传颂"];
    NSArray *torrents = [self.managedObjectContext executeFetchRequest:existTorrentRequest error:NULL];
    for (DMHYTorrent *torrent in torrents) {
        [self.managedObjectContext deleteObject:torrent];
    }
    [self.managedObjectContext save:NULL];
}

- (IBAction)switchTheme:(id)sender {
    NSInteger themeCode = [PreferenceController preferenceTheme];
    [PreferenceController setPreferenceTheme:(!themeCode)];
    [DMHYNotification postNotificationName:DMHYThemeChangedNotification];
}

- (IBAction)showHelp:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[self helpURL]];
}

- (IBAction)togglePreviewPanel:(id)previewPanel
{
    if ([QLPreviewPanel sharedPreviewPanelExists] && [[QLPreviewPanel sharedPreviewPanel] isVisible])
    {
        [[QLPreviewPanel sharedPreviewPanel] orderOut:nil];
    }
    else
    {
        [[QLPreviewPanel sharedPreviewPanel] makeKeyAndOrderFront:nil];
    }
}

- (NSURL *)helpURL {
    return [NSURL URLWithString:@"https://github.com/yaqinking/DMHY/wiki"];
}

#pragma mark - Properties Initialization

- (NSWindowController *)preferencesWindowController
{
    if (_preferencesWindowController == nil)
    {
        NSViewController *generalViewController = [[PreferenceController alloc] init];
        NSViewController *siteViewController = [[SitePreferenceController alloc] init];
        
        NSArray *controllers = @[generalViewController, siteViewController];
        
        // To add a flexible space between General and Advanced preference panes insert [NSNull null]:
        //     NSArray *controllers = [[NSArray alloc] initWithObjects:generalViewController, [NSNull null], advancedViewController, nil];
        
        NSString *title = @"设置";
        _preferencesWindowController = [[MASPreferencesWindowController alloc] initWithViewControllers:controllers title:title];

    }
    return _preferencesWindowController;
}

- (NSManagedObjectContext *)managedObjectContext {
    if (!_context) {
        _context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        _context.persistentStoreCoordinator = [[DMHYCoreDataStackManager sharedManager] persistentStoreCoordinator];
    }
    return _context;
}

- (void)saveData {
    NSError *error = nil;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Error %@",[error localizedDescription]);
    }
}

@end
