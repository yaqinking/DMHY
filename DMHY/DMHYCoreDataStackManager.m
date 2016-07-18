//
//  DMHYCoreDataStackManager.m
//  DMHY
//
//  Created by 小笠原やきん on 9/22/15.
//  Copyright © 2015 yaqinking. All rights reserved.
//

#import "DMHYCoreDataStackManager.h"

NSString *const ApplicationDocumentsDirectoryName = @"com.yaqinking.DMHY";
NSString *const MainStoreFileName                 = @"DMHY.storedata";
NSString *const ErrorDomain                       = @"moe.yaqinking.dmhy.core.data.stack.error";
NSString *const DMHYSeedDataCompletedNotification = @"moe.yaqinking.dmhy.seed.data.completed";

@implementation DMHYCoreDataStackManager

#pragma mark - synthesize

@synthesize managedObjectModel            = _managedObjectModel;
@synthesize persistentStoreCoordinator    = _persistentStoreCoordinator;
@synthesize applicationDocumentsDirectory = _applicationDocumentsDirectory;
@synthesize storeURL                      = _storeURL;
@synthesize managedObjectContext          = _managedObjectContext;

+ (instancetype)sharedManager {
    static DMHYCoreDataStackManager *shareManager = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareManager = [[self alloc] init];
    });
    
    return shareManager;
}

- (NSManagedObjectModel *)managedObjectModel {
    if (_managedObjectModel) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"DMHY"
                                              withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];

    return _managedObjectModel;
}

- (NSURL *)applicationDocumentsDirectory {
    if (!_applicationDocumentsDirectory) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSArray *URLs = [fileManager URLsForDirectory:NSApplicationSupportDirectory
                                            inDomains:NSUserDomainMask];
        NSURL *URL = URLs[URLs.count - 1];
        URL = [URL URLByAppendingPathComponent:ApplicationDocumentsDirectoryName];
        NSError *error = nil;
        NSDictionary *properties = [URL resourceValuesForKeys:@[NSURLIsDirectoryKey]
                                                        error:&error];
        if (properties) {
            NSNumber *isDirectoryNumber = properties[NSURLIsDirectoryKey];
            if (isDirectoryNumber && !isDirectoryNumber.boolValue) {
                NSString *description = NSLocalizedString(@"Could not access the application folder...", @"Failed to initialize applicationSupportDirectory >_<");
                NSString *reason = NSLocalizedString(@"Found a file in its place.", @"Failed to initialize applicationSupportDirectory");
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey : description,
                                           NSLocalizedFailureReasonErrorKey : reason};
                error = [NSError errorWithDomain:ErrorDomain
                                            code:101
                                        userInfo:userInfo];
                [NSApp presentError:error];
                return nil;
            }
        } else {
            if (error.code == NSFileReadNoSuchFileError) {
                BOOL ok = [fileManager createDirectoryAtPath:URL.path
                                 withIntermediateDirectories:YES
                                                  attributes:nil
                                                       error:&error];
                if (!ok) {
                    [NSApp presentError:error];
                    return nil;
                }
            }
        }
        _applicationDocumentsDirectory = URL;
    }
    return _applicationDocumentsDirectory;
}

- (NSURL *)storeURL {
    if (!_storeURL) {
        _storeURL = [self.applicationDocumentsDirectory URLByAppendingPathComponent:MainStoreFileName];
    }
    return _storeURL;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (_persistentStoreCoordinator) {
        return _persistentStoreCoordinator;
    }
    NSURL *url = self.storeURL;
    if (!url) {
        return nil;
    }
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
    NSDictionary *options = @{
                              NSMigratePersistentStoresAutomaticallyOption : @(YES),
                              NSInferMappingModelAutomaticallyOption : @(YES),
                              };
    NSError *error;
    if (![psc addPersistentStoreWithType:NSSQLiteStoreType
                           configuration:nil
                                     URL:url
                                 options:options
                                   error:&error]) {
        [NSApp presentError:error];
        return nil;
    }
    _persistentStoreCoordinator = psc;
    return _persistentStoreCoordinator;
}

- (NSManagedObjectContext *)managedObjectContext {
    if (!_managedObjectContext) {
        _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        _managedObjectContext.undoManager = nil;
        _managedObjectContext.persistentStoreCoordinator = [self persistentStoreCoordinator];
    }
    return _managedObjectContext;
}

