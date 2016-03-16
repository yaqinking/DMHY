//
//  ViewController.m
//  DMHY
//
//  Created by 小笠原やきん on 15/8/30.
//  Copyright © 2015年 yaqinking. All rights reserved.
//

#import "ViewController.h"
#import "AFNetworking.h"
#import "AFOnoResponseSerializer.h"
#import "DMHYAPI.h"
#import "Ono.h"
#import "TorrentItem.h"
#import "DMHYTorrent.h"
#import "DMHYKeyword.h"
#import "TitleTableCellView.h"
#import "NavigationView.h"
#import "PreferenceController.h"
#import "DMHYCoreDataStackManager.h"
#import "DMHYTool.h"

@interface ViewController()<NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate>

@property (weak) IBOutlet NSTableView         *tableView;
@property (weak) IBOutlet NSProgressIndicator *indicator;

@property (weak) IBOutlet NSTextField *keyword;
@property (weak) IBOutlet NSTextField *info;

@property (nonatomic, strong) NSMutableArray *torrents;
@property (nonatomic, strong) NSString       *searchURLString;
@property (nonatomic, strong) NSString       *today;
@property (nonatomic, strong) NSString       *yesterday;
@property (nonatomic, strong) NSString       *dayBeforeYesterday;

@property (nonatomic, strong) NSURL          *savePath;

@property (nonatomic) BOOL isSearch;
@property (nonatomic) BOOL isMagnetLink;
@property (nonatomic) BOOL isSubKeyword;
@property (nonatomic) NSInteger downloadSite;
@property (nonatomic) NSInteger fetchInterval;

@property (nonatomic, strong) AFURLSessionManager *manager;
@property (nonatomic, strong) AFHTTPSessionManager *httpManager;
@property (nonatomic, strong) NSDateFormatter     *dateFormater;

@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, strong) NSArray *fetchedTorrents;
@property (nonatomic, strong) NSTimer *timer;
@end

@implementation ViewController
@synthesize managedObjectContext = _context;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupTableViewStyle];
    [self setupData:self];
    [self setupPreference];
    [self observeNotification];
    [self setupRepeatTask];

    self.keyword.delegate       = self;
    
    self.tableView.doubleAction = @selector(openTorrentLink:);

}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    
    // Update the view, if already loaded.
}

#pragma mark - Setup

- (void)setupTableViewStyle {
    self.tableView.usesAlternatingRowBackgroundColors = YES;
    self.tableView.rowSizeStyle                       = NSTableViewRowSizeStyleLarge;
    self.tableView.columnAutoresizingStyle            = NSTableViewUniformColumnAutoresizingStyle;
    [self.tableView sizeLastColumnToFit];
}

/**
 *  Retrive saved preference value and set to self variable.
 */
- (void)setupPreference {
    self.isMagnetLink  = [PreferenceController preferenceDownloadLinkType];
    self.savePath      = [PreferenceController preferenceSavePath];
    self.fetchInterval = [PreferenceController preferenceFetchInterval];
    self.downloadSite  = [PreferenceController preferenceDownloadSite];
}

- (BOOL)isCurrentSiteBangumiMoe {
    return ([PreferenceController preferenceDownloadSite] == DMHYSiteBangumiMoe) ? YES : NO;
}

