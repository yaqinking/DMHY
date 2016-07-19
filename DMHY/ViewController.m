//
//  ViewController.m
//  DMHY
//
//  Created by 小笠原やきん on 15/8/30.
//  Copyright © 2015年 yaqinking. All rights reserved.
//

#import "ViewController.h"
#import "PreferenceController.h"
#import "SitePreferenceController.h"
#import "DMHYCoreDataStackManager.h"
#import "TorrentItem.h"
#import "TitleTableCellView.h"
#import "NavigationView.h"
#import "DMHYXMLDataManager.h"
#import "DMHYJSONDataManager.h"
#import "NSTableView+ContextMenu.h"
#import <Carbon/Carbon.h>
#import "DMHYSiteChecker.h"

/**
 *  加载数据步骤：
 1. 判断当前站点返回是 XML 还是 JSON 数据
 2. 调用相应的解析方法
 3. 解析完毕，重新载入 tableview
 
 下载动漫花园种子：
 1. 获取到该条目的介绍页面
 2. 解析介绍页面的 HTML DOM 用 XPath 提取出种子链接
 3. 调用下载种子文件的方法（DMHYDownloader downloadTorrentWithURL:）
 
 */
@interface ViewController()<NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate, ContextMenuDelegate>

@property (weak) IBOutlet NSTableView       *tableView;
@property (weak) IBOutlet NSProgressIndicator *indicator;

@property (weak) IBOutlet NSTextField *searchTextField;
@property (weak) IBOutlet NSTextField *info;

@property (nonatomic, strong) NSMutableArray *torrents;
@property (nonatomic, strong) NSString       *searchURLString;

@property (nonatomic, strong) DMHYSite *site;

@property (nonatomic) BOOL isMagnetLink;
@property (nonatomic) BOOL isSubKeyword;

@property (nonatomic) NSInteger fetchInterval;
@property (nonatomic) NSInteger currentRow;

@property (nonatomic, strong) DMHYSiteChecker *checker;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self observeNotification];
    [self registeAppDefaults];
    [[DMHYCoreDataStackManager sharedManager] seedDataIfNeed];
    [self setupPreference];
    [self setupTableViewStyle];
    [self setupData:self];
    [self setupRepeatTask];
    [self setupMenuItems];
    [self setupTableViewDoubleAction];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
}

#pragma mark - Setup

