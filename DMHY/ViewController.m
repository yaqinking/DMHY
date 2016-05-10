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
#import "DMHYAPI.h"
#import "DMHYTorrent.h"
#import "DMHYKeyword.h"
#import "DMHYCoreDataStackManager.h"
#import "TorrentItem.h"
#import "TitleTableCellView.h"
#import "NavigationView.h"
// Networking and XML parse
#import "AFNetworking.h"
#import "AFOnoResponseSerializer.h"
#import "Ono.h"
#import "DMHYXMLDataManager.h"
#import "DMHYJSONDataManager.h"
#import "NSTableView+ContextMenu.h"
#import <Carbon/Carbon.h>

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

@property (weak) IBOutlet NSTextField *keyword;
@property (weak) IBOutlet NSTextField *info;

@property (nonatomic, strong) NSMutableArray *torrents;
@property (nonatomic, strong) NSArray        *fetchedTorrents;
@property (nonatomic, strong) NSString       *searchURLString;
@property (nonatomic, strong) NSString       *today;
@property (nonatomic, strong) NSString       *yesterday;
@property (nonatomic, strong) NSString       *dayBeforeYesterday;
@property (nonatomic, strong) NSDictionary   *currentSite;

@property (nonatomic) BOOL isMagnetLink;
@property (nonatomic) BOOL isSubKeyword;
@property (nonatomic) BOOL dontDownloadCollection;

@property (nonatomic) NSInteger fetchInterval;
@property (nonatomic) NSInteger currentRow;

@property (nonatomic, strong) NSDateFormatter     *dateFormater;

@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, strong) NSTimer *timer;
@end

@implementation ViewController
@synthesize managedObjectContext = _context;

- (void)viewDidLoad {
    [super viewDidLoad];
//    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:DMHYThemeKey];
    [self observeNotification];
    [self setupPreference];
    [self setupTableViewStyle];
//    [self checkResponseType];
    [self setupData:self];
    [self setupRepeatTask];
    [self setupMenuItems];
    [self setupTableViewDoubleAction];
    self.keyword.delegate       = self;
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
}

#pragma mark - Setup

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
- (void)checkResponseType {
    NSString *responseType = self.currentSite[SiteResponseType];
    if (responseType == nil) {
        [SitePreferenceController setupDefaultSites];
    }
}
*/
/**
 *  Retrive saved preference value and set to self variable.
 */
- (void)setupPreference {
    self.isMagnetLink  = [PreferenceController preferenceDownloadLinkType];
    self.fetchInterval = [PreferenceController preferenceFetchInterval];
    self.dontDownloadCollection = [PreferenceController preferenceDontDownloadCollection];
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
    [self startAnimatingProgressIndicator];
    [self configureSearchURLString];
    [self.torrents removeAllObjects];
    if ([self isCurrentSiteResponseJSONData]) {
        [[DMHYJSONDataManager manager] GET:self.searchURLString fromSite:self.currentSite[SiteNameKey]];
    } else {
       [[DMHYXMLDataManager manager] GET:self.searchURLString fromSite:self.currentSite[SiteNameKey]];
    }
}

#pragma mark - Notification Data Load Completed

- (void)handleXMLDataLoadCompleted:(NSNotification *)noti {
    self.torrents = noti.object;
    [self reloadDataAndStopIndicator];
}

- (void)handleJSONDataLoadCompleted:(NSNotification *)noti {
    self.torrents = noti.object;
    [self reloadDataAndStopIndicator];
}

- (void)reloadDataAndStopIndicator {
    [self stopAnimatingProgressIndicator];
    [self.tableView reloadData];
    self.info.stringValue = @"加载完成 w";
}

- (void)setErrorInfoAndStopIndicator {
    self.info.stringValue = @"电波很差 poi 或者 花园酱傲娇了 w";
    [self stopAnimatingProgressIndicator];
}

/**
 *  Set search url string to download site.
 */
- (void)configureSearchURLString {
    if ([self isLoadHomePage]) {
        NSString *siteMain = self.currentSite[SiteMainKey];
        self.searchURLString = siteMain;
    } else {
        NSString *siteSearch = self.currentSite[SiteSearchKey];
        self.searchURLString = [[NSString stringWithFormat:siteSearch, self.keyword.stringValue] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    }
    NSLog(@"Site Info %@ %@ %@",self.currentSite[SiteNameKey],self.currentSite[SiteResponseType], self.currentSite[SiteMainKey]);
}

#pragma mark - Repeat Task

/**
 *  Schedule auto download new torrent task.
 */
- (void)setupRepeatTask {
    if (self.fetchInterval != 0) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:self.fetchInterval
                                                      target:self
                                                    selector:@selector(setupAutomaticDownloadNewTorrent)
                                                    userInfo:nil
                                                     repeats:YES];
    }
}