- (BOOL)isCurrentSiteACGGG {
    return ([PreferenceController preferenceDownloadSite] == DMHYSiteACGGG) ? YES : NO;
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
    if ([self isCurrentSiteBangumiMoe]) {
        [self setupJSONData];
        return;
    }
    if (self.isSearch) {
        [self.torrents removeAllObjects];
    }
    
    NSURL *url = [NSURL URLWithString:self.searchURLString];
    NSLog(@"url -> %@",url);
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    AFHTTPRequestOperation *op = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    BOOL isACGGGSite = (self.downloadSite == DMHYSiteACGGG);
    // Check code it works but mmm.
    if (op && isACGGGSite) {
        op.responseSerializer = [AFOnoResponseSerializer XMLResponseSerializer];
        op.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"application/rss+xml"];
    } else {
        op.responseSerializer = [AFOnoResponseSerializer XMLResponseSerializer];
    }
    
    [op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation * _Nonnull operation, ONOXMLDocument *xmlDoc) {
        
        [xmlDoc enumerateElementsWithXPath:kXPathTorrentItem usingBlock:^(ONOXMLElement *element, NSUInteger idx, BOOL *stop) {
            TorrentItem *item = [self torrentItemWithElement:element];
            [self.torrents addObject:item];
        }];
        [self reloadDataAndStopIndicator];
    } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
        // Do this check when first start can't load data. mmm.
        if ((self.downloadSite == DMHYSiteACGGG) && [self.keyword.stringValue isEqualToString:@""]) {
            [self setupData:nil];
            return ;
        }
        [self setInfoAndStopIndicator];
        NSLog(@"Error %@",[error localizedDescription]);
    }];
    [[NSOperationQueue mainQueue] addOperation:op];
}

- (void)setupJSONData {
    if (self.isSearch) {
        [self.torrents removeAllObjects];
    }
    if ([self.keyword.stringValue isEqualToString:@""]) {
        self.searchURLString = DMHYBangumiMoeRSS;
    }
    //Bangumi Moe Only Magnet link and open torrent page.
    [self.httpManager GET:self.searchURLString
               parameters:nil
                  success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
                    NSArray *torrentsArray = [responseObject valueForKey:@"torrents"];
                    for (NSDictionary *dict in torrentsArray) {
                        TorrentItem *item = [self torrentItemWithElement:dict];
                        [self.torrents addObject:item];
                    }
                    [self reloadDataAndStopIndicator];
                } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                    [self setInfoAndStopIndicator];
                    NSLog(@"Error %@",[error localizedDescription]);
                }];
}

- (void)reloadDataAndStopIndicator {
    [self stopAnimatingProgressIndicator];
    [self.tableView reloadData];
    self.info.stringValue = @"加载完成 w";
}

- (void)setInfoAndStopIndicator {
    self.info.stringValue = @"电波很差 poi 或者 花园酱傲娇了 w";
    [self stopAnimatingProgressIndicator];
 
}
/**
 *  Get a TorrentItem object from ONOXMLElemnt or JSON Dictionary.
 *
 *  @param element The ONOXMLElement or JSON Dictonary
 *
 *  @return torrent item with queryed value
 */
- (TorrentItem *)torrentItemWithElement:(id)element {
    TorrentItem *item    = [[TorrentItem alloc] init];
    if ([element isKindOfClass:[ONOXMLElement class]]) {
        NSString *dateString = [[element firstChildWithTag:@"pubDate"] stringValue];
        item.pubDate         = [self formatedDateStringFromDMHYDateString:dateString];
        item.title           = [[element firstChildWithTag:@"title"] stringValue];
        item.link            = [NSURL URLWithString:[[element firstChildWithTag:@"link"] stringValue]];
        item.author          = [[element firstChildWithTag:@"author"] stringValue];
        NSString *magStr     = [[element firstChildWithXPath:@"//enclosure/@url"] stringValue];
        item.magnet          = [NSURL URLWithString:magStr];
    } else if ([element isKindOfClass:[NSDictionary class]]) {
        NSString *pubDate = element[@"publish_time"];
        NSString *link = element[@"_id"];
        NSString *team_name = [element valueForKeyPath:@"team.name"];
        if (!team_name) {
            team_name = [element valueForKeyPath:@"uploader.username"];
        }
        item.title   = element[@"title"];
        item.magnet  = [NSURL URLWithString:element[@"magnet"]];
        item.link    = [NSURL URLWithString:[NSString stringWithFormat:DMHYBangumiMoeOpenTorrentPagePrefixFormat,link]];
        item.pubDate = pubDate;
        item.author  = team_name;
    }
    return item;
}