- (BOOL)resetDatabase {
    NSURL *storedURL = [self storeURL];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    if ([fileManager fileExistsAtPath:storedURL.path]) {
        if (![fileManager removeItemAtURL:storedURL error:&error]) {
            [NSApp presentError:error];
            return NO;
        } else {
            return YES;
        }
    }
    return NO;
}

- (void)seedDataIfNeed {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:DMHYSiteEntityKey];
    NSError *error = nil;
    NSArray *sites = [self.managedObjectContext executeFetchRequest:request error:&error];
    if (error) {
        [NSApp presentError:error];
        [NSApp terminate:self];
    }
    // 如果有站点数据存在不进行 seed 操作
    if (sites.count > 0) {
//        NSLog(@"Exist sites count %lu Return", (unsigned long)sites.count);
        return;
    }
    // 读取 json 文件
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"support-site" withExtension:@"json"];
    NSData *data = [NSData dataWithContentsOfURL:url];
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
    NSArray<NSDictionary *> *sitesArray = json[@"sites"];
    
    __block NSManagedObjectID *dmhyObjectID;
    [sitesArray enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull site, NSUInteger idx, BOOL * _Nonnull stop) {
        DMHYSite *insertedSite = [DMHYSite entityFormDictionary:site inManagedObjectContext:self.managedObjectContext];
        if ([insertedSite.name isEqualToString:@"dmhy"]) {
            dmhyObjectID = insertedSite.objectID;
        }
    }];
    __block DMHYSite *dmhySite = [self.managedObjectContext objectWithID:dmhyObjectID];
    __block NSArray<DMHYSite *> *insertedObjects = [[self.managedObjectContext insertedObjects] allObjects];
    
    // 查看是否有现有的关键字
    request = [NSFetchRequest fetchRequestWithEntityName:DMHYKeywordEntityKey];
    NSArray<DMHYKeyword *> *keywords = [self.managedObjectContext executeFetchRequest:request error:&error];
    if (error) {
        [NSApp presentError:error];
    }
    if (keywords.count > 0) {
        [keywords enumerateObjectsUsingBlock:^(DMHYKeyword * _Nonnull keyword, NSUInteger idx, BOOL * _Nonnull stop) {
            [dmhySite addKeywordsObject:keyword];
        }];
        [insertedObjects enumerateObjectsUsingBlock:^(DMHYSite * _Nonnull site, NSUInteger idx, BOOL * _Nonnull stop) {
            if (![site.name isEqualToString:@"dmhy"]) {
                [self addDefaultWeekdaysToSite:site];
            }
        }];
    } else {
        [insertedObjects enumerateObjectsUsingBlock:^(DMHYSite * _Nonnull site, NSUInteger idx, BOOL * _Nonnull stop) {
            [self addDefaultWeekdaysToSite:site];
        }];
    }
    [self saveContext];
    [DMHYNotification postNotificationName:DMHYSeedDataCompletedNotification];

}

- (DMHYSite *)currentUseSite {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:DMHYSiteEntityKey];
    request.predicate = [NSPredicate predicateWithFormat:@"isCurrentUse == %@", @YES];
    return [[self.managedObjectContext executeFetchRequest:request error:NULL] firstObject];
}

- (NSArray<DMHYSite *> *)autoDownloadSites {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:DMHYSiteEntityKey];
    request.predicate = [NSPredicate predicateWithFormat:@"isAutoDownload == %@", @YES];
    return [self.managedObjectContext executeFetchRequest:request error:NULL];
}

- (NSArray<DMHYSite *> *)allSites {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:DMHYSiteEntityKey];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"createDate" ascending:YES]];
    return [self.managedObjectContext executeFetchRequest:request error:NULL];
}

- (void)addDefaultWeekdaysToSite:(DMHYSite *)site {
    __block NSArray<NSString *> *weekdays = @[@"周一", @"周二", @"周三", @"周四", @"周五", @"周六", @"周日", @"其他"];
    [weekdays enumerateObjectsUsingBlock:^(NSString * _Nonnull weekday, NSUInteger idx, BOOL * _Nonnull stop) {
        DMHYKeyword *keyword = [DMHYKeyword entityForKeywordName:weekday isSubKeyword:@NO inManagedObjectContext:self.managedObjectContext];
        [site addKeywordsObject:keyword];
    }];
}

