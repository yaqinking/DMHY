//
//  DMHYXMLDataManager.h
//  DMHY
//
//  Created by 小笠原やきん on 3/31/16.
//  Copyright © 2016 yaqinking. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TorrentItem;

extern NSString * const pubDateKey;
extern NSString * const titleKey;
extern NSString * const linkKey;
extern NSString * const authorKey;
extern NSString * const kXPathItem;

typedef void (^DMHYXMLDataFetchSuccessBlock)(NSArray<TorrentItem *> *objects);
typedef void (^DMHYXMLDataFetchFailureBlock)(NSError *error);

@interface DMHYXMLDataManager : NSObject

@property (nonatomic, readonly) DMHYXMLDataFetchSuccessBlock successBlock;
@property (nonatomic, readonly) DMHYXMLDataFetchFailureBlock failureBlock;

+ (DMHYXMLDataManager *)manager;

- (void)GET:(NSString *)urlString success:(DMHYXMLDataFetchSuccessBlock) successBlock failure:(DMHYXMLDataFetchFailureBlock) failureBlock;

@end
