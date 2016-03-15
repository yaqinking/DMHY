//
//  DMHYTool.h
//  DMHY
//
//  Created by 小笠原やきん on 16/1/21.
//  Copyright © 2016年 yaqinking. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DMHYTool : NSObject
/**
 *  Get chinese weekday.
 *
 *  @param weekday the weekday code.
 *
 *  @return Chinese weekday string.
 */
+ (NSString *) cn_weekdayFromWeekdayCode:(NSInteger )weekday;
/**
 *  Convert a url string to valided URL.
 *
 *  @param urlString The url string maybe contain chinese.
 *
 *  @return The valided URL.
 */
+ (NSURL *)convertToURLWithURLString:(NSString *)urlString;

@end
