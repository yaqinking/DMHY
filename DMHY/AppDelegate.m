//
//  AppDelegate.m
//  DMHY
//
//  Created by 小笠原やきん on 9/9/15.
//  Copyright © 2015 yaqinking. All rights reserved.
//

#import "AppDelegate.h"
#import "PreferenceController.h"
#import "ViewPreferenceController.h"
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
    [self registeAppDefaults];
    [self setupInitialWeekdaysData];
}

- (void)registeAppDefaults {
    NSMutableArray *sites = [NSMutableArray array];
    NSDictionary *siteDMHY       = @{ SiteNameKey : @"share.dmhy.org",
                                      SiteMainKey : DMHYRSS,
                                      SiteSearchKey : DMHYSearchByKeyword,
                                      SiteResponseType : SiteResponseXML };
    NSDictionary *siteDandanplay = @{ SiteNameKey : @"dmhy.dandanplay.com",
                                      SiteMainKey : DMHYdandanplayRSS,
                                      SiteSearchKey : DMHYdandanplaySearchByKeyword,
                                      SiteResponseType : SiteResponseXML };
    NSDictionary *siteACGGG      = @{ SiteNameKey : @"bt.acg.gg",
                                      SiteMainKey : DMHYACGGGRSS,
                                      SiteSearchKey : DMHYACGGGSearchByKeyword,
                                      SiteResponseType : SiteResponseXML };
    NSDictionary *siteBangumiMoe = @{ SiteNameKey : @"bangumi.moe",
                                      SiteMainKey : DMHYBangumiMoeRSS,
                                      SiteSearchKey : DMHYBangumiMoeSearchByKeyword,
                                      SiteResponseType : SiteResponseJSON };
    [sites addObject:siteDMHY];
    [sites addObject:siteDandanplay];
    [sites addObject:siteACGGG];
    [sites addObject:siteBangumiMoe];
    NSDictionary *appDefaults = @{ FliterKeywordKey : @"",
                                   DontDownloadCollectionKey : @YES,
                                   kFetchInterval : @300,
                                   kCurrentSite : siteDMHY,
                                   kSupportSite : sites,
                                   kMainViewRowStyle : @2,
                                   kDownloadLinkType : @0 };
    [[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
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
        NSLog(@"Delete Torrent %@", torrent.title);
        [self.managedObjectContext deleteObject:torrent];
    }
    [self.managedObjectContext save:NULL];
    NSLog(@"Delete Done!");
}

- (IBAction)fetchTorrents:(id)sender {
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Torrent"];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"pubDate" ascending:NO]];
    NSArray *torrents = [self.managedObjectContext executeFetchRequest:request
                                                                 error:NULL];
    for (DMHYTorrent *torrent in torrents) {
        BOOL isNew = torrent.isNewTorrent.boolValue;
        NSLog(@"[IsNew %@ ][Title: %@ ][Date %@ ]", isNew?@"是":@"否", torrent.title, torrent.pubDate);
    }
}

- (IBAction)switchTheme:(id)sender {
    NSInteger themeCode = [PreferenceController preferenceTheme];
    [PreferenceController setPreferenceTheme:(!themeCode)];
    NSInteger currentTheme = [PreferenceController preferenceTheme];
    switch (currentTheme) {
        case DMHYThemeLight:
            NSLog(@"Light");
            break;
        case DMHYThemeDark:
            NSLog(@"Dark");
        default:
            break;
    }
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
        NSViewController *viewViewController = [[ViewPreferenceController alloc] init];
        NSViewController *siteViewController = [[SitePreferenceController alloc] init];
        
        
        NSArray *controllers = [[NSArray alloc] initWithObjects:generalViewController, viewViewController, siteViewController, nil];
        
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
        [DMHYNotification postNotificationName:DMHYInitialWeekdayCompleteNotification];
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
