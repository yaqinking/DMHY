//
//  DMHYXMLDataManager.h
//  DMHY
//
//  Created by 小笠原やきん on 3/31/16.
//  Copyright © 2016 yaqinking. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const pubDateKey;
extern NSString * const titleKey;
extern NSString * const linkKey;
extern NSString * const authorKey;
extern NSString * const kXPathItem;
extern NSString * const DMHYXMLDataLoadCompletedNotification;

@interface DMHYXMLDataManager : NSObject

+ (DMHYXMLDataManager *)manager;

- (void)GET:(NSString *)urlString fromSite:(NSString *)siteName;

@end
