//
//  DMHYXMLDataManager.h
//  DMHY
//
//  Created by 小笠原やきん on 3/31/16.
//  Copyright © 2016 yaqinking. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DMHYCoreDataStackManager.h"

@class TorrentItem;

extern NSString * const pubDateKey;
extern NSString * const titleKey;
extern NSString * const linkKey;
extern NSString * const authorKey;
extern NSString * const kXPathItem;

typedef void (^DMHYXMLDataFetchSuccessBlock)(NSArray<TorrentItem *> *objects);
typedef void (^DMHYXMLDataFetchFailureBlock)(NSError *error);
typedef void (^DMHYXMLDataFetchedNewTorrentBlock)(DMHYTorrent *torrent);
typedef void (^DMHYXMLDataFetchCompletionBlock)();

@interface DMHYXMLDataManager : NSObject

@property (nonatomic, readonly) DMHYXMLDataFetchSuccessBlock successBlock;
@property (nonatomic, readonly) DMHYXMLDataFetchFailureBlock failureBlock;

+ (DMHYXMLDataManager *)manager;

- (void)GET:(NSString *)urlString success:(DMHYXMLDataFetchSuccessBlock) successBlock failure:(DMHYXMLDataFetchFailureBlock) failureBlock;
- (void)fetchFromSite:(DMHYSite *) site queryKeyword:(DMHYKeyword *)keyword fetchedNew:(DMHYXMLDataFetchedNewTorrentBlock) block completion:(DMHYXMLDataFetchCompletionBlock) completionHandler failure:(DMHYXMLDataFetchFailureBlock) failureHandler;

@end
