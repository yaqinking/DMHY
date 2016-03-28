//
//  DMHYJSONManager.h
//  DMHY
//
//  Created by 小笠原やきん on 3/31/16.
//  Copyright © 2016 yaqinking. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const DMHYBangumiMoeOpenTorrentPagePrefixFormat;
extern NSString * const publishTimeKey;
extern NSString * const idKey;
extern NSString * const teamNameKeyPath;
extern NSString * const uploaderUserNameKeyPath;
extern NSString * const magnetKey;
extern NSString * const DMHYJSONDataLoadCompletedNotification;

@interface DMHYJSONDataManager : NSObject

+ (DMHYJSONDataManager *)manager;
- (void)GET:(NSString *)urlString fromSite:(NSString *)siteName;

@end
