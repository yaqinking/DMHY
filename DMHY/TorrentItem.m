//
//  TorrentItem.m
//  DMHY
//
//  Created by 小笠原やきん on 15/8/31.
//  Copyright © 2015年 yaqinking. All rights reserved.
//

#import "TorrentItem.h"

@implementation TorrentItem


- (NSString *)description {
    return [NSString stringWithFormat:@"PublishDate: %@ \n Title: %@ \n Author: %@ \n",self.pubDate,self.title,self.author];
}

//- (id)valueForUndefinedKey:(NSString *)key {
//
//    return nil;
//}

@end
