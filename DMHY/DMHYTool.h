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
 *  1 周日 2 周一 3 周二 4 周三 5 周四 6 周五 7 周日 0 周六 -1 周五
 *  @param weekday the weekday code. -1 to 7
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

/**
 *  Get bangumi season by month
 *
 *  @param month The current month code
 *
 *  @return belong to season
 */
+ (NSString *) bangumiSeasonOfMonth:(NSInteger )month;
@end