- (void)registeAppDefaults {
    NSDictionary *appDefaults = @{ FliterKeywordKey : @"",
                                   DontDownloadCollectionKey : @YES,
                                   kFetchInterval : @(15*60),
                                   kMainTableViewRowStyle :@2,
                                   kDownloadLinkType :@0,
                                   DMHYThemeKey : @1 };
    [[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
}

- (void)setupTableViewStyle {
    self.tableView.rowSizeStyle = [self preferedRowSizeStyle];
    self.tableView.usesAlternatingRowBackgroundColors = YES;
    self.tableView.columnAutoresizingStyle            = NSTableViewUniformColumnAutoresizingStyle;
    [self.tableView sizeLastColumnToFit];
}

- (NSTableViewRowSizeStyle )preferedRowSizeStyle {
    NSInteger rowStyle = [PreferenceController viewPreferenceTableViewRowStyle];
    switch (rowStyle) {
        case 0:
            return NSTableViewRowSizeStyleSmall;
        case 1:
            return NSTableViewRowSizeStyleMedium;
        case 2:
            return NSTableViewRowSizeStyleLarge;
        default:
            break;
    }
    return NSTableViewRowSizeStyleSmall;
}

/**
 *  Retrive saved preference value and set to self variable.
 */
- (void)setupPreference {
    self.isMagnetLink  = [PreferenceController preferenceDownloadLinkType];
    self.fetchInterval = [PreferenceController preferenceFetchInterval];
}

/**
 * Configure  data start point.
 *
 */
- (IBAction)setupData:(id)sender {
    //NSLog(@"sender class %@",[sender class]);
    if ([sender isKindOfClass:[ViewController class]]) {
        self.isSubKeyword = YES;
    }
    if (!self.isSubKeyword) {
        return;
    }
    [self resetData];
    [self startAnimatingProgressIndicator];
    [self configureSearchURLString];
    [self.torrents removeAllObjects];
    if ([self.site.responseType isEqualToString:@"json"]) {
        [[DMHYJSONDataManager manager] GET:self.searchURLString success:^(NSArray<TorrentItem *> *objects) {
            self.torrents = [objects mutableCopy];
            [self reloadDataAndStopIndicator];
        } failure:^(NSError *error) {
            [self setErrorInfoAndStopIndicator];
        }];
    } else {
        [[DMHYXMLDataManager manager] GET:self.searchURLString success:^(NSArray<TorrentItem *> *objects) {
            self.torrents = [objects mutableCopy];
            [self reloadDataAndStopIndicator];
        } failure:^(NSError *error) {
            [self setErrorInfoAndStopIndicator];
        }];
    }
}

#pragma mark - Indicator and reload table view data

- (void)reloadDataAndStopIndicator {
    [self stopAnimatingProgressIndicator];
    [self.tableView reloadData];
    self.info.stringValue = @"加载完成 w";
}

- (void)setErrorInfoAndStopIndicator {
    self.info.stringValue = @"网络错误喵？";
    [self stopAnimatingProgressIndicator];
}

/**
 *  Set search url string to download site.
 */
- (void)configureSearchURLString {
    if ([self isLoadHomePage]) {
        NSString *siteMain = self.site.mainURL;
        self.searchURLString = siteMain;
    } else {
        NSString *siteSearch = self.site.searchURL;
        self.searchURLString = [[NSString stringWithFormat:siteSearch, self.searchTextField.stringValue] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    }
//    NSLog(@"Site Info %@ %@ %@",self.site.name,self.site.responseType, self.site.isAutoDownload);
}

#pragma mark - Repeat Task

/**
 *  Schedule auto download new torrent task.
 */
- (void)setupRepeatTask {
    self.checker = [[DMHYSiteChecker alloc] init];
    [self.checker startWitchCheckInterval:self.fetchInterval];
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.torrents.count;
}

#pragma mark - NSTableViewDelegate

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSString *identifier = tableColumn.identifier;
    TorrentItem *torrent = self.torrents[row];
    if ([identifier isEqualToString:@"pubDateCell"]) {
        NSTableCellView *cellView      = [tableView makeViewWithIdentifier:@"pubDateCell" owner:self];
        cellView.textField.stringValue = torrent.pubDate;
        return cellView;
    }
    if ([identifier isEqualToString:@"titleCell"]) {
        TitleTableCellView *cellView   = [tableView makeViewWithIdentifier:@"titleCell" owner:self];
        cellView.textField.stringValue = torrent.title;
        return cellView;
    }
    if ([identifier isEqualToString:@"authorCell"]) {
        NSTableCellView *cellView      = [tableView makeViewWithIdentifier:@"authorCell" owner:self];
        cellView.textField.stringValue = torrent.author;
        return cellView;
    }
    return nil;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    self.currentRow = self.tableView.selectedRow;
}

#pragma mark - Table View Context Menu Delegate

- (NSMenu *)tableView:(NSTableView *)aTableView menuForRows:(NSIndexSet *)rows {
    NSMenu *rightClickMenu = [[NSMenu alloc] initWithTitle:@""];
    NSMenuItem *openItem = [[NSMenuItem alloc] initWithTitle:@"打开介绍页面"
                                                      action:@selector(openTorrentLink:)
                                               keyEquivalent:@""];
    NSMenuItem *downloadItem = [[NSMenuItem alloc] initWithTitle:@"下载"
                                                          action:@selector(queryDownloadURL:)
                                                   keyEquivalent:@""];
    [rightClickMenu addItem:openItem];
    [rightClickMenu addItem:downloadItem];
    return rightClickMenu;
}

#pragma mark - Notification

- (void)observeNotification {
    [DMHYNotification addObserver:self selector:@selector(handleDownloadTypeChanged)   name:DMHYDownloadLinkTypeNotification];
    [DMHYNotification addObserver:self selector:@selector(handleAutoDownloadSiteChanged)   name:DMHYAutoDownloadSiteChangedNotification];
    [DMHYNotification addObserver:self selector:@selector(handleSelectKeywordChanged:) name:DMHYSelectKeywordChangedNotification];
    [DMHYNotification addObserver:self selector:@selector(handleFetchIntervalChanged)  name:DMHYFetchIntervalChangedNotification];
    [DMHYNotification addObserver:self selector:@selector(handleThemeChanged)          name:DMHYThemeChangedNotification];
    [DMHYNotification addObserver:self selector:@selector(handleDoubleActionChanged)   name:DMHYDoubleActionChangedNotification];
    [DMHYNotification addObserver:self selector:@selector(handleMainTableViewRowStyleChanged) name:DMHYMainTableViewRowStyleChangedNotification];
    [DMHYNotification addObserver:self selector:@selector(handleDontDownloadCollectionChanged) name:DMHYDontDownloadCollectionKeyDidChangedNotification];
    [DMHYNotification addObserver:self selector:@selector(handleSearchSiteChanged:) name:DMHYSearchSiteChangedNotification];
    [DMHYNotification addObserver:self selector:@selector(handleKeywordChecked:) name:DMHYKeywordCheckedNotification];
}

- (void)handleKeywordChecked:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSString *infoText = [NSString stringWithFormat:@"%@ %@ 检查完毕", userInfo[@"site"], userInfo[@"keyword"]];
    self.info.stringValue = infoText;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSDate *time = [NSDate new];
        self.info.stringValue = [NSString stringWithFormat:@" 上次检查时间 %@",[[DMHYTool tool] infoDateStringFromDate:time]];
    });
}

