//
//  DMHYTool.h
//  DMHY
//
//  Created by 小笠原やきん on 16/1/21.
//  Copyright © 2016年 yaqinking. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DMHYTool : NSObject

+ (NSString *) cn_weekdayFromWeekdayCode:(NSInteger )weekday;
+ (NSURL *)convertToURLWithURLString:(NSString *)urlString;

@end
