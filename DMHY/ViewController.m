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
#import "TitleTableCellView.h"
#import "NavigationView.h"
#import "PreferenceController.h"

@interface ViewController()<NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate>

@property (weak) IBOutlet NSTableView *tableView;
@property (weak) IBOutlet NSProgressIndicator *indicator;

@property (weak) IBOutlet NSTextField *keyword;
@property (weak) IBOutlet NSTextField *info;

@property (nonatomic, strong) NSMutableArray *torrents;
@property (nonatomic, strong) NSString *searchURLString;
@property (nonatomic, strong) NSURL *savePath;

@property (nonatomic) BOOL isSearch;
@property (nonatomic) BOOL isMagnetLink;
@property (nonatomic) BOOL isSubKeyword;

@property (nonatomic, strong) AFURLSessionManager *manager;
@property (nonatomic, strong) NSDateFormatter *dateFormater;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupTableViewStyle];
    [self setupData:self];
    [self setupPreference];
    [self observeNotification];
    
    // set NSTextFieldDelegate
    self.keyword.delegate = self;
  
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    
    // Update the view, if already loaded.
}

#pragma mark - Setup

- (void)setupTableViewStyle {
    self.tableView.usesAlternatingRowBackgroundColors = YES;
    self.tableView.rowSizeStyle = NSTableViewRowSizeStyleLarge;
    self.tableView.columnAutoresizingStyle = NSTableViewUniformColumnAutoresizingStyle;
    self.tableView.usesAlternatingRowBackgroundColors = YES;
    [self.tableView sizeLastColumnToFit];
}

- (void)setupPreference {
    self.isMagnetLink = [PreferenceController preferenceDownloadLinkType];
    self.savePath = [PreferenceController preferenceSavePath];
}

- (IBAction)setupData:(id)sender {
    NSLog(@"sender class %@",[sender class]);
    if ([sender isKindOfClass:[ViewController class]]) {
        self.isSubKeyword = YES;
    }
    if (!self.isSubKeyword) {
        return;
    }
    [self startAnimatingProgressIndicator];
    self.info.stringValue = @"";
    if ([self.keyword isEqual:@""]) {
        self.searchURLString = DMHYRSS;
        self.isSearch = NO;
    } else {
        
        self.searchURLString = [[NSString stringWithFormat:DMHYSearchByKeyword,self.keyword.stringValue]
                                stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        NSLog(@"%@",self.searchURLString);
        self.isSearch = YES;
    }
    if (self.isSearch) {
        [self.torrents removeAllObjects];
    }
    
    NSURL *url = [NSURL URLWithString:self.searchURLString];
    NSLog(@"url -> %@",url);
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    AFHTTPRequestOperation *op = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    if (op) {
        op.responseSerializer = [AFOnoResponseSerializer XMLResponseSerializer];
    }
    
    [op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation * _Nonnull operation, ONOXMLDocument *xmlDoc) {
        
        [xmlDoc enumerateElementsWithXPath:kXPathTorrentItem usingBlock:^(ONOXMLElement *element, NSUInteger idx, BOOL *stop) {
            
            TorrentItem *item = [[TorrentItem alloc] init];
            NSString *dateString = [[element firstChildWithTag:@"pubDate"] stringValue];
            item.pubDate = [self formatedDateStringFromDMHYDateString:dateString];
            item.title = [[element firstChildWithTag:@"title"] stringValue];
            item.link = [NSURL URLWithString:[[element firstChildWithTag:@"link"] stringValue]];
            item.author = [[element firstChildWithTag:@"author"] stringValue];
            NSString *magStr = [[element firstChildWithXPath:@"//enclosure/@url"] stringValue];
            item.magnet = [NSURL URLWithString:magStr];
            [self.torrents addObject:item];
            
        }];
        [self stopAnimatingProgressIndicator];
        [self.tableView reloadData];
        self.info.stringValue = @"加载完成 w";
//        for (TorrentItem *item in self.torrents) {
//            //            NSLog(@"%@",item);
//            NSLog(@"%@", [item valueForKey:@"title"]);
//        }
        
    } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
        self.info.stringValue = @"电波很差 poi 或者 花园酱傲娇了 w";
        [self stopAnimatingProgressIndicator];
        NSLog(@"Error %@",[error localizedDescription]);
    }];
    [[NSOperationQueue mainQueue] addOperation:op];
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
        NSTableCellView *cellView = [tableView makeViewWithIdentifier:@"pubDateCell" owner:self];
        cellView.textField.stringValue = torrent.pubDate;
        return cellView;
    }
    if ([identifier isEqualToString:@"titleCell"]) {
        TitleTableCellView *cellView = [tableView makeViewWithIdentifier:@"titleCell" owner:self];
        cellView.textField.stringValue = torrent.title;
        return cellView;
    }
    if ([identifier isEqualToString:@"authorCell"]) {
        NSTableCellView *cellView = [tableView makeViewWithIdentifier:@"authorCell" owner:self];
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
}

