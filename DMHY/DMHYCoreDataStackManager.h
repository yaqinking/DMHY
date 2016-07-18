//
//  DMHYCoreDataStackManager.h
//  DMHY
//
//  Created by 小笠原やきん on 9/22/15.
//  Copyright © 2015 yaqinking. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DMHYAPI.h"
#import "DMHYSite.h"
#import "DMHYKeyword.h"
#import "DMHYTorrent.h"

extern NSString * const DMHYSeedDataCompletedNotification;

@import Cocoa;

@interface DMHYCoreDataStackManager : NSObject

@property (nonatomic, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, readonly) NSURL *storeURL;
@property (nonatomic, readonly) NSURL *applicationDocumentsDirectory;

+ (instancetype)sharedManager;
- (BOOL)resetDatabase;

- (void)seedDataIfNeed;
- (void)saveContext;



- (DMHYSite *)querySiteWithSiteName:(NSString *)siteName;
- (void)addDefaultWeekdaysToSite:(DMHYSite *)site;

/**
 *  Insert multi keywords 
 *  (site->weeday->keywords)
 *
 *  @param keywords Keywords array to insert
 *  @param weekday  The keywords is belong to this weekday
 *  @param site     The weekday belong to this site
 */
- (void)insertKeywords:(NSArray<NSString *> *)keywords weekday:(NSString *)weekday site:(DMHYSite *) site;

- (DMHYSite *)currentUseSite;
- (NSArray<DMHYSite *> *)autoDownloadSites;
- (NSArray<DMHYSite *> *)allSites;

- (BOOL)existTorrentWithTitle:(NSString *)title;

- (void)importFromSites:(NSArray<NSDictionary *> *)sites success:(void(^)()) successHandler failure:(void(^)(NSError *error)) failureHandler;
- (void)exportSites:(NSArray<NSString *> *)siteNames success:(void(^)(NSString *json)) successHandler failure:(void(^)(NSError *error)) failureHandler;

@end
