//
//  Bangumi.m
//  DMHY
//
//  Created by 小笠原やきん on 3/20/16.
//  Copyright © 2016 yaqinking. All rights reserved.
//

#import "Bangumi.h"

@implementation Bangumi

- (NSString *)description {
    return [NSString stringWithFormat:@"Bangumi title %@ weekDayCN %@ timeCN %@ showDate %@", self.titleCN, self.weekDayCN, self.timeCN, self.showDate];
}

@end
