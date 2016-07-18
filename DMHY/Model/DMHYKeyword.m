//
//  DMHYKeyword.m
//  DMHY
//
//  Created by 小笠原やきん on 9/23/15.
//  Copyright © 2015 yaqinking. All rights reserved.
//

#import "DMHYKeyword.h"
#import "DMHYTorrent.h"
#import "DMHYSite.h"

@implementation DMHYKeyword

// Insert code here to add functionality to your managed object subclass

+ (DMHYKeyword *)entityForKeywordName:(NSString *)name isSubKeyword:(NSNumber *)subKeyword inManagedObjectContext:(NSManagedObjectContext *)context {
    DMHYKeyword *entity = [NSEntityDescription insertNewObjectForEntityForName:@"Keyword" inManagedObjectContext:context];
    entity.keyword = name;
    entity.createDate = [NSDate new];
    entity.isSubKeyword = subKeyword;
    return entity;
}

@end