/**
 *  Get today then invoke automaticDownloadTorrentWithWeekday:
 */
- (void)setupAutomaticDownloadNewTorrent {
    NSDate *now            = [NSDate new];
    NSCalendar* cal        = [NSCalendar currentCalendar];
    NSDateComponents *com  = [cal components:NSCalendarUnitWeekday fromDate:now];
    NSInteger weekdayToday = [com weekday];// 1 = Sunday, 2 = Monday, etc.
    self.today              = [DMHYTool cn_weekdayFromWeekdayCode:weekdayToday];
    self.yesterday          = [DMHYTool cn_weekdayFromWeekdayCode:weekdayToday-1];
    self.dayBeforeYesterday = [DMHYTool cn_weekdayFromWeekdayCode:weekdayToday-2];
    [self automaticDownloadTorrentWithWeekday:self.today];
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
    [DMHYNotification addObserver:self selector:@selector(handleXMLDataLoadCompleted:) name:DMHYXMLDataLoadCompletedNotification];
    [DMHYNotification addObserver:self selector:@selector(handleJSONDataLoadCompleted:) name:DMHYJSONDataLoadCompletedNotification];
    [DMHYNotification addObserver:self selector:@selector(setErrorInfoAndStopIndicator) name:DMHYXMLDataLoadErrorNotification];
    [DMHYNotification addObserver:self selector:@selector(setErrorInfoAndStopIndicator) name:DMHYJSONDataLoadErrorNotification];
    [DMHYNotification addObserver:self selector:@selector(handleDownloadTypeChanged)   name:DMHYDownloadLinkTypeNotification];
    [DMHYNotification addObserver:self selector:@selector(handleDownloadSiteChanged)   name:DMHYDownloadSiteChangedNotification];
    [DMHYNotification addObserver:self selector:@selector(handleSelectKeywordChanged:) name:DMHYSelectKeywordChangedNotification];
    [DMHYNotification addObserver:self selector:@selector(handleFetchIntervalChanged)  name:DMHYFetchIntervalChangedNotification];
    [DMHYNotification addObserver:self selector:@selector(handleThemeChanged)          name:DMHYThemeChangedNotification];
    [DMHYNotification addObserver:self selector:@selector(handleDoubleActionChanged)   name:DMHYDoubleActionChangedNotification];
    [DMHYNotification addObserver:self selector:@selector(handleMainTableViewRowStyleChanged) name:DMHYMainTableViewRowStyleChangedNotification];
    [DMHYNotification addObserver:self selector:@selector(handleDontDownloadCollectionChanged) name:DMHYDontDownloadCollectionKeyDidChangedNotification];
}