- (void)handleSearchSiteChanged:(NSNotification *)notification {
    DMHYSite *site = notification.object;
    self.site = site;
    [self setupData:self];
}

- (void)resetData {
    [self.torrents removeAllObjects];
    [self.tableView reloadData];
}

- (void)handleAutoDownloadSiteChanged {
    [self.checker invalidateTimer];
    self.fetchInterval = [PreferenceController preferenceFetchInterval];
    [self setupRepeatTask];
}

- (void)handleDownloadTypeChanged {
    [self setupPreference];
}

- (void)handleDontDownloadCollectionChanged {
    [self setupPreference];
}

- (void)handleSelectKeywordChanged:(NSNotification *)noti {
    NSDictionary *userInfo = noti.userInfo;
    
    NSString *keywordStr  = userInfo[kSelectKeyword];
    BOOL isSubKeywordBOOL = [userInfo[kSelectKeywordIsSubKeyword] boolValue];

    self.isSubKeyword     = isSubKeywordBOOL;
    if (!isSubKeywordBOOL) {
        self.searchTextField.stringValue = @"";
    } else {
        self.searchTextField.stringValue = keywordStr;
    }
    
    [self setupData:userInfo];
}

- (void)handleDoubleActionChanged {
    [self setupTableViewDoubleAction];
}

- (void)setupTableViewDoubleAction {
    NSInteger action = [PreferenceController preferenceDoubleAction];
    switch (action) {
        case 0:
            self.tableView.doubleAction = @selector(openTorrentLink:);
            break;
        case 1:
            self.tableView.doubleAction = @selector(queryDownloadURL:);
            break;
        default:
            break;
    }

}

- (void)handleFetchIntervalChanged {
    [self.checker invalidateTimer];
    self.fetchInterval = [PreferenceController preferenceFetchInterval];
    [self setupRepeatTask];
}

- (void)handleThemeChanged {
    [self.view setNeedsDisplay:YES];
}

- (void)handleMainTableViewRowStyleChanged {
    [self setupTableViewStyle];
    [self.tableView setNeedsDisplay:YES];
}

#pragma mark - Property Initialization

- (NSMutableArray *)torrents {
    if (!_torrents) {
        _torrents = [NSMutableArray array];
    }
    return _torrents;
}

- (DMHYSite *)site {
    if (!_site) {
        _site = [[DMHYCoreDataStackManager sharedManager] currentUseSite];
    }
    return _site;
}

