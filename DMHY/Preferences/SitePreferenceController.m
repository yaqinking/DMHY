//
//  SitePreferenceController.m
//  DMHY
//
//  Created by 小笠原やきん on 3/22/16.
//  Copyright © 2016 yaqinking. All rights reserved.
//

#import "SitePreferenceController.h"
#import "DMHYAPI.h"

NSString * const SiteResponseJSON = @"JSON";
NSString * const SiteResponseXML = @"XML";

@interface SitePreferenceController ()<NSTableViewDelegate, NSTableViewDataSource>

@property (weak) IBOutlet NSTextField *siteNameTextField;
@property (weak) IBOutlet NSTextField *mainURLTextField;
@property (weak) IBOutlet NSTextField *searchURLTextField;
@property (weak) IBOutlet NSPopUpButton *siteResponseTypePopUpButton;

@property (weak) IBOutlet NSTableView *tableView;

@property (nonatomic, strong) NSMutableArray *sites;

@end

@implementation SitePreferenceController

- (void)viewDidLoad {
    [super viewDidLoad];
//    [[NSUserDefaults standardUserDefaults] setObject:[NSNull null] forKey:kSupportSite];
    // Do view setup here.
    [self observeNotifications];
    [SitePreferenceController setupDefaultSites];
    [self.tableView reloadData];
}

- (void)observeNotifications {
    [DMHYNotification addObserver:self selector:@selector(handleDefaultSiteSetupCompleted) name:DMHYDefaultSitesSetupComplatedNotification];
}

- (void)handleDefaultSiteSetupCompleted {
    self.sites = nil;
    [self.tableView reloadData];
}

+ (void)setupDefaultSites {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSArray *savedSites = [userDefaults arrayForKey:kSupportSite];
    NSString *siteResponseType = [[savedSites firstObject] valueForKey:SiteResponseType];
    
    if (savedSites.count == 0 || siteResponseType == nil) {
        NSMutableArray *sites = [NSMutableArray array];
        NSDictionary *siteDMHY = @{ SiteNameKey : @"share.dmhy.org",
                                    SiteMainKey : DMHYRSS,
                                    SiteSearchKey : DMHYSearchByKeyword,
                                    SiteResponseType : SiteResponseXML };
        NSDictionary *siteDandanplay = @{ SiteNameKey : @"dmhy.dandanplay.com",
                                          SiteMainKey : DMHYdandanplayRSS,
                                          SiteSearchKey : DMHYdandanplaySearchByKeyword,
                                          SiteResponseType : SiteResponseXML };
        NSDictionary *siteACGGG = @{ SiteNameKey : @"bt.acg.gg",
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
        [userDefaults setObject:sites forKey:kSupportSite];
        if ([userDefaults synchronize]) {
            
        };
        [DMHYNotification postNotificationName:DMHYDefaultSitesSetupComplatedNotification];
        NSLog(@"Initial");
    }
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.sites.count;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    return 22.0f;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSString *identifier = tableColumn.identifier;
    NSDictionary *site = self.sites[row];
    if ([identifier isEqualToString:@"siteNameCell"]) {
        NSTableCellView *cellView      = [tableView makeViewWithIdentifier:@"siteNameCell" owner:self];
        NSString *siteName = [site valueForKey:SiteNameKey];
        cellView.textField.stringValue = siteName;
        return cellView;
    }
    
    if ([identifier isEqualToString:@"responseTypeCell"]) {
        NSTableCellView *cellView   = [tableView makeViewWithIdentifier:@"responseTypeCell" owner:self];
        NSString *siteMain = [site valueForKey:SiteResponseType];
        cellView.textField.stringValue = siteMain;
        return cellView;
    }
    if ([identifier isEqualToString:@"siteMainCell"]) {
        NSTableCellView *cellView   = [tableView makeViewWithIdentifier:@"siteMainCell" owner:self];
        NSString *siteMain = [site valueForKey:SiteMainKey];
        cellView.textField.stringValue = siteMain;
        return cellView;
    }
    if ([identifier isEqualToString:@"siteSearchCell"]) {
        NSTableCellView *cellView      = [tableView makeViewWithIdentifier:@"siteSearchCell" owner:self];
        NSString *siteSearch = [site valueForKey:SiteSearchKey];
        cellView.textField.stringValue = siteSearch;
        return cellView;
    }
    return nil;

}

- (NSMutableArray *)sites {
    if (!_sites) {
        _sites = [NSMutableArray array];
        _sites = [[[NSUserDefaults standardUserDefaults] arrayForKey:kSupportSite] mutableCopy];
    }
    return _sites;
}

- (IBAction)addSite:(id)sender {
    NSString *siteName = self.siteNameTextField.stringValue;
    NSString *siteMain = self.mainURLTextField.stringValue;
    NSString *siteSearch = self.searchURLTextField.stringValue;
    NSString *siteResponseType = self.siteResponseTypePopUpButton.selectedItem.title;
    if (!siteName.length && !siteMain.length && !siteSearch.length) {
        return;
    }
    NSDictionary *newSite = @{ SiteNameKey : siteName,
                               SiteMainKey : siteMain,
                               SiteSearchKey : siteSearch,
                               SiteResponseType : siteResponseType};
    [self.sites addObject:newSite];
    [[NSUserDefaults standardUserDefaults] setObject:self.sites forKey:kSupportSite];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self.tableView reloadData];
}

- (IBAction)deleteSite:(id)sender {
    NSInteger selectRow = self.tableView.selectedRow;
    if (selectRow < 4) { // Shouldn't remove default site
        return;
    }
    [self.sites removeObject:self.sites[selectRow]];
    [[NSUserDefaults standardUserDefaults] setObject:self.sites forKey:kSupportSite];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self.tableView reloadData];
}

- (IBAction)setCurrentSite:(id)sender {
    NSInteger selectRow = self.tableView.selectedRow;
    if (selectRow < 0 || selectRow > self.sites.count) { // Unknow row index
        return;
    }
    [[NSUserDefaults standardUserDefaults] setObject:self.sites[selectRow] forKey:kCurrentSite];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [DMHYNotification postNotificationName:DMHYDownloadSiteChangedNotification];
}


- (NSString *)identifier
{
    return @"SitesPreferences";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:NSImageNameNetwork];
}

- (NSString *)toolbarItemLabel
{
    return @"站点";
}

@end