- (void)handleDownloadSiteChanged {
    self.currentSite = nil;
    [self setupPreference];
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
        self.keyword.stringValue = @"";
    } else {
        self.keyword.stringValue = keywordStr;
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
    [self.timer invalidate];
    self.timer         = nil;
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

- (NSDictionary *)currentSite {
    if (!_currentSite) {
        NSDictionary *siteDMHY = @{ SiteNameKey : @"share.dmhy.org",
                                    SiteMainKey : DMHYRSS,
                                    SiteSearchKey : DMHYSearchByKeyword,
                                    SiteResponseType : SiteResponseXML };
//        _currentSite = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kCurrentSite];
        _currentSite = siteDMHY;
    }
    return _currentSite;
}

- (NSString *)searchURLString {
    if (!_searchURLString) {
        _searchURLString = [NSString new];
    }
    return _searchURLString;
}

#pragma mark - Check

- (BOOL)isCurrentSiteResponseJSONData {
    NSString *responseFileType = self.currentSite[SiteResponseType];
    return [responseFileType isEqualToString:@"JSON"] ? YES : NO;
}

- (BOOL)isCurrentSiteResponseXMLData {
    NSString *responseFileType = self.currentSite[SiteResponseType];
    return [responseFileType isEqualToString:@"XML"] ? YES : NO;
}

/**
 *  判断搜索关键字是否为空，如果为空的话加载主页，否则加载搜索页
 *
 *  @return YES 加载主页数据
 */
- (BOOL)isLoadHomePage {
    return [self.keyword.stringValue isEqualToString:@""] ? YES : NO;
}

- (BOOL)isCurrentSiteACGGG {
    NSString *siteName = self.currentSite[SiteNameKey];
    return [siteName isEqualToString:ACGGG] ? YES : NO;
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
    if ([self isCurrentSiteACGGG]) {
        // As acggg the enclose url is download url
        if (self.isMagnetLink) {
            [[DMHYDownloader downloader] downloadTorrentWithURL:item.magnet];
            return;
        }
    }
    if (self.isMagnetLink) {
        [self stopAnimatingProgressIndicator];
        [self openMagnetWith:item.magnet];
        return;
    } else {
        [self extractTorrentDownloadURLWithURLString:item.link.absoluteString];
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

#pragma mark - Automatic Download Today Keywords Torrents

/**
 *  Check wheather today has new torrent. 其它分类下的每次都 fetch。
 *  Then invoke downloadNewTorrents:
 *  @param weekday today string
 */
- (void)automaticDownloadTorrentWithWeekday:(NSString *) weekday {
    NSFetchRequest *requestTodayKeywords = [self fetchRequestTodayKeywords];
    NSArray *fetchedKeywords = [self.managedObjectContext executeFetchRequest:requestTodayKeywords
                                                     error:NULL];
    
    for (DMHYKeyword *weekdayKeyword in fetchedKeywords) {
        NSLog(@"%@ has %lu bangumi.", weekdayKeyword.keyword, weekdayKeyword.subKeywords.count);
        for (DMHYKeyword *keyword in weekdayKeyword.subKeywords) {
            NSLog(@"%@ => %@", weekdayKeyword.keyword, keyword.keyword);
            NSString *searchStr = [[NSString stringWithFormat:DMHYSearchByKeyword,keyword.keyword]
                                   stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
            NSURL *url = [NSURL URLWithString:searchStr];
            NSURLRequest *request = [NSURLRequest requestWithURL:url];
            AFHTTPRequestOperation *op = [[AFHTTPRequestOperation alloc] initWithRequest:request];
            if (op) {
                op.responseSerializer = [AFOnoResponseSerializer XMLResponseSerializer];
            }
            
            [op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation * _Nonnull operation, ONOXMLDocument *xmlDoc) {
                [xmlDoc enumerateElementsWithXPath:kXPathTorrentItem usingBlock:^(ONOXMLElement *element, NSUInteger idx, BOOL *stop) {
                    NSString *title                     = [[element firstChildWithTag:@"title"] stringValue];
                    if (self.dontDownloadCollection) {
                        if ([title containsString:@"合集"] ||
                            [title containsString:@"全集"]) {
                            return;
                        }
                    }
                    NSString *fliter = [[NSUserDefaults standardUserDefaults] stringForKey:FliterKeywordKey];
                    
                    if (![fliter isEqualToString:@""] && (fliter.length != 0)) {
                        __block NSMutableString *containFliterResult = [NSMutableString new];
                        NSArray *flites = [fliter componentsSeparatedByString:@" "];
                        [flites enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                            if ([title containsString:obj]) {
                                [containFliterResult appendString:@"1"];
                            } else {
                                [containFliterResult appendString:@"0"];
                            }
                        }];
                        if ([containFliterResult containsString:@"0"]) {
                            return ;
                        }
                    }
                    
                    NSFetchRequest *requestExistTorrent = [NSFetchRequest fetchRequestWithEntityName:@"Torrent"];
                    requestExistTorrent.predicate       = [NSPredicate predicateWithFormat:@"title == %@",title];
                    NSArray *existsTorrents = [self.managedObjectContext executeFetchRequest:requestExistTorrent
                                                                                       error:NULL];
                    if (!existsTorrents.count) {
                        //                    NSLog(@"Didn't exist %@",title);
                        DMHYTorrent *item = [NSEntityDescription insertNewObjectForEntityForName:@"Torrent"
                                                                          inManagedObjectContext:self.managedObjectContext];
                        NSString *dateString = [[element firstChildWithTag:@"pubDate"] stringValue];
                        item.pubDate = [[DMHYTool tool] formatedDateFromDMHYDateString:dateString];
                        item.title = [[element firstChildWithTag:@"title"] stringValue];
                        item.link = [[element firstChildWithTag:@"link"] stringValue];
                        item.author = [[element firstChildWithTag:@"author"] stringValue];
                        NSString *magnetXPath = [NSString stringWithFormat:@"//item[%lu]//enclosure/@url", (idx+1)];
                        NSString *magStr     = [[element firstChildWithXPath:magnetXPath] stringValue];
                        item.magnet = magStr;
                        item.isNewTorrent = @YES;
                        item.isDownloaded = @NO;
                        item.keyword = keyword;
                        NSLog(@"[New %@]",item.title);
                        NSError *error = nil;
                        if (![self.managedObjectContext save:&error]) {
                            NSLog(@"Error %@",error);
                        }
                        [self downloadNewTorrents];
                    } else {
                        *stop = 1;
                    }
                }];
            } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
                /*
                 self.info.stringValue = @"电波很差 poi 或者 花园酱傲娇了 w";
                 [self stopAnimatingProgressIndicator];
                 NSLog(@"Error %@",[error localizedDescription]);
                 */
            }];
            [[NSOperationQueue mainQueue] addOperation:op];
        }
    }
    NSDate *time = [NSDate new];
    self.info.stringValue = [NSString stringWithFormat:@"上次检查时间 %@",[[DMHYTool tool] infoDateStringFromDate:time]];
}

/**
 *  Fetch info from database then check if it has new torrent then invoke extractTorrentDownloadURLWithURLString:
 */
- (void)downloadNewTorrents {
    NSFetchRequest *request = [self fetchRequestTodayKeywords];
    NSArray *fetchedKeywords = [self.managedObjectContext executeFetchRequest:request
                                                              error:NULL];

    for (DMHYKeyword *weekdayKeyword in fetchedKeywords) {
        for (DMHYKeyword *keyword in weekdayKeyword.subKeywords) {
            for (DMHYTorrent *torrent in keyword.torrents) {
                BOOL isNewTorrent = torrent.isNewTorrent.boolValue;
                if (isNewTorrent) {
                    torrent.isNewTorrent = @NO;
                    if (self.isMagnetLink) {
                        [self openMagnetWith:[NSURL URLWithString:torrent.magnet]];
                    } else {
                        [self extractTorrentDownloadURLWithURLString:torrent.link];
                    }
                }
            }
        }
    }
    
    if ([self.managedObjectContext hasChanges]) {
        [self.managedObjectContext save:NULL];
        [DMHYNotification postNotificationName:DMHYDatabaseChangedNotification];
    }
}

/**
 *  Init a Today Keywords Fetch Request
 *
 *  @return fetch request with today keywords
 */
- (NSFetchRequest *)fetchRequestTodayKeywords {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:DMHYKeywordEntityKey];
    request.predicate = [NSPredicate predicateWithFormat:@"keyword == %@ OR keyword == %@ OR keyword == %@ OR keyword == %@",self.today, self.yesterday, self.dayBeforeYesterday, kWeekdayOther];
    return request;
}