- (DMHYSite *)querySiteWithSiteName:(NSString *)siteName {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:DMHYSiteEntityKey];
    request.predicate = [NSPredicate predicateWithFormat:@"name == %@", siteName];
    DMHYSite *site = [[self.managedObjectContext executeFetchRequest:request error:NULL] firstObject];
    return site ? site : nil;
}

- (void)importFromSites:(NSArray<NSDictionary *> *)sites success:(void (^)())successHandler failure:(void (^)(NSError *))failureHandler {
    [sites enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull site, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *siteName = site[DMHYSiteNameKey];
        DMHYSite *existedSite = [self querySiteWithSiteName:siteName];
        NSDictionary *keywordsDictionary = site[DMHYSiteKeywordsKey];
        if (existedSite) {
            [[self weekdayKeys] enumerateObjectsUsingBlock:^(NSString * _Nonnull weekdayKey, NSUInteger idx, BOOL * _Nonnull stop) {
                NSArray *keywords = keywordsDictionary[weekdayKey];
                if (keywords) {
                    NSString *cnWeekday = [self cn_weekdayFromEN:weekdayKey];
                    [self insertKeywords:keywords weekday:cnWeekday site:existedSite];
                }
            }];
            [DMHYNotification postNotificationName:DMHYKeywordAddedNotification object:existedSite];
        } else {
            DMHYSite *insertedSite = [DMHYSite entityFormDictionary:site inManagedObjectContext:self.managedObjectContext];
            [self addDefaultWeekdaysToSite:insertedSite];
            [[self weekdayKeys] enumerateObjectsUsingBlock:^(NSString * _Nonnull weekdayKey, NSUInteger idx, BOOL * _Nonnull stop) {
                NSArray *keywords = keywordsDictionary[weekdayKey];
                if (keywords) {
                    NSString *cnWeekday = [self cn_weekdayFromEN:weekdayKey];
                    [self insertKeywords:keywords weekday:cnWeekday site:insertedSite];
                }
            }];
            [DMHYNotification postNotificationName:DMHYSiteAddedNotification];
        }
        if (idx == (sites.count-1)) {
            successHandler();
        }
    }];
}

- (void)exportSites:(NSArray<NSString *> *)siteNames success:(void (^)(NSString *))successHandler failure:(void (^)(NSError *))failureHandler {
    __block NSMutableArray *exportSites = [NSMutableArray new];
    [siteNames enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        DMHYSite *site = [[DMHYCoreDataStackManager sharedManager] querySiteWithSiteName:obj];
        if (site) {
            NSMutableDictionary *json = [NSMutableDictionary new];
            [json setValue:site.name forKey:DMHYSiteNameKey];
            NSString *tempMainURL = [self replacingDoubleAndSingeSlashToPlaceHolder:site.mainURL];
            [json setValue:tempMainURL forKey:DMHYSiteMainURLKey];
            NSString *tempSearchURL = [self replacingDoubleAndSingeSlashToPlaceHolder:site.searchURL];
            [json setValue:tempSearchURL forKey:DMHYSiteSearchURLKey];
            [json setValue:site.isFliterSite forKey:DMHYSiteFliterKey];
            [json setValue:site.isAutoDownload forKey:DMHYSiteAutoDLKey];
            [json setValue:site.downloadType forKey:DMHYSiteDLTypeKey];
            [json setValue:site.isDownloadFin forKey:DMHYSiteDLFinKey];
            [json setValue:site.responseType forKey:DMHYSiteResponseTypeKey];
            [json setValue:site.isCurrentUse forKey:DMHYSiteCurrentUseKey];
            NSMutableDictionary *keywordsDict = [NSMutableDictionary new];
            [site.keywords enumerateObjectsUsingBlock:^(DMHYKeyword * _Nonnull weekdayKeyword, BOOL * _Nonnull stop) {
                NSString *enWeekday = [self en_weekdayFromCN:weekdayKeyword.keyword];
                if (enWeekday && (weekdayKeyword.subKeywords.count != 0)) {
                    NSMutableArray *keywords = [NSMutableArray new];
                    [weekdayKeyword.subKeywords enumerateObjectsUsingBlock:^(DMHYKeyword * _Nonnull obj, BOOL * _Nonnull stop) {
                        [keywords addObject:obj.keyword];
                    }];
                    [keywordsDict setValue:keywords forKey:enWeekday];
                }
            }];
            if (keywordsDict) {
                [json setValue:keywordsDict forKey:DMHYSiteKeywordsKey];
                [exportSites addObject:json];
            }
        }
    }];
    NSDictionary *outputJSONDictionary = @{ @"sites": exportSites};
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:outputJSONDictionary options:NSJSONWritingPrettyPrinted error:&error];
    NSString *tempJSONString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    if (!error) {
        NSString *jsonString = [self replacingPlaceHolderToDoubleAndSingleSlash:tempJSONString];
        successHandler(jsonString);
    } else {
        failureHandler(error);
    }
}

