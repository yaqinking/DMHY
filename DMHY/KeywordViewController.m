//
//  KeywordViewController.m
//  DMHY
//
//  Created by 小笠原やきん on 3/20/16.
//  Copyright © 2016 yaqinking. All rights reserved.
//

#import "KeywordViewController.h"

#import "DMHYAPI.h"
#import "DMHYTool.h"
#import "DMHYKeyword.h"
#import "DMHYCoreDataStackManager.h"
#import "Bangumi.h"
#import "AFNetworking.h"
#import "AFOnoResponseSerializer.h"
#import "Ono.h"

@interface KeywordViewController ()<NSTableViewDataSource, NSTableViewDelegate>

@property (weak) IBOutlet NSTableView *tableView;
@property (weak) IBOutlet NSTextField *infoTextField;

@property (nonatomic, strong) NSString               *bangumiURLString;
@property (nonatomic, strong) NSMutableArray         *allBangumi;
@property (nonatomic, strong) NSMutableArray         *bangumiDatas;
@property (nonatomic, strong) NSMutableArray         *fetchedTitles;
@property (nonatomic, strong) NSArray                *parentKeywords;
@property (nonatomic, strong) AFHTTPSessionManager   *httpManager;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, assign) NSUInteger             titleIndex;

@end

@implementation KeywordViewController

@synthesize managedObjectContext = _context;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupTableViewStyle];
    [self setupBangumiURLString];
}

- (void)setupBangumiURLString {
    NSDate *now                   = [NSDate new];
    NSDateFormatter *dateFormater = [NSDateFormatter new];
    dateFormater.dateFormat       = @"MM";
    NSInteger month         = [[dateFormater stringFromDate:now] integerValue];
    dateFormater.dateFormat = @"YY";
    NSString *year          = [dateFormater stringFromDate:now];
    NSString *season        = [DMHYTool bangumiSeasonOfMonth:month];
    self.bangumiURLString   = [NSString stringWithFormat:BGMListYearSeasonFormat, year, season];
}

- (void)setupTableViewStyle {
    self.tableView.usesAlternatingRowBackgroundColors = YES;
    self.tableView.allowsMultipleSelection            = YES;
    self.tableView.rowSizeStyle                       = NSTableViewRowSizeStyleMedium;
    self.tableView.columnAutoresizingStyle            = NSTableViewUniformColumnAutoresizingStyle;
    [self.tableView sizeLastColumnToFit];
}

/**
 *  Set Bangumi Main Info
 */
- (IBAction)fetchBangumiInfo:(id) sender {
    [self.httpManager GET:self.bangumiURLString
               parameters:nil
                  success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
                      NSArray *bangumiList = [responseObject allValues];
                      for (NSDictionary *bgmDict in bangumiList) {
                          Bangumi *bgm = [Bangumi new];
                          NSString *title = bgmDict[BangumiTitleCNKey];
                          NSString *titleJP = bgmDict[BangumiTitleJPKey];
                          bgm.titleJP = titleJP;
                          bgm.titleCN     = [self shortTitleWithOriginal:title];
                          bgm.titleCNFull = title;
                          bgm.newBgm      = [bgmDict[BangumiNewBGMKey] boolValue];
                          NSInteger timeJP      = [bgmDict[BangumiTimeJPKey] integerValue];
                          if (timeJP <= 2359 && timeJP >= 1500) {
                              NSInteger weekdayCode = [bgmDict[BangumiWeekDayJPKey] integerValue] +2;
                              bgm.weekDayCN = [DMHYTool cn_weekdayFromWeekdayCode:weekdayCode];
                          }
                          if (timeJP <= 1459 && timeJP >= 0000) {
                              NSInteger weekdayCode = [[bgmDict valueForKey:BangumiWeekDayJPKey] integerValue] + 1;
                              bgm.weekDayCN = [DMHYTool cn_weekdayFromWeekdayCode:weekdayCode];
                          }
                          bgm.timeCN      = bgmDict[BangumiTimeCNKey];
                          bgm.officalSite = bgmDict[BangumiOfficalSiteKey];
                          [self.allBangumi addObject:bgm];
                      }
                      self.infoTextField.stringValue = @"载入基本信息完毕，开始解析字幕组信息";
                      [self setupSubGroup];
                  } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                      self.infoTextField.stringValue = @"究竟哪里出问题了呢 _(:3 」∠)_";
                      NSLog(@"Error %@",error);
                  }];
}

/**
 *  Set Bangumi SubGroup Property
 */