/**
 *  提取动漫花园条目介绍页面的种子下载链接
 *
 *  @param urlString 条目页面的 URL
 */
- (void)extractTorrentDownloadURLWithURLString:(NSString *)urlString {
    [self startAnimatingProgressIndicator];
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    AFHTTPRequestOperation *op = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    if (op) {
        op.responseSerializer = [AFOnoResponseSerializer HTMLResponseSerializer];
    }
    [op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation * _Nonnull operation, ONOXMLDocument *doc ){
        
        dispatch_async(dispatch_queue_create("download queue", nil), ^{
            
            __block NSMutableString *downloadString = [NSMutableString new];
            [doc enumerateElementsWithXPath:kXpathTorrentDirectDownloadLink usingBlock:^(ONOXMLElement *element, NSUInteger idx, BOOL *stop) {
                downloadString = [[element stringValue] mutableCopy];
                *stop = YES;
            }];
           
            NSURL *dlURL = [NSURL URLWithString:[NSString stringWithFormat:DMHYURLPrefixFormat,downloadString]];
            [[DMHYDownloader downloader] downloadTorrentWithURL:dlURL];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self stopAnimatingProgressIndicator];
            });
        });
        
    } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
        NSLog(@"Error %@",[error localizedDescription]);
        [self stopAnimatingProgressIndicator];
    }];
    
    [[NSOperationQueue mainQueue] addOperation:op];
}

- (NSManagedObjectContext *)managedObjectContext {
    if (!_context) {
        _context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        _context.persistentStoreCoordinator = [[DMHYCoreDataStackManager sharedManager] persistentStoreCoordinator];
        _context.undoManager = nil;
    }
    return _context;
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