- (NSString *)searchURLString {
    if (!_searchURLString) {
        _searchURLString = [NSString new];
    }
    return _searchURLString;
}

/**
 *  判断搜索关键字是否为空，如果为空的话加载主页，否则加载搜索页
 *
 *  @return YES 加载主页数据
 */
- (BOOL)isLoadHomePage {
    return [self.searchTextField.stringValue isEqualToString:@""] ? YES : NO;
}

#pragma mark - Download

/**
 *  Query clicked row torrent download url then download torrent.
 *
 *  @param sender
 */
- (IBAction)queryDownloadURL:(id)sender {
    NSInteger row = -1;
    if ([sender isKindOfClass:[NSButton class]]) {
        row = [self.tableView rowForView:sender];
    } else {
        row = self.currentRow;
    }
    [self startAnimatingProgressIndicator];
    TorrentItem *item = (TorrentItem *)[self.torrents objectAtIndex:row];
    if ([self.site.name isEqualToString:@"dmhy"]) {
        if (!self.isMagnetLink) {
            [[DMHYDownloader downloader] downloadTorrentFromPageURLString:item.link.absoluteString willStartBlock:^{
               [self startAnimatingProgressIndicator];
            } success:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self stopAnimatingProgressIndicator];
                });
            } failure:^(NSError *error) {
                NSLog(@"Error %@",[error localizedDescription]);
                [self setErrorInfoAndStopIndicator];
            }];
            return;
        }
    }
    // acg.rip contains .torrent bt.acg.gg contains down.php
    if ([item.magnet.absoluteString containsString:@".torrent"] ||
        [item.magnet.absoluteString containsString:@"down.php"]) {
        [[DMHYDownloader downloader] downloadTorrentWithURL:item.magnet];
        [self stopAnimatingProgressIndicator];
        return;
    }
    if ([item.magnet.absoluteString containsString:@"magnet:?xt=urn:btih:"]) {
        [self stopAnimatingProgressIndicator];
        [self openMagnetWith:item.magnet];
        return;
    }
}

- (void)openMagnetWith:(NSURL *)magnet {
    [[NSWorkspace sharedWorkspace] openURL:magnet];
}


#pragma mark - NSTextFieldDelegate

- (void)controlTextDidEndEditing:(NSNotification *)notification {
    if ([notification.userInfo[@"NSTextMovement"] intValue] == NSReturnTextMovement) {
        [self setupData:self];
    }
}


#pragma mark - ProgressIndicator

- (void)startAnimatingProgressIndicator {
    [self.indicator startAnimation:self];
    self.info.stringValue = @"";
}

- (void)stopAnimatingProgressIndicator {
    [self.indicator stopAnimation:self];
}

#pragma mark - Utils

/**
 *  Open Torrent Description Page in default browser.
 *
 *  @param sender
 */
- (void)openTorrentLink:(id) sender {
    NSInteger rowIndex = self.currentRow;
    if (rowIndex < 0) {
        //Click column header do nothing.
        return;
    }
    TorrentItem *item = self.torrents[rowIndex];
    [[NSWorkspace sharedWorkspace] openURL:item.link];
}

- (void)setupAutomaticDownloadNewTorrent {
    [self.checker automaticDownloadTorrent];
    
}

- (void)setupMenuItems {
    NSMenu *mainMenu = [[NSApplication sharedApplication] mainMenu];
    NSMenuItem *fileMenuItem = [mainMenu itemWithTitle:@"File"];
    NSMenu *fileSubMenu = [fileMenuItem submenu];
    // 设置快捷键时默认 mask 是 command，然后加单键使用小写字母（如：@“r” == cmd+r），想要多加个 shift mask，用大写字母。（如：@“R” == cmd+shift+r）
    NSMenuItem *menuRefreshSubKeywordMenuItem = [[NSMenuItem alloc] initWithTitle:@"手动检查订阅更新"
                                                                      action:@selector(setupAutomaticDownloadNewTorrent)
                                                                    keyEquivalent:@"r"];
    [fileSubMenu addItem:menuRefreshSubKeywordMenuItem];
    
}

@end
