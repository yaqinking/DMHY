//
//  DMHYNotification.h
//  DMHY
//
//  Created by 小笠原やきん on 3/23/16.
//  Copyright © 2016 yaqinking. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DMHYNotification : NSObject

+ (void)postNotificationName:(NSString *) name;
+ (void)postNotificationName:(NSString *)name userInfo:(id) info;
+ (void)postNotificationName:(NSString *)name object:(id)object;
+ (void)addObserver:(id)object selector:(SEL) selector name:(NSString *)name;

@end