- (void)setupSubGroup {
    [self.allBangumi enumerateObjectsUsingBlock:^(Bangumi * bgm, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *searchURLString = [[NSString stringWithFormat:DMHYSearchByKeyword, bgm.titleCN] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        NSURL *url = [NSURL URLWithString:searchURLString];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        AFHTTPRequestOperation *op = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        op.responseSerializer = [AFOnoResponseSerializer XMLResponseSerializer];
        __block NSUInteger progress = idx+2;
        [op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation * _Nonnull operation, ONOXMLDocument *xmlDoc) {
            dispatch_async(dispatch_queue_create("subGroupQueue", 0), ^{
                [xmlDoc enumerateElementsWithXPath:kXPathTorrentItem usingBlock:^(ONOXMLElement *element, NSUInteger idx, BOOL *stop) {
                    NSString *title = [[element firstChildWithTag:@"title"] stringValue];
                    [self.fetchedTitles addObject:title];
                    if ([title containsString:@"Ohys-Raw"]) {
                        *stop = 1;
                        self.titleIndex = idx;
                    }
                }];
                
                if (self.titleIndex == 0) {
                    self.fetchedTitles = nil;
                    self.titleIndex = 0;
                    bgm.subGroup = @"";
                    return ;
                }
                if ((self.titleIndex - 1) > 0) {
                    NSString *bangumi = self.fetchedTitles[(self.titleIndex-1)];
                    NSMutableString *subGroup = [NSMutableString new];
                    if ([bangumi containsString:@"字幕组"]) {
                        NSRange subRange = [bangumi rangeOfString:@"字幕组"];
                        NSUInteger idx = subRange.location;
                        NSRange newRange = NSMakeRange(1, (idx-1));
                        subGroup = [[bangumi substringWithRange:newRange] mutableCopy];
                    }
                    if ([bangumi containsString:@"字幕組"]) {
                        NSRange subRange = [bangumi rangeOfString:@"字幕組"];
                        NSUInteger idx = subRange.location;
                        NSRange newRange = NSMakeRange(1, (idx-1));
                        subGroup = [[bangumi substringWithRange:newRange] mutableCopy];
                    }
                    if ([bangumi containsString:@"字幕社"]) {
                        NSRange subRange = [bangumi rangeOfString:@"字幕社"];
                        NSUInteger idx = subRange.location;
                        NSRange newRange = NSMakeRange(1, (idx-1));
                        subGroup = [[bangumi substringWithRange:newRange] mutableCopy];
                        if ([subGroup containsString:@"&"]) {
                            subGroup = [[subGroup stringByReplacingOccurrencesOfString:@"&" withString:@""] mutableCopy];
                        }
                    }
                    bgm.subGroup = subGroup;
//                    NSLog(@"%@ %@ %@", bgm.titleCN, subGroup, bgm.weekDayCN);
                }
                self.fetchedTitles = nil;
                self.titleIndex = 0;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView reloadData];
                    if (progress == self.allBangumi.count) {
                        self.infoTextField.stringValue = @"全部解析完毕 >_< 预测偏差巨大，请谨慎使用。";
                    } else {
                        self.infoTextField.stringValue = [NSString stringWithFormat:@"字幕组分析进度 %li 分之 %lu 完了，%@ => %@", self.allBangumi.count,progress, bgm.titleCN, bgm.subGroup];
                    }
                });
            });
            
        } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
            self.infoTextField.stringValue = @"不知道哪里出问题了 _(:3 」∠)_";
            NSLog(@"Error %@",[error localizedDescription]);
        }];
        [[NSOperationQueue mainQueue] addOperation:op];
    }];
}

#pragma mark - Table View
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.allBangumi.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSString *identifier = tableColumn.identifier;
    Bangumi *bangumi = self.allBangumi[row];
    if ([identifier isEqualToString:@"titleJPCell"]) {
        NSTableCellView *cellView = [tableView makeViewWithIdentifier:@"titleJPCell" owner:self];
        cellView.textField.stringValue = bangumi.titleJP;
        return cellView;
    }
    if ([identifier isEqualToString:@"titleCNFullCell"]) {
        NSTableCellView *cellView = [tableView makeViewWithIdentifier:@"titleCNFullCell" owner:self];
        cellView.textField.stringValue = bangumi.titleCNFull;
        return cellView;
    }
    if ([identifier isEqualToString:@"titleCNCell"]) {
        NSTableCellView *cellView = [tableView makeViewWithIdentifier:@"titleCNCell" owner:self];
        cellView.textField.stringValue = bangumi.titleCN;
        return cellView;
    }
    if ([identifier isEqualToString:@"subGroupCell"]) {
        NSTableCellView *cellView = [tableView makeViewWithIdentifier:@"subGroupCell" owner:self];
        if (!bangumi.subGroup) {
            cellView.textField.stringValue = @"";
        } else {
            cellView.textField.stringValue = bangumi.subGroup;
        }
        return cellView;
    }
    if ([identifier isEqualToString:@"weekDayCell"]) {
        NSTableCellView *cellView = [tableView makeViewWithIdentifier:@"weekDayCell" owner:self];
        cellView.textField.stringValue = bangumi.weekDayCN;
        return cellView;
    }
    return nil;
}

