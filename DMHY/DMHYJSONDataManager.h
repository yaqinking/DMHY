//
//  DMHYJSONManager.h
//  DMHY
//
//  Created by 小笠原やきん on 3/31/16.
//  Copyright © 2016 yaqinking. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TorrentItem;

extern NSString * const DMHYBangumiMoeOpenTorrentPagePrefixFormat;
extern NSString * const publishTimeKey;
extern NSString * const idKey;
extern NSString * const teamNameKeyPath;
extern NSString * const uploaderUserNameKeyPath;
extern NSString * const magnetKey;

typedef void (^DMHYJSONDataFetchSuccessBlock)(NSArray<TorrentItem *> *objects);
typedef void (^DMHYJSONDataFetchFailureBlock)(NSError *error);

@interface DMHYJSONDataManager : NSObject

+ (DMHYJSONDataManager *)manager;

- (void)GET:(NSString *)urlString success:(DMHYJSONDataFetchSuccessBlock) successBlock failure:(DMHYJSONDataFetchFailureBlock) failureBlock;

@end