- (void)handleDownloadTypeChanged:(NSNotification *)noti {
    [self setupPreference];
}

- (void)handleSavaPathChanged:(NSNotification *)noti {
    [self setupPreference];
}

- (void)handleSelectKeywordChanged:(NSNotification *)noti {
    NSDictionary *userInfo = noti.userInfo;
    
    NSString *keywordStr   = userInfo[kSelectKeyword];
    BOOL isSubKeywordBOOL = [userInfo[kSelectKeywordIsSubKeyword] boolValue];
   
    self.isSubKeyword        = isSubKeywordBOOL;
    if (!isSubKeywordBOOL) {
        self.keyword.stringValue = @"";
    } else {
        self.keyword.stringValue = keywordStr;
    }
    
    [self setupData:userInfo];
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
        _manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:conf];
    }
    return _manager;
}

- (NSDateFormatter *)dateFormater {
    if (!_dateFormater) {
        _dateFormater = [[NSDateFormatter alloc] init];
    }
    return _dateFormater;
}

#pragma mark - Download

- (IBAction)queryDownloadURL:(id)sender {
    NSLog(@"queryDownloadURL");
    [self startAnimatingProgressIndicator];
    NSInteger row = [self.tableView rowForView:sender];
    TorrentItem *item = (TorrentItem *)[self.torrents objectAtIndex:row];
    NSURL *url;
    if (self.isMagnetLink) {
        url = item.magnet;
        [self stopAnimatingProgressIndicator];
        [[NSWorkspace sharedWorkspace] openURL:url];
        return;
    } else {
        NSLog(@"not returned download torrent");
        url = item.link;
    }
    NSLog(@"%@",item.link);
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
            NSLog(@"DL: %@",downloadString);
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

- (void)downloadTorrentWithURL:(NSURL *)url {
   
//    NSLog(@"manager %@",self.manager);
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLSessionDownloadTask *downloadTask = [self.manager downloadTaskWithRequest:request
                                                                     progress:nil
                                                                  destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
                                                                      
                                                                      return [self.savePath URLByAppendingPathComponent:[response suggestedFilename]];
                                                                      
                                                                  } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nonnull filePath, NSError * _Nonnull error) {
                                                                      NSLog(@"Download to : %@",filePath);
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
}

- (void)stopAnimatingProgressIndicator {
    [self.indicator stopAnimation:self];
}

#pragma mark - Utils

- (NSString *)formatedDateStringFromDMHYDateString:(NSString *)dateString {
//    NSLog(@"dateFormater %@",self.dateFormater);
    self.dateFormater.dateFormat = @"EEE, dd MM yyyy HH:mm:ss Z";
    self.dateFormater.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    NSDate *longDate = [self.dateFormater dateFromString:dateString];
    self.dateFormater.dateFormat = @"EEE HH:mm:ss yy-MM-dd";
    self.dateFormater.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];
    return [self.dateFormater stringFromDate:longDate];
    
}

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

@end