- (IBAction)addSelectBangumi:(id)sender {
    if (self.allBangumi.count != 0) {
        NSIndexSet *selectSet = [self.tableView selectedRowIndexes];
        [selectSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
            [self saveBangumiToDatabaseWithIndex:idx];
        }];
        [self saveChangesAndNotify];
    }
}
- (IBAction)addAllBangumi:(id)sender {
    if (self.allBangumi.count != 0) {
        [self.allBangumi enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [self saveBangumiToDatabaseWithIndex:idx];
        }];
        [self saveChangesAndNotify];
    }
}

- (void)saveChangesAndNotify {
    if ([self.managedObjectContext hasChanges]) {
        [self.managedObjectContext save:NULL];
        [self.managedObjectContext reset];
    }
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter postNotificationName:DMHYSearsonKeywordAddedNotification object:nil];
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"重启"];
    [alert addButtonWithTitle:@"取消"];
    [alert setMessageText:@"添加完成"];
    [alert setInformativeText:@"手动重启应用生效 <_<"];
    [alert setAlertStyle:NSWarningAlertStyle];
    if ([alert runModal] == NSAlertFirstButtonReturn) {
        [[NSApplication sharedApplication] terminate:self];
    }
}

- (void)saveBangumiToDatabaseWithIndex:(NSUInteger )idx {
    Bangumi *bgm = self.allBangumi[idx];
    
    __block NSInteger currentParentIdx = 0;
    [self.parentKeywords enumerateObjectsUsingBlock:^(DMHYKeyword * _Nonnull keyword, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([keyword.keyword isEqualToString:bgm.weekDayCN]) {
            currentParentIdx = idx;
        }
    }];
    DMHYKeyword *parentKeyword = self.parentKeywords[currentParentIdx];
    
    NSString *keywordString = [NSString stringWithFormat:@"%@ %@",bgm.titleCN, bgm.subGroup];
    NSFetchRequest *requestKeyword = [NSFetchRequest fetchRequestWithEntityName:@"Keyword"];
    requestKeyword.predicate       = [NSPredicate predicateWithFormat:@"keyword == %@",keywordString];
    NSArray *existKeywords = [self.managedObjectContext executeFetchRequest:requestKeyword
                                                                      error:NULL];
    
    if (!existKeywords.count) {
        //                    NSLog(@"Didn't exist %@",title);
        DMHYKeyword *keyword = [NSEntityDescription insertNewObjectForEntityForName:@"Keyword"
                                                             inManagedObjectContext:self.managedObjectContext];
        keyword.keyword      = keywordString;
        keyword.createDate   = [NSDate new];
        keyword.isSubKeyword = @YES;
        [parentKeyword addSubKeywordsObject:keyword];
    } else {
        //                    NSLog(@"Exist");
        return ;
    }
//    NSLog(@"Insert %@ %@ %@ done.",bgm.titleCN,bgm.subGroup,bgm.weekDayCN);
}

- (IBAction)fetchAllBangumi:(id)sender {
    NSLog(@"%@",self.allBangumi);
}

- (NSString *)shortTitleWithOriginal:(NSString *)longTitle {
    if ([longTitle containsString:@"&"]) {
        return [[longTitle stringByReplacingOccurrencesOfString:@"&" withString:@""] substringWithRange:NSMakeRange(0, 2)];
    }
    return [longTitle substringWithRange:NSMakeRange(0, 2)];
}

- (AFHTTPSessionManager *)httpManager {
    if (!_httpManager) {
        _httpManager = [AFHTTPSessionManager manager];
        _httpManager.requestSerializer = [AFJSONRequestSerializer serializer];
        _httpManager.responseSerializer = [AFJSONResponseSerializer serializer];
        _httpManager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/plain"];
    }
    return _httpManager;
}

- (NSMutableArray *)allBangumi {
    if (!_allBangumi) {
        _allBangumi = [NSMutableArray new];
    }
    return _allBangumi;
}

- (NSArray *)parentKeywords {
    if (!_parentKeywords) {
        NSFetchRequest *requestKeyword = [NSFetchRequest fetchRequestWithEntityName:@"Keyword"];
        requestKeyword.predicate = [NSPredicate predicateWithFormat:@"isSubKeyword != YES"];
        _parentKeywords = [self.managedObjectContext executeFetchRequest:requestKeyword
                                                                   error:NULL];
    }
    return _parentKeywords;
}

- (NSMutableArray *)fetchedTitles {
    if (!_fetchedTitles) {
        _fetchedTitles = [NSMutableArray new];
    }
    return _fetchedTitles;
}

- (NSMutableArray *)bangumiDatas {
    if (!_bangumiDatas) {
        _bangumiDatas = [NSMutableArray new];
    }
    return _bangumiDatas;
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
