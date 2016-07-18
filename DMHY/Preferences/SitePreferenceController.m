//
//  SitePreferenceController.m
//  DMHY
//
//  Created by 小笠原やきん on 3/22/16.
//  Copyright © 2016 yaqinking. All rights reserved.
//

#import "SitePreferenceController.h"
#import "DMHYCoreDataStackManager.h"
#import "ButtonTableCellView.h"

NSString * const SiteResponseJSON = @"JSON";
NSString * const SiteResponseXML = @"XML";

@interface SitePreferenceController ()<NSTableViewDelegate, NSTableViewDataSource>

@property (weak) IBOutlet NSTableView *tableView;

@property (nonatomic, strong) NSArray *sites;

@end

@implementation SitePreferenceController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    [self observeNotifications];
    [self.tableView reloadData];
}

- (void)observeNotifications {
    [DMHYNotification addObserver:self selector:@selector(handleSeedDataCompleted) name:DMHYSeedDataCompletedNotification];
}

- (void)handleSeedDataCompleted {
    self.sites = nil;
    [self.tableView reloadData];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.sites.count;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    return 22.0f;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSString *identifier = tableColumn.identifier;
    DMHYSite *site = self.sites[row];
    
    if ([identifier isEqualToString:@"currentUseCell"]) {
        ButtonTableCellView *cellView      = [tableView makeViewWithIdentifier:@"currentUseCell" owner:self];
        [cellView.checkButton setState:site.isCurrentUse.integerValue];
        return cellView;
    }
    if ([identifier isEqualToString:@"autoDownloadCell"]) {
        ButtonTableCellView *cellView      = [tableView makeViewWithIdentifier:@"autoDownloadCell" owner:self];
        [cellView.checkButton setState:site.isAutoDownload.integerValue];
        return cellView;
    }
    if ([identifier isEqualToString:@"siteNameCell"]) {
        NSTableCellView *cellView      = [tableView makeViewWithIdentifier:@"siteNameCell" owner:self];
        cellView.textField.stringValue = site.name;
        return cellView;
    }
    
    if ([identifier isEqualToString:@"responseTypeCell"]) {
        NSTableCellView *cellView   = [tableView makeViewWithIdentifier:@"responseTypeCell" owner:self];
        cellView.textField.stringValue = site.responseType;
        return cellView;
    }
    if ([identifier isEqualToString:@"siteMainCell"]) {
        NSTableCellView *cellView   = [tableView makeViewWithIdentifier:@"siteMainCell" owner:self];
        cellView.textField.stringValue = site.mainURL;
        return cellView;
    }
    return nil;
}

- (IBAction)changeAutoDownload:(NSButton *)sender {
    NSInteger state = sender.state;
    NSInteger row = [self.tableView rowForView:sender];
    if (state < 0 || state > 1 || row < 0) {
        return;
    }
    DMHYSite *site = self.sites[row];
    site.isAutoDownload = @(state);
    [[DMHYCoreDataStackManager sharedManager] saveContext];
    [DMHYNotification postNotificationName:DMHYAutoDownloadSiteChangedNotification];
}

- (IBAction)changeCurrentUse:(NSButton *)sender {
    NSInteger state = sender.state;
    NSInteger row = [self.tableView rowForView:sender];
    if (state < 0 || state > 1 || row < 0) {
        return;
    }
    DMHYSite *currentUseSite = [[DMHYCoreDataStackManager sharedManager] currentUseSite];
    currentUseSite.isCurrentUse = @NO;
    DMHYSite *site = self.sites[row];
    site.isCurrentUse = @(state);
    [[DMHYCoreDataStackManager sharedManager] saveContext];
    [self.tableView reloadData];
    [DMHYNotification postNotificationName:DMHYSearchSiteChangedNotification object:site];
}

-(NSArray *)sites {
    if (!_sites) {
        _sites = [[DMHYCoreDataStackManager sharedManager] allSites];
    }
    return _sites;
}

- (NSString *)identifier {
    return @"SitesPreferences";
}

- (NSImage *)toolbarItemImage {
    return [NSImage imageNamed:NSImageNameNetwork];
}

- (NSString *)toolbarItemLabel {
    return @"站点";
}

@end