/**
 *  Set search url string to download site.
 */
- (void)configureSearchURLString {
    if ([self.keyword isEqual:@""]) {
        self.isSearch = NO;
        switch (self.downloadSite) {
            case DMHYSiteDefault:
                self.searchURLString = DMHYRSS;
                break;
            case DMHYSiteDandanplay:
                self.searchURLString = DMHYdandanplayRSS;
                break;
            case DMHYSiteACGGG:
                self.searchURLString = DMHYACGGGRSS;
                break;
            case DMHYSiteBangumiMoe:
                self.searchURLString = DMHYBangumiMoeRSS;
                break;
            default:
                break;
        }
    } else {
        self.isSearch = YES;
        switch (self.downloadSite) {
            case DMHYSiteDefault:
                self.searchURLString = [[NSString stringWithFormat:DMHYSearchByKeyword,self.keyword.stringValue]
                                        stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
                break;
            case DMHYSiteDandanplay:
                self.searchURLString = [[NSString stringWithFormat:DMHYdandanplaySearchByKeyword,self.keyword.stringValue]
                                        stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
                break;
            case DMHYSiteACGGG:
                self.searchURLString = [[NSString stringWithFormat:DMHYACGGGSearchByKeyword,self.keyword.stringValue]
                                        stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
                break;
            case DMHYSiteBangumiMoe:
                self.searchURLString = [[NSString stringWithFormat:DMHYBangumiMoeSearchByKeyword,self.keyword.stringValue]
                                        stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
                break;
            default:
                break;
        }
    }
}

#pragma mark - Repeat Task

/**
 *  Schedule auto download new torrent task.
 */
- (void)setupRepeatTask {
    //self.fetchInterval
    self.timer = [NSTimer scheduledTimerWithTimeInterval:self.fetchInterval
                                                      target:self
                                                    selector:@selector(setupAutomaticDownloadNewTorrent)
                                                    userInfo:nil
                                                     repeats:YES];
}

/**
 *  Get today then invoke automaticDownloadTorrentWithWeekday:
 */
- (void)setupAutomaticDownloadNewTorrent {
    NSDate *now            = [NSDate new];
    NSCalendar* cal        = [NSCalendar currentCalendar];
    NSDateComponents *com  = [cal components:NSCalendarUnitWeekday fromDate:now];
    NSInteger weekdayToday = [com weekday];// 1 = Sunday, 2 = Monday, etc.
    self.today             = [DMHYTool cn_weekdayFromWeekdayCode:weekdayToday];
    switch (weekdayToday) {
        case 1:
            self.yesterday = [DMHYTool cn_weekdayFromWeekdayCode:7];
            self.dayBeforeYesterday = [DMHYTool cn_weekdayFromWeekdayCode:6];
            break;
        case 2:
            self.yesterday = [DMHYTool cn_weekdayFromWeekdayCode:weekdayToday-1];
            self.dayBeforeYesterday = [DMHYTool cn_weekdayFromWeekdayCode:7];
            break;
        default:
            self.yesterday = [DMHYTool cn_weekdayFromWeekdayCode:weekdayToday-1];
            self.dayBeforeYesterday = [DMHYTool cn_weekdayFromWeekdayCode:weekdayToday-2];
            break;
    }
    [self automaticDownloadTorrentWithWeekday:self.today];
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.torrents.count;
}


#pragma mark - NSTableViewDelegate

// Cell based
//- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
//    TorrentItem *torrent = [self.torrents objectAtIndex:row];
//
//    return [torrent valueForKey:tableColumn.identifier];
//}

// View based
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

#pragma mark - Notification

- (void)observeNotification {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(handleDownloadTypeChanged:)
                               name:DMHYDownloadLinkTypeNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(handleSavaPathChanged:)
                               name:DMHYSavePathChangedNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(handleSelectKeywordChanged:)
                               name:DMHYSelectKeywordChangedNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(handleFetchIntervalChanged:)
                               name:DMHYFetchIntervalChangedNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(handleThemeChanged:)
                               name:DMHYThemeChangedNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(handleDownloadSiteChanged:)
                               name:DMHYDownloadSiteChangedNotification
                             object:nil];
}

- (void)handleDownloadSiteChanged:(NSNotification *)noti {
    [self setupPreference];
}

- (void)handleDownloadTypeChanged:(NSNotification *)noti {
    [self setupPreference];
}

- (void)handleSavaPathChanged:(NSNotification *)noti {
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

- (void)handleFetchIntervalChanged:(NSNotification *)noti {
    [self.timer invalidate];
    self.timer         = nil;
    self.fetchInterval = [PreferenceController preferenceFetchInterval];
    [self setupRepeatTask];
}

- (void)handleThemeChanged:(NSNotification *)noti {
    [self.view setNeedsDisplay:YES];
}

#pragma mark - Property Initialization

- (NSMutableArray *)torrents {
    if (!_torrents) {
        _torrents = [NSMutableArray array];
    }
    return _torrents;
}

- (NSString *)searchURLString {
    if (!_searchURLString) {
        _searchURLString = [NSString new];
    }
    return _searchURLString;
}

- (AFURLSessionManager *)manager {
    if (!_manager) {
        NSURLSessionConfiguration *conf = [NSURLSessionConfiguration defaultSessionConfiguration];
        _manager                        = [[AFURLSessionManager alloc] initWithSessionConfiguration:conf];
    }
    return _manager;
}

- (AFHTTPSessionManager *)httpManager {
    if (!_httpManager) {
        _httpManager = [AFHTTPSessionManager manager];
        _httpManager.responseSerializer = [AFJSONResponseSerializer serializer];
    }
    return _httpManager;
}

- (NSDateFormatter *)dateFormater {
    if (!_dateFormater) {
        _dateFormater = [[NSDateFormatter alloc] init];
    }
    return _dateFormater;
}

#pragma mark - Download

/**
 *  Query clicked row torrent download url then download torrent.
 *
 *  @param sender
 */
- (IBAction)queryDownloadURL:(id)sender {
    //NSLog(@"queryDownloadURL");
    [self startAnimatingProgressIndicator];
    NSInteger row     = [self.tableView rowForView:sender];
    TorrentItem *item = (TorrentItem *)[self.torrents objectAtIndex:row];
    if ([self isCurrentSiteACGGG]) {
        // As acggg the enclose url is download url
        if (self.isMagnetLink) {
            [self downloadTorrentWithURL:item.magnet];
            return;
        }
    }
    NSURL *url;
    if (self.isMagnetLink) {
        url = item.magnet;
        [self stopAnimatingProgressIndicator];
        [[NSWorkspace sharedWorkspace] openURL:url];
        return;
    } else {
        //NSLog(@"not returned download torrent");
        url = item.link;
    }
    //NSLog(@"%@",item.link);
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    AFHTTPRequestOperation *op = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    if (op) {
        op.responseSerializer = [AFOnoResponseSerializer HTMLResponseSerializer];
    }
    [op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation * _Nonnull operation, ONOXMLDocument *doc ){
        
        dispatch_async(dispatch_queue_create("download queue", nil), ^{
            NSMutableArray *urlArr = [NSMutableArray new];
            for (ONOXMLElement *element in [doc XPath:kTest]) {
                [urlArr addObject:[element stringValue]];
            }
            
            NSString *downloadString = [urlArr firstObject];
            //NSLog(@"DL: %@",downloadString);
            NSURL *dlURL = [NSURL URLWithString:[NSString stringWithFormat:DMHYURLPrefixFormat,downloadString]];
            [self downloadTorrentWithURL:dlURL];
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

/**
 *  Download torrent with given url.
 *
 *  @param url The URL to download
 */
- (void)downloadTorrentWithURL:(NSURL *)url {
    [self startAnimatingProgressIndicator];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLSessionDownloadTask *downloadTask = [self.manager downloadTaskWithRequest:request
                                                                     progress:nil
                                                                  destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
                                                                      NSString *fileName = [response suggestedFilename];
                                                                      [self postUserNotificationWithFileName:fileName];
                                                                      return [self.savePath URLByAppendingPathComponent:[response suggestedFilename]];
                                                                      
                                                                  } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nonnull filePath, NSError * _Nonnull error) {
                                                                      //NSLog(@"Download to : %@",filePath);
                                                                      if ([self.managedObjectContext hasChanges]) {
                                                                          [self.managedObjectContext save:NULL];
                                                                      }
                                                                      [self stopAnimatingProgressIndicator];
                                                                  }];
    [downloadTask resume];
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

- (NSString *)formatedDateStringFromDMHYDateString:(NSString *)dateString {
//    NSLog(@"dateFormater %@",self.dateFormater);
    self.dateFormater.dateFormat = @"EEE, dd MM yyyy HH:mm:ss Z";
    self.dateFormater.locale     = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    NSDate *longDate             = [self.dateFormater dateFromString:dateString];
    self.dateFormater.dateFormat = @"EEE HH:mm:ss yy-MM-dd";
    self.dateFormater.locale     = [[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];
    return [self.dateFormater stringFromDate:longDate];
    
}

- (NSDate *)formatedDateFromDMHYDateString:(NSString *)dateString {
    self.dateFormater.dateFormat = @"EEE, dd MM yyyy HH:mm:ss Z";
    self.dateFormater.locale     = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    NSDate *longDate             = [self.dateFormater dateFromString:dateString];
    return longDate;
}

/**
 *  Open Torrent Description Page in default browser.
 *
 *  @param sender
 */
- (void)openTorrentLink:(id) sender {
    NSInteger rowIndex = self.tableView.clickedRow;
    if (rowIndex < 0) {
        //Click column header do nothing.
        return;
    }
    TorrentItem *item = self.torrents[rowIndex];
    NSLog(@"Item Link %@",item.link);
    [[NSWorkspace sharedWorkspace] openURL:item.link];
}

/**
 *  Remove notification observer.
 */
- (void)dealloc {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self
                                  name:DMHYDownloadLinkTypeNotification
                                object:nil];
    [notificationCenter removeObserver:self
                                  name:DMHYSavePathChangedNotification
                                object:nil];
    [notificationCenter removeObserver:self
                                  name:DMHYSelectKeywordChangedNotification
                                object:nil];
}

#pragma mark - Automatic Download Today Keywords Torrents

/**
 *  Check wheather today has new torrent. 其它分类下的每次都 fetch。
 *  Then invoke downloadNewTorrents:
 *  @param weekday today string
 */
- (void)automaticDownloadTorrentWithWeekday:(NSString *) weekday {
    NSFetchRequest *requestTodayKeywords = [NSFetchRequest fetchRequestWithEntityName:@"Keyword"];
    requestTodayKeywords.predicate = [NSPredicate predicateWithFormat:@"keyword == %@ OR keyword == %@ OR keyword == %@ OR keyword == %@",self.today, self.yesterday, self.dayBeforeYesterday, kWeekdayOther];
    
    NSArray *fetchedKeywords = [self.managedObjectContext executeFetchRequest:requestTodayKeywords
                                                     error:NULL];
    for (DMHYKeyword *weekdayKeyword in fetchedKeywords) {
        NSLog(@"Today has %lu bangumi.",weekdayKeyword.subKeywords.count);
        for (DMHYKeyword *keyword in weekdayKeyword.subKeywords) {
            NSLog(@"Today %@ Keyword %@", weekdayKeyword.keyword, keyword.keyword);
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
                    NSFetchRequest *requestExistTorrent = [NSFetchRequest fetchRequestWithEntityName:@"Torrent"];
                    requestExistTorrent.predicate       = [NSPredicate predicateWithFormat:@"title == %@",title];
                    NSArray *existsTorrents = [self.managedObjectContext executeFetchRequest:requestExistTorrent
                                                                                       error:NULL];
                    if (!existsTorrents.count) {
                        //                    NSLog(@"Didn't exist %@",title);
                        DMHYTorrent *item = [NSEntityDescription insertNewObjectForEntityForName:@"Torrent"
                                                                          inManagedObjectContext:self.managedObjectContext];
                        NSString *dateString = [[element firstChildWithTag:@"pubDate"] stringValue];
                        item.pubDate = [self formatedDateFromDMHYDateString:dateString];
                        item.title = [[element firstChildWithTag:@"title"] stringValue];
                        item.link = [[element firstChildWithTag:@"link"] stringValue];
                        item.author = [[element firstChildWithTag:@"author"] stringValue];
                        NSString *magStr = [[element firstChildWithXPath:@"//enclosure/@url"] stringValue];
                        item.magnet = magStr;
                        item.isNewTorrent = @YES;
                        item.isDownloaded = @NO;
                        item.keyword = keyword;
                        NSLog(@"[New %@]",item.title);
                    } else {
                        //                    NSLog(@"Exist");
                        return ;
                    }
                }];
                NSError *error = nil;
                if (![self.managedObjectContext save:&error]) {
                    NSLog(@"Error %@",error);
                }
                [self downloadNewTorrents];
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
}

/**
 *  Fetch info from database then check if it has new torrent then invoke extractTorrentDownloadURLWithURLString:
 */
- (void)downloadNewTorrents {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:DMHYKeywordEntityKey];
    request.predicate = [NSPredicate predicateWithFormat:@"keyword == %@ OR keyword == %@ OR keyword == %@ OR keyword == %@",self.today, self.yesterday, self.dayBeforeYesterday, kWeekdayOther];
    NSArray *fetchedKeywords = [self.managedObjectContext executeFetchRequest:request
                                                              error:NULL];

    for (DMHYKeyword *weekdayKeyword in fetchedKeywords) {
        for (DMHYKeyword *keyword in weekdayKeyword.subKeywords) {
            for (DMHYTorrent *torrent in keyword.torrents) {
                BOOL isNewTorrent = torrent.isNewTorrent.boolValue;
                if (isNewTorrent) {
                    torrent.isNewTorrent = @NO;
                    [self extractTorrentDownloadURLWithURLString:torrent.link];
                }
            }
        }
    }
    
    if ([self.managedObjectContext hasChanges]) {
        [self.managedObjectContext save:NULL];
    }
    
}

/**
 *  Extract torrent download url then download torrent.
 *
 *  @param urlString Donload URL String
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
            NSMutableArray *urlArr = [NSMutableArray new];
            
            for (ONOXMLElement *element in [doc XPath:kTest]) {
                [urlArr addObject:[element stringValue]];
            }
            
            NSString *downloadString = [urlArr firstObject];
            NSURL *dlURL = [NSURL URLWithString:[NSString stringWithFormat:DMHYURLPrefixFormat,downloadString]];
            
            [self downloadTorrentWithURL:dlURL];
            
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

#pragma mark - LocalNotification

- (void)postUserNotificationWithFileName:(NSString *)fileName {
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = @"下载完成";
    notification.informativeText = fileName;
    notification.soundName = NSUserNotificationDefaultSoundName;
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}

- (NSManagedObjectContext *)managedObjectContext {
    if (!_context) {
        _context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        _context.persistentStoreCoordinator = [[DMHYCoreDataStackManager sharedManager] persistentStoreCoordinator];
        _context.undoManager = nil;
    }
    return _context;
}

@end