- (NSString *)replacingDoubleAndSingeSlashToPlaceHolder:(NSString *)string {
    return [[string stringByReplacingOccurrencesOfString:@"//" withString:@"DOUBLESLASH"] stringByReplacingOccurrencesOfString:@"/" withString:@"SINGLESLASH"];
}

- (NSString *)replacingPlaceHolderToDoubleAndSingleSlash:(NSString *)string {
    return [[string stringByReplacingOccurrencesOfString:@"DOUBLESLASH" withString:@"//"] stringByReplacingOccurrencesOfString:@"SINGLESLASH" withString:@"/"];
}

- (void)insertKeywords:(NSArray<NSString *> *)keywords weekday:(NSString *)weekday site:(DMHYSite *)site {
    DMHYKeyword *weekdayKeyword = [[site.keywords filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"keyword == %@", weekday]] anyObject];
    if (weekdayKeyword) {
        [keywords enumerateObjectsUsingBlock:^(NSString * _Nonnull name, NSUInteger idx, BOOL * _Nonnull stop) {
            DMHYKeyword *existSubKeyword = [[weekdayKeyword.subKeywords filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"keyword == %@", name]] anyObject];
            if (!existSubKeyword) {
                DMHYKeyword *entity = [DMHYKeyword entityForKeywordName:name isSubKeyword:@YES inManagedObjectContext:self.managedObjectContext];
                [weekdayKeyword addSubKeywordsObject:entity];
//                NSLog(@"Inserted %@ Weekday %@ Site %@",entity.keyword, weekday, site.name);
            } else {
//                NSLog(@"Exist %@ Weekday %@ Site %@",name, weekday, site.name);
            }
        }];
    }
}

- (NSArray<NSString *> *)weekdayKeys {
    return @[@"monday", @"tuesday", @"wednesday", @"thursday", @"friday", @"saturday", @"sunday", @"other"];
}

- (NSDictionary *)encnWeekdayDicionary {
    return @{@"monday": @"周一",
             @"tuesday": @"周二",
             @"wednesday": @"周三",
             @"thursday": @"周四",
             @"friday": @"周五",
             @"saturday": @"周六",
             @"sunday": @"周日",
             @"other": @"其他"};
}

- (NSDictionary *)cnenWeekdayDicionary {
    return @{@"周一":@"monday",
             @"周二":@"tuesday",
             @"周三":@"wednesday",
             @"周四":@"thursday",
             @"周五":@"friday",
             @"周六":@"saturday",
             @"周日":@"sunday",
             @"其他":@"other" };
}

- (NSString *)cn_weekdayFromEN:(NSString *)key {
    return [[self encnWeekdayDicionary] valueForKey:key];
}

- (NSString *)en_weekdayFromCN:(NSString *)key {
    return [[self cnenWeekdayDicionary] valueForKey:key];
}

- (void)saveContext {
    NSError *error = nil;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Error %@",[error localizedDescription]);
    }
}

- (BOOL)existTorrentWithTitle:(NSString *)title {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:DMHYTorrentEntityKey];
    request.predicate = [NSPredicate predicateWithFormat:@"title == %@", title];
    return [self.managedObjectContext countForFetchRequest:request error:NULL] > 0 ? YES : NO;
}

@end
