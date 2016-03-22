//
//  DMHYNotification.m
//  DMHY
//
//  Created by 小笠原やきん on 3/23/16.
//  Copyright © 2016 yaqinking. All rights reserved.
//

#import "DMHYNotification.h"

@implementation DMHYNotification

+ (void)postNotificationName:(NSString *)name {
    [[NSNotificationCenter defaultCenter] postNotificationName:name object:nil];
}

+ (void)postNotificationName:(NSString *)name userInfo:(id)info {
    [[NSNotificationCenter defaultCenter] postNotificationName:name object:nil userInfo:info];
}

+ (void)addObserver:(id)object selector:(SEL)selector name:(NSString *)name {
    [[NSNotificationCenter defaultCenter] addObserver:object
                                             selector:selector
                                                 name:name
                                               object:nil];
}

@end
