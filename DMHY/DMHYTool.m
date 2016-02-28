//
//  DMHYTool.m
//  DMHY
//
//  Created by 小笠原やきん on 16/1/21.
//  Copyright © 2016年 yaqinking. All rights reserved.
//

#import "DMHYTool.h"

@interface DMHYTool ()

@end

@implementation DMHYTool

+ (NSString *) cn_weekdayFromWeekdayCode:(NSInteger )weekday {
    switch (weekday) {
        case 1:
            return @"周日";
            break;
        case 2:
            return @"周一";
        case 3:
            return @"周二";
        case 4:
            return @"周三";
        case 5:
            return @"周四";
        case 6:
            return @"周五";
        case 7:
            return @"周六";
        default:
            break;
    }
    return @"";
}

+ (NSURL *)convertToURLWithURLString:(NSString *)urlString {
    NSCharacterSet *set = [NSCharacterSet URLQueryAllowedCharacterSet];
    NSString *escapedString = [urlString stringByAddingPercentEncodingWithAllowedCharacters:set];
    return [NSURL URLWithString:escapedString];
}


@end
